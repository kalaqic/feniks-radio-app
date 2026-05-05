import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/metadata_service.dart';
import '../services/firestore_service.dart';

const kStreamUrl = 'https://c30.radioboss.fm:8234/stream';

class RadioPlayerModel extends ChangeNotifier {
  final _player = AudioPlayer();
  final _metadataService = MetadataService();
  bool _initialized = false;
  bool get isInitialized => _initialized;

  DateTime? _sessionStartTime;
  Timer? _sessionTimer;
  DateTime? _lastStopTime;
  int _todayListeningSeconds = 0;
  int _longestSessionDuration = 0;

  final Map<String, int> _weeklyListeningData = {
    'Mon': 0,
    'Tue': 0,
    'Wed': 0,
    'Thu': 0,
    'Fri': 0,
    'Sat': 0,
    'Sun': 0,
  };

  bool _hasShownCelebrationToday = false;
  int _consecutiveDays = 0;
  bool _hasShownAchievementModal = false;

  // Badge system
  final List<Map<String, dynamic>> _earnedBadges = [];
  final List<String> _pendingBadges = []; // Badges earned but not shown yet

  // Achievement tracking
  DateTime? _lastListeningDate;
  int _earlyBirdSessions = 0;
  int _nightOwlSessions = 0;
  int _midnightSessions = 0;
  int _pagesVisited = 0;
  int _sharesCount = 0;
  int _fastStartCount = 0;
  bool _hasPlayedBefore = false;
  bool _hasPlayedSuccessfully = false;
  final List<String> _visitedPages = [];

  // New tracking variables
  int _totalListeningMinutes = 0;
  int _sessionCount = 0;
  int _morningListens = 0;
  int _afternoonListens = 0;
  int _eveningListens = 0;
  DateTime? _appInstallDate;
  final Set<String> _uniqueSongs = {};
  final Set<String> _musicGenres = {};
  int _referralCount = 0;
  bool _isCommunityMember = false;
  bool _syncInProgress = false;

  // Track unique days for weekend_warrior and workday_warrior
  final Set<String> _weekendDaysVisited = {};
  final Set<String> _weekdayDaysVisited = {};

  // Track continuous listening for technical achievements
  DateTime? _continuousSessionStart;
  DateTime? _qualitySessionStart;

  // Track competitive achievements
  int _top10Weeks = 0;

  // Feniks Points System
  int _messagesSent = 0;
  int _listeningPoints = 0;
  int _badgePoints = 0;

  /// Section order for badges page.
  static const List<String> badgeSectionOrder = [
    'Prvi koraci',
    'Dnevno slušanje',
    'Ukupno slušanje',
    'Broj sesija',
    'Nizovi',
    'Vrijeme u danu',
    'Vikend i radni dan',
    'Omiljene pjesme',
    'Otkrivanje',
    'Tehnički',
    'Milestoni',
  ];

  static const Map<String, String> _badgeToSection = {
    'first_listen': 'Prvi koraci',
    'first_playing': 'Prvi koraci',
    'app_explorer': 'Prvi koraci',
    'speed_start': 'Prvi koraci',
    'first_hour': 'Dnevno slušanje',
    'marathon': 'Dnevno slušanje',
    'five_hours': 'Dnevno slušanje',
    'ten_hours': 'Ukupno slušanje',
    'fifty_hours': 'Ukupno slušanje',
    'hundred_hours': 'Ukupno slušanje',
    'ten_sessions': 'Broj sesija',
    'fifty_sessions': 'Broj sesija',
    'hundred_sessions': 'Broj sesija',
    'daily_listener': 'Nizovi',
    'weekly_champion': 'Nizovi',
    'loyal_fan': 'Nizovi',
    'legend': 'Nizovi',
    'early_bird': 'Vrijeme u danu',
    'night_owl': 'Vrijeme u danu',
    'midnight_listener': 'Vrijeme u danu',
    'morning_person': 'Vrijeme u danu',
    'afternoon_listener': 'Vrijeme u danu',
    'evening_enthusiast': 'Vrijeme u danu',
    'weekend_warrior': 'Vikend i radni dan',
    'workday_warrior': 'Vikend i radni dan',
    'music_lover': 'Omiljene pjesme',
    'music_collector': 'Omiljene pjesme',
    'music_expert': 'Omiljene pjesme',
    'music_master': 'Omiljene pjesme',
    'song_discoverer': 'Otkrivanje',
    'genre_explorer': 'Otkrivanje',
    'stable_connection': 'Tehnički',
    'quality_listener': 'Tehnički',
    'ultra_marathon': 'Tehnički',
    'first_week': 'Milestoni',
    'first_month': 'Milestoni',
    'loyal_user': 'Milestoni',
  };

