import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/metadata_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

const kStreamUrl = 'https://c30.radioboss.fm:8234/stream';

/// Feniks poeni za slušanje: [kListeningPointsPerBlock] poena za svakih
/// [kListeningBlockMinutes] minuta stvarnog slušanja.
const int kListeningBlockMinutes = 1;
const int kListeningPointsPerBlock = 2;

/// Koliko minuta treba slušati u danu da bi se dan računao kao "dan slušanja"
/// (za nizove, vikende, radne dane i dane slušanja).
const int kMinMinutesForListeningDay = 5;

/// Koliko minuta treba slušati u jednom dobu dana da bi se taj dan računao
/// za značke tipa "Rana ptica", "Noćna ptica"...
const int kMinMinutesForTimeSlot = 5;

/// Sesija se računa za značke sesija tek kada traje bar ovoliko minuta.
const int kMinMinutesForSession = 10;

/// Pjesme koje se ne računaju (džinglovi / rezervni naslov kad nema metapodataka).
const String kFallbackTitle = 'Feniks Radio';
const String kFallbackArtist = 'Samo dobre vijesti!';

/// Stranice koje se računaju za značku "Istraživač".
const List<String> kExplorablePages = [
  '/home',
  '/leaderboard',
  '/badges',
  '/favorites',
  '/profile',
  '/settings',
];

/// Doba dana (početni sat uključen, krajnji isključen).
const Map<String, List<int>> _timeSlots = {
  'midnight_listener': [0, 5],
  'early_bird': [5, 8],
  'morning_person': [8, 12],
  'afternoon_listener': [12, 18],
  'evening_enthusiast': [18, 22],
  'night_owl': [22, 24],
};

class RadioPlayerModel extends ChangeNotifier {
  /// [clock] and the `enable*` flags exist so the progress logic can be tested
  /// without audio, network, Firebase or a real clock.
  RadioPlayerModel({
    DateTime Function()? clock,
    this.enableSync = true,
    this.enablePersistence = true,
  }) : _clock = clock ?? DateTime.now {
    _todayKey = _dayKey(_clock());
  }

  final DateTime Function() _clock;
  final bool enableSync;
  final bool enablePersistence;

  AudioPlayer? _playerInstance;
  AudioPlayer get _player => _playerInstance ??= AudioPlayer();
  MetadataService? _metadataInstance;
  MetadataService get _metadataService =>
      _metadataInstance ??= MetadataService();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  // ---------------------------------------------------------------------------
  // Live listening tracking
  // ---------------------------------------------------------------------------
  Timer? _ticker;
  DateTime? _lastTick;
  bool _sessionActive = false;
  bool _sessionCounted = false;
  int _sessionListenedSeconds = 0;
  int _secondsTowardsMinute = 0;
  int _msCarry = 0;
  DateTime? _lastSyncAt;

  late String _todayKey;
  int _todayListeningSeconds = 0;
  bool _todayCountedAsListeningDay = false;

  /// Minutes listened today per time slot (in memory only).
  final Map<String, int> _slotMinutesToday = {};

  bool _hasShownCelebrationToday = false;

  // ---------------------------------------------------------------------------
  // Persisted progress
  // ---------------------------------------------------------------------------
  final List<Map<String, dynamic>> _earnedBadges = [];
  final List<String> _pendingBadges = [];

  int _totalListeningSeconds = 0;
  int _sessionCount = 0;
  int _longestSessionMinutes = 0;

  int _consecutiveDays = 0;
  DateTime? _lastListeningDate;
  int _totalListeningDays = 0;

  int _weekendDaysCount = 0;
  String? _workweekKey; // Monday of the week, yyyy-mm-dd
  final Set<int> _workdaysThisWeek = {}; // 1..5

  /// slot id -> number of distinct days the user listened in that slot
  final Map<String, int> _slotDayCounts = {};

  /// slot id -> last day (yyyy-mm-dd) that was counted for that slot
  final Map<String, String> _slotLastCountedDay = {};

  final Set<String> _uniqueSongs = {};
  final List<String> _visitedPages = [];
  bool _hasPlayedBefore = false;

  /// Firebase uid whose progress is currently loaded (null = not loaded yet).
  String? loadedUserId;

  bool _syncInProgress = false;
  bool _syncAgain = false;
  Completer<void>? _syncDone;

  // ---------------------------------------------------------------------------
  // Badges
  // ---------------------------------------------------------------------------

  /// Section order for badges page.
  static const List<String> badgeSectionOrder = [
    'Prvi koraci',
    'Dnevno slušanje',
    'Bez pauze',
    'Ukupno slušanje',
    'Sesije',
    'Nizovi',
    'Dani slušanja',
    'Doba dana',
    'Vikend i radni dan',
    'Omiljene pjesme',
    'Otkrivanje',
  ];

  static const Map<String, String> _badgeToSection = {
    'first_listen': 'Prvi koraci',
    'app_explorer': 'Prvi koraci',
    'first_hour': 'Dnevno slušanje',
    'marathon': 'Dnevno slušanje',
    'five_hours': 'Dnevno slušanje',
    'quality_listener': 'Bez pauze',
    'stable_connection': 'Bez pauze',
    'ultra_marathon': 'Bez pauze',
    'ten_hours': 'Ukupno slušanje',
    'fifty_hours': 'Ukupno slušanje',
    'hundred_hours': 'Ukupno slušanje',
    'ten_sessions': 'Sesije',
    'fifty_sessions': 'Sesije',
    'hundred_sessions': 'Sesije',
    'daily_listener': 'Nizovi',
    'weekly_champion': 'Nizovi',
    'loyal_fan': 'Nizovi',
    'legend': 'Nizovi',
    'first_week': 'Dani slušanja',
    'first_month': 'Dani slušanja',
    'loyal_user': 'Dani slušanja',
    'midnight_listener': 'Doba dana',
    'early_bird': 'Doba dana',
    'morning_person': 'Doba dana',
    'afternoon_listener': 'Doba dana',
    'evening_enthusiast': 'Doba dana',
    'night_owl': 'Doba dana',
    'weekend_warrior': 'Vikend i radni dan',
    'workday_warrior': 'Vikend i radni dan',
    'music_lover': 'Omiljene pjesme',
    'music_collector': 'Omiljene pjesme',
    'music_expert': 'Omiljene pjesme',
    'music_master': 'Omiljene pjesme',
    'song_discoverer': 'Otkrivanje',
    'song_hunter': 'Otkrivanje',
  };

