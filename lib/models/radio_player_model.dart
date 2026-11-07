import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../config/app_config.dart';
import '../services/app_settings.dart';
import '../services/metadata_service.dart';
import '../services/notification_service.dart';
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

/// The state the screens work with: the radio player, the song that is
/// playing, settings and the user's progress.
///
/// The actual work is done by smaller parts:
///  * [ListeningProgress] – listening time, streaks, favorites, achievements
///  * [ProgressSync] – saving progress and the leaderboard entry to Firestore
///  * [AppSettings] – settings stored on the device
class RadioPlayerModel extends ChangeNotifier {
  /// [clock] and the `enable*` flags exist so the logic can be tested without
  /// audio, network, Firebase or a real clock.
  RadioPlayerModel({
    DateTime Function()? clock,
    bool enableSync = true,
    bool enablePersistence = true,
  }) : _progress = ListeningProgress(clock: clock),
       _settings = AppSettings(persist: enablePersistence) {
    _sync = ProgressSync(_progress, enabled: enableSync);
    _progress
      ..onChanged = notifyListeners
      ..onSaveRequested = _sync.request
      ..onAchievementEarned = (earned) => onAchievementEarned?.call(earned);
  }

  final ListeningProgress _progress;
  final AppSettings _settings;
  late final ProgressSync _sync;

  // ===========================================================================
  // Player
  // ===========================================================================

  // Created on first use, so tests never touch the audio plugin.
  AudioPlayer? _playerInstance;
  AudioPlayer get _player => _playerInstance ??= AudioPlayer();
  MetadataService? _metadataInstance;
  MetadataService get _metadata => _metadataInstance ??= MetadataService();

  Timer? _ticker;
  Duration _lastPosition = Duration.zero;
  bool? _lastListeningLogged;