  // All available badges
  static final Map<String, Map<String, dynamic>> _allBadges = {
    // Time-based achievements
    'first_hour': {
      'id': 'first_hour',
      'name': 'Prvi Sat',
      'description': 'Slušaj više od sata vremena u jednom danu',
      'icon': '⏰',
      'color': 0xFF34C759,
      'requirement': 60, // minutes
      'points': 50,
      'type': 'daily_listening',
    },
    'five_hours': {
      'id': 'five_hours',
      'name': 'Pet Sati',
      'description': 'Slušaj 5 sati u jednom danu',
      'icon': '🕐',
      'color': 0xFF5856D6,
      'requirement': 300, // minutes
      'points': 200,
      'type': 'daily_listening',
    },
    'marathon': {
      'id': 'marathon',
      'name': 'Maraton Slušanje',
      'description': 'Slušaj 3 sata u jednom danu',
      'icon': '🏃',
      'color': 0xFFFF9500,
      'requirement': 180, // minutes daily
      'points': 200,
      'type': 'daily_listening',
    },
    'ultra_marathon': {
      'id': 'ultra_marathon',
      'name': 'Ultra Maraton',
      'description': 'Slušaj bez prekida 6 sati',
      'icon': '🚀',
      'color': 0xFFFF3B30,
      'requirement': 360, // minutes continuously
      'points': 500,
      'type': 'continuous_listening',
    },

    // Streak achievements
    'daily_listener': {
      'id': 'daily_listener',
      'name': 'Dnevni Slušalac',
      'description': 'Slušaj Feniks Radio 7 dana zaredom',
      'icon': '📅',
      'color': 0xFFEB6556,
      'requirement': 7, // consecutive days
      'points': 150,
      'type': 'streak',
    },
    'weekly_champion': {
      'id': 'weekly_champion',
      'name': 'Sedmični Šampion',
      'description': 'Slušaj Feniks Radio 14 dana zaredom',
      'icon': '🎖️',
      'color': 0xFF32D74B,
      'requirement': 14, // consecutive days
      'points': 250,
      'type': 'streak',
    },
    'loyal_fan': {
      'id': 'loyal_fan',
      'name': 'Vjeran Fan',
      'description': 'Slušaj Feniks Radio 30 dana zaredom',
      'icon': '👑',
      'color': 0xFF8B5CF6,
      'requirement': 30, // consecutive days
      'points': 500,
      'type': 'streak',
    },
    'legend': {
      'id': 'legend',
      'name': 'Legenda',
      'description': 'Slušaj Feniks Radio 100 dana zaredom',
      'icon': '⚡',
      'color': 0xFFFFD700,
      'requirement': 100, // consecutive days
      'points': 1000,
      'type': 'streak',
    },

    // Time-of-day achievements
    'early_bird': {
      'id': 'early_bird',
      'name': 'Rana Ptica',
      'description': 'Slušaj radio između 5AM i 8AM',
      'icon': '🐦',
      'color': 0xFF32D74B,
      'requirement': 5, // times
      'points': 75,
      'type': 'time_based',
    },
    'night_owl': {
      'id': 'night_owl',
      'name': 'Noćna Ptica',
      'description': 'Slušaj radio između 10PM i 2AM',
      'icon': '🦉',
      'color': 0xFF5856D6,
      'requirement': 5, // times
      'points': 75,
      'type': 'time_based',
    },
    'midnight_listener': {
      'id': 'midnight_listener',
      'name': 'Ponoćni Slušalac',
      'description': 'Slušaj radio između 12AM i 2AM',
      'icon': '🌙',
      'color': 0xFF8B5CF6,
      'requirement': 3, // times
      'points': 100,
      'type': 'time_based',
    },
    'weekend_warrior': {
      'id': 'weekend_warrior',
      'name': 'Vikend Ratnik',
      'description': 'Slušaj radio svaki vikend u mjesecu',
      'icon': '🎉',
      'color': 0xFFFF9500,
      'requirement': 8, // weekend days
      'points': 200,
      'type': 'time_based',
    },

    // Music-related achievements
    'music_lover': {
      'id': 'music_lover',
      'name': 'Ljubitelj Muzike',
      'description': 'Dodaj 10 pjesama u omiljene',
      'icon': '💝',
      'color': 0xFFFF3B30,
      'requirement': 10, // favorite songs
      'points': 150,
      'type': 'favorites',
    },
    'music_collector': {
      'id': 'music_collector',
      'name': 'Kolekcionar Muzike',
      'description': 'Dodaj 25 pjesama u omiljene',
      'icon': '📀',
      'color': 0xFF007AFF,
      'requirement': 25, // favorite songs
      'points': 300,
      'type': 'favorites',
    },
    'music_expert': {
      'id': 'music_expert',
      'name': 'Stručnjak za Muziku',
      'description': 'Dodaj 50 pjesama u omiljene',
      'icon': '🎵',
      'color': 0xFF5856D6,
      'requirement': 50, // favorite songs
      'points': 500,
      'type': 'favorites',
    },
    'music_master': {
      'id': 'music_master',
      'name': 'Majstor Muzike',
      'description': 'Dodaj 100 pjesama u omiljene',
      'icon': '🎼',
      'color': 0xFFFFD700,
      'requirement': 100, // favorite songs
      'points': 750,
      'type': 'favorites',
    },

    // Special achievements
    'first_listen': {
      'id': 'first_listen',
      'name': 'Prvi Put',
      'description': 'Pokreni Feniks Radio prvi put',
      'icon': '🎧',
      'color': 0xFF34C759,
      'requirement': 1, // times
      'points': 25,
      'type': 'special',
    },
    'first_playing': {
      'id': 'first_playing',
      'name': 'Prva Reprodukcija',
      'description': 'Uspješno pokreni reprodukciju radija',
      'icon': '▶️',
      'color': 0xFF007AFF,
      'requirement': 1, // successful plays
      'points': 50,
      'type': 'special',
    },
    'app_explorer': {
      'id': 'app_explorer',
      'name': 'Istraživač Aplikacije',
      'description': 'Posjeti sve stranice u aplikaciji',
      'icon': '🧭',
      'color': 0xFF007AFF,
      'requirement': 5, // different pages
      'points': 100,
      'type': 'special',
    },
    'speed_start': {
      'id': 'speed_start',
      'name': 'Brzinski Start',
      'description': 'Pokreni radio u manje od 5 sekundi 10 puta',
      'icon': '💨',
      'color': 0xFFFF3B30,
      'requirement': 10,
      'points': 200,
      'type': 'special',
    },

    // Time milestone achievements
    'ten_hours': {
      'id': 'ten_hours',
      'name': 'Deset Sati',
      'description': 'Slušaj ukupno 10 sati',
      'icon': '🕙',
      'color': 0xFFFF9500,
      'requirement': 600, // minutes total
      'points': 300,
      'type': 'total_listening',
    },
    'fifty_hours': {
      'id': 'fifty_hours',
      'name': 'Pedeset Sati',
      'description': 'Slušaj ukupno 50 sati',
      'icon': '🕐',
      'color': 0xFF5856D6,
      'requirement': 3000, // minutes total
      'points': 750,
      'type': 'total_listening',
    },
    'hundred_hours': {
      'id': 'hundred_hours',
      'name': 'Sto Sati',
      'description': 'Slušaj ukupno 100 sati',
      'icon': '💯',
      'color': 0xFFFFD700,
      'requirement': 6000, // minutes total
      'points': 1500,
      'type': 'total_listening',
    },

    // Session count achievements
    'ten_sessions': {
      'id': 'ten_sessions',
      'name': 'Deset Sesija',
      'description': 'Završi 10 slušajnih sesija',
      'icon': '🔟',
      'color': 0xFF34C759,
      'requirement': 10, // sessions
      'points': 100,
      'type': 'session_count',
    },
    'fifty_sessions': {
      'id': 'fifty_sessions',
      'name': 'Pedeset Sesija',
      'description': 'Završi 50 slušajnih sesija',
      'icon': '📻',
      'color': 0xFF007AFF,
      'requirement': 50, // sessions
      'points': 300,
      'type': 'session_count',
    },
    'hundred_sessions': {
      'id': 'hundred_sessions',
      'name': 'Sto Sesija',
      'description': 'Završi 100 slušajnih sesija',
      'icon': '🎯',
      'color': 0xFFFF3B30,
      'requirement': 100, // sessions
      'points': 600,
      'type': 'session_count',
    },

    // Habit achievements
    'morning_person': {
      'id': 'morning_person',
      'name': 'Jutarnja Osoba',
      'description': 'Slušaj radio 10 puta ujutru (6AM-10AM)',
      'icon': '🌅',
      'color': 0xFFFFD700,
      'requirement': 10, // times
      'points': 200,
      'type': 'time_based',
    },
    'afternoon_listener': {
      'id': 'afternoon_listener',
      'name': 'Popodnevni Slušalac',
      'description': 'Slušaj radio 10 puta poslije podne (12PM-6PM)',
      'icon': '☀️',
      'color': 0xFFFF9500,
      'requirement': 10, // times
      'points': 150,
      'type': 'time_based',
    },
    'evening_enthusiast': {
      'id': 'evening_enthusiast',
      'name': 'Večernji Entuzijast',
      'description': 'Slušaj radio 10 puta navečer (6PM-10PM)',
      'icon': '🌆',
      'color': 0xFF8B5CF6,
      'requirement': 10, // times
      'points': 150,
      'type': 'time_based',
    },

    // Discovery achievements
    'song_discoverer': {
      'id': 'song_discoverer',
      'name': 'Otkrivač Pjesama',
      'description': 'Otkrij 5 različitih pjesama',
      'icon': '🔍',
      'color': 0xFF32D74B,
      'requirement': 5, // unique songs
      'points': 100,
      'type': 'discovery',
    },
    'genre_explorer': {
      'id': 'genre_explorer',
      'name': 'Istraživač Žanrova',
      'description': 'Slušaj pjesme iz 10 različitih žanrova',
      'icon': '🎼',
      'color': 0xFF5856D6,
      'requirement': 10, // genres
      'points': 300,
      'type': 'discovery',
    },

    // Dedication achievements
    'workday_warrior': {
      'id': 'workday_warrior',
      'name': 'Radni Dan Ratnik',
      'description': 'Slušaj radio svaki radni dan u sedmici',
      'icon': '💼',
      'color': 0xFF007AFF,
      'requirement': 5, // weekdays
      'points': 250,
      'type': 'time_based',
    },

    // Technical achievements
    'stable_connection': {
      'id': 'stable_connection',
      'name': 'Stabilna Konekcija',
      'description': 'Slušaj 2 sata bez prekida konekcije',
      'icon': '📡',
      'color': 0xFF34C759,
      'requirement': 120, // minutes without disconnection
      'points': 200,
      'type': 'technical',
    },
    'quality_listener': {
      'id': 'quality_listener',
      'name': 'Kvalitetni Slušalac',
      'description': 'Održi konstantan kvalitet zvuka 30 minuta',
      'icon': '🔊',
      'color': 0xFF007AFF,
      'requirement': 30, // minutes good quality
      'points': 150,
      'type': 'technical',
    },

    // Milestone achievements
    'first_week': {
      'id': 'first_week',
      'name': 'Prva Sedmica',
      'description': 'Koristi aplikaciju sedam dana',
      'icon': '📅',
      'color': 0xFF32D74B,
      'requirement': 7, // days since install
      'points': 100,
      'type': 'milestone',
    },
    'first_month': {
      'id': 'first_month',
      'name': 'Prvi Mjesec',
      'description': 'Koristi aplikaciju mjesec dana',
      'icon': '🗓️',
      'color': 0xFF5856D6,
      'requirement': 30, // days since install
      'points': 300,
      'type': 'milestone',
    },
    'loyal_user': {
      'id': 'loyal_user',
      'name': 'Vjeran Korisnik',
      'description': 'Koristi aplikaciju šest mjeseci',
      'icon': '💎',
      'color': 0xFFFFD700,
      'requirement': 180, // days since install
      'points': 800,
      'type': 'milestone',
    },
  };

