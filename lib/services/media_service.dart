import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart' show AudioPlayer, ProcessingState;

import '../config/app_config.dart';
import '../utils/log.dart';

/// Keeps the radio playing on Android while the app is in the background or
/// the screen is off, and shows it in the notification and on the lock screen.
///
/// Android stops a background app's sound unless it runs a media service. iOS
/// does not need this: it has the `audio` background mode in Info.plist.
class MediaService extends BaseAudioHandler {
  MediaService({
    required this.onPlay,
    required this.onStop,
    Duration pausedTimeout = const Duration(minutes: 10),
  }) : _pausedTimeout = pausedTimeout;

  final Future<void> Function() onPlay;
  final Future<void> Function() onStop;

  /// How long a stopped radio can be started again from the lock screen. The
  /// service (and its wake lock) ends after that.
  final Duration _pausedTimeout;
  Timer? _pausedTimer;

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Starts the service, or returns null where it is not needed or fails. The
  /// radio then still plays while the app is open.
  static Future<MediaService?> start({
    required AudioPlayer player,
    required Future<void> Function() onPlay,
    required Future<void> Function() onStop,
  }) async {
    if (!isSupported) return null;
    try {
      final service = await AudioService.init(
        builder: () => MediaService(onPlay: onPlay, onStop: onStop),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'feniks_player',
          androidNotificationChannelName: 'Radio uživo',
          androidNotificationIcon: 'drawable/ic_stat_feniks',
          // Android 12+ does not let a background app go back to the
          // foreground, for example to resume after a phone call.
          androidStopForegroundOnPause: false,
        ),
      );
      service._artUri = await _artwork();
      player.playerStateStream.listen(
        (state) => service.update(
          playing: state.playing,
          processing: state.processingState,
        ),
        onError: (Object e) => logError('Player state', e),
      );
      return service;
    } catch (e) {
      logError('Starting the media service', e);
      return null;
    }
  }

  Uri? _artUri;

  /// The notification can only show a file, not a Flutter asset.
  static Future<Uri?> _artwork() async {
    try {
      final data = await rootBundle.load('lib/assets/png/app_icon.png');
      final file = File('${Directory.systemTemp.path}/feniks_artwork.png');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      return file.uri;
    } catch (e) {
      logError('Preparing the notification artwork', e);
      return null;
    }
  }

  void showSong({required String title, required String artist}) {
    mediaItem.add(
      MediaItem(
        id: AppConfig.streamUrl,
        title: title,
        artist: artist.isEmpty ? AppConfig.appName : artist,
        artUri: _artUri,
      ),
    );
  }

  void update({required bool playing, required ProcessingState processing}) {
    if (playing) {
      _pausedTimer?.cancel();
      _pausedTimer = null;
    } else if (playbackState.value.playing) {
      _pausedTimer = Timer(_pausedTimeout, stop);
    }
    // Nothing to show until the radio is first played.
    final started = playing || _pausedTimer != null;
    playbackState.add(
      PlaybackState(
        controls: [playing ? MediaControl.pause : MediaControl.play],
        androidCompactActionIndices: const [0],
        playing: playing,
        processingState: started
            ? _stateOf(playing, processing)
            : AudioProcessingState.idle,
      ),
    );
  }

  static AudioProcessingState _stateOf(
    bool playing,
    ProcessingState processing,
  ) {
    // A stopped player is idle, but the service must stay up so that it can be
    // started again from the lock screen.
    if (!playing) return AudioProcessingState.ready;
    return switch (processing) {
      ProcessingState.ready => AudioProcessingState.ready,
      _ => AudioProcessingState.buffering,
    };
  }

  @override
  Future<void> play() => onPlay();

  /// Live radio has nothing to pause: playing again joins it live.
  @override
  Future<void> pause() => onStop();

  /// Ends the radio and the service.
  @override
  Future<void> stop() async {
    await onStop();
    _pausedTimer?.cancel();
    _pausedTimer = null;
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
      ),
    );
  }

  /// Swiping the app away keeps a playing radio on.
  @override
  Future<void> onTaskRemoved() async {
    if (!playbackState.value.playing) await stop();
  }
}
