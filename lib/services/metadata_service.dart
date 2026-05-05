import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MetadataService {
  static const String streamUrl = 'https://c30.radioboss.fm:8234/stream';
  static const String apiBaseUrl = 'https://c30.radioboss.fm';
  static const String apiKey = 'RAP0IRW5DSEX';
  static const String stationId = '234';

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

  /// Attempt to get ICY metadata from the stream
  Future<Map<String, String>> _getIcyMetadata() async {
    try {
      final request = http.Request('GET', Uri.parse(streamUrl));
      request.headers['Icy-MetaData'] = '1';
      request.headers['User-Agent'] = 'FeniksRadio/1.0';

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 10),
      );

      // Check for ICY metadata interval
      final icyMetaInt = streamedResponse.headers['icy-metaint'];
      if (icyMetaInt != null) {
        final metaInterval = int.tryParse(icyMetaInt);
        if (metaInterval != null && metaInterval > 0) {
          // Read the stream and extract metadata
          final metadata = await _extractIcyMetadata(
            streamedResponse,
            metaInterval,
          );
          return metadata;
        }
      }
    } catch (_) {}
    return {};
  }

  /// Extract ICY metadata from the stream
  Future<Map<String, String>> _extractIcyMetadata(
    http.StreamedResponse response,
    int metaInterval,
  ) async {
    try {
      final stream = response.stream;
      var bytesRead = 0;

      await for (var chunk in stream) {
        bytesRead += chunk.length;

        if (bytesRead >= metaInterval) {
          // We've reached the metadata block
          // Read the metadata length (1 byte * 16)
          final metaLength = chunk[metaInterval % chunk.length] * 16;

          if (metaLength > 0) {
            // Extract metadata string
            var metaBytes = <int>[];

            // This is simplified - in practice you'd need to handle
            // metadata that spans multiple chunks
            if (chunk.length > metaInterval + 1 + metaLength) {
              metaBytes = chunk.sublist(
                metaInterval + 1,
                metaInterval + 1 + metaLength,
              );
            }

            if (metaBytes.isNotEmpty) {
              final metaString = String.fromCharCodes(metaBytes).trim();
              return _parseIcyMetadata(metaString);
            }
          }
          break;
        }
      }
    } catch (_) {}
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
      final endpoint = 'https://c30.radioboss.fm:8234/status-json.xsl';

      final response = await http
          .get(
            Uri.parse(endpoint),
            headers: {
              'User-Agent': 'FeniksRadio/1.0',
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
    } catch (_) {}
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
    } catch (_) {}

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
        result['artist'] = 'Uvijek otvoreni za vaše divne poruke';
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
            result['artist'] = 'Uvijek otvoreni za vaše divne poruke';
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