  String _currentSong = 'Feniks Radio';
  String _currentArtist = 'Samo dobre vijesti!';
  bool _isFetchingCurrentSong = false;
  final List<String> _favoriteSongs = [];

  /// Today's listening time in seconds. Includes current session while playing so the counter updates live.
  int get todayListeningSeconds {
    final base = _todayListeningSeconds;
    if (playing && _sessionStartTime != null) {
      return base + DateTime.now().difference(_sessionStartTime!).inSeconds;
    }
    return base;
  }

  int get todayListeningMinutes => (todayListeningSeconds / 60).round();
  Map<String, int> get weeklyListeningData => _weeklyListeningData;
  bool get shouldShowCelebration => !_hasShownCelebrationToday;
  int get consecutiveDays => _consecutiveDays;
  bool get shouldShowAchievementModal => !_hasShownAchievementModal;

  // Badge system getters
  List<Map<String, dynamic>> get earnedBadges =>
      List.unmodifiable(_earnedBadges);
  List<String> get pendingBadges => List.unmodifiable(_pendingBadges);
  Map<String, Map<String, dynamic>> get allBadges => _allBadges;
  bool get hasPendingBadges => _pendingBadges.isNotEmpty;

  /// Badges grouped by section for display, in badgeSectionOrder. Only sections that have badges are included.
  Map<String, List<Map<String, dynamic>>> get badgesGroupedBySection {
    final Map<String, List<Map<String, dynamic>>> result = {};
    for (final entry in _allBadges.entries) {
      final id = entry.key;
      final badge = Map<String, dynamic>.from(entry.value);
      final section = _badgeToSection[id] ?? 'Ostalo';
      result.putIfAbsent(section, () => []).add(badge);
    }
    // Sort keys by badgeSectionOrder
    final ordered = <String, List<Map<String, dynamic>>>{};
    for (final section in badgeSectionOrder) {
      if (result.containsKey(section)) ordered[section] = result[section]!;
    }
    for (final key in result.keys) {
      if (!ordered.containsKey(key)) ordered[key] = result[key]!;
    }
    return ordered;
  }