  Future<void> init() async {
    await _settings.load();
    if (_settings.persist && _settings.notificationsEnabled) {
      // Re-schedule the daily reminders (keeps the rotation going and the time
      // right after DST changes). Not awaited: must not delay the app start.
      unawaited(
        NotificationService.instance
            .scheduleDailyReminders(
              hour: _settings.reminderHour,
              minute: _settings.reminderMinute,
            )
            .catchError((Object e) => logError('Scheduling reminders', e)),
      );
    }
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(AppConfig.streamUrl)),
      );
      await _player.setVolume(_settings.volume);
    } catch (e) {
      logError('Initializing the audio player', e);
    }
    _metadata.start();
    _metadata.metadataStream?.listen(_updateCurrentSong);
    unawaited(updateSong());
    _startTicker();
    notifyListeners();
  }

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  bool get playing => _player.playing;

  Future<void> play() async {
    // just_audio's play() completes only when playback stops, so it is not
    // awaited; listening is tracked by the ticker instead.
    unawaited(
      _player.play().catchError((Object e) => logError('Playing audio', e)),
    );
    _startTicker();
    unawaited(updateSong());
    notifyListeners();
  }

  Future<void> pause() async {
    await _player.pause();
    _progress.endSession();
  }

  Future<void> stop() async {
    await _player.stop();
    _progress.endSession();
  }

  /// Real listening time of the current session (buffering excluded).
  Duration get currentSessionDuration => _progress.currentSession;

  void _startTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _tick(listening: _isListeningNow(), playerPlaying: _player.playing);
    });
  }

  /// True while audio is really coming out. On iOS a live stream can report
  /// "buffering" the whole time it plays, so "buffering" also counts when the
  /// playback position keeps moving.
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

  void _tick({required bool listening, required bool playerPlaying}) {
    final wasListening = _progress.isSessionActive;
    _progress.tick(listening: listening, playerPlaying: playerPlaying);
    // The song that is playing when a session starts counts as heard.
    if (!wasListening && _progress.isSessionActive) _countCurrentSong();
  }

  /// Simulates one timer tick (tests advance the clock themselves).
  @visibleForTesting
  void debugTick({required bool listening}) =>
      _tick(listening: listening, playerPlaying: listening);

  /// Feeds now-playing data as if it came from the station (tests only).
  @visibleForTesting
  void debugSetSong(String title, String artist) =>
      _updateCurrentSong({'title': title, 'artist': artist});

  @override
  void dispose() {
    _ticker?.cancel();
    _metadataInstance?.stop();
    _playerInstance?.dispose();
    super.dispose();
  }

  // ===========================================================================
  // Song that is playing
  // ===========================================================================

  String _currentSong = kFallbackTitle;
  String _currentArtist = kFallbackArtist;
  bool _isFetchingCurrentSong = false;

  String get currentSong => _currentSong;
  String get currentArtist => _currentArtist;
  bool get isFetchingCurrentSong => _isFetchingCurrentSong;

  /// True when there is no real song info (station jingle / fallback text).
  bool get isFallbackSong {
    final title = _currentSong.trim().toLowerCase();
    return title.isEmpty || title == kFallbackTitle.toLowerCase();
  }

  /// "Title - Artist"; also the key under which favorites are stored.
  String get currentSongDisplay =>
      _currentArtist.isEmpty ? _currentSong : '$_currentSong - $_currentArtist';

  Future<void> updateSong() async {
    _isFetchingCurrentSong = true;
    notifyListeners();
    try {
      _updateCurrentSong(await _metadata.getCurrentMetadata());
    } finally {
      _isFetchingCurrentSong = false;
      notifyListeners();
    }
  }

  void _updateCurrentSong(Map<String, String> metadata) {
    if (metadata.isEmpty) return;
    // Same formatting as on screen, so favorites match what the user sees.
    _currentSong = TextFormatting.formatTitle(
      metadata['title'] ?? kFallbackTitle,
    );
    _currentArtist = TextFormatting.formatArtist(
      metadata['artist'] ?? kFallbackArtist,
    );
    _isFetchingCurrentSong = false;
    _countCurrentSong();
    notifyListeners();
  }

  void _countCurrentSong() {
    if (!isFallbackSong) _progress.songHeard(currentSongDisplay);
  }

  // ===========================================================================
  // Favorites
  // ===========================================================================

  List<String> get favoriteSongs => _progress.favorites;

  bool isFavorite(String song) => _progress.isFavorite(song);

  /// Adds or removes the song that is playing. The station jingle (no song
  /// info) can't be added.
  void toggleFavorite() {
    final song = currentSongDisplay;
    if (_progress.isFavorite(song)) {
      _progress.removeFavorite(song);
    } else if (!isFallbackSong) {
      _progress.addFavorite(song);
    }
  }

  void removeFavorite(String song) => _progress.removeFavorite(song);

  // ===========================================================================
  // Progress, points and achievements
  // ===========================================================================

  int get todayListeningSeconds => _progress.todaySeconds;
  int get todayListeningMinutes => _progress.todayMinutes;
  int get totalListeningMinutes => _progress.totalMinutes;
  int get totalListeningDays => _progress.listeningDays;
  int get sessionCount => _progress.sessionCount;

  /// Days in a row with listening (0 when a day was missed).
  int get consecutiveDays => _progress.streak;

  int get listeningPoints => _progress.listeningPoints;
  int get achievementPoints => _progress.achievementPoints;
  int get totalFeniksPoints => _progress.totalPoints;

  /// Called right after an achievement is unlocked (used for the popup).
  void Function(EarnedAchievement earned)? onAchievementEarned;

  List<Achievement> get allAchievements => Achievements.all;
  List<EarnedAchievement> get earnedAchievements => _progress.earned;

  /// All achievements per category, in display order.
  Map<AchievementCategory, List<Achievement>> get achievementsByCategory => {
    for (final category in AchievementCategory.values)
      category: [
        for (final a in Achievements.all)
          if (a.category == category) a,
      ],
  };

  bool hasAchievement(Achievement achievement) =>
      _progress.hasAchievement(achievement);

  /// Unlocked achievements whose popup has not been shown yet.
  bool get hasPendingAchievements => _progress.pending.isNotEmpty;
  Achievement? get nextPendingAchievement =>
      _progress.pending.isEmpty ? null : _progress.pending.first;

  void markAchievementShown(Achievement achievement) =>
      _progress.markShown(achievement);

  /// Unlocks everything the current progress already qualifies for.
  void checkAchievements() => _progress.checkAll();

  /// Counts a page visit (for the "Istraživač Aplikacije" achievement).
  void trackPageVisit(String route) => _progress.pageVisited(route);

  // ===========================================================================
  // Loading and saving the user's progress
  // ===========================================================================

  /// Firebase uid whose progress is loaded (null = not loaded yet).
  String? get loadedUserId => _sync.loadedUserId;

  /// Loads the saved progress of [uid] ([data] is null for new users).
  /// Listening done before the data loaded is added on top, so it's not lost.
  void loadUserProgress(String uid, Map<String, dynamic>? data) {
    final unsaved = _sync.loadedUserId == null ? _progress.snapshot() : null;
    _progress.loadJson(data ?? const {});
    if (unsaved != null) _progress.mergeUnsaved(unsaved);
    _sync.loadedUserId = uid;
    notifyListeners();
  }

  /// Clears all progress (logout / account deletion). Nothing is saved until
  /// the next [loadUserProgress].
  void resetProgress() {
    _sync.loadedUserId = null;
    _progress.reset();
  }

  /// The progress as it is saved in Firestore.
  Map<String, dynamic> progressToJson() => _progress.toJson();

  /// Saves progress and the leaderboard entry now (no-op when logged out).
  Future<void> syncNow() => _sync.save();

  /// Waits until a save that is already running has finished.
  Future<void> waitForPendingSync() => _sync.waitForPending();

  // ===========================================================================
  // Settings and one-time UI state
  // ===========================================================================

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

  /// True only the first time it is asked in an app launch, and only when
  /// auto-play is on (so returning to the home page doesn't restart the radio).
  bool takeAutoPlay() {
    if (_autoPlayHandled) return false;
    _autoPlayHandled = true;
    return _settings.autoPlay;
  }

  bool _celebrationShown = false;

  /// The welcome popup is shown once per app launch.
  bool get shouldShowCelebration => !_celebrationShown;

  void markCelebrationShown() {
    _celebrationShown = true;
    notifyListeners();
  }
}
