import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../utils/log.dart';

/// Finds out which song is on air.
///
/// Sources, best first:
/// 1. The `title` of our mount on the Icecast status page
///    ([AppConfig.nowPlayingUrl]). It changes the moment a new song starts,
///    whether the radio is playing in the app or not.
/// 2. One ICY block read from a short, separate connection to the stream.
/// 3. The station name ([fallback]).
///
/// While the radio plays, [RadioPlayerModel] also listens to the ICY
/// metadata inside the stream itself and feeds it through [parseSong].
///
/// [start] polls every [pollInterval]; [pause] stops polling, for example
/// while the app is in the background and nothing is playing.
class MetadataService {
  static const pollInterval = Duration(seconds: 3);
  static const _timeout = Duration(seconds: 6);

  /// Artist shown with studio announcements; these are not songs.
  static const stationArtist = 'Feniks Radio';

  static const fallback = {
    'title': 'Feniks Radio',
    'artist': 'Samo dobre vijesti!',
  };

  StreamController<Map<String, String>>? _controller =
      StreamController<Map<String, String>>.broadcast();
  Timer? _timer;
  Future<Map<String, String>>? _inFlight;

  /// Every result of a poll, also when nothing changed.
  Stream<Map<String, String>>? get metadataStream => _controller?.stream;

  bool get isPolling => _timer != null;

  /// True while the app's player is playing. The player then reads the
  /// song from the stream itself, so no second connection to the stream is
  /// opened here (that could make the audio stutter).
  bool streamPlaying = false;