  // Achievement popup callback
  void Function(Map<String, dynamic>)? onAchievementEarned;

  /// Called when progress changes (for Firestore sync).
  void Function()? onProgressChanged;

  // Settings
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _autoPlay = false;
  bool _highQuality = true;
  bool _downloadOnWifi = true;
  double _volume = 0.8;
  int _notificationHour = 8;
  int _notificationMinute = 0;

  // Feniks Points getters
  int get messagesSent => _messagesSent;
  int get listeningPoints => _listeningPoints;
  int get badgePoints => _badgePoints;
  int get totalFeniksPoints => _listeningPoints + _badgePoints;

  /// Total minutes listened (all time). Includes current session while playing.
  int get totalListeningMinutes =>
      _totalListeningMinutes +
      (playing && _sessionStartTime != null
          ? currentSessionDuration.inMinutes
          : 0);

  // Settings getters
  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get autoPlay => _autoPlay;
  bool get highQuality => _highQuality;
  bool get downloadOnWifi => _downloadOnWifi;
  double get volume => _volume;
  int get notificationHour => _notificationHour;
  int get notificationMinute => _notificationMinute;

  // Settings setters
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

  set highQuality(bool value) {
    _highQuality = value;
    _updateAudioQuality();
    _saveSettings();
    notifyListeners();
  }

  set downloadOnWifi(bool value) {
    _downloadOnWifi = value;
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

  String get currentSong => _currentSong;
  String get currentArtist => _currentArtist;
  bool get isFetchingCurrentSong => _isFetchingCurrentSong;
  List<String> get favoriteSongs => List.unmodifiable(_favoriteSongs);

  bool isFavorite(String song) => _favoriteSongs.contains(song);

  String get currentSongDisplay {
    if (_currentArtist.isNotEmpty) {
      return '$_currentSong - $_currentArtist';
    }
    return _currentSong;
  }

  void markCelebrationShown() {
    _hasShownCelebrationToday = true;
    notifyListeners();
  }

  void markAchievementModalShown() {
    _hasShownAchievementModal = true;
    notifyListeners();
  }

  void toggleFavorite() {
    final songKey = currentSongDisplay;
    if (_favoriteSongs.contains(songKey)) {
      _favoriteSongs.remove(songKey);
    } else {
      _favoriteSongs.add(songKey);
      // Check music-related achievements when adding favorites
      _checkMusicAchievements();
    }
    onProgressChanged?.call();
    unawaited(_syncProgressToFirestore());
    notifyListeners();
  }

  void removeFavorite(String song) {
    _favoriteSongs.remove(song);
    onProgressChanged?.call();
    unawaited(_syncProgressToFirestore());
    notifyListeners();
  }

  // Badge system methods
  void checkAndAwardBadges() {
    // Check first hour badge
    if (todayListeningMinutes >= 60 && !hasBadge('first_hour')) {
      _awardBadge('first_hour');
    }

    // Check music lover badge
    if (_favoriteSongs.length >= 10 && !hasBadge('music_lover')) {
      _awardBadge('music_lover');
    }

    // Check daily listener badge
    if (_consecutiveDays >= 7 && !hasBadge('daily_listener')) {
      _awardBadge('daily_listener');
    }

    // Check loyal fan badge
    if (_consecutiveDays >= 30 && !hasBadge('loyal_fan')) {
      _awardBadge('loyal_fan');
    }

    // Removed automatic top_monthly badge
  }

  bool hasBadge(String badgeId) {
    return _earnedBadges.any((badge) => badge['id'] == badgeId);
  }

  void _awardBadge(String badgeId) {
    if (!hasBadge(badgeId) && _allBadges.containsKey(badgeId)) {
      final badgeData = Map<String, dynamic>.from(_allBadges[badgeId]!);
      badgeData['earnedDate'] = DateTime.now().toIso8601String();

      _earnedBadges.add(badgeData);
      _pendingBadges.add(badgeId);

      // Add badge points to Feniks Points
      final badgePoints = badgeData['points'] as int? ?? 0;
      _addBadgePoints(badgePoints);

      // Trigger immediate popup
      if (onAchievementEarned != null) {
        onAchievementEarned!(badgeData);
      }
      onProgressChanged?.call();
      unawaited(_syncProgressToFirestore());
      notifyListeners();
    }
  }

  void markBadgeShown(String badgeId) {
    _pendingBadges.remove(badgeId);
    notifyListeners();
  }

  String getNextPendingBadge() {
    return _pendingBadges.isNotEmpty ? _pendingBadges.first : '';
  }

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

  /// True if string has at least one letter and all letters are uppercase.
  static bool _isAllCaps(String s) {
    if (s.isEmpty) return false;
    if (!RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(s)) return false;
    return s == s.toUpperCase();
  }

  /// Song title: only first letter uppercase, rest lowercase (when all caps).
  static String _formatSongTitle(String s) {
    if (s.isEmpty) return s;
    if (!_isAllCaps(s)) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  /// Artist: every word first letter uppercase (when all caps).
  static String _formatArtistName(String s) {
    if (s.isEmpty) return s;
    if (!_isAllCaps(s)) return s;
    return s
        .split(' ')
        .map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        })
        .join(' ');
  }