  static Map<String, dynamic> _badge(
    String id,
    String name,
    String description,
    String icon,
    int color,
    int requirement,
    int points,
    String type,
  ) => {
    'id': id,
    'name': name,
    'description': description,
    'icon': icon,
    'color': color,
    'requirement': requirement,
    'points': points,
    'type': type,
  };

  // All available badges. Every badge has a unique id, name and icon, and a
  // single place in the code where it is awarded.
  static final Map<String, Map<String, dynamic>> _allBadges = {
    // Prvi koraci
    'first_listen': _badge('first_listen', 'Prvi Put',
        'Pokreni Feniks Radio prvi put', '🎧', 0xFF34C759, 1, 25, 'special'),
    'app_explorer': _badge(
        'app_explorer',
        'Istraživač Aplikacije',
        'Posjeti sve stranice: Početna, Ljestvica, Značke, Omiljene, Profil i Postavke',
        '🧭',
        0xFF007AFF,
        kExplorablePages.length,
        50,
        'special'),

    // Dnevno slušanje (zbir u jednom danu)
    'first_hour': _badge('first_hour', 'Prvi Sat',
        'Slušaj 1 sat u jednom danu', '⏰', 0xFF34C759, 60, 50, 'daily_listening'),
    'marathon': _badge('marathon', 'Maraton', 'Slušaj 3 sata u jednom danu',
        '🏃', 0xFFFF9500, 180, 150, 'daily_listening'),
    'five_hours': _badge('five_hours', 'Pet Sati', 'Slušaj 5 sati u jednom danu',
        '🔥', 0xFF5856D6, 300, 250, 'daily_listening'),

    // Bez pauze (jedna sesija, bez zaustavljanja)
    'quality_listener': _badge('quality_listener', 'Pola Sata u Komadu',
        'Slušaj 30 minuta bez pauze', '🔊', 0xFF007AFF, 30, 50, 'continuous_listening'),
    'stable_connection': _badge('stable_connection', 'Dva Sata Bez Pauze',
        'Slušaj 2 sata bez pauze', '📡', 0xFF34C759, 120, 150, 'continuous_listening'),
    'ultra_marathon': _badge('ultra_marathon', 'Ultra Maraton',
        'Slušaj 6 sati bez pauze', '🚀', 0xFFFF3B30, 360, 400, 'continuous_listening'),

    // Ukupno slušanje
    'ten_hours': _badge('ten_hours', 'Deset Sati', 'Slušaj ukupno 10 sati',
        '🕙', 0xFFFF9500, 600, 150, 'total_listening'),
    'fifty_hours': _badge('fifty_hours', 'Pedeset Sati', 'Slušaj ukupno 50 sati',
        '⌛', 0xFF5856D6, 3000, 500, 'total_listening'),
    'hundred_hours': _badge('hundred_hours', 'Sto Sati', 'Slušaj ukupno 100 sati',
        '💯', 0xFFFFD700, 6000, 1000, 'total_listening'),

    // Sesije
    'ten_sessions': _badge('ten_sessions', 'Deset Sesija',
        'Završi 10 sesija slušanja od bar $kMinMinutesForSession minuta', '🔟',
        0xFF34C759, 10, 100, 'session_count'),
    'fifty_sessions': _badge('fifty_sessions', 'Pedeset Sesija',
        'Završi 50 sesija slušanja od bar $kMinMinutesForSession minuta', '📻',
        0xFF007AFF, 50, 300, 'session_count'),
    'hundred_sessions': _badge('hundred_sessions', 'Sto Sesija',
        'Završi 100 sesija slušanja od bar $kMinMinutesForSession minuta', '🎯',
        0xFFFF3B30, 100, 600, 'session_count'),

    // Nizovi (uzastopni dani)
    'daily_listener': _badge('daily_listener', 'Sedmica Zaredom',
        'Slušaj Feniks Radio 7 dana zaredom', '📆', 0xFFEB6556, 7, 150, 'streak'),
    'weekly_champion': _badge('weekly_champion', 'Dvije Sedmice Zaredom',
        'Slušaj Feniks Radio 14 dana zaredom', '🎖️', 0xFF32D74B, 14, 250, 'streak'),
    'loyal_fan': _badge('loyal_fan', 'Vjeran Fan',
        'Slušaj Feniks Radio 30 dana zaredom', '👑', 0xFF8B5CF6, 30, 500, 'streak'),
    'legend': _badge('legend', 'Legenda',
        'Slušaj Feniks Radio 100 dana zaredom', '⚡', 0xFFFFD700, 100, 1000, 'streak'),

    // Dani slušanja (ukupno, ne moraju biti zaredom)
    'first_week': _badge('first_week', 'Sedam Dana Slušanja',
        'Slušaj radio u 7 različitih dana', '📅', 0xFF32D74B, 7, 75, 'listening_days'),
    'first_month': _badge('first_month', 'Mjesec Dana Slušanja',
        'Slušaj radio u 30 različitih dana', '🗓️', 0xFF5856D6, 30, 250, 'listening_days'),
    'loyal_user': _badge('loyal_user', 'Vjeran Korisnik',
        'Slušaj radio u 180 različitih dana', '💎', 0xFFFFD700, 180, 800, 'listening_days'),

    // Doba dana (broj različitih dana sa bar 5 minuta slušanja u tom periodu)
    'midnight_listener': _badge('midnight_listener', 'Ponoćni Slušalac',
        'Slušaj radio između 00 i 05h u 3 različita dana', '🌙', 0xFF8B5CF6, 3, 100, 'time_slot'),
    'early_bird': _badge('early_bird', 'Rana Ptica',
        'Slušaj radio između 05 i 08h u 5 različitih dana', '🐦', 0xFF32D74B, 5, 75, 'time_slot'),
    'morning_person': _badge('morning_person', 'Jutarnja Osoba',
        'Slušaj radio između 08 i 12h u 10 različitih dana', '🌅', 0xFFFFD700, 10, 150, 'time_slot'),
    'afternoon_listener': _badge('afternoon_listener', 'Popodnevni Slušalac',
        'Slušaj radio između 12 i 18h u 10 različitih dana', '☀️', 0xFFFF9500, 10, 150, 'time_slot'),
    'evening_enthusiast': _badge('evening_enthusiast', 'Večernji Entuzijast',
        'Slušaj radio između 18 i 22h u 10 različitih dana', '🌆', 0xFF8B5CF6, 10, 150, 'time_slot'),
    'night_owl': _badge('night_owl', 'Noćna Ptica',
        'Slušaj radio između 22 i 24h u 5 različitih dana', '🦉', 0xFF5856D6, 5, 75, 'time_slot'),

    // Vikend i radni dan
    'weekend_warrior': _badge('weekend_warrior', 'Vikend Ratnik',
        'Slušaj radio u 8 različitih vikend dana (subota ili nedjelja)', '🎉',
        0xFFFF9500, 8, 200, 'weekend'),
    'workday_warrior': _badge('workday_warrior', 'Radna Sedmica',
        'Slušaj radio svaki radni dan (pon–pet) u istoj sedmici', '💼',
        0xFF007AFF, 5, 250, 'workweek'),

    // Omiljene pjesme
    'music_lover': _badge('music_lover', 'Ljubitelj Muzike',
        'Imaj 10 pjesama u omiljenim', '💝', 0xFFFF3B30, 10, 100, 'favorites'),
    'music_collector': _badge('music_collector', 'Kolekcionar Muzike',
        'Imaj 25 pjesama u omiljenim', '📀', 0xFF007AFF, 25, 200, 'favorites'),
    'music_expert': _badge('music_expert', 'Stručnjak za Muziku',
        'Imaj 50 pjesama u omiljenim', '🎵', 0xFF5856D6, 50, 350, 'favorites'),
    'music_master': _badge('music_master', 'Majstor Muzike',
        'Imaj 100 pjesama u omiljenim', '🎼', 0xFFFFD700, 100, 500, 'favorites'),

    // Otkrivanje (različite pjesme koje su svirale dok si slušao)
    'song_discoverer': _badge('song_discoverer', 'Otkrivač Pjesama',
        'Čuj 50 različitih pjesama na Feniks Radiju', '🔍', 0xFF32D74B, 50, 100, 'discovery'),
    'song_hunter': _badge('song_hunter', 'Lovac na Pjesme',
        'Čuj 250 različitih pjesama na Feniks Radiju', '🎶', 0xFF5856D6, 250, 300, 'discovery'),
  };

