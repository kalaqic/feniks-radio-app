import 'achievement.dart';
import 'achievements.dart';
import 'progress_rules.dart';

/// Tracks listening time, streaks, favorites and unlocked achievements.
///
/// Pure logic: no audio, network or Flutter widgets. Time comes from [clock]
/// and listening is reported through [tick], so everything can be tested
/// without waiting for real time to pass.
class ListeningProgress {
  ListeningProgress({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _todayKey = _dayKey(_clock());
  }

  final DateTime Function() _clock;

  /// Longest time a single tick may count (protects against a timer that was
  /// suspended while the app was in the background).
  static const int _maxStepMs = 60000;

  /// Called right after an achievement is unlocked.
  void Function(EarnedAchievement earned)? onAchievementEarned;

  /// Called whenever something visible changed.
  void Function()? onChanged;

  /// Called when the progress should be saved.
  void Function()? onSaveRequested;

  // --- Current session (not saved) -----------------------------------------
  DateTime? _lastTick;
  int _msCarry = 0;
  int _secondsTowardsMinute = 0;
  bool _sessionActive = false;
  bool _sessionCounted = false;
  int _sessionSeconds = 0;
  DateTime? _lastSaveRequest;
  final Map<Achievement, int> _slotMinutesToday = {};

  /// True while loading saved data: re-checking old progress must not show
  /// popups for achievements that were earned long ago.
  bool _silent = false;

  // --- Saved progress --------------------------------------------------------
  final List<EarnedAchievement> _earned = [];
  final List<Achievement> _pending = [];

  int _totalSeconds = 0;
  late String _todayKey;
  int _todaySeconds = 0;
  bool _todayCounted = false;

  int _sessionCount = 0;
  int _longestSessionMinutes = 0;

  int _streak = 0;
  DateTime? _lastListeningDay;
  int _listeningDays = 0;

  int _weekendDays = 0;
  String? _workweekKey; // Monday of the week, yyyy-mm-dd
  final Set<int> _workdaysThisWeek = {}; // 1 (Mon) .. 5 (Fri)

  /// Time-of-day achievement id -> distinct days counted / last day counted.
  final Map<String, int> _slotDays = {};
  final Map<String, String> _slotLastDay = {};

  final List<String> _favorites = [];
  final Set<String> _songsHeard = {};
  final List<String> _visitedPages = [];
  bool _hasPlayedBefore = false;

  // ===========================================================================
  // Read access
  // ===========================================================================

  int get todaySeconds => _todaySeconds;
  int get todayMinutes => _todaySeconds ~/ 60;
  int get totalMinutes => _totalSeconds ~/ 60;
  int get sessionCount => _sessionCount;
  int get listeningDays => _listeningDays;
  Duration get currentSession => Duration(seconds: _sessionSeconds);
  bool get isSessionActive => _sessionActive;

  /// Current streak; 0 when the last listening day was before yesterday.
  int get streak {
    final last = _lastListeningDay;
    if (last == null) return 0;
    return _daysBetween(last, _clock()) <= 1 ? _streak : 0;
  }

  /// Points from listening: [ProgressRules.pointsPerMinute] per full minute.
  int get listeningPoints => totalMinutes * ProgressRules.pointsPerMinute;

  /// Points from unlocked achievements.
  int get achievementPoints =>
      _earned.fold(0, (sum, e) => sum + e.achievement.points);

  int get totalPoints => listeningPoints + achievementPoints;

  List<EarnedAchievement> get earned => List.unmodifiable(_earned);
  List<Achievement> get pending => List.unmodifiable(_pending);
  List<String> get favorites => List.unmodifiable(_favorites);

  bool hasAchievement(Achievement achievement) =>
      _earned.any((e) => e.id == achievement.id);

  bool isFavorite(String song) => _favorites.contains(song);

  // ===========================================================================
  // Listening
  // ===========================================================================

  /// Called about once per second. [listening] is true while audio is really
  /// playing; [playerPlaying] is false once the user or the system stopped it.
  void tick({required bool listening, required bool playerPlaying}) {
    final now = _clock();
    final last = _lastTick ?? now;
    _lastTick = now;
    _rollOverDayIfNeeded(now);

    if (!listening) {
      if (_sessionActive && !playerPlaying) endSession();
      return;
    }

    if (!_sessionActive) {
      // Count from the first tick on, so time before playback never leaks in.
      _startSession();
      _msCarry = 0;
      _changed();
      return;
    }

    // Cap the step so that a suspended timer can never award phantom time.
    var stepMs = now.difference(last).inMilliseconds;
    if (stepMs < 0) stepMs = 0;
    if (stepMs > _maxStepMs) stepMs = _maxStepMs;
    _msCarry += stepMs;
    final seconds = _msCarry ~/ 1000;
    _msCarry -= seconds * 1000;
    if (seconds == 0) return;

    _todaySeconds += seconds;
    _totalSeconds += seconds;
    _sessionSeconds += seconds;
    _secondsTowardsMinute += seconds;
    while (_secondsTowardsMinute >= 60) {
      _secondsTowardsMinute -= 60;
      _onListeningMinute(now);
    }
    _changed();
  }

  /// Ends the current session (pause/stop).
  void endSession() {
    if (!_sessionActive) return;
    _sessionActive = false;
    _updateLongestSession();
    _requestSave();
    _changed();
  }

  void _startSession() {
    _sessionActive = true;
    _sessionCounted = false;
    _sessionSeconds = 0;
    if (!_hasPlayedBefore) {
      _hasPlayedBefore = true;
      _unlock(Achievements.firstListen);
    }
  }

  /// Runs once for every full minute of real listening.
  void _onListeningMinute(DateTime now) {
    if (!_todayCounted &&
        todayMinutes >= ProgressRules.minMinutesForListeningDay) {
      _todayCounted = true;
      _registerListeningDay(now);
    }

    _countTimeSlotMinute(now);

    if (!_sessionCounted &&
        _sessionSeconds >= ProgressRules.minMinutesForSession * 60) {
      _sessionCounted = true;
      _sessionCount++;
      _checkSessions();
    }
    _updateLongestSession();

    _checkDailyListening();
    _checkWithoutPause();
    _checkTotalListening();

    final lastSave = _lastSaveRequest;
    if (lastSave == null ||
        now.difference(lastSave) >= ProgressRules.saveInterval) {
      _requestSave();
    }
  }

  void _countTimeSlotMinute(DateTime now) {
    final slot = Achievements.timeSlotFor(now.hour);
    final today = _dayKey(now);
    if (_slotLastDay[slot.id] == today) return; // already counted today

    final minutes = (_slotMinutesToday[slot] ?? 0) + 1;
    _slotMinutesToday[slot] = minutes;
    if (minutes >= ProgressRules.minMinutesForTimeSlot) {
      _slotLastDay[slot.id] = today;
      _slotDays[slot.id] = (_slotDays[slot.id] ?? 0) + 1;
      _checkTimeSlot(slot);
    }
  }

  void _registerListeningDay(DateTime now) {
    final today = _dateOnly(now);
    final last = _lastListeningDay;
    if (last != null && _daysBetween(last, today) == 0) return;

    _streak = (last != null && _daysBetween(last, today) == 1)
        ? _streak + 1
        : 1;
    _lastListeningDay = today;
    _listeningDays++;

    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      _weekendDays++;
      _checkWeekend();
    } else {
      // Monday of this week, built from date parts (safe across DST changes).
      final monday = _dayKey(
        DateTime(today.year, today.month, today.day - (now.weekday - 1)),
      );
      if (_workweekKey != monday) {
        _workweekKey = monday;
        _workdaysThisWeek.clear();
      }
      _workdaysThisWeek.add(now.weekday);
      _checkWorkweek();
    }

    _checkStreaks();
    _checkListeningDays();
    _requestSave();
  }