  void _updateCurrentSong(Map<String, String> metadata) {
    if (metadata.isNotEmpty) {
      final rawSong = metadata['title'] ?? 'Feniks Radio';
      final rawArtist = metadata['artist'] ?? 'Samo dobre vijesti!';
      final newSong = _formatSongTitle(rawSong);
      final newArtist = _formatArtistName(rawArtist);
      _currentSong = newSong;
      _currentArtist = newArtist;
      final genre = metadata['genre'];
      if (genre != null && genre.isNotEmpty) {
        trackMusicGenre(genre);
      }
      _isFetchingCurrentSong = false;
      notifyListeners();
    }
  }

  Future<void> init() async {
    try {
      _appInstallDate ??= DateTime.now();
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await _player.setAudioSource(AudioSource.uri(Uri.parse(kStreamUrl)));
      await _player.setVolume(_volume);
      _initialized = true;

      // Points and stats come from Firestore when user is logged in (loaded on HomePage)

      // Start metadata service and listen for updates
      _metadataService.start();
      _metadataService.metadataStream?.listen(_updateCurrentSong);

      // Get initial metadata
      updateSong();
      _checkMilestoneAchievements();

      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Error initializing audio player: $e');
      // Still mark as initialized so the UI can continue to work
      _initialized = true;

      // Start metadata service even if audio fails
      _metadataService.start();
      _metadataService.metadataStream?.listen(_updateCurrentSong);
      updateSong();
      _checkMilestoneAchievements();

      notifyListeners();
    }
  }

  Future<void> play() async {
    try {
      final now = DateTime.now();

      _sessionStartTime = now;
      _continuousSessionStart = now;
      _qualitySessionStart = now;

      // Track fast start for speed_start achievement (play within 5 seconds of app start or last stop)
      if (_lastStopTime != null) {
        final timeSinceLastStop = now.difference(_lastStopTime!).inSeconds;
        if (timeSinceLastStop <= 5) {
          trackFastStart();
        }
      } else {
        // First play after app start - could be considered fast start
        // Track it if app was just initialized
        trackFastStart();
      }

      // Track first listen achievement
      if (!_hasPlayedBefore) {
        _hasPlayedBefore = true;
        _awardBadge('first_listen');
      }

      // Track time-based achievements
      _checkTimeBasedAchievements(now);

      // Track consecutive days
      _updateConsecutiveDays(now);

      await _player.play();

      // Track successful play for "first playing" achievement
      if (!_hasPlayedSuccessfully) {
        _hasPlayedSuccessfully = true;
        _awardBadge('first_playing');
      }

      // Start timer to update session duration every second for UI
      _sessionTimer?.cancel();
      _sessionTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => notifyListeners(),
      );

      // Check technical achievements periodically
      _startTechnicalTracking();

      updateSong(); // Update song when starting to play
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('Error playing audio: $e');
      // Reset session start time if play failed
      _sessionTimer?.cancel();
      _sessionTimer = null;
      _sessionStartTime = null;
      _continuousSessionStart = null;
      _qualitySessionStart = null;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    _trackSessionEnd();
    await _player.pause();
  }

  Future<void> stop() async {
    _trackSessionEnd();
    await _player.stop();
  }

  void _trackSessionEnd() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    if (_sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);
      final sessionMinutes = sessionDuration.inMinutes;

      _todayListeningSeconds += sessionDuration.inSeconds;
      _totalListeningMinutes += sessionMinutes;
      _sessionCount++;

      // Track continuous listening for stable_connection achievement
      if (_continuousSessionStart != null) {
        final continuousDuration = DateTime.now().difference(
          _continuousSessionStart!,
        );
        final continuousMinutes = continuousDuration.inMinutes;
        if (continuousMinutes >=
            (_allBadges['stable_connection']!['requirement'] as int)) {
          _awardBadge('stable_connection');
        }
      }

      // Track quality listening for quality_listener achievement
      if (_qualitySessionStart != null) {
        final qualityDuration = DateTime.now().difference(
          _qualitySessionStart!,
        );
        final qualityMinutes = qualityDuration.inMinutes;
        if (qualityMinutes >=
            (_allBadges['quality_listener']!['requirement'] as int)) {
          _awardBadge('quality_listener');
        }
      }

      // Track longest session
      if (sessionMinutes > _longestSessionDuration) {
        _longestSessionDuration = sessionMinutes;
      }

      // Add this session's points to cumulative listening points (persisted in Firestore)
      _listeningPoints += (sessionMinutes * 1.67).round();

      // Check achievements based on session duration
      _checkSessionAchievements(sessionMinutes);
      _checkDailyListeningAchievements();
      _checkTotalListeningAchievements();
      _checkSessionCountAchievements();