  static int _req(String id) => _allBadges[id]!['requirement'] as int;

  // ---------------------------------------------------------------------------
  // Now playing / favorites / settings
  // ---------------------------------------------------------------------------
  String _currentSong = kFallbackTitle;
  String _currentArtist = kFallbackArtist;
  bool _isFetchingCurrentSong = false;
  final List<String> _favoriteSongs = [];

  bool _isDarkMode = false;
  bool _notificationsEnabled = false;
  bool _autoPlay = false;
  double _volume = 0.8;
  int _notificationHour = 8;
  int _notificationMinute = 0;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------
  int get todayListeningSeconds => _todayListeningSeconds;
  int get todayListeningMinutes => _todayListeningSeconds ~/ 60;
  bool get shouldShowCelebration => !_hasShownCelebrationToday;

  /// Current streak. Shows 0 if the last listening day was before yesterday.
  int get consecutiveDays {
    if (_lastListeningDate == null) return 0;
    final today = _dateOnly(_clock());
    final diff = today.difference(_dateOnly(_lastListeningDate!)).inDays;
    return diff <= 1 ? _consecutiveDays : 0;
  }

  int get totalListeningDays => _totalListeningDays;
  int get sessionCount => _sessionCount;
  int get longestSessionMinutes => _longestSessionMinutes;

  List<Map<String, dynamic>> get earnedBadges =>
      List.unmodifiable(_earnedBadges);
  List<String> get pendingBadges => List.unmodifiable(_pendingBadges);
  Map<String, Map<String, dynamic>> get allBadges => _allBadges;
  bool get hasPendingBadges => _pendingBadges.isNotEmpty;

  /// Badges grouped by section for display, in [badgeSectionOrder].
  Map<String, List<Map<String, dynamic>>> get badgesGroupedBySection {
    final Map<String, List<Map<String, dynamic>>> result = {};
    for (final entry in _allBadges.entries) {
      final section = _badgeToSection[entry.key] ?? 'Ostalo';
      result
          .putIfAbsent(section, () => [])
          .add(Map<String, dynamic>.from(entry.value));
    }
    final ordered = <String, List<Map<String, dynamic>>>{};
    for (final section in badgeSectionOrder) {
      if (result.containsKey(section)) ordered[section] = result[section]!;
    }
    for (final key in result.keys) {
      if (!ordered.containsKey(key)) ordered[key] = result[key]!;
    }
    return ordered;
  }

  /// Called right after a badge is earned (used to show the popup).
  void Function(Map<String, dynamic>)? onAchievementEarned;

