import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/log.dart';

class MetadataService {
  Timer? _metadataTimer;
  StreamController<Map<String, String>>? _metadataController;

  Stream<Map<String, String>>? get metadataStream =>
      _metadataController?.stream;

  /// Initialize the metadata service and start fetching metadata
  void start() {
    _metadataController = StreamController<Map<String, String>>.broadcast();

    // Fetch metadata immediately
    _fetchMetadata();

    // Set up periodic fetching (every 30 seconds)
    _metadataTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchMetadata();
    });
  }

  /// Stop the metadata service
  void stop() {
    _metadataTimer?.cancel();
    _metadataTimer = null;
    _metadataController?.close();
    _metadataController = null;
  }

  /// Fetch current song metadata from the radio stream
  Future<Map<String, String>> _fetchMetadata() async {
    try {
      final apiMetadata = await _getApiMetadata();
      if (apiMetadata.isNotEmpty) {
        _metadataController?.add(apiMetadata);
        return apiMetadata;
      }
      final icyMetadata = await _getIcyMetadata();
      if (icyMetadata.isNotEmpty) {
        _metadataController?.add(icyMetadata);
        return icyMetadata;
      }
      final fallback = {
        'title': 'Feniks Radio',
        'artist': 'Samo dobre vijesti!',
      };
      _metadataController?.add(fallback);
      return fallback;
    } catch (_) {
      final fallback = {
        'title': 'Feniks Radio',
        'artist': 'Samo dobre vijesti!',
      };
      _metadataController?.add(fallback);
      return fallback;
    }
  }

  /// Attempt to get ICY metadata from the stream. Reads only until the first
  /// metadata block and always closes the connection, so the audio stream is
  /// never downloaded in the background.
  Future<Map<String, String>> _getIcyMetadata() async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(AppConfig.streamUrl));
      request.headers['Icy-MetaData'] = '1';
      request.headers['User-Agent'] = AppConfig.userAgent;

      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 10));
      final metaInterval = int.tryParse(response.headers['icy-metaint'] ?? '');
      if (metaInterval == null || metaInterval <= 0) return {};

      final metadata = await _extractIcyMetadata(
        response,
        metaInterval,
      ).timeout(const Duration(seconds: 10));
      return metadata;
    } catch (_) {
      return {};
    } finally {
      client.close();
    }
  }

  /// Extract the first ICY metadata block from the stream.
  Future<Map<String, String>> _extractIcyMetadata(
    http.StreamedResponse response,
    int metaInterval,
  ) async {
    final buffer = <int>[];
    int? metaLength;
    await for (final chunk in response.stream) {
      buffer.addAll(chunk);
      if (metaLength == null && buffer.length > metaInterval) {
        metaLength = buffer[metaInterval] * 16;
        if (metaLength == 0) return {};
      }
      if (metaLength != null &&
          buffer.length >= metaInterval + 1 + metaLength) {
        final bytes = buffer.sublist(
          metaInterval + 1,
          metaInterval + 1 + metaLength,
        );
        final metaString = utf8
            .decode(bytes, allowMalformed: true)
            .replaceAll('\u0000', '')
            .trim();
        return _parseIcyMetadata(metaString);
      }
      // Safety limit: never read more than ~1 MB of audio.
      if (buffer.length > 1024 * 1024) break;
    }
    return {};
  }

  /// Parse ICY metadata string
  Map<String, String> _parseIcyMetadata(String metaString) {
    final result = <String, String>{};

    // ICY metadata format: StreamTitle='Artist - Title';StreamUrl='';
    final titleMatch = RegExp(r"StreamTitle='([^']*)'").firstMatch(metaString);
    if (titleMatch != null) {
      final streamTitle = titleMatch.group(1) ?? '';

      // Try to split artist and title
      if (streamTitle.contains(' - ')) {
        final parts = streamTitle.split(' - ');
        if (parts.length >= 2) {
          result['artist'] = parts[0].trim();
          result['title'] = parts.sublist(1).join(' - ').trim();
        } else {
          result['title'] = streamTitle;
          result['artist'] = '';
        }
      } else {
        result['title'] = streamTitle;
        result['artist'] = '';
      }
    }

    return result;
  }

  /// Get metadata from the API using the correct JSON endpoint
  Future<Map<String, String>> _getApiMetadata() async {
    try {
      // Use the correct JSON status endpoint

      final response = await http
          .get(
            Uri.parse(AppConfig.nowPlayingUrl),
            headers: {
              'User-Agent': AppConfig.userAgent,
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          final result = _parseRadioBossJson(data);
          if (result.isNotEmpty) {
            return result;
          }
        } catch (_) {
          // If not JSON, try to parse as text
          final result = _parseApiText(response.body);
          if (result.isNotEmpty) {
            return result;
          }
        }
      }
    } catch (e) {
      logError('Fetching song from the status endpoint', e);
    }
    return {};
  }

  /// Parse RadioBoss JSON status response
  Map<String, String> _parseRadioBossJson(dynamic data) {
    final result = <String, String>{};

    try {
      if (data is Map) {
        // RadioBoss JSON typically contains these fields
        String? title;
        String? artist;

        // Look for common RadioBoss JSON fields
        if (data.containsKey('title')) {
          title = data['title']?.toString();
        }

        if (data.containsKey('artist')) {
          artist = data['artist']?.toString();
        }

        // Handle RadioBoss Icecast JSON structure
        if (data.containsKey('icestats')) {
          final icestats = data['icestats'];
          if (icestats is Map && icestats.containsKey('source')) {
            final source = icestats['source'];

            // Source can be either a single object or an array
            if (source is List && source.isNotEmpty) {
              // Take the first source that has metadata
              for (final sourceItem in source) {
                if (sourceItem is Map) {
                  // Check for yp_currently_playing (complete song info)
                  if (sourceItem.containsKey('yp_currently_playing')) {
                    final songInfo = sourceItem['yp_currently_playing']
                        ?.toString();
                    if (songInfo != null && songInfo.isNotEmpty) {
                      return _parseSongString(songInfo);
                    }
                  }

                  // Check for title field
                  if (sourceItem.containsKey('title')) {
                    final songInfo = sourceItem['title']?.toString();
                    if (songInfo != null && songInfo.isNotEmpty) {
                      return _parseSongString(songInfo);
                    }
                  }
                }
              }
            } else if (source is Map) {
              // Handle single source object
              if (source.containsKey('yp_currently_playing')) {
                final songInfo = source['yp_currently_playing']?.toString();
                if (songInfo != null && songInfo.isNotEmpty) {
                  return _parseSongString(songInfo);
                }
              }

              if (source.containsKey('title')) {
                final songInfo = source['title']?.toString();
                if (songInfo != null && songInfo.isNotEmpty) {
                  return _parseSongString(songInfo);
                }
              }
            }
          }
        }

        // Look for stream title that might contain "Artist - Title"
        if (data.containsKey('stream_title') ||
            data.containsKey('streamtitle')) {
          final streamTitle = (data['stream_title'] ?? data['streamtitle'])
              ?.toString();
          if (streamTitle != null && streamTitle.isNotEmpty) {
            return _parseSongString(streamTitle);
          }
        }

        // Look for yp_currently_playing (common in Icecast)
        if (data.containsKey('yp_currently_playing')) {
          final currentlyPlaying = data['yp_currently_playing']?.toString();
          if (currentlyPlaying != null && currentlyPlaying.isNotEmpty) {
            return _parseSongString(currentlyPlaying);
          }
        }

        // If we found separate title and artist
        if (title != null || artist != null) {
          result['title'] = title ?? '';
          result['artist'] = artist ?? '';
        }
      }
    } catch (e) {
      logError('Parsing the status response', e);
    }

    return result;
  }

  /// Parse text API response
  Map<String, String> _parseApiText(String text) {
    final result = <String, String>{};

    // Look for common patterns in the response
    final patterns = [
      RegExp(r'<title>(.*?)</title>', caseSensitive: false),
      RegExp(r'<song>(.*?)</song>', caseSensitive: false),
      RegExp(r'StreamTitle="([^"]*)"', caseSensitive: false),
      RegExp(r'Current song:\s*(.*)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final value = match.group(1)?.trim() ?? '';
        if (value.isNotEmpty) {
          if (value.contains(' - ')) {
            final parts = value.split(' - ');
            result['artist'] = parts[0].trim();
            result['title'] = parts.sublist(1).join(' - ').trim();
          } else {
            result['title'] = value;
          }
          break;
        }
      }
    }

    return result;
  }

  /// Helper method to parse song strings in "Artist - Title" format
  Map<String, String> _parseSongString(String songString) {
    final result = <String, String>{};

    if (songString.isNotEmpty) {
      // Check if this is the Feniks Radio phone number pattern
      if (_isPhoneNumberMetadata(songString)) {
        result['title'] = 'Feniks Radio';
        result['artist'] = 'Samo dobre vijesti!';
        return result;
      }

      if (songString.contains(' - ')) {
        final parts = songString.split(' - ');
        if (parts.length >= 2) {
          final artist = parts[0].trim();
          final title = parts.sublist(1).join(' - ').trim();

          // Check if artist or title contains phone number
          if (_isPhoneNumberMetadata(artist) || _isPhoneNumberMetadata(title)) {
            result['title'] = 'Feniks Radio';
            result['artist'] = 'Samo dobre vijesti!';
            return result;
          }

          result['artist'] = artist;
          result['title'] = title;
        } else {
          result['title'] = songString.trim();
          result['artist'] = '';
        }
      } else {
        result['title'] = songString.trim();
        result['artist'] = '';
      }
    }

    return result;
  }

  /// Check if the metadata contains phone number patterns
  bool _isPhoneNumberMetadata(String text) {
    if (text.isEmpty) return false;

    // Common phone number patterns for Feniks Radio
    final phonePatterns = [
      RegExp(r'066\s*/?\s*17\s*17\s*13', caseSensitive: false),
      RegExp(r'066\s*-?\s*17\s*-?\s*17\s*-?\s*13', caseSensitive: false),
      RegExp(r'066\s*/?17\s*/?17\s*/?13', caseSensitive: false),
      RegExp(r'\+387\s*66\s*17\s*17\s*13', caseSensitive: false),
      RegExp(r'066\s*171713', caseSensitive: false),
    ];

    for (final pattern in phonePatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }

    return false;
  }

  /// Get current metadata once (without starting the stream)
  Future<Map<String, String>> getCurrentMetadata() async {
    return await _fetchMetadata();
  }
}