      _lastStopTime = DateTime.now();
      _sessionStartTime = null;
      _continuousSessionStart = null;
      _qualitySessionStart = null;
      onProgressChanged?.call();
      unawaited(_syncProgressToFirestore());
      notifyListeners();
    }
  }

  void _startTechnicalTracking() {
    // This would be called periodically during playback to check connection stability
    // For now, we track it when session ends
  }

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Duration? get position => _player.position;
  bool get playing => _player.playing;

  /// Current session listening duration (updates every second while playing).
  Duration get currentSessionDuration {
    if (_sessionStartTime == null) return Duration.zero;
    return DateTime.now().difference(_sessionStartTime!);
  }

  // Feniks Points management methods
  void addMessagePoints() {
    _messagesSent++;
    notifyListeners();
  }

  void _addBadgePoints(int points) {
    _badgePoints += points;
    notifyListeners();
  }

  // Achievement checking methods (removed duplicate method)

  void _checkTimeBasedAchievements(DateTime now) {
    final hour = now.hour;
    final weekday = now.weekday;

    // Early bird (5AM - 8AM)
    if (hour >= 5 && hour < 8) {
      _earlyBirdSessions++;
      if (_earlyBirdSessions >=
          (_allBadges['early_bird']!['requirement'] as int)) {
        _awardBadge('early_bird');
      }
    }

    // Morning person (6AM - 10AM)
    if (hour >= 6 && hour < 10) {
      _morningListens++;
      if (_morningListens >=
          (_allBadges['morning_person']!['requirement'] as int)) {
        _awardBadge('morning_person');
      }
    }

    // Afternoon listener (12PM - 6PM)
    if (hour >= 12 && hour < 18) {
      _afternoonListens++;
      if (_afternoonListens >=
          (_allBadges['afternoon_listener']!['requirement'] as int)) {
        _awardBadge('afternoon_listener');
      }
    }

    // Evening enthusiast (6PM - 10PM)
    if (hour >= 18 && hour < 22) {
      _eveningListens++;
      if (_eveningListens >=
          (_allBadges['evening_enthusiast']!['requirement'] as int)) {
        _awardBadge('evening_enthusiast');
      }
    }

    // Night owl (10PM - 2AM)
    if (hour >= 22 || hour < 2) {
      _nightOwlSessions++;
      if (_nightOwlSessions >=
          (_allBadges['night_owl']!['requirement'] as int)) {
        _awardBadge('night_owl');
      }
    }

    // Midnight listener (12AM - 2AM)
    if (hour >= 0 && hour < 2) {
      _midnightSessions++;
      if (_midnightSessions >=
          (_allBadges['midnight_listener']!['requirement'] as int)) {
        _awardBadge('midnight_listener');
      }
    }

    // Weekend warrior (Saturday and Sunday) - track unique weekend days
    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      final dateKey = '${now.year}-${now.month}-${now.day}';
      if (_weekendDaysVisited.add(dateKey)) {
        if (_weekendDaysVisited.length >=
            (_allBadges['weekend_warrior']!['requirement'] as int)) {
          _awardBadge('weekend_warrior');
        }
      }
    }

    // Workday warrior (Monday - Friday) - track unique weekdays
    if (weekday >= DateTime.monday && weekday <= DateTime.friday) {
      final dateKey = '${now.year}-${now.month}-${now.day}';
      if (_weekdayDaysVisited.add(dateKey)) {
        if (_weekdayDaysVisited.length >=
            (_allBadges['workday_warrior']!['requirement'] as int)) {
          _awardBadge('workday_warrior');
        }
      }
    }
  }

  void _updateConsecutiveDays(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    if (_lastListeningDate == null) {
      // First time listening
      _consecutiveDays = 1;
      _lastListeningDate = today;
    } else {
      final lastDate = DateTime(
        _lastListeningDate!.year,
        _lastListeningDate!.month,
        _lastListeningDate!.day,
      );
      final daysDifference = today.difference(lastDate).inDays;

      if (daysDifference == 1) {
        // Consecutive day
        _consecutiveDays++;
        _lastListeningDate = today;
      } else if (daysDifference > 1) {
        // Streak broken
        _consecutiveDays = 1;
        _lastListeningDate = today;
      }
      // If daysDifference == 0, it's the same day, don't change streak
    }

    // Check streak achievements
    _checkStreakAchievements();
  }

  void _checkStreakAchievements() {
    final streakAchievements = [
      'daily_listener',
      'weekly_champion',
      'loyal_fan',
      'legend',
    ];

    for (final achievementId in streakAchievements) {
      final requirement = _allBadges[achievementId]!['requirement'] as int;
      if (_consecutiveDays >= requirement) {
        _awardBadge(achievementId);
      }
    }
  }

  void _checkSessionAchievements(int sessionMinutes) {
    // Continuous listening achievements
    if (sessionMinutes >=
        (_allBadges['ultra_marathon']!['requirement'] as int)) {
      _awardBadge('ultra_marathon');
    }
  }

  void _checkDailyListeningAchievements() {
    final todayMinutes = _todayListeningSeconds ~/ 60;

    // Daily listening achievements
    if (todayMinutes >= (_allBadges['first_hour']!['requirement'] as int)) {
      _awardBadge('first_hour');
    }

    if (todayMinutes >= (_allBadges['marathon']!['requirement'] as int)) {
      _awardBadge('marathon');
    }

    if (todayMinutes >= (_allBadges['five_hours']!['requirement'] as int)) {
      _awardBadge('five_hours');
    }
  }

  void _checkMusicAchievements() {
    final favoriteCount = _favoriteSongs.length;

    // Music-related achievements
    if (favoriteCount >= (_allBadges['music_lover']!['requirement'] as int)) {
      _awardBadge('music_lover');
    }

    if (favoriteCount >=
        (_allBadges['music_collector']!['requirement'] as int)) {
      _awardBadge('music_collector');
    }

    if (favoriteCount >= (_allBadges['music_expert']!['requirement'] as int)) {
      _awardBadge('music_expert');
    }

    if (favoriteCount >= (_allBadges['music_master']!['requirement'] as int)) {
      _awardBadge('music_master');
    }
  }

  // Method to track page visits for app explorer achievement
  void trackPageVisit(String pageName) {
    if (!_visitedPages.contains(pageName)) {
      _visitedPages.add(pageName);
      _pagesVisited = _visitedPages.length;

      if (_pagesVisited >=
          (_allBadges['app_explorer']!['requirement'] as int)) {
        _awardBadge('app_explorer');
      }
      onProgressChanged?.call();
      unawaited(_syncProgressToFirestore());
    }
  }

  Future<void> _syncProgressToFirestore() async {
    if (_syncInProgress) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _syncInProgress = true;
    try {
      await FirestoreService.instance.saveUserAchievements(
        user.uid,
        getAchievementData(),
      );
      await FirestoreService.instance.updateLeaderboardEntry(
        user.uid,
        user.displayName ?? 'Anonim',
        totalFeniksPoints,
        earnedBadges.length,
      );
    } catch (_) {
      // Keep app stable if Firestore rules are strict.
    } finally {
      _syncInProgress = false;
    }
  }

  // Track sharing for social achievements
  void trackShare() {
    _sharesCount++;
  }

  // Track fast starts for Brzinski Start achievement
  void trackFastStart() {
    _fastStartCount++;
    if (_fastStartCount >= (_allBadges['speed_start']!['requirement'] as int)) {
      _awardBadge('speed_start');
    }
  }

  // New achievement checking methods
  void _checkTotalListeningAchievements() {
    if (_totalListeningMinutes >=
        (_allBadges['ten_hours']!['requirement'] as int)) {
      _awardBadge('ten_hours');
    }
    if (_totalListeningMinutes >=
        (_allBadges['fifty_hours']!['requirement'] as int)) {
      _awardBadge('fifty_hours');
    }
    if (_totalListeningMinutes >=
        (_allBadges['hundred_hours']!['requirement'] as int)) {
      _awardBadge('hundred_hours');
    }
  }

  void _checkSessionCountAchievements() {
    if (_sessionCount >= (_allBadges['ten_sessions']!['requirement'] as int)) {
      _awardBadge('ten_sessions');
    }
    if (_sessionCount >=
        (_allBadges['fifty_sessions']!['requirement'] as int)) {
      _awardBadge('fifty_sessions');
    }
    if (_sessionCount >=
        (_allBadges['hundred_sessions']!['requirement'] as int)) {
      _awardBadge('hundred_sessions');
    }
  }

  // Methods to track new song discovery
  void trackSongHeard(String songTitle) {
    if (_uniqueSongs.add(songTitle)) {
      if (_uniqueSongs.length >=
          (_allBadges['song_discoverer']!['requirement'] as int)) {
        _awardBadge('song_discoverer');
      }
    }
  }

  void trackMusicGenre(String genre) {
    if (_musicGenres.add(genre)) {
      if (_musicGenres.length >=
          (_allBadges['genre_explorer']!['requirement'] as int)) {
        _awardBadge('genre_explorer');
      }
    }
  }

  // Social tracking methods
  void trackReferral() {
    _referralCount++;
  }

  void markAsCommunityMember() {
    if (!_isCommunityMember) {
      _isCommunityMember = true;
    }
  }

  // Special achievements
  void trackHolidayListening() {}

  void trackBirthdayListening() {}

  void triggerSecretAchievement() {}

  void trackDeveloperMessage() {}

  void trackBetaFeatureUsage() {}

  // Milestone checking
  void _checkMilestoneAchievements() {
    if (_appInstallDate != null) {
      final daysSinceInstall = DateTime.now()
          .difference(_appInstallDate!)
          .inDays;

      if (daysSinceInstall >=
              (_allBadges['first_week']!['requirement'] as int) &&
          !hasBadge('first_week')) {
        _awardBadge('first_week');
      }
      if (daysSinceInstall >=
              (_allBadges['first_month']!['requirement'] as int) &&
          !hasBadge('first_month')) {
        _awardBadge('first_month');
      }
      if (daysSinceInstall >=
              (_allBadges['loyal_user']!['requirement'] as int) &&
          !hasBadge('loyal_user')) {
        _awardBadge('loyal_user');
      }
    }
  }

  // Competitive achievement methods (these would typically be called from leaderboard service)
  // In-memory storage methods (temporary solution)
  void _saveProgress() {
    // For now, just keep everything in memory
    // This will reset when app restarts, but achievements will still work during session
    if (kDebugMode)
      debugPrint(
        'Achievement progress saved in memory (SharedPreferences not available)',
      );
  }

  void _saveSettings() {
    // For now, settings are in memory only
    if (kDebugMode) debugPrint('Settings saved in memory');
  }

  void _updateAudioQuality() {
    // Update audio stream URL based on quality setting
    if (_initialized) {
      final url = _highQuality
          ? 'https://c30.radioboss.fm:8234/autodj' // High quality stream
          : 'https://c30.radioboss.fm:8234/repetitor'; // Lower quality stream
      _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
    }
  }

  void _loadProgress() {
    // Set default values for first-time users
    // Only set install date if it hasn't been set before (persist this in SharedPreferences in production)
    _appInstallDate ??= DateTime.now();

    // Reset flags for testing
    _hasPlayedBefore = false;
    _hasPlayedSuccessfully = false;

    // Initialize empty achievement data

    notifyListeners();
  }

  // Call this when the app starts
  Future<void> initialize() async {
    if (_initialized) return;

    _loadProgress();

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    await _player.setAudioSource(AudioSource.uri(Uri.parse(kStreamUrl)));

    _metadataService.start();
    _metadataService.metadataStream?.listen((metadata) {
      final rawTitle = metadata['title'] ?? 'Feniks Radio';
      final rawArtist = metadata['artist'] ?? 'Samo dobre vijesti!';
      _currentSong = _formatSongTitle(rawTitle);
      _currentArtist = _formatArtistName(rawArtist);

      // Track unique songs for discovery achievements
      if (_currentSong != 'Feniks Radio') {
        trackSongHeard(_currentSong);
      }

      notifyListeners();
    });

    // Check milestone achievements after loading progress
    _checkMilestoneAchievements();

    _initialized = true;
    notifyListeners();
  }

  /// Returns a map of all achievement-related data for Firestore persistence.
  Map<String, dynamic> getAchievementData() {
    return {
      'earnedBadges': _earnedBadges
          .map((b) => {'id': b['id'], 'earnedDate': b['earnedDate']})
          .toList(),
      'consecutiveDays': _consecutiveDays,
      'lastListeningDate': _lastListeningDate?.toIso8601String(),
      'totalListeningMinutes': _totalListeningMinutes,
      'sessionCount': _sessionCount,
      'favoriteSongs': List<String>.from(_favoriteSongs),
      'earlyBirdSessions': _earlyBirdSessions,
      'nightOwlSessions': _nightOwlSessions,
      'midnightSessions': _midnightSessions,
      'morningListens': _morningListens,
      'afternoonListens': _afternoonListens,
      'eveningListens': _eveningListens,
      'weekendDaysVisited': _weekendDaysVisited.toList(),
      'weekdayDaysVisited': _weekdayDaysVisited.toList(),
      'uniqueSongs': _uniqueSongs.toList(),
      'musicGenres': _musicGenres.toList(),
      'pagesVisited': _pagesVisited,
      'visitedPages': List<String>.from(_visitedPages),
      'sharesCount': _sharesCount,
      'fastStartCount': _fastStartCount,
      'hasPlayedBefore': _hasPlayedBefore,
      'hasPlayedSuccessfully': _hasPlayedSuccessfully,
      'appInstallDate': _appInstallDate?.toIso8601String(),
      'referralCount': _referralCount,
      'isCommunityMember': _isCommunityMember,
      'top10Weeks': _top10Weeks,
      'badgePoints': _badgePoints,
      'messagesSent': _messagesSent,
      'listeningPoints': _listeningPoints,
      'todayListeningSeconds': _todayListeningSeconds,
      'dateForTodayListening': DateTime.now()
          .toIso8601String()
          .split('T')
          .first,
      'longestSessionDuration': _longestSessionDuration,
    };
  }

  /// Restores achievement state from Firestore data.
  void loadAchievementData(Map<String, dynamic>? data) {
    if (data == null) return;
    final badges = data['earnedBadges'] as List<dynamic>?;
    if (badges != null) {
      _earnedBadges.clear();
      for (final b in badges) {
        final map = Map<String, dynamic>.from(b as Map);
        final id = map['id'] as String?;
        // Migrate old badge id to new (e.g. speed_demon -> speed_start)
        final resolvedId = id == 'speed_demon' ? 'speed_start' : id;
        if (resolvedId != null && _allBadges.containsKey(resolvedId)) {
          final full = Map<String, dynamic>.from(_allBadges[resolvedId]!);
          full['earnedDate'] =
              map['earnedDate'] ?? DateTime.now().toIso8601String();
          _earnedBadges.add(full);
        }
      }
    }
    _consecutiveDays = data['consecutiveDays'] as int? ?? 0;
    final last = data['lastListeningDate'] as String?;
    _lastListeningDate = last != null ? DateTime.tryParse(last) : null;
    _totalListeningMinutes = data['totalListeningMinutes'] as int? ?? 0;
    _sessionCount = data['sessionCount'] as int? ?? 0;
    final fav = data['favoriteSongs'] as List<dynamic>?;
    if (fav != null) {
      _favoriteSongs.clear();
      _favoriteSongs.addAll(fav.cast<String>());
    }
    _earlyBirdSessions = data['earlyBirdSessions'] as int? ?? 0;
    _nightOwlSessions = data['nightOwlSessions'] as int? ?? 0;
    _midnightSessions = data['midnightSessions'] as int? ?? 0;
    _morningListens = data['morningListens'] as int? ?? 0;
    _afternoonListens = data['afternoonListens'] as int? ?? 0;
    _eveningListens = data['eveningListens'] as int? ?? 0;
    final wkd = data['weekendDaysVisited'] as List<dynamic>?;
    if (wkd != null) {
      _weekendDaysVisited.clear();
      _weekendDaysVisited.addAll(wkd.cast<String>());
    }
    final wkdd = data['weekdayDaysVisited'] as List<dynamic>?;
    if (wkdd != null) {
      _weekdayDaysVisited.clear();
      _weekdayDaysVisited.addAll(wkdd.cast<String>());
    }
    final songs = data['uniqueSongs'] as List<dynamic>?;
    if (songs != null) {
      _uniqueSongs.clear();
      _uniqueSongs.addAll(songs.cast<String>());
    }
    final genres = data['musicGenres'] as List<dynamic>?;
    if (genres != null) {
      _musicGenres.clear();
      _musicGenres.addAll(genres.cast<String>());
    }
    _pagesVisited = data['pagesVisited'] as int? ?? 0;
    final vp = data['visitedPages'] as List<dynamic>?;
    if (vp != null) {
      _visitedPages.clear();
      _visitedPages.addAll(vp.cast<String>());
    }
    _sharesCount = data['sharesCount'] as int? ?? 0;
    _fastStartCount = data['fastStartCount'] as int? ?? 0;
    _hasPlayedBefore = data['hasPlayedBefore'] as bool? ?? false;
    _hasPlayedSuccessfully = data['hasPlayedSuccessfully'] as bool? ?? false;
    final install = data['appInstallDate'] as String?;
    _appInstallDate = install != null ? DateTime.tryParse(install) : null;
    _referralCount = data['referralCount'] as int? ?? 0;
    _isCommunityMember = data['isCommunityMember'] as bool? ?? false;
    _top10Weeks = data['top10Weeks'] as int? ?? 0;
    _badgePoints = data['badgePoints'] as int? ?? 0;
    _messagesSent = data['messagesSent'] as int? ?? 0;
    _listeningPoints = data['listeningPoints'] as int? ?? 0;
    final dateForToday = data['dateForTodayListening'] as String?;
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    if (dateForToday == todayStr) {
      _todayListeningSeconds = data['todayListeningSeconds'] as int? ?? 0;
    } else {
      _todayListeningSeconds = 0;
    }
    _longestSessionDuration = data['longestSessionDuration'] as int? ?? 0;
    _checkMilestoneAchievements();
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _saveProgress(); // Save progress before disposing
    _metadataService.stop();
    _player.dispose();
    super.dispose();
  }
}