  /// Points from listening: [kListeningPointsPerBlock] for every full
  /// [kListeningBlockMinutes] minutes ever listened.
  int get listeningPoints =>
      (_totalListeningSeconds ~/ (kListeningBlockMinutes * 60)) *
      kListeningPointsPerBlock;

  /// Points from badges (always the sum of the earned badges' points).
  int get badgePoints => _earnedBadges.fold<int>(
    0,
    (sum, b) => sum + ((b['points'] as int?) ?? 0),
  );

  int get totalFeniksPoints => listeningPoints + badgePoints;

  /// Total minutes listened (all time), updated live while playing.
  int get totalListeningMinutes => _totalListeningSeconds ~/ 60;

  /// Seconds until the next listening points are awarded.
  int get secondsUntilNextListeningPoints {
    final block = kListeningBlockMinutes * 60;
    return block - (_totalListeningSeconds % block);
  }

  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get autoPlay => _autoPlay;
  double get volume => _volume;
  int get notificationHour => _notificationHour;
  int get notificationMinute => _notificationMinute;

  set isDarkMode(bool value) {
    _isDarkMode = value;
    _saveSettings();
    notifyListeners();
  }

  set notificationsEnabled(bool value) {
    _notificationsEnabled = value;
    _saveSettings();
    notifyListeners();
  }

  set autoPlay(bool value) {
    _autoPlay = value;
    _saveSettings();
    notifyListeners();
  }

  set volume(double value) {
    _volume = value;
    _player.setVolume(value);
    _saveSettings();
    notifyListeners();
  }

  void setNotificationTime(int hour, int minute) {
    _notificationHour = hour;
    _notificationMinute = minute;
    _saveSettings();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Settings persistence (stored on the device)
  // ---------------------------------------------------------------------------
  static const kPrefDarkMode = 'settings.darkMode';
  static const _kPrefNotifications = 'settings.notificationsEnabled';
  static const _kPrefAutoPlay = 'settings.autoPlay';
  static const _kPrefVolume = 'settings.volume';
  static const _kPrefNotifHour = 'settings.notificationHour';
  static const _kPrefNotifMinute = 'settings.notificationMinute';

  Future<void> _loadSettings() async {
    if (!enablePersistence) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(kPrefDarkMode) ?? _isDarkMode;
      _notificationsEnabled =
          prefs.getBool(_kPrefNotifications) ?? _notificationsEnabled;
      _autoPlay = prefs.getBool(_kPrefAutoPlay) ?? _autoPlay;
      _volume = prefs.getDouble(_kPrefVolume) ?? _volume;
      _notificationHour = prefs.getInt(_kPrefNotifHour) ?? _notificationHour;
      _notificationMinute =
          prefs.getInt(_kPrefNotifMinute) ?? _notificationMinute;
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading settings: $e');
    }
  }

