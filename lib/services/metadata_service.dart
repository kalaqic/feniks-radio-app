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

  void start() {
    _metadataController = StreamController<Map<String, String>>.broadcast();

    _fetchMetadata();

    _metadataTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchMetadata();
    });
  }

  void stop() {
    _metadataTimer?.cancel();
    _metadataTimer = null;
    _metadataController?.close();
    _metadataController = null;
  }

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

      if (buffer.length > 1024 * 1024) break;
    }
    return {};
  }

  Map<String, String> _parseIcyMetadata(String metaString) {
    final result = <String, String>{};

    final titleMatch = RegExp(r"StreamTitle='([^']*)'").firstMatch(metaString);
    if (titleMatch != null) {
      final streamTitle = titleMatch.group(1) ?? '';

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

  Future<Map<String, String>> _getApiMetadata() async {
    try {
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

  Map<String, String> _parseRadioBossJson(dynamic data) {
    final result = <String, String>{};

    try {
      if (data is Map) {
        String? title;
        String? artist;

        if (data.containsKey('title')) {
          title = data['title']?.toString();
        }

        if (data.containsKey('artist')) {
          artist = data['artist']?.toString();
        }

        if (data.containsKey('icestats')) {
          final icestats = data['icestats'];
          if (icestats is Map && icestats.containsKey('source')) {
            final source = icestats['source'];

            if (source is List && source.isNotEmpty) {
              for (final sourceItem in source) {
                if (sourceItem is Map) {
                  if (sourceItem.containsKey('yp_currently_playing')) {
                    final songInfo = sourceItem['yp_currently_playing']
                        ?.toString();
                    if (songInfo != null && songInfo.isNotEmpty) {
                      return _parseSongString(songInfo);
                    }
                  }

                  if (sourceItem.containsKey('title')) {
                    final songInfo = sourceItem['title']?.toString();
                    if (songInfo != null && songInfo.isNotEmpty) {
                      return _parseSongString(songInfo);
                    }
                  }
                }
              }
            } else if (source is Map) {
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

        if (data.containsKey('stream_title') ||
            data.containsKey('streamtitle')) {
          final streamTitle = (data['stream_title'] ?? data['streamtitle'])
              ?.toString();
          if (streamTitle != null && streamTitle.isNotEmpty) {
            return _parseSongString(streamTitle);
          }
        }

        if (data.containsKey('yp_currently_playing')) {
          final currentlyPlaying = data['yp_currently_playing']?.toString();
          if (currentlyPlaying != null && currentlyPlaying.isNotEmpty) {
            return _parseSongString(currentlyPlaying);
          }
        }

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

  Map<String, String> _parseApiText(String text) {
    final result = <String, String>{};

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

  Map<String, String> _parseSongString(String songString) {
    final result = <String, String>{};

    if (songString.isNotEmpty) {
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

  bool _isPhoneNumberMetadata(String text) {
    if (text.isEmpty) return false;

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

  Future<Map<String, String>> getCurrentMetadata() async {
    return await _fetchMetadata();
  }
}
