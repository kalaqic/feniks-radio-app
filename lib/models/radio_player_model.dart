import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../services/metadata_service.dart';

const kStreamUrl = 'https://c30.radioboss.fm:8234/stream';

class RadioPlayerModel extends ChangeNotifier {
  final _player = AudioPlayer();
  final _metadataService = MetadataService();
  bool _initialized = false;
  bool get isInitialized => _initialized;
  
  DateTime? _sessionStartTime;
  DateTime? _currentSessionStart;
  int _todayListeningSeconds = 0;
  int _currentSessionDuration = 0;
  int _longestSessionDuration = 0;
  
  final Map<String, int> _weeklyListeningData = {
    'Mon': 45,
    'Tue': 32,
    'Wed': 28,
    'Thu': 67,
    'Fri': 41,
    'Sat': 23,
    'Sun': 55,
  };
  
  bool _hasShownCelebrationToday = false;
  int _consecutiveDays = 0;
  bool _hasShownAchievementModal = false;
  
  // Badge system
  final List<Map<String, dynamic>> _earnedBadges = [];
  final List<String> _pendingBadges = []; // Badges earned but not shown yet
  
  // Achievement tracking
  final Map<String, int> _achievementProgress = {};
  DateTime? _lastListeningDate;
  int _earlyBirdSessions = 0;
  int _nightOwlSessions = 0;
  int _midnightSessions = 0;
  int _weekendSessions = 0;
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
  int _weekdayListens = 0;
  int _referralCount = 0;
  bool _isCommunityMember = false;
  
  // Feniks Points System
  int _messagesSent = 0;
  int _listeningPoints = 0;
  int _badgePoints = 0;
  
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
    'social_butterfly': {
      'id': 'social_butterfly',
      'name': 'Društveni Leptir',
      'description': 'Podijeli 5 pjesama iz omiljenih',
      'icon': '🦋',
      'color': 0xFFFF9500,
      'requirement': 5, // shares
      'points': 150,
      'type': 'special',
    },
    'speed_demon': {
      'id': 'speed_demon',
      'name': 'Brzinski Demon',
      'description': 'Pokreni radio u manje od 5 sekundi',
      'icon': '💨',
      'color': 0xFFFF3B30,
      'requirement': 10, // times
      'points': 200,
      'type': 'special',
    },
    