  void _saveSettings() {
    if (!enablePersistence) return;
    unawaited(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(kPrefDarkMode, _isDarkMode);
        await prefs.setBool(_kPrefNotifications, _notificationsEnabled);
        await prefs.setBool(_kPrefAutoPlay, _autoPlay);
        await prefs.setDouble(_kPrefVolume, _volume);
        await prefs.setInt(_kPrefNotifHour, _notificationHour);
        await prefs.setInt(_kPrefNotifMinute, _notificationMinute);
      } catch (e) {
        if (kDebugMode) debugPrint('Error saving settings: $e');
      }
    }());
  }

  String get currentSong => _currentSong;
  String get currentArtist => _currentArtist;
  bool get isFetchingCurrentSong => _isFetchingCurrentSong;
  List<String> get favoriteSongs => List.unmodifiable(_favoriteSongs);

  bool isFavorite(String song) => _favoriteSongs.contains(song);

  /// True when no real song info is available (station jingle / fallback).
  bool get isFallbackSong =>
      _currentSong.trim().isEmpty ||
      _currentSong.trim().toLowerCase() == kFallbackTitle.toLowerCase();

  String get currentSongDisplay {
    if (_currentArtist.isNotEmpty) {
      return '$_currentSong - $_currentArtist';
    }
    return _currentSong;
  }

  bool _autoPlayHandled = false;

  /// True only the first time it is asked in an app launch, and only when
  /// auto-play is on (so returning to the home page doesn't restart the radio).
  bool takeAutoPlay() {
    if (_autoPlayHandled) return false;
    _autoPlayHandled = true;
    return _autoPlay;
  }

  void markCelebrationShown() {
    _hasShownCelebrationToday = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Favorites
  // ---------------------------------------------------------------------------
  void toggleFavorite() {
    final songKey = currentSongDisplay;
    if (_favoriteSongs.contains(songKey)) {
      _favoriteSongs.remove(songKey);
    } else {
      // The station name / jingle is not a song.
      if (isFallbackSong) return;
      _favoriteSongs.add(songKey);
      _checkFavoriteAchievements();
    }
    _requestSync();
    notifyListeners();
  }

  void removeFavorite(String song) {
    _favoriteSongs.remove(song);
    _requestSync();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Badge helpers
  // ---------------------------------------------------------------------------

  /// Re-checks every badge whose condition can be evaluated from stored state.
  /// Safe to call at any time (e.g. after loading data from Firestore).
  void checkAndAwardBadges() {
    if (_hasPlayedBefore) _awardBadge('first_listen');
    _checkExplorer();
    _checkDailyListening();
    _checkTotalListening();
    _checkSessionCount();
    _checkStreak();
    _checkListeningDays();
    for (final slot in _timeSlots.keys) {
      _checkSlot(slot);
    }
    _checkWeekend();
    _checkWorkweek();
    _checkFavoriteAchievements();
    _checkDiscovery();
  }

  bool hasBadge(String badgeId) =>
      _earnedBadges.any((badge) => badge['id'] == badgeId);

  void _awardBadge(String badgeId) {
    if (hasBadge(badgeId) || !_allBadges.containsKey(badgeId)) return;
    final badgeData = Map<String, dynamic>.from(_allBadges[badgeId]!);
    badgeData['earnedDate'] = _clock().toIso8601String();
    _earnedBadges.add(badgeData);
    _pendingBadges.add(badgeId);
    onAchievementEarned?.call(badgeData);
    _requestSync();
    notifyListeners();
  }

  void _awardIf(bool condition, String badgeId) {
    if (condition) _awardBadge(badgeId);
  }

  void markBadgeShown(String badgeId) {
    _pendingBadges.remove(badgeId);
    notifyListeners();
  }

  String getNextPendingBadge() =>
      _pendingBadges.isNotEmpty ? _pendingBadges.first : '';

  void _checkExplorer() {
    final visited = _visitedPages.where(kExplorablePages.contains).toSet();
    _awardIf(visited.length >= _req('app_explorer'), 'app_explorer');
  }

  void _checkDailyListening() {
    final minutes = todayListeningMinutes;
    for (final id in const ['first_hour', 'marathon', 'five_hours']) {
      _awardIf(minutes >= _req(id), id);
    }
  }

  void _checkContinuous() {
    final minutes = _sessionListenedSeconds ~/ 60;
    for (final id in const [
      'quality_listener',
      'stable_connection',
      'ultra_marathon',
    ]) {
      _awardIf(minutes >= _req(id), id);
    }
  }

  void _checkTotalListening() {
    final minutes = totalListeningMinutes;
    for (final id in const ['ten_hours', 'fifty_hours', 'hundred_hours']) {
      _awardIf(minutes >= _req(id), id);
    }
  }

  void _checkSessionCount() {
    for (final id in const [
      'ten_sessions',
      'fifty_sessions',
      'hundred_sessions',
    ]) {
      _awardIf(_sessionCount >= _req(id), id);
    }
  }

  void _checkStreak() {
    for (final id in const [
      'daily_listener',
      'weekly_champion',
      'loyal_fan',
      'legend',
    ]) {
      _awardIf(_consecutiveDays >= _req(id), id);
    }
  }

  void _checkListeningDays() {
    for (final id in const ['first_week', 'first_month', 'loyal_user']) {
      _awardIf(_totalListeningDays >= _req(id), id);
    }
  }

  void _checkSlot(String slot) {
    _awardIf((_slotDayCounts[slot] ?? 0) >= _req(slot), slot);
  }

  void _checkWeekend() {
    _awardIf(_weekendDaysCount >= _req('weekend_warrior'), 'weekend_warrior');
  }

  void _checkWorkweek() {
    _awardIf(
      _workdaysThisWeek.length >= _req('workday_warrior'),
      'workday_warrior',
    );
  }

  void _checkFavoriteAchievements() {
    final count = _favoriteSongs.length;
    for (final id in const [
      'music_lover',
      'music_collector',
      'music_expert',
      'music_master',
    ]) {
      _awardIf(count >= _req(id), id);
    }
  }

  void _checkDiscovery() {
    final count = _uniqueSongs.length;
    _awardIf(count >= _req('song_discoverer'), 'song_discoverer');
    _awardIf(count >= _req('song_hunter'), 'song_hunter');
  }

  // ---------------------------------------------------------------------------
  // Metadata
  // ---------------------------------------------------------------------------
  Future<void> updateSong() async {
    _isFetchingCurrentSong = true;
    notifyListeners();
    try {
      final metadata = await _metadataService.getCurrentMetadata();
      _updateCurrentSong(metadata);
    } finally {
      _isFetchingCurrentSong = false;
      notifyListeners();
    }
  }

  static bool _isAllCaps(String s) {
    if (s.isEmpty) return false;
    if (!RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(s)) return false;
    return s == s.toUpperCase();
  }

  static String _formatSongTitle(String s) {
    if (s.isEmpty || !_isAllCaps(s)) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  static String _formatArtistName(String s) {
    if (s.isEmpty || !_isAllCaps(s)) return s;
    return s
        .split(' ')
        .map(
          (w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  void _updateCurrentSong(Map<String, String> metadata) {
    if (metadata.isEmpty) return;
    _currentSong = _formatSongTitle(metadata['title'] ?? kFallbackTitle);
    _currentArtist = _formatArtistName(metadata['artist'] ?? kFallbackArtist);
    _isFetchingCurrentSong = false;
    _trackCurrentSongHeard();
    notifyListeners();
  }

  /// Counts the current song for discovery badges, only while actually listening.
  void _trackCurrentSongHeard() {
    if (!_sessionActive || isFallbackSong) return;
    if (hasBadge('song_hunter')) return; // nothing left to unlock
    if (_uniqueSongs.add(currentSongDisplay.toLowerCase())) {
      _checkDiscovery();
    }
  }

  // ---------------------------------------------------------------------------
  // Player
  // ---------------------------------------------------------------------------
  Future<void> init() async {
    await _loadSettings();
    if (enablePersistence && _notificationsEnabled) {
      // Re-schedule the daily reminder (keeps the time right after DST changes).
      // Not awaited: scheduling 30 reminders must not delay the app start.
      unawaited(
        NotificationService.instance
            .scheduleDailyGoodNews(
              hour: _notificationHour,
              minute: _notificationMinute,
            )
            .catchError((Object e) {
              if (kDebugMode) debugPrint('Error scheduling reminder: $e');
            }),
      );
    }
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await _player.setAudioSource(AudioSource.uri(Uri.parse(kStreamUrl)));
      await _player.setVolume(_volume);
    } catch (e) {
      if (kDebugMode) debugPrint('Error initializing audio player: $e');
    }
    _initialized = true;
    _metadataService.start();
    _metadataService.metadataStream?.listen(_updateCurrentSong);
    updateSong();
    _startTicker();
    notifyListeners();
  }

  Duration _lastPosition = Duration.zero;
  bool? _lastListeningLogged;

  /// True while audio is really coming out. On iOS a live stream can report
  /// "buffering" for the whole time it plays, so besides the "ready" state we
  /// also accept "buffering" when the playback position keeps moving.
  bool _isListeningNow() {
    final player = _player;
    final state = player.processingState;
    final position = player.position;
    final advanced = (position - _lastPosition).inMilliseconds > 200;
    _lastPosition = position;
    final listening =
        player.playing &&
        (state == ProcessingState.ready ||
            (state == ProcessingState.buffering && advanced));
    if (kDebugMode && listening != _lastListeningLogged) {
      _lastListeningLogged = listening;
      debugPrint(
        '[Feniks] listening=$listening state=$state position=$position '
        'total=${_totalListeningSeconds}s',
      );
    }
    return listening;
  }

  Future<void> play() async {
    try {
      // Note: just_audio's play() future completes only when playback stops,
      // so it must not be awaited before tracking starts.
      unawaited(
        _player.play().catchError((Object e) {
          if (kDebugMode) debugPrint('Error playing audio: $e');
        }),
      );
      _startTicker();
      updateSong();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Error playing audio: $e');
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _player.pause();
    _endSession();
  }

  Future<void> stop() async {
    await _player.stop();
    _endSession();
  }

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Duration? get position => _player.position;
  bool get playing => _player.playing;

  /// Real listening time of the current session (pauses for buffering excluded).
  Duration get currentSessionDuration =>
      Duration(seconds: _sessionListenedSeconds);

  void _startTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    _tick(listening: _isListeningNow(), playerPlaying: _player.playing);
  }

  /// Simulates one timer tick (used by tests; the clock is advanced by the test).
  @visibleForTesting
  void debugTick({required bool listening}) =>
      _tick(listening: listening, playerPlaying: listening);

  /// Feeds now-playing metadata as if it came from the station (tests only).
  @visibleForTesting
  void debugSetSong(String title, String artist) =>
      _updateCurrentSong({'title': title, 'artist': artist});

  void _tick({required bool listening, required bool playerPlaying}) {
    final now = _clock();
    final last = _lastTick ?? now;
    _lastTick = now;
    _rollOverDayIfNeeded(now);

    if (!listening) {
      // Stopped by the user or the system (call, other app, lost connection...).
      if (_sessionActive && !playerPlaying) _endSession();
      return;
    }

    if (!_sessionActive) {
      // Count from the first tick on, so time before playback can never leak in.
      _startSession();
      _msCarry = 0;
      notifyListeners();
      return;
    }

    // Cap the delta so that a suspended timer can never award phantom time.
    var deltaMs = now.difference(last).inMilliseconds;
    if (deltaMs < 0) deltaMs = 0;
    if (deltaMs > 60000) deltaMs = 60000;
    _msCarry += deltaMs;
    final delta = _msCarry ~/ 1000;
    _msCarry -= delta * 1000;
    if (delta == 0) return;

    _todayListeningSeconds += delta;
    _totalListeningSeconds += delta;
    _sessionListenedSeconds += delta;
    _secondsTowardsMinute += delta;

    while (_secondsTowardsMinute >= 60) {
      _secondsTowardsMinute -= 60;
      _onListeningMinute(now);
    }

    notifyListeners();
  }

  void _startSession() {
    _sessionActive = true;
    _sessionCounted = false;
    _sessionListenedSeconds = 0;
    if (!_hasPlayedBefore) {
      _hasPlayedBefore = true;
      _awardBadge('first_listen');
    }
    _trackCurrentSongHeard();
  }

  void _endSession() {
    if (!_sessionActive) return;
    _sessionActive = false;
    final minutes = _sessionListenedSeconds ~/ 60;
    if (minutes > _longestSessionMinutes) _longestSessionMinutes = minutes;
    _requestSync();
    notifyListeners();
  }

  /// Called once for every full minute of real listening.
  void _onListeningMinute(DateTime now) {
    if (kDebugMode) {
      debugPrint(
        '[Feniks] +1 min (danas ${todayListeningMinutes}min, '
        'ukupno ${totalListeningMinutes}min, poeni od slušanja $listeningPoints)',
      );
    }
    // Listening day (streak, weekend, workweek, total days)
    if (!_todayCountedAsListeningDay &&
        todayListeningMinutes >= kMinMinutesForListeningDay) {
      _todayCountedAsListeningDay = true;
      _registerListeningDay(now);
    }

    // Time of day
    final slot = _slotFor(now.hour);
    final todayKey = _dayKey(now);
    if (_slotLastCountedDay[slot] != todayKey) {
      final m = (_slotMinutesToday[slot] ?? 0) + 1;
      _slotMinutesToday[slot] = m;
      if (m >= kMinMinutesForTimeSlot) {
        _slotLastCountedDay[slot] = todayKey;
        _slotDayCounts[slot] = (_slotDayCounts[slot] ?? 0) + 1;
        _checkSlot(slot);
      }
    }

    // Session count (a session counts once it reaches the minimum length)
    if (!_sessionCounted &&
        _sessionListenedSeconds >= kMinMinutesForSession * 60) {
      _sessionCounted = true;
      _sessionCount++;
      _checkSessionCount();
    }
    final sessionMinutes = _sessionListenedSeconds ~/ 60;
    if (sessionMinutes > _longestSessionMinutes) {
      _longestSessionMinutes = sessionMinutes;
    }

    _checkDailyListening();
    _checkContinuous();
    _checkTotalListening();

    // Save progress regularly even without new points or badges.
    if (_lastSyncAt == null ||
        now.difference(_lastSyncAt!) >= const Duration(minutes: 5)) {
      _requestSync();
    }
  }

  void _registerListeningDay(DateTime now) {
    final today = _dateOnly(now);
    final last = _lastListeningDate == null
        ? null
        : _dateOnly(_lastListeningDate!);
    if (last != null && last == today) return; // already counted

    if (last != null && today.difference(last).inDays == 1) {
      _consecutiveDays++;
    } else {
      _consecutiveDays = 1;
    }
    _lastListeningDate = today;
    _totalListeningDays++;

    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      _weekendDaysCount++;
      _checkWeekend();
    } else {
      final weekKey = _dayKey(today.subtract(Duration(days: now.weekday - 1)));
      if (_workweekKey != weekKey) {
        _workweekKey = weekKey;
        _workdaysThisWeek.clear();
      }
      _workdaysThisWeek.add(now.weekday);
      _checkWorkweek();
    }

    _checkStreak();
    _checkListeningDays();
    _requestSync();
  }

  void _rollOverDayIfNeeded(DateTime now) {
    final key = _dayKey(now);
    if (key == _todayKey) return;
    _todayKey = key;
    _todayListeningSeconds = 0;
    _todayCountedAsListeningDay = false;
    _slotMinutesToday.clear();
    notifyListeners();
  }

  static String _slotFor(int hour) {
    for (final e in _timeSlots.entries) {
      if (hour >= e.value[0] && hour < e.value[1]) return e.key;
    }
    return 'night_owl';
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------------
  // Page visits
  // ---------------------------------------------------------------------------
  void trackPageVisit(String pageName) {
    if (!kExplorablePages.contains(pageName)) return;
    if (_visitedPages.contains(pageName)) return;
    _visitedPages.add(pageName);
    _checkExplorer();
    _requestSync();
  }

  // ---------------------------------------------------------------------------
  // Firestore sync
  // ---------------------------------------------------------------------------
  void _requestSync() {
    unawaited(_syncProgressToFirestore());
  }

  /// Saves progress and the leaderboard entry now (no-op when logged out).
  Future<void> syncNow() => _syncProgressToFirestore();

  /// Waits until a save that is already running has finished (max [timeout]).
  Future<void> waitForPendingSync({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final done = _syncDone;
    if (done == null) return;
    try {
      await done.future.timeout(timeout);
    } catch (_) {}
  }

  Future<void> _syncProgressToFirestore() async {
    if (!enableSync) return;
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      return;
    }
    if (user == null) return;
    // Never overwrite the saved progress before it has been loaded.
    if (loadedUserId != user.uid) return;
    if (_syncInProgress) {
      _syncAgain = true; // make sure the latest state gets written too
      return;
    }
    _syncInProgress = true;
    final done = _syncDone = Completer<void>();
    try {
      do {
        // Stop if the user logged out / progress was reset meanwhile, so an
        // empty state can never overwrite the saved progress.
        if (loadedUserId != user.uid) break;
        _syncAgain = false;
        _lastSyncAt = _clock();
        // Take one consistent snapshot before any await.
        final data = getAchievementData();
        final listening = listeningPoints;
        final badges = badgePoints;
        final badgeCount = _earnedBadges.length;
        await FirestoreService.instance.saveUserAchievements(user.uid, data);
        await FirestoreService.instance.updateLeaderboardEntry(
          user.uid,
          displayName: user.displayName ?? 'Anonim',
          listeningPoints: listening,
          badgePoints: badges,
          badgeCount: badgeCount,
        );
      } while (_syncAgain);
    } catch (_) {
      // Keep app stable if Firestore rules are strict.
    } finally {
      _syncInProgress = false;
      done.complete();
      if (identical(_syncDone, done)) _syncDone = null;
    }
  }

  /// Returns all achievement-related data for Firestore persistence.
  Map<String, dynamic> getAchievementData() {
    return {
      'earnedBadges': _earnedBadges
          .map((b) => {'id': b['id'], 'earnedDate': b['earnedDate']})
          .toList(),
      'consecutiveDays': _consecutiveDays,
      'lastListeningDate': _lastListeningDate?.toIso8601String(),
      'totalListeningDays': _totalListeningDays,
      'totalListeningSeconds': _totalListeningSeconds,
      'totalListeningMinutes': totalListeningMinutes,
      'sessionCount': _sessionCount,
      'longestSessionDuration': _longestSessionMinutes,
      'favoriteSongs': List<String>.from(_favoriteSongs),
      'slotDayCounts': Map<String, int>.from(_slotDayCounts),
      'slotLastCountedDay': Map<String, String>.from(_slotLastCountedDay),
      'weekendDaysCount': _weekendDaysCount,
      'workweekKey': _workweekKey,
      'workdaysThisWeek': _workdaysThisWeek.toList(),
      'uniqueSongs': _uniqueSongs.toList(),
      'visitedPages': List<String>.from(_visitedPages),
      'hasPlayedBefore': _hasPlayedBefore,
      'badgePoints': badgePoints,
      'listeningPoints': listeningPoints,
      'todayListeningSeconds': _todayListeningSeconds,
      'dateForTodayListening': _todayKey,
      'todayCountedAsListeningDay': _todayCountedAsListeningDay,
    };
  }

  /// Restores achievement state from Firestore data (also migrates data saved
  /// by older app versions).
  void loadAchievementData(Map<String, dynamic>? data) {
    if (data == null) return;

    _earnedBadges.clear();
    final badges = data['earnedBadges'] as List<dynamic>?;
    if (badges != null) {
      for (final b in badges) {
        final map = Map<String, dynamic>.from(b as Map);
        final id = map['id'] as String?;
        if (id != null && _allBadges.containsKey(id) && !hasBadge(id)) {
          final full = Map<String, dynamic>.from(_allBadges[id]!);
          full['earnedDate'] =
              map['earnedDate'] ?? _clock().toIso8601String();
          _earnedBadges.add(full);
        }
      }
    }

    _consecutiveDays = (data['consecutiveDays'] as num?)?.toInt() ?? 0;
    final last = data['lastListeningDate'] as String?;
    _lastListeningDate = last != null ? DateTime.tryParse(last) : null;

    final seconds = (data['totalListeningSeconds'] as num?)?.toInt();
    final minutes = (data['totalListeningMinutes'] as num?)?.toInt() ?? 0;
    _totalListeningSeconds = seconds ?? minutes * 60;

    _sessionCount = (data['sessionCount'] as num?)?.toInt() ?? 0;
    _longestSessionMinutes =
        (data['longestSessionDuration'] as num?)?.toInt() ?? 0;

    _favoriteSongs
      ..clear()
      ..addAll((data['favoriteSongs'] as List<dynamic>? ?? []).cast<String>());

    // Time of day counters (old versions stored counts per play under other keys)
    _slotDayCounts.clear();
    final slotCounts = data['slotDayCounts'];
    if (slotCounts is Map) {
      slotCounts.forEach((k, v) {
        if (v is num) _slotDayCounts[k.toString()] = v.toInt();
      });
    }
    _slotLastCountedDay.clear();
    final slotDays = data['slotLastCountedDay'];
    if (slotDays is Map) {
      slotDays.forEach((k, v) {
        if (v is String) _slotLastCountedDay[k.toString()] = v;
      });
    }

    // Weekend days (old versions stored a list of weekend dates)
    final oldWeekend = data['weekendDaysVisited'] as List<dynamic>?;
    _weekendDaysCount = (data['weekendDaysCount'] as num?)?.toInt() ??
        (oldWeekend?.length ?? 0);

    _workweekKey = data['workweekKey'] as String?;
    _workdaysThisWeek
      ..clear()
      ..addAll(
        (data['workdaysThisWeek'] as List<dynamic>? ?? [])
            .whereType<num>()
            .map((e) => e.toInt()),
      );

    // Total listening days (old versions did not track this)
    _totalListeningDays = (data['totalListeningDays'] as num?)?.toInt() ??
        (_consecutiveDays > 0 ? _consecutiveDays : 0);

    _uniqueSongs
      ..clear()
      ..addAll(
        (data['uniqueSongs'] as List<dynamic>? ?? [])
            .map((e) => e.toString().toLowerCase()),
      );
    _visitedPages
      ..clear()
      ..addAll(
        (data['visitedPages'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .where(kExplorablePages.contains),
      );
    _hasPlayedBefore = data['hasPlayedBefore'] as bool? ?? false;

    final dateForToday = data['dateForTodayListening'] as String?;
    final todayKey = _dayKey(_clock());
    _todayKey = todayKey;
    if (dateForToday != null && _normalizeDayKey(dateForToday) == todayKey) {
      _todayListeningSeconds =
          (data['todayListeningSeconds'] as num?)?.toInt() ?? 0;
      _todayCountedAsListeningDay =
          data['todayCountedAsListeningDay'] as bool? ??
          (_lastListeningDate != null &&
              _dateOnly(_lastListeningDate!) == _dateOnly(_clock()));
    } else {
      _todayListeningSeconds = 0;
      _todayCountedAsListeningDay = false;
    }

    _pendingBadges.clear();
    // Award anything that the stored progress already qualifies for, without
    // showing a popup storm for badges earned by old progress.
    final callback = onAchievementEarned;
    onAchievementEarned = null;
    checkAndAwardBadges();
    onAchievementEarned = callback;
    _pendingBadges.clear();

    notifyListeners();
  }

  /// Loads the saved progress of [uid]. Anything listened before the data
  /// was loaded (e.g. without being logged in) is added on top, so it is not lost.
  void loadUserProgress(String uid, Map<String, dynamic>? data) {
    final mergeGuest = loadedUserId == null;
    final guestTotal = _totalListeningSeconds;
    final guestToday = _todayKey == _dayKey(_clock()) ? _todayListeningSeconds : 0;
    final guestSessions = _sessionCount;
    final guestLongest = _longestSessionMinutes;
    final guestPlayed = _hasPlayedBefore;
    final guestPages = List<String>.from(_visitedPages);
    final guestSongs = Set<String>.from(_uniqueSongs);

    loadAchievementData(data ?? <String, dynamic>{});

    if (mergeGuest) {
      _totalListeningSeconds += guestTotal;
      _todayListeningSeconds += guestToday;
      _sessionCount += guestSessions;
      if (guestLongest > _longestSessionMinutes) {
        _longestSessionMinutes = guestLongest;
      }
      _hasPlayedBefore = _hasPlayedBefore || guestPlayed;
      for (final page in guestPages) {
        if (!_visitedPages.contains(page)) _visitedPages.add(page);
      }
      _uniqueSongs.addAll(guestSongs);
      final callback = onAchievementEarned;
      onAchievementEarned = null;
      checkAndAwardBadges();
      onAchievementEarned = callback;
      _pendingBadges.clear();
    }
    loadedUserId = uid;
    notifyListeners();
  }

  /// Clears all progress (used on logout so the next user starts clean).
  void resetProgress() {
    loadedUserId = null;
    _earnedBadges.clear();
    _pendingBadges.clear();
    _totalListeningSeconds = 0;
    _todayListeningSeconds = 0;
    _todayKey = _dayKey(_clock());
    _todayCountedAsListeningDay = false;
    _slotMinutesToday.clear();
    _sessionCount = 0;
    _sessionCounted = _sessionActive; // a running session is not counted again
    _longestSessionMinutes = 0;
    _consecutiveDays = 0;
    _lastListeningDate = null;
    _totalListeningDays = 0;
    _weekendDaysCount = 0;
    _workweekKey = null;
    _workdaysThisWeek.clear();
    _slotDayCounts.clear();
    _slotLastCountedDay.clear();
    _uniqueSongs.clear();
    _visitedPages.clear();
    _favoriteSongs.clear();
    _hasPlayedBefore = false;
    notifyListeners();
  }

  static String _normalizeDayKey(String s) {
    final parts = s.split('-');
    if (parts.length != 3) return s;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return s;
    return _dayKey(DateTime(y, m, d));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    _metadataInstance?.stop();
    _playerInstance?.dispose();
    super.dispose();
  }
}
