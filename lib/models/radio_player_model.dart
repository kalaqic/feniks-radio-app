import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';

import '../config/app_config.dart';
import '../services/app_settings.dart';
import '../services/metadata_service.dart';
import '../services/notification_service.dart';
import '../services/presence_service.dart';
import '../services/progress_sync.dart';
import '../utils/log.dart';
import '../utils/text_formatting.dart';
import 'achievement.dart';
import 'achievements.dart';
import 'listening_progress.dart';
import 'progress_rules.dart';

export 'achievement.dart';
export 'achievements.dart';
export 'progress_rules.dart';

class RadioPlayerModel extends ChangeNotifier {
  RadioPlayerModel({
    DateTime Function()? clock,
    bool enableSync = true,
    bool enablePersistence = true,
  }) : _progress = ListeningProgress(clock: clock),
       _settings = AppSettings(persist: enablePersistence),
       _presence = PresenceService(enabled: enableSync) {
    _sync = ProgressSync(_progress, enabled: enableSync);
    _progress
      ..onChanged = notifyListeners
      ..onSaveRequested = _sync.request
      ..onAchievementEarned = (earned) => onAchievementEarned?.call(earned);
  }

  final ListeningProgress _progress;
  final AppSettings _settings;
  final PresenceService _presence;
  AppLifecycleListener? _lifecycle;
  bool _appInForeground = true;
  late final ProgressSync _sync;

  AudioPlayer? _playerInstance;
  AudioPlayer get _player => _playerInstance ??= AudioPlayer(
    // A live 320 kbps stream: keep a bigger buffer so short network hiccups
    // do not cut the sound.
    audioLoadConfiguration: const AudioLoadConfiguration(
      darwinLoadControl: DarwinLoadControl(
        preferredForwardBufferDuration: Duration(seconds: 20),
      ),
      androidLoadControl: AndroidLoadControl(
        minBufferDuration: Duration(seconds: 15),
        maxBufferDuration: Duration(seconds: 60),
        bufferForPlaybackDuration: Duration(seconds: 3),
        bufferForPlaybackAfterRebufferDuration: Duration(seconds: 6),
      ),
    ),
  );
  MetadataService? _metadataInstance;
  MetadataService get _metadata => _metadataInstance ??= MetadataService();

  Timer? _ticker;
  Duration _lastPosition = Duration.zero;
  bool? _lastListeningLogged;