  void _rollOverDayIfNeeded(DateTime now) {
    final key = _dayKey(now);
    if (key == _todayKey) return;
    _todayKey = key;
    _todaySeconds = 0;
    _todayCounted = false;
    _slotMinutesToday.clear();
    _changed();
  }

  void _updateLongestSession() {
    final minutes = _sessionSeconds ~/ 60;
    if (minutes > _longestSessionMinutes) _longestSessionMinutes = minutes;
  }

  // ===========================================================================
  // Songs, favorites and pages
  // ===========================================================================

  /// Counts a song for the discovery achievements (only while listening).
  void songHeard(String song) {
    if (!_sessionActive) return;
    if (hasAchievement(Achievements.songHunter)) return; // nothing left
    if (_songsHeard.add(song.toLowerCase())) _checkDiscovery();
  }

  void addFavorite(String song) {
    if (_favorites.contains(song)) return;
    _favorites.add(song);
    _checkFavorites();
    _requestSave();
    _changed();
  }

  void removeFavorite(String song) {
    if (!_favorites.remove(song)) return;
    _requestSave();
    _changed();
  }

  /// Counts a page visit for the "Istraživač Aplikacije" achievement.
  void pageVisited(String route) {
    if (!ProgressRules.explorablePages.contains(route)) return;
    if (_visitedPages.contains(route)) return;
    _visitedPages.add(route);
    _checkExplorer();
    _requestSave();
  }

  // ===========================================================================
  // Achievements
  // ===========================================================================

  /// Unlocks everything the current progress already qualifies for.
  void checkAll() {
    if (_hasPlayedBefore) _unlock(Achievements.firstListen);
    _checkExplorer();
    _checkDailyListening();
    _checkTotalListening();
    _checkSessions();
    _checkStreaks();
    _checkListeningDays();
    for (final (slot, _, _) in Achievements.timeSlots) {
      _checkTimeSlot(slot);
    }
    _checkWeekend();
    _checkWorkweek();
    _checkFavorites();
    _checkDiscovery();
  }

  /// Marks an unlocked achievement as shown to the user.
  void markShown(Achievement achievement) {
    _pending.removeWhere((a) => a.id == achievement.id);
    _changed();
  }

  void _unlock(Achievement achievement) {
    if (hasAchievement(achievement)) return;
    final earned = EarnedAchievement(achievement, _clock());
    _earned.add(earned);
    if (!_silent) {
      _pending.add(achievement);
      onAchievementEarned?.call(earned);
    }
    _requestSave();
    _changed();
  }

  /// Unlocks every achievement in [group] whose requirement is reached.
  void _unlockReached(List<Achievement> group, int progress) {
    for (final achievement in group) {
      if (progress >= achievement.requirement) _unlock(achievement);
    }
  }

  void _checkExplorer() =>
      _unlockReached([Achievements.appExplorer], _visitedPages.length);

  void _checkDailyListening() =>
      _unlockReached(Achievements.dailyListening, todayMinutes);

  void _checkWithoutPause() =>
      _unlockReached(Achievements.withoutPause, _sessionSeconds ~/ 60);

  void _checkTotalListening() =>
      _unlockReached(Achievements.totalListening, totalMinutes);

  void _checkSessions() => _unlockReached(Achievements.sessions, _sessionCount);

  void _checkStreaks() => _unlockReached(Achievements.streaks, _streak);

  void _checkListeningDays() =>
      _unlockReached(Achievements.listeningDays, _listeningDays);

  void _checkTimeSlot(Achievement slot) =>
      _unlockReached([slot], _slotDays[slot.id] ?? 0);

  void _checkWeekend() =>
      _unlockReached([Achievements.weekendWarrior], _weekendDays);

  void _checkWorkweek() =>
      _unlockReached([Achievements.fullWorkweek], _workdaysThisWeek.length);

  void _checkFavorites() =>
      _unlockReached(Achievements.favorites, _favorites.length);

  void _checkDiscovery() =>
      _unlockReached(Achievements.discovery, _songsHeard.length);

  // ===========================================================================
  // Saving, loading, merging
  // ===========================================================================

  /// Data stored in Firestore under `users/{uid}.achievements`.
  /// The keys are kept from older app versions so saved progress still loads.
  Map<String, dynamic> toJson() => {
    'earnedBadges': [
      for (final e in _earned)
        {'id': e.id, 'earnedDate': e.earnedAt.toIso8601String()},
    ],
    'consecutiveDays': _streak,
    'lastListeningDate': _lastListeningDay?.toIso8601String(),
    'totalListeningDays': _listeningDays,
    'totalListeningSeconds': _totalSeconds,
    'totalListeningMinutes': totalMinutes,
    'sessionCount': _sessionCount,
    'longestSessionDuration': _longestSessionMinutes,
    'favoriteSongs': List<String>.of(_favorites),
    'slotDayCounts': Map<String, int>.of(_slotDays),
    'slotLastCountedDay': Map<String, String>.of(_slotLastDay),
    'weekendDaysCount': _weekendDays,
    'workweekKey': _workweekKey,
    'workdaysThisWeek': _workdaysThisWeek.toList(),
    'uniqueSongs': _songsHeard.toList(),
    'visitedPages': List<String>.of(_visitedPages),
    'hasPlayedBefore': _hasPlayedBefore,
    'badgePoints': achievementPoints,
    'listeningPoints': listeningPoints,
    'todayListeningSeconds': _todaySeconds,
    'dateForTodayListening': _todayKey,
    'todayCountedAsListeningDay': _todayCounted,
  };

  /// Replaces the progress with saved data (also reads older formats).
  void loadJson(Map<String, dynamic> data) {
    _earned.clear();
    for (final item in data['earnedBadges'] as List<dynamic>? ?? const []) {
      final map = item as Map;
      final achievement = Achievements.byId(map['id'] as String? ?? '');
      if (achievement == null || hasAchievement(achievement)) continue;
      final earnedAt = DateTime.tryParse(map['earnedDate'] as String? ?? '');
      _earned.add(EarnedAchievement(achievement, earnedAt ?? _clock()));
    }

    _streak = _readInt(data, 'consecutiveDays');
    final lastDay = DateTime.tryParse(
      data['lastListeningDate'] as String? ?? '',
    );
    _lastListeningDay = lastDay == null ? null : _dateOnly(lastDay);
    _totalSeconds =
        _readIntOrNull(data, 'totalListeningSeconds') ??
        _readInt(data, 'totalListeningMinutes') * 60;
    _sessionCount = _readInt(data, 'sessionCount');
    _longestSessionMinutes = _readInt(data, 'longestSessionDuration');
    _listeningDays =
        _readIntOrNull(data, 'totalListeningDays') ?? _streak; // older saves

    _favorites
      ..clear()
      ..addAll(_readStrings(data, 'favoriteSongs'));
    _songsHeard
      ..clear()
      ..addAll(_readStrings(data, 'uniqueSongs').map((s) => s.toLowerCase()));
    _visitedPages
      ..clear()
      ..addAll(
        _readStrings(
          data,
          'visitedPages',
        ).where(ProgressRules.explorablePages.contains),
      );
    _hasPlayedBefore = data['hasPlayedBefore'] as bool? ?? false;

    _slotDays
      ..clear()
      ..addAll(
        _readMap<num>(
          data,
          'slotDayCounts',
        ).map((key, value) => MapEntry(key, value.toInt())),
      );
    _slotLastDay
      ..clear()
      ..addAll(_readMap<String>(data, 'slotLastCountedDay'));

    _weekendDays =
        _readIntOrNull(data, 'weekendDaysCount') ??
        _readStrings(data, 'weekendDaysVisited').length; // older saves
    _workweekKey = data['workweekKey'] as String?;
    _workdaysThisWeek
      ..clear()
      ..addAll(
        (data['workdaysThisWeek'] as List<dynamic>? ?? const [])
            .whereType<num>()
            .map((day) => day.toInt()),
      );

    _todayKey = _dayKey(_clock());
    final savedDay = data['dateForTodayListening'] as String?;
    if (savedDay != null && _normalizeDayKey(savedDay) == _todayKey) {
      _todaySeconds = _readInt(data, 'todayListeningSeconds');
      _todayCounted =
          data['todayCountedAsListeningDay'] as bool? ??
          (_lastListeningDay != null &&
              _daysBetween(_lastListeningDay!, _clock()) == 0);
    } else {
      _todaySeconds = 0;
      _todayCounted = false;
    }

    _pending.clear();
    _silently(checkAll);
    _changed();
  }

  /// Adds progress made before the saved data was loaded (e.g. before
  /// logging in), so that listening time is never lost.
  void mergeUnsaved(ListeningProgress unsaved) {
    _totalSeconds += unsaved._totalSeconds;
    if (unsaved._todayKey == _todayKey) _todaySeconds += unsaved._todaySeconds;
    _sessionCount += unsaved._sessionCount;
    if (unsaved._longestSessionMinutes > _longestSessionMinutes) {
      _longestSessionMinutes = unsaved._longestSessionMinutes;
    }
    _hasPlayedBefore = _hasPlayedBefore || unsaved._hasPlayedBefore;
    for (final page in unsaved._visitedPages) {
      if (!_visitedPages.contains(page)) _visitedPages.add(page);
    }
    _songsHeard.addAll(unsaved._songsHeard);
    _silently(checkAll);
    _changed();
  }

  /// Copy of the saved part of the progress (used before loading over it).
  ListeningProgress snapshot() =>
      ListeningProgress(clock: _clock)..loadJson(toJson());

  /// Clears all progress (logout / account deletion). A running session keeps
  /// running but is not counted as a new session again.
  void reset() {
    _earned.clear();
    _pending.clear();
    _totalSeconds = 0;
    _todayKey = _dayKey(_clock());
    _todaySeconds = 0;
    _todayCounted = false;
    _slotMinutesToday.clear();
    _sessionCount = 0;
    _sessionCounted = _sessionActive;
    _longestSessionMinutes = 0;
    _streak = 0;
    _lastListeningDay = null;
    _listeningDays = 0;
    _weekendDays = 0;
    _workweekKey = null;
    _workdaysThisWeek.clear();
    _slotDays.clear();
    _slotLastDay.clear();
    _favorites.clear();
    _songsHeard.clear();
    _visitedPages.clear();
    _hasPlayedBefore = false;
    _changed();
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  void _silently(void Function() action) {
    _silent = true;
    try {
      action();
    } finally {
      _silent = false;
    }
  }

  void _requestSave() {
    _lastSaveRequest = _clock();
    onSaveRequested?.call();
  }

  void _changed() => onChanged?.call();

  static int _readInt(Map<String, dynamic> data, String key) =>
      _readIntOrNull(data, key) ?? 0;

  static int? _readIntOrNull(Map<String, dynamic> data, String key) =>
      (data[key] as num?)?.toInt();

  static Iterable<String> _readStrings(Map<String, dynamic> data, String key) =>
      (data[key] as List<dynamic>? ?? const []).map((e) => e.toString());

  static Map<String, T> _readMap<T>(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! Map) return {};
    return {
      for (final entry in value.entries)
        if (entry.value is T) entry.key.toString(): entry.value as T,
    };
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Whole calendar days from [from] to [to]. Counted in UTC so that days with
  /// a daylight saving change (23 or 25 hours long) still count as one day.
  static int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Older versions saved days without zero padding (2026-1-5).
  static String _normalizeDayKey(String key) {
    final parts = key.split('-').map(int.tryParse).toList();
    if (parts.length != 3 || parts.contains(null)) return key;
    return _dayKey(DateTime(parts[0]!, parts[1]!, parts[2]!));
  }
}