  /// Fetches right away and then every [pollInterval]. Calling it again
  /// restarts the timer and fetches again.
  void start() {
    if (_controller == null) return;
    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) => unawaited(refresh()));
    unawaited(refresh());
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  void stop() {
    pause();
    unawaited(_controller?.close());
    _controller = null;
  }

  /// Fetches the song now. Calls that come while a fetch is running share
  /// its result instead of starting a second one.
  Future<Map<String, String>> getCurrentMetadata() => refresh();

  Future<Map<String, String>> refresh() =>
      _inFlight ??= _fetch().whenComplete(() => _inFlight = null);

  Future<Map<String, String>> _fetch() async {
    var song = await _fromStatusPage();
    var source = 'status';
    if (song.isEmpty && !streamPlaying) {
      song = await _fromIcy();
      source = 'icy';
    }
    if (song.isEmpty && streamPlaying) return const {};
    if (song.isEmpty) {
      song = fallback;
      source = 'fallback';
    }
    if (kDebugMode) {
      debugPrint('[Feniks] song ($source): ${song['artist']} - ${song['title']}');
    }
    final controller = _controller;
    if (controller != null && !controller.isClosed) controller.add(song);
    return song;
  }

  // ---------------------------------------------------------------- status

  Future<Map<String, String>> _fromStatusPage() async {
    try {
      final response = await http
          .get(
            Uri.parse(AppConfig.nowPlayingUrl),
            headers: const {
              'User-Agent': AppConfig.userAgent,
              'Accept': 'application/json',
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
            },
          )
          .timeout(_timeout);
      if (response.statusCode != 200) {
        logError('Status page', 'HTTP ${response.statusCode}');
        return {};
      }
      // Decoded by hand: without a charset header `response.body` would be
      // read as Latin-1 and break č, ć, š, ž, đ.
      final data = json.decode(_decode(response.bodyBytes));
      final song = songFromStatus(data);
      if (song.isEmpty && kDebugMode) {
        final body = _decode(response.bodyBytes);
        logError(
          'Status page has no title',
          body.length > 600 ? body.substring(0, 600) : body,
        );
      }
      return song;
    } catch (e) {
      logError('Fetching song from the status page', e);
      return {};
    }
  }

  /// Song from a decoded `status-json.xsl` response, or `{}`.
  ///
  /// Prefers our mount (the one whose `listenurl` ends like
  /// [AppConfig.streamUrl]) and falls back to any mount with a `title`, which Icecast updates on
  /// every song change. `yp_currently_playing` is only a fallback because it
  /// is refreshed when the server reports to the directory, which can be
  /// minutes late.
  @visibleForTesting
  static Map<String, String> songFromStatus(Object? data) {
    if (data is! Map) return {};
    final icestats = data['icestats'];
    final sources = switch (icestats is Map ? icestats['source'] : null) {
      final List<Object?> list => list.whereType<Map<Object?, Object?>>(),
      final Map<Object?, Object?> one => [one],
      _ => const <Map<Object?, Object?>>[],
    };
    if (sources.isEmpty) return {};

    // Our mount first, then the others: on this server "/stream" can be a
    // relay without a title while "/autodj" has it.
    final mount = Uri.parse(AppConfig.streamUrl).path;
    bool ours(Map<Object?, Object?> s) =>
        '${s['listenurl'] ?? ''}'.endsWith(mount);
    final ordered = [...sources.where(ours), ...sources.where((s) => !ours(s))];

    for (final source in ordered) {
      var text = '${source['title'] ?? ''}'.trim();
      final artist = '${source['artist'] ?? ''}'.trim();
      if (text.isNotEmpty && artist.isNotEmpty && !text.contains(' - ')) {
        text = '$artist - $text';
      }
      if (text.isEmpty) text = '${source['yp_currently_playing'] ?? ''}'.trim();
      if (text.isNotEmpty) return parseSong(text);
    }
    return {};
  }

  // ------------------------------------------------------------------- ICY

  Future<Map<String, String>> _fromIcy() async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(AppConfig.streamUrl))
        ..headers['Icy-MetaData'] = '1'
        ..headers['User-Agent'] = AppConfig.userAgent;
      final response = await client.send(request).timeout(_timeout);
      final interval = int.tryParse(response.headers['icy-metaint'] ?? '');
      if (interval == null || interval <= 0) return {};
      return await _readIcyBlock(response.stream, interval).timeout(_timeout);
    } catch (e) {
      logError('Reading ICY metadata', e);
      return {};
    } finally {
      client.close();
    }
  }

  Future<Map<String, String>> _readIcyBlock(
    Stream<List<int>> stream,
    int interval,
  ) async {
    final buffer = <int>[];
    await for (final chunk in stream) {
      buffer.addAll(chunk);
      if (buffer.length <= interval) continue;
      final length = buffer[interval] * 16;
      if (length == 0) return {};
      if (buffer.length < interval + 1 + length) continue;
      final block = _decode(
        buffer.sublist(interval + 1, interval + 1 + length),
      ).replaceAll('\u0000', '');
      final match = RegExp("StreamTitle='(.*?)';").firstMatch(block);
      return parseSong(match?.group(1) ?? '');
    }
    return {};
  }

  // --------------------------------------------------------------- parsing

  /// `Artist - Title` (as sent by the station) to `{title, artist}`.
  /// Studio announcements with the phone number ("Studio - 066 17 17 13")
  /// are shown whole as the title, with [stationArtist] as the artist, so
  /// listeners see where to call. Empty text becomes `{}`.
  static Map<String, String> parseSong(String text) {
    final value = text.trim();
    if (value.isEmpty) return {};
    if (_isPhoneNumber(value)) {
      return {'title': value, 'artist': stationArtist};
    }
    final dash = value.indexOf(' - ');
    if (dash < 0) return {'title': value, 'artist': ''};
    return {
      'artist': value.substring(0, dash).trim(),
      'title': value.substring(dash + 3).trim(),
    };
  }

  static final _phone = RegExp(
    r'(\+387\s*|0)66[\s/-]*17[\s/-]*17[\s/-]*13',
  );

  static bool _isPhoneNumber(String text) => _phone.hasMatch(text);

  static String _decode(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes);
    }
  }
}