  Future<void> init() async {
    await _settings.load();
    if (_settings.persist && _settings.notificationsEnabled) {
      unawaited(
        NotificationService.instance
            .scheduleDailyReminders(
              hour: _settings.reminderHour,
              minute: _settings.reminderMinute,
            )
            .catchError((Object e) => logError('Scheduling reminders', e)),
      );
    }
    // The song is polled from the start, also while the radio is off.
    // Loading the stream can wait until the first play on iOS, so polling
    // must not depend on it.
    _metadata.metadataStream?.listen(_updateCurrentSong);
    _metadata.start();
    if (kDebugMode) {
      // Every change, to see whether the cuts are the network (buffering).
      _player.processingStateStream.listen(
        (state) => debugPrint('[Feniks] player ${DateTime.now()} $state'),
      );
    }
    _player.playingStream.listen((playing) {
      _metadata.streamPlaying = playing;
    });
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(AppConfig.streamUrl)),
      );
      // Volume is left to the phone's buttons. 80 % leaves some headroom:
      // at full gain the loud stream peaks and sounds distorted.
      await _player.setVolume(.8);
    } catch (e) {
      logError('Initializing the audio player', e);
    }
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        final resumed = state == AppLifecycleState.resumed;
        if (resumed && !_appInForeground) {
          // Polls again and fetches right away, the song may have changed.
          _metadata.start();
        } else if (!resumed && _appInForeground && !_player.playing) {
          // Nobody sees the song now, no need to keep asking.
          _metadata.pause();
        }
        _appInForeground = resumed;
        _reportPresence();
      },
    );
    _startTicker();
    notifyListeners();
  }

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  bool get playing => _player.playing;

  Future<void> play() async {
    unawaited(
      _player.play().catchError((Object e) => logError('Playing audio', e)),
    );
    _startTicker();
    unawaited(updateSong());
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    _progress.endSession();
  }

  Duration get currentSessionDuration => _progress.currentSession;

  void _startTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _tick(listening: _isListeningNow(), playerPlaying: _player.playing);
      _reportPresence();
    });
  }

  bool _isListeningNow() {
    final state = _player.processingState;
    final position = _player.position;
    final advanced = (position - _lastPosition).inMilliseconds > 200;
    _lastPosition = position;
    final listening =
        _player.playing &&
        (state == ProcessingState.ready ||
            (state == ProcessingState.buffering && advanced));
    if (kDebugMode && listening != _lastListeningLogged) {
      _lastListeningLogged = listening;
      debugPrint('[Feniks] listening=$listening state=$state');
    }
    return listening;
  }

  void _reportPresence() {
    final listening = _progress.isSessionActive;
    _presence.update(
      listening: listening,
      active: _appInForeground || listening,
    );
  }

  void _tick({required bool listening, required bool playerPlaying}) {
    final wasListening = _progress.isSessionActive;
    _progress.tick(listening: listening, playerPlaying: playerPlaying);

    if (!wasListening && _progress.isSessionActive) _countCurrentSong();
  }

  @visibleForTesting
  void debugTick({required bool listening}) =>
      _tick(listening: listening, playerPlaying: listening);

  @visibleForTesting
  void debugSetSong(String title, String artist) =>
      _updateCurrentSong({'title': title, 'artist': artist});

  @override
  void dispose() {
    _ticker?.cancel();
    _lifecycle?.dispose();
    _metadataInstance?.stop();
    _playerInstance?.dispose();
    super.dispose();
  }

  String _currentSong = kFallbackTitle;
  String _currentArtist = kFallbackArtist;
  bool _isFetchingCurrentSong = false;

  String get currentSong => _currentSong;
  String get currentArtist => _currentArtist;
  bool get isFetchingCurrentSong => _isFetchingCurrentSong;

  /// A studio announcement (for example the phone number), not a song: it
  /// is shown, but not counted, saved as a favorite or kept in the history.
  bool get isStationInfo =>
      isFallbackSong ||
      _currentArtist.toLowerCase() ==
          MetadataService.stationArtist.toLowerCase();

  bool get isFallbackSong {
    final title = _currentSong.trim().toLowerCase();
    return title.isEmpty || title == kFallbackTitle.toLowerCase();
  }

  String get currentSongDisplay =>
      _currentArtist.isEmpty ? _currentSong : '$_currentSong - $_currentArtist';

  Future<void> updateSong() async {
    _isFetchingCurrentSong = true;
    notifyListeners();
    try {
      _updateCurrentSong(await _metadata.refresh());
    } finally {
      _isFetchingCurrentSong = false;
      notifyListeners();
    }
  }

  void _updateCurrentSong(Map<String, String> metadata) {
    if (metadata.isEmpty) return;

    final title = TextFormatting.formatTitle(
      TextFormatting.cleanSongText(metadata['title'] ?? kFallbackTitle),
    );
    final artist = TextFormatting.formatArtist(
      TextFormatting.cleanSongText(metadata['artist'] ?? kFallbackArtist),
    );
    // Polls repeat the same song most of the time.
    if (title == _currentSong && artist == _currentArtist) return;
    if (!isStationInfo) {
      final previous = currentSongDisplay;
      _recentSongs
        ..remove(previous)
        ..insert(0, previous);
      if (_recentSongs.length > 4) _recentSongs.removeLast();
    }
    _currentSong = title;
    _currentArtist = artist;
    _isFetchingCurrentSong = false;
    _recentSongs.remove(currentSongDisplay);
    _countCurrentSong();
    notifyListeners();
  }

  final List<String> _recentSongs = [];

  /// Up to four songs that played before the current one, newest first.
  /// Only remembered while the app is open.
  List<String> get recentSongs => List.unmodifiable(_recentSongs);

  void _countCurrentSong() {
    if (!isStationInfo) _progress.songHeard(currentSongDisplay);
  }

  List<String> get favoriteSongs => _progress.favorites;

  bool isFavorite(String song) => _progress.isFavorite(song);

  void toggleFavorite() {
    final song = currentSongDisplay;
    if (_progress.isFavorite(song)) {
      _progress.removeFavorite(song);
    } else if (!isStationInfo) {
      _progress.addFavorite(song);
    }
  }

  void removeFavorite(String song) => _progress.removeFavorite(song);

  /// Adds or removes any song, for example one that played earlier.
  void toggleFavoriteSong(String song) {
    if (_progress.isFavorite(song)) {
      _progress.removeFavorite(song);
    } else {
      _progress.addFavorite(song);
    }
  }

  int get todayListeningMinutes => _progress.todayMinutes;
  int get totalListeningMinutes => _progress.totalMinutes;
  int get totalListeningDays => _progress.listeningDays;
  int get sessionCount => _progress.sessionCount;

  int get consecutiveDays => _progress.streak;

  /// True once today already counts towards [consecutiveDays].
  bool get listenedToday => _progress.listenedToday;

  int get listeningPoints => _progress.listeningPoints;
  int get achievementPoints => _progress.achievementPoints;
  int get totalFeniksPoints => _progress.totalPoints;

  void Function(EarnedAchievement earned)? onAchievementEarned;

  List<Achievement> get allAchievements => Achievements.all;
  List<EarnedAchievement> get earnedAchievements => _progress.earned;

  Map<AchievementCategory, List<Achievement>> get achievementsByCategory => {
    for (final category in AchievementCategory.values)
      category: [
        for (final a in Achievements.all)
          if (a.category == category) a,
      ],
  };

  bool hasAchievement(Achievement achievement) =>
      _progress.hasAchievement(achievement);

  Achievement? get nextPendingAchievement =>
      _progress.pending.isEmpty ? null : _progress.pending.first;

  void markAchievementShown(Achievement achievement) =>
      _progress.markShown(achievement);

  void checkAchievements() => _progress.checkAll();

  void trackPageVisit(String route) => _progress.pageVisited(route);

  String? get loadedUserId => _sync.loadedUserId;

  void loadUserProgress(String uid, Map<String, dynamic>? data) {
    final unsaved = _sync.loadedUserId == null ? _progress.snapshot() : null;
    _progress
      ..achievementsEnabled = true
      ..loadJson(data ?? const {});
    if (unsaved != null) _progress.mergeUnsaved(unsaved);
    _sync.loadedUserId = uid;
    notifyListeners();
  }

  void resetProgress() {
    _sync.loadedUserId = null;
    _progress
      ..achievementsEnabled = false
      ..reset();
  }

  /// Achievements are only unlocked for logged-in users.
  set achievementsEnabled(bool value) => _progress.achievementsEnabled = value;

  Map<String, dynamic> progressToJson() => _progress.toJson();

  Future<void> syncNow() => _sync.save();

  Future<void> waitForPendingSync() => _sync.waitForPending();

  bool get notificationsEnabled => _settings.notificationsEnabled;
  set notificationsEnabled(bool value) {
    _settings.notificationsEnabled = value;
    _settingsChanged();
  }

  bool get autoPlay => _settings.autoPlay;
  set autoPlay(bool value) {
    _settings.autoPlay = value;
    _settingsChanged();
  }

  double get volume => _settings.volume;
  set volume(double value) {
    _settings.volume = value;
    unawaited(_player.setVolume(value));
    _settingsChanged();
  }

  int get notificationHour => _settings.reminderHour;
  int get notificationMinute => _settings.reminderMinute;

  void setNotificationTime(int hour, int minute) {
    _settings
      ..reminderHour = hour
      ..reminderMinute = minute;
    _settingsChanged();
  }

  void _settingsChanged() {
    _settings.save();
    notifyListeners();
  }

  bool _autoPlayHandled = false;

  bool takeAutoPlay() {
    if (_autoPlayHandled) return false;
    _autoPlayHandled = true;
    return _settings.autoPlay;
  }

  bool _celebrationShown = false;

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// The streak popup comes at most once a day, and only once there is a
  /// streak to continue (yesterday was a listening day).
  bool get shouldShowCelebration {
    if (_celebrationShown) return false;
    if (_settings.celebrationDay == _dayKey(DateTime.now())) return false;
    final pastDays = listenedToday ? consecutiveDays - 1 : consecutiveDays;
    return pastDays >= 1;
  }

  void markCelebrationShown() {
    _celebrationShown = true;
    _settings.celebrationDay = _dayKey(DateTime.now());
    _settings.save();
    notifyListeners();
  }
}