    // Competitive achievements
    'top_monthly': {
      'id': 'top_monthly',
      'name': 'Mjesečni Prvak',
      'description': 'Završi prvi na mjesečnoj ljestvici',
      'icon': '🏆',
      'color': 0xFFFFD700,
      'requirement': 1, // rank position
      'points': 500,
      'type': 'competitive',
    },
    'top_weekly': {
      'id': 'top_weekly',
      'name': 'Sedmični Prvak',
      'description': 'Završi prvi na sedmičnoj ljestvici',
      'icon': '🥇',
      'color': 0xFF32D74B,
      'requirement': 1, // rank position
      'points': 200,
      'type': 'competitive',
    },
    'consistent_top10': {
      'id': 'consistent_top10',
      'name': 'Konzistentan Top 10',
      'description': 'Ostani u top 10 četiri sedmice zaredom',
      'icon': '📊',
      'color': 0xFF5856D6,
      'requirement': 4, // weeks
      'points': 400,
      'type': 'competitive',
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
    
    // Social achievements
    'friend_referral': {
      'id': 'friend_referral',
      'name': 'Preporuči Prijatelju',
      'description': 'Podijeli aplikaciju sa prijateljem',
      'icon': '👫',
      'color': 0xFF34C759,
      'requirement': 1, // referrals
      'points': 200,
      'type': 'special',
    },
    'community_member': {
      'id': 'community_member',
      'name': 'Član Zajednice',
      'description': 'Budi aktivan član Feniks zajednice',
      'icon': '🤝',
      'color': 0xFF007AFF,
      'requirement': 1, // community actions
      'points': 250,
      'type': 'special',
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
    'holiday_listener': {
      'id': 'holiday_listener',
      'name': 'Praznični Slušalac',
      'description': 'Slušaj radio na praznik',
      'icon': '🎄',
      'color': 0xFFFF3B30,
      'requirement': 1, // holidays
      'points': 150,
      'type': 'special',
    },
    'birthday_celebration': {
      'id': 'birthday_celebration',
      'name': 'Rođendanska Proslava',
      'description': 'Slušaj radio na svoj rođendan',
      'icon': '🎂',
      'color': 0xFFFF9500,
      'requirement': 1, // birthdays
      'points': 300,
      'type': 'special',
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
    
    // Hidden/Easter egg achievements
    'secret_listener': {
      'id': 'secret_listener',
      'name': 'Tajni Slušalac',
      'description': 'Otkrij skrivenu funkciju aplikacije',
      'icon': '🕵️',
      'color': 0xFF8B5CF6,
      'requirement': 1, // secret action
      'points': 500,
      'type': 'hidden',
    },
    'developer_fan': {
      'id': 'developer_fan',
      'name': 'Fan Developera',
      'description': 'Pošalji poruku developerima',
      'icon': '💻',
      'color': 0xFF32D74B,
      'requirement': 1, // developer message
      'points': 200,
      'type': 'hidden',
    },
    'beta_tester': {
      'id': 'beta_tester',
      'name': 'Beta Tester',
      'description': 'Testiraj novu funkciju prije ostalih',
      'icon': '🧪',
      'color': 0xFFFF9500,
      'requirement': 1, // beta features used
      'points': 300,
      'type': 'hidden',
    },
  };
  
  String _currentSong = 'Feniks Radio';
  String _currentArtist = 'Uživo prijenos';
  final List<String> _favoriteSongs = [];
  

  int get todayListeningMinutes => (_todayListeningSeconds / 60).round();
  Map<String, int> get weeklyListeningData => _weeklyListeningData;
  bool get shouldShowCelebration => !_hasShownCelebrationToday;
  int get consecutiveDays => _consecutiveDays;
  bool get shouldShowAchievementModal => !_hasShownAchievementModal;
  
  // Badge system getters
  List<Map<String, dynamic>> get earnedBadges => List.unmodifiable(_earnedBadges);
  List<String> get pendingBadges => List.unmodifiable(_pendingBadges);
  Map<String, Map<String, dynamic>> get allBadges => _allBadges;
  bool get hasPendingBadges => _pendingBadges.isNotEmpty;
  
  // Achievement popup callback
  void Function(Map<String, dynamic>)? onAchievementEarned;
  
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
  int get totalFeniksPoints => _listeningPoints + (_messagesSent * 10) + _badgePoints;
  
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
    notifyListeners();
  }

  void removeFavorite(String song) {
    _favoriteSongs.remove(song);
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
  
  void updateSong() {
    _metadataService.getCurrentMetadata().then(_updateCurrentSong);
  }
  
  void _updateCurrentSong(Map<String, String> metadata) {
    print('DEBUG: Received metadata: $metadata');
    if (metadata.isNotEmpty) {
      final newSong = metadata['title'] ?? 'Feniks Radio';
      final newArtist = metadata['artist'] ?? 'Uživo prijenos';
      
      print('DEBUG: Updating song from "$_currentSong" to "$newSong"');
      print('DEBUG: Updating artist from "$_currentArtist" to "$newArtist"');
      
      _currentSong = newSong;
      _currentArtist = newArtist;
      notifyListeners();
    } else {
      print('DEBUG: Empty metadata received');
    }
  }

  Future<void> init() async {
    try {
      final session = await AudioSession.instance; 
      await session.configure(const AudioSessionConfiguration.music());
      await _player.setAudioSource(AudioSource.uri(Uri.parse(kStreamUrl)));
      await _player.setVolume(_volume);
      _initialized = true;
      
      // Mock today's listening time (in minutes for testing)
      _todayListeningSeconds = 38 * 60; // 38 minutes
      
      // Mock Feniks Points data for testing
      _messagesSent = 12; // 12 messages = 120 points
      _badgePoints = 200; // Some earned badges
      _updateListeningPoints(); // Calculate listening points
      
      // Start metadata service and listen for updates
      _metadataService.start();
      _metadataService.metadataStream?.listen(_updateCurrentSong);
      
      // Get initial metadata
      updateSong();
      
      notifyListeners();
    } catch (e) {
      print('Error initializing audio player: $e');
      // Still mark as initialized so the UI can continue to work
      _initialized = true;
      
      // Start metadata service even if audio fails
      _metadataService.start();
      _metadataService.metadataStream?.listen(_updateCurrentSong);
      updateSong();
      
      notifyListeners();
    }
  }

  Future<void> play() async {
    try {
      print('DEBUG: Play button pressed, starting playback');
      final now = DateTime.now();
      _sessionStartTime = now;
      _currentSessionStart = now;
      
      // Track first listen achievement
      if (!_hasPlayedBefore) {
        print('DEBUG: First time playing, awarding first_listen achievement');
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
        print('DEBUG: First successful play, awarding first_playing achievement');
        _hasPlayedSuccessfully = true;
        _awardBadge('first_playing');
      }
      
      updateSong(); // Update song when starting to play
      notifyListeners();
    } catch (e) {
      print('Error playing audio: $e');
      // Reset session start time if play failed
      _sessionStartTime = null;
      _currentSessionStart = null;
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
    if (_sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);
      final sessionMinutes = sessionDuration.inMinutes;
      
      _todayListeningSeconds += sessionDuration.inSeconds;
      _currentSessionDuration = sessionMinutes;
      _totalListeningMinutes += sessionMinutes;
      _sessionCount++;
      
      // Track longest session
      if (sessionMinutes > _longestSessionDuration) {
        _longestSessionDuration = sessionMinutes;
      }
      
      _updateListeningPoints(); // Update Feniks Points
      
      // Check achievements based on session duration
      _checkSessionAchievements(sessionMinutes);
      _checkDailyListeningAchievements();
      _checkTotalListeningAchievements();
      _checkSessionCountAchievements();
      
      _sessionStartTime = null;
      _currentSessionStart = null;
      notifyListeners();
    }
  }
  
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Duration? get position => _player.position;
  bool get playing => _player.playing;
  
  // Feniks Points management methods
  void addMessagePoints() {
    _messagesSent++;
    notifyListeners();
  }
  
  void _updateListeningPoints() {
    // Calculate points: 100 points per hour (1.67 points per minute)
    _listeningPoints = ((_todayListeningSeconds / 60) * 1.67).round();
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
      if (_earlyBirdSessions >= (_allBadges['early_bird']!['requirement'] as int)) {
        _awardBadge('early_bird');
      }
    }
    
    // Morning person (6AM - 10AM)
    if (hour >= 6 && hour < 10) {
      _morningListens++;
      if (_morningListens >= (_allBadges['morning_person']!['requirement'] as int)) {
        _awardBadge('morning_person');
      }
    }
    
    // Afternoon listener (12PM - 6PM)
    if (hour >= 12 && hour < 18) {
      _afternoonListens++;
      if (_afternoonListens >= (_allBadges['afternoon_listener']!['requirement'] as int)) {
        _awardBadge('afternoon_listener');
      }
    }
    
    // Evening enthusiast (6PM - 10PM)
    if (hour >= 18 && hour < 22) {
      _eveningListens++;
      if (_eveningListens >= (_allBadges['evening_enthusiast']!['requirement'] as int)) {
        _awardBadge('evening_enthusiast');
      }
    }
    
    // Night owl (10PM - 2AM)
    if (hour >= 22 || hour < 2) {
      _nightOwlSessions++;
      if (_nightOwlSessions >= (_allBadges['night_owl']!['requirement'] as int)) {
        _awardBadge('night_owl');
      }
    }
    
    // Midnight listener (12AM - 2AM)
    if (hour >= 0 && hour < 2) {
      _midnightSessions++;
      if (_midnightSessions >= (_allBadges['midnight_listener']!['requirement'] as int)) {
        _awardBadge('midnight_listener');
      }
    }
    
    // Weekend warrior (Saturday and Sunday)
    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      _weekendSessions++;
      if (_weekendSessions >= (_allBadges['weekend_warrior']!['requirement'] as int)) {
        _awardBadge('weekend_warrior');
      }
    }
    
    // Workday warrior (Monday - Friday)
    if (weekday >= DateTime.monday && weekday <= DateTime.friday) {
      _weekdayListens++;
      if (_weekdayListens >= (_allBadges['workday_warrior']!['requirement'] as int)) {
        _awardBadge('workday_warrior');
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
      final lastDate = DateTime(_lastListeningDate!.year, _lastListeningDate!.month, _lastListeningDate!.day);
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
    final streakAchievements = ['daily_listener', 'weekly_champion', 'loyal_fan', 'legend'];
    
    for (final achievementId in streakAchievements) {
      final requirement = _allBadges[achievementId]!['requirement'] as int;
      if (_consecutiveDays >= requirement) {
        _awardBadge(achievementId);
      }
    }
  }

  void _checkSessionAchievements(int sessionMinutes) {
    // Continuous listening achievements
    if (sessionMinutes >= (_allBadges['ultra_marathon']!['requirement'] as int)) {
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
    
    if (favoriteCount >= (_allBadges['music_collector']!['requirement'] as int)) {
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
      
      if (_pagesVisited >= (_allBadges['app_explorer']!['requirement'] as int)) {
        _awardBadge('app_explorer');
      }
    }
  }

  // Track sharing for social achievements
  void trackShare() {
    _sharesCount++;
    if (_sharesCount >= (_allBadges['social_butterfly']!['requirement'] as int)) {
      _awardBadge('social_butterfly');
    }
  }

  // Track fast starts for speed demon achievement
  void trackFastStart() {
    _fastStartCount++;
    if (_fastStartCount >= (_allBadges['speed_demon']!['requirement'] as int)) {
      _awardBadge('speed_demon');
    }
  }

  // New achievement checking methods
  void _checkTotalListeningAchievements() {
    if (_totalListeningMinutes >= (_allBadges['ten_hours']!['requirement'] as int)) {
      _awardBadge('ten_hours');
    }
    if (_totalListeningMinutes >= (_allBadges['fifty_hours']!['requirement'] as int)) {
      _awardBadge('fifty_hours');
    }
    if (_totalListeningMinutes >= (_allBadges['hundred_hours']!['requirement'] as int)) {
      _awardBadge('hundred_hours');
    }
  }

  void _checkSessionCountAchievements() {
    if (_sessionCount >= (_allBadges['ten_sessions']!['requirement'] as int)) {
      _awardBadge('ten_sessions');
    }
    if (_sessionCount >= (_allBadges['fifty_sessions']!['requirement'] as int)) {
      _awardBadge('fifty_sessions');
    }
    if (_sessionCount >= (_allBadges['hundred_sessions']!['requirement'] as int)) {
      _awardBadge('hundred_sessions');
    }
  }

  // Methods to track new song discovery
  void trackSongHeard(String songTitle) {
    if (_uniqueSongs.add(songTitle)) {
      if (_uniqueSongs.length >= (_allBadges['song_discoverer']!['requirement'] as int)) {
        _awardBadge('song_discoverer');
      }
    }
  }

  void trackMusicGenre(String genre) {
    if (_musicGenres.add(genre)) {
      if (_musicGenres.length >= (_allBadges['genre_explorer']!['requirement'] as int)) {
        _awardBadge('genre_explorer');
      }
    }
  }

  // Social tracking methods
  void trackReferral() {
    _referralCount++;
    if (_referralCount >= (_allBadges['friend_referral']!['requirement'] as int)) {
      _awardBadge('friend_referral');
    }
  }

  void markAsCommunityMember() {
    if (!_isCommunityMember) {
      _isCommunityMember = true;
      _awardBadge('community_member');
    }
  }

  // Special achievements
  void trackHolidayListening() {
    _awardBadge('holiday_listener');
  }

  void trackBirthdayListening() {
    _awardBadge('birthday_celebration');
  }

  void triggerSecretAchievement() {
    _awardBadge('secret_listener');
  }
  
  // Debug method to manually trigger an achievement for testing
  void debugTriggerAchievement(String achievementId) {
    print('DEBUG: Manually triggering achievement: $achievementId');
    _awardBadge(achievementId);
  }

  void trackDeveloperMessage() {
    _awardBadge('developer_fan');
  }

  void trackBetaFeatureUsage() {
    _awardBadge('beta_tester');
  }

  // Milestone checking
  void _checkMilestoneAchievements() {
    if (_appInstallDate != null) {
      final daysSinceInstall = DateTime.now().difference(_appInstallDate!).inDays;
      
      if (daysSinceInstall >= (_allBadges['first_week']!['requirement'] as int)) {
        _awardBadge('first_week');
      }
      if (daysSinceInstall >= (_allBadges['first_month']!['requirement'] as int)) {
        _awardBadge('first_month');
      }
      if (daysSinceInstall >= (_allBadges['loyal_user']!['requirement'] as int)) {
        _awardBadge('loyal_user');
      }
    }
  }

  // In-memory storage methods (temporary solution)
  void _saveProgress() {
    // For now, just keep everything in memory
    // This will reset when app restarts, but achievements will still work during session
    print('Achievement progress saved in memory (SharedPreferences not available)');
  }
  
  void _saveSettings() {
    // For now, settings are in memory only
    print('Settings saved in memory');
  }
  
  void _updateAudioQuality() {
    // Update audio stream URL based on quality setting
    if (_initialized) {
      final url = _highQuality 
        ? 'https://c30.radioboss.fm:8234/autodj'  // High quality stream
        : 'https://c30.radioboss.fm:8234/repetitor'; // Lower quality stream
      _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
    }
  }

  void _loadProgress() {
    // Set default values for first-time users
    _appInstallDate = DateTime.now();
    
    // Reset flags for testing
    _hasPlayedBefore = false;
    _hasPlayedSuccessfully = false;
    
    // Initialize empty achievement data
    
    notifyListeners();
  }

  // Reset daily stats (should be called at midnight)
  void _resetDailyStats() {
    _todayListeningSeconds = 0;
    _currentSessionDuration = 0;
    // Don't reset streak or other persistent stats
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
      _currentSong = metadata['title'] ?? 'Feniks Radio';
      _currentArtist = metadata['artist'] ?? 'Uživo prijenos';
      
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


  @override
  void dispose() {
    _saveProgress(); // Save progress before disposing
    _metadataService.stop();
    _player.dispose();
    super.dispose();
  }
}