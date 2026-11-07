import 'package:flutter/painting.dart' show Color;

import 'achievement.dart';
import 'progress_rules.dart';

const _green = Color(0xFF34C759);
const _brightGreen = Color(0xFF32D74B);
const _blue = Color(0xFF007AFF);
const _orange = Color(0xFFFF9500);
const _indigo = Color(0xFF5856D6);
const _purple = Color(0xFF8B5CF6);
const _red = Color(0xFFFF3B30);
const _gold = Color(0xFFFFD700);
const _brand = Color(0xFFEB6556);

abstract final class Achievements {
  static const firstListen = Achievement(
    id: 'first_listen',
    name: 'Prvi Put',
    description: 'Pokreni Feniks Radio prvi put',
    icon: '🎧',
    color: _green,
    requirement: 1,
    points: 25,
    category: AchievementCategory.firstSteps,
  );
  static const appExplorer = Achievement(
    id: 'app_explorer',
    name: 'Istraživač Aplikacije',
    description:
        'Posjeti sve stranice: Početna, Ljestvica, Značke, Omiljene, Profil i Postavke',
    icon: '🧭',
    color: _blue,
    requirement: 6,
    points: 50,
    category: AchievementCategory.firstSteps,
  );

  static const firstHour = Achievement(
    id: 'first_hour',
    name: 'Prvi Sat',
    description: 'Slušaj 1 sat u jednom danu',
    icon: '⏰',
    color: _green,
    requirement: 60,
    points: 50,
    category: AchievementCategory.dailyListening,
  );
  static const marathon = Achievement(
    id: 'marathon',
    name: 'Maraton',
    description: 'Slušaj 3 sata u jednom danu',
    icon: '🏃',
    color: _orange,
    requirement: 180,
    points: 150,
    category: AchievementCategory.dailyListening,
  );
  static const fiveHours = Achievement(
    id: 'five_hours',
    name: 'Pet Sati',
    description: 'Slušaj 5 sati u jednom danu',
    icon: '🔥',
    color: _indigo,
    requirement: 300,
    points: 250,
    category: AchievementCategory.dailyListening,
  );

  static const halfHourNonStop = Achievement(
    id: 'quality_listener',
    name: 'Pola Sata u Komadu',
    description: 'Slušaj 30 minuta bez pauze',
    icon: '🔊',
    color: _blue,
    requirement: 30,
    points: 50,
    category: AchievementCategory.withoutPause,
  );
  static const twoHoursNonStop = Achievement(
    id: 'stable_connection',
    name: 'Dva Sata Bez Pauze',
    description: 'Slušaj 2 sata bez pauze',
    icon: '📡',
    color: _green,
    requirement: 120,
    points: 150,
    category: AchievementCategory.withoutPause,
  );
  static const ultraMarathon = Achievement(
    id: 'ultra_marathon',
    name: 'Ultra Maraton',
    description: 'Slušaj 6 sati bez pauze',
    icon: '🚀',
    color: _red,
    requirement: 360,
    points: 400,
    category: AchievementCategory.withoutPause,
  );

  static const tenHours = Achievement(
    id: 'ten_hours',
    name: 'Deset Sati',
    description: 'Slušaj ukupno 10 sati',
    icon: '🕙',
    color: _orange,
    requirement: 600,
    points: 150,
    category: AchievementCategory.totalListening,
  );
  static const fiftyHours = Achievement(
    id: 'fifty_hours',
    name: 'Pedeset Sati',
    description: 'Slušaj ukupno 50 sati',
    icon: '⌛',
    color: _indigo,
    requirement: 3000,
    points: 500,
    category: AchievementCategory.totalListening,
  );
  static const hundredHours = Achievement(
    id: 'hundred_hours',
    name: 'Sto Sati',
    description: 'Slušaj ukupno 100 sati',
    icon: '💯',
    color: _gold,
    requirement: 6000,
    points: 1000,
    category: AchievementCategory.totalListening,
  );

  static const tenSessions = Achievement(
    id: 'ten_sessions',
    name: 'Deset Sesija',
    description:
        'Završi 10 sesija slušanja od bar ${ProgressRules.minMinutesForSession} minuta',
    icon: '🔟',
    color: _green,
    requirement: 10,
    points: 100,
    category: AchievementCategory.sessions,
  );
  static const fiftySessions = Achievement(
    id: 'fifty_sessions',
    name: 'Pedeset Sesija',
    description:
        'Završi 50 sesija slušanja od bar ${ProgressRules.minMinutesForSession} minuta',
    icon: '📻',
    color: _blue,
    requirement: 50,
    points: 300,
    category: AchievementCategory.sessions,
  );
  static const hundredSessions = Achievement(
    id: 'hundred_sessions',
    name: 'Sto Sesija',
    description:
        'Završi 100 sesija slušanja od bar ${ProgressRules.minMinutesForSession} minuta',
    icon: '🎯',
    color: _red,
    requirement: 100,
    points: 600,
    category: AchievementCategory.sessions,
  );

  static const weekStreak = Achievement(
    id: 'daily_listener',
    name: 'Sedmica Zaredom',
    description: 'Slušaj Feniks Radio 7 dana zaredom',
    icon: '📆',
    color: _brand,
    requirement: 7,
    points: 150,
    category: AchievementCategory.streaks,
  );
  static const twoWeekStreak = Achievement(
    id: 'weekly_champion',
    name: 'Dvije Sedmice Zaredom',
    description: 'Slušaj Feniks Radio 14 dana zaredom',
    icon: '🎖️',
    color: _brightGreen,
    requirement: 14,
    points: 250,
    category: AchievementCategory.streaks,
  );
  static const loyalFan = Achievement(
    id: 'loyal_fan',
    name: 'Vjeran Fan',
    description: 'Slušaj Feniks Radio 30 dana zaredom',
    icon: '👑',
    color: _purple,
    requirement: 30,
    points: 500,
    category: AchievementCategory.streaks,
  );
  static const legend = Achievement(
    id: 'legend',
    name: 'Legenda',
    description: 'Slušaj Feniks Radio 100 dana zaredom',
    icon: '⚡',
    color: _gold,
    requirement: 100,
    points: 1000,
    category: AchievementCategory.streaks,
  );

  static const sevenDays = Achievement(
    id: 'first_week',
    name: 'Sedam Dana Slušanja',
    description: 'Slušaj radio u 7 različitih dana',
    icon: '📅',
    color: _brightGreen,
    requirement: 7,
    points: 75,
    category: AchievementCategory.listeningDays,
  );
  static const thirtyDays = Achievement(
    id: 'first_month',
    name: 'Mjesec Dana Slušanja',
    description: 'Slušaj radio u 30 različitih dana',
    icon: '🗓️',
    color: _indigo,
    requirement: 30,
    points: 250,
    category: AchievementCategory.listeningDays,
  );
  static const loyalUser = Achievement(
    id: 'loyal_user',
    name: 'Vjeran Korisnik',
    description: 'Slušaj radio u 180 različitih dana',
    icon: '💎',
    color: _gold,
    requirement: 180,
    points: 800,
    category: AchievementCategory.listeningDays,
  );

  static const midnightListener = Achievement(
    id: 'midnight_listener',
    name: 'Ponoćni Slušalac',
    description: 'Slušaj radio između 00 i 05h u 3 različita dana',
    icon: '🌙',
    color: _purple,
    requirement: 3,
    points: 100,
    category: AchievementCategory.timeOfDay,
  );
  static const earlyBird = Achievement(
    id: 'early_bird',
    name: 'Rana Ptica',
    description: 'Slušaj radio između 05 i 08h u 5 različitih dana',
    icon: '🐦',
    color: _brightGreen,
    requirement: 5,
    points: 75,
    category: AchievementCategory.timeOfDay,
  );
  static const morningPerson = Achievement(
    id: 'morning_person',
    name: 'Jutarnja Osoba',
    description: 'Slušaj radio između 08 i 12h u 10 različitih dana',
    icon: '🌅',
    color: _gold,
    requirement: 10,
    points: 150,
    category: AchievementCategory.timeOfDay,
  );
  static const afternoonListener = Achievement(
    id: 'afternoon_listener',
    name: 'Popodnevni Slušalac',
    description: 'Slušaj radio između 12 i 18h u 10 različitih dana',
    icon: '☀️',
    color: _orange,
    requirement: 10,
    points: 150,
    category: AchievementCategory.timeOfDay,
  );
  static const eveningEnthusiast = Achievement(
    id: 'evening_enthusiast',
    name: 'Večernji Entuzijast',
    description: 'Slušaj radio između 18 i 22h u 10 različitih dana',
    icon: '🌆',
    color: _purple,
    requirement: 10,
    points: 150,
    category: AchievementCategory.timeOfDay,
  );
  static const nightOwl = Achievement(
    id: 'night_owl',
    name: 'Noćna Ptica',
    description: 'Slušaj radio između 22 i 24h u 5 različitih dana',
    icon: '🦉',
    color: _indigo,
    requirement: 5,
    points: 75,
    category: AchievementCategory.timeOfDay,
  );

  static const weekendWarrior = Achievement(
    id: 'weekend_warrior',
    name: 'Vikend Ratnik',
    description:
        'Slušaj radio u 8 različitih vikend dana (subota ili nedjelja)',
    icon: '🎉',
    color: _orange,
    requirement: 8,
    points: 200,
    category: AchievementCategory.weekendAndWorkweek,
  );
  static const fullWorkweek = Achievement(
    id: 'workday_warrior',
    name: 'Radna Sedmica',
    description: 'Slušaj radio svaki radni dan (pon–pet) u istoj sedmici',
    icon: '💼',
    color: _blue,
    requirement: 5,
    points: 250,
    category: AchievementCategory.weekendAndWorkweek,
  );

  static const musicLover = Achievement(
    id: 'music_lover',
    name: 'Ljubitelj Muzike',
    description: 'Imaj 10 pjesama u omiljenim',
    icon: '💝',
    color: _red,
    requirement: 10,
    points: 100,
    category: AchievementCategory.favorites,
  );
  static const musicCollector = Achievement(
    id: 'music_collector',
    name: 'Kolekcionar Muzike',
    description: 'Imaj 25 pjesama u omiljenim',
    icon: '📀',
    color: _blue,
    requirement: 25,
    points: 200,
    category: AchievementCategory.favorites,
  );
  static const musicExpert = Achievement(
    id: 'music_expert',
    name: 'Stručnjak za Muziku',
    description: 'Imaj 50 pjesama u omiljenim',
    icon: '🎵',
    color: _indigo,
    requirement: 50,
    points: 350,
    category: AchievementCategory.favorites,
  );
  static const musicMaster = Achievement(
    id: 'music_master',
    name: 'Majstor Muzike',
    description: 'Imaj 100 pjesama u omiljenim',
    icon: '🎼',
    color: _gold,
    requirement: 100,
    points: 500,
    category: AchievementCategory.favorites,
  );

  static const songDiscoverer = Achievement(
    id: 'song_discoverer',
    name: 'Otkrivač Pjesama',
    description: 'Čuj 50 različitih pjesama na Feniks Radiju',
    icon: '🔍',
    color: _brightGreen,
    requirement: 50,
    points: 100,
    category: AchievementCategory.discovery,
  );
  static const songHunter = Achievement(
    id: 'song_hunter',
    name: 'Lovac na Pjesme',
    description: 'Čuj 250 različitih pjesama na Feniks Radiju',
    icon: '🎶',
    color: _indigo,
    requirement: 250,
    points: 300,
    category: AchievementCategory.discovery,
  );

  static const dailyListening = [firstHour, marathon, fiveHours];
  static const withoutPause = [halfHourNonStop, twoHoursNonStop, ultraMarathon];
  static const totalListening = [tenHours, fiftyHours, hundredHours];
  static const sessions = [tenSessions, fiftySessions, hundredSessions];
  static const streaks = [weekStreak, twoWeekStreak, loyalFan, legend];
  static const listeningDays = [sevenDays, thirtyDays, loyalUser];
  static const favorites = [
    musicLover,
    musicCollector,
    musicExpert,
    musicMaster,
  ];
  static const discovery = [songDiscoverer, songHunter];
  static const timeOfDay = [
    midnightListener,
    earlyBird,
    morningPerson,
    afternoonListener,
    eveningEnthusiast,
    nightOwl,
  ];

  static const List<(Achievement, int, int)> timeSlots = [
    (midnightListener, 0, 5),
    (earlyBird, 5, 8),
    (morningPerson, 8, 12),
    (afternoonListener, 12, 18),
    (eveningEnthusiast, 18, 22),
    (nightOwl, 22, 24),
  ];

  static const List<Achievement> all = [
    firstListen,
    appExplorer,
    ...dailyListening,
    ...withoutPause,
    ...totalListening,
    ...sessions,
    ...streaks,
    ...listeningDays,
    ...timeOfDay,
    weekendWarrior,
    fullWorkweek,
    ...favorites,
    ...discovery,
  ];

  static final Map<String, Achievement> _byId = {for (final a in all) a.id: a};

  static Achievement? byId(String id) => _byId[id];

  static Achievement timeSlotFor(int hour) {
    for (final (achievement, from, to) in timeSlots) {
      if (hour >= from && hour < to) return achievement;
    }
    return nightOwl;
  }
}
