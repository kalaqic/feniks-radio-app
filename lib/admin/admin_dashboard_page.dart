import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'admin_data.dart';
import 'admin_stats.dart';

String formatMinutes(num minutes) {
  final total = minutes.round();
  if (total < 60) return '$total min';
  final hours = total ~/ 60;
  final rest = total % 60;
  return rest == 0 ? '$hours h' : '$hours h $rest min';
}

String formatPercent(double value) => '${value.round()}%';

String formatDate(DateTime? date) {
  if (date == null) return '—';
  return '${date.day}.${date.month}.${date.year}.';
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _repository = AdminRepository();
  late Future<List<AdminUser>> _users;
  late final Stream<List<PresenceEntry>> _presence;
  Timer? _clock;
  DateTime _loadedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _users = _repository.loadUsers();
    _presence = _repository.watchPresence();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _users = _repository.loadUsers();
      _loadedAt = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feniks Admin'),
        actions: [
          IconButton(
            tooltip: 'Osvježi',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Odjavi se',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<List<AdminUser>>(
        future: _users,
        builder: (context, usersSnapshot) {
          if (usersSnapshot.hasError) {
            return _Message(
              'Podaci se ne mogu učitati. Provjerite da su objavljena nova '
              'Firestore pravila.\n\n${usersSnapshot.error}',
            );
          }
          if (!usersSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<List<PresenceEntry>>(
            stream: _presence,
            builder: (context, presenceSnapshot) {
              final users = usersSnapshot.data!;
              final stats = AdminStats.compute(
                users,
                presenceSnapshot.data ?? const [],
                DateTime.now(),
              );
              return _Dashboard(
                users: users,
                stats: stats,
                loadedAt: _loadedAt,
              );
            },
          );
        },
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.users,
    required this.stats,
    required this.loadedAt,
  });

  final List<AdminUser> users;
  final AdminStats stats;
  final DateTime loadedAt;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Section(
          title: 'Uživo',
          subtitle: 'Osvježava se samo, kašnjenje do 2 minute',
          child: _TileGrid(
            tiles: [
              _StatTile(
                icon: Icons.headphones,
                color: AppTheme.primary,
                label: 'Slušaju sada (aplikacija)',
                value: '${stats.listeningNow}',
              ),
              _StatTile(
                icon: Icons.phone_iphone,
                color: Colors.blue,
                label: 'Aktivni u aplikaciji',
                value: '${stats.activeNow}',
                hint: 'Aplikacija otvorena ili radio svira',
              ),
            ],
          ),
        ),
        _Section(
          title: 'Korisnici',
          subtitle:
              'Podaci učitani u ${loadedAt.hour.toString().padLeft(2, '0')}:'
              '${loadedAt.minute.toString().padLeft(2, '0')}',
          child: _TileGrid(
            tiles: [
              _StatTile(
                icon: Icons.people,
                color: Colors.indigo,
                label: 'Registrovanih korisnika',
                value: '${stats.totalUsers}',
                hint: '+${stats.newUsersLast7Days} u zadnjih 7 dana',
              ),
              _StatTile(
                icon: Icons.today,
                color: Colors.green,
                label: 'Slušali danas',
                value: '${stats.listenedToday}',
                hint:
                    '${formatPercent(stats.shareOfUsers(stats.listenedToday))} korisnika',
              ),
              _StatTile(
                icon: Icons.date_range,
                color: Colors.teal,
                label: 'Slušali zadnjih 7 dana',
                value: '${stats.listenedLast7Days}',
                hint:
                    '${formatPercent(stats.shareOfUsers(stats.listenedLast7Days))} korisnika',
              ),
              _StatTile(
                icon: Icons.calendar_month,
                color: Colors.cyan,
                label: 'Slušali zadnjih 30 dana',
                value: '${stats.listenedLast30Days}',
                hint:
                    '${formatPercent(stats.shareOfUsers(stats.listenedLast30Days))} korisnika',
              ),
              _StatTile(
                icon: Icons.local_fire_department,
                color: Colors.deepOrange,
                label: 'Slušaju svaki dan',
                value: formatPercent(
                  stats.shareOfUsers(stats.listenedEveryDayLast7),
                ),
                hint: '${stats.listenedEveryDayLast7} korisnika, svih 7 prethodnih dana',
              ),
              _StatTile(
                icon: Icons.replay,
                color: Colors.purple,
                label: 'Vraćaju se',
                value: formatPercent(stats.retentionPercent),
                hint:
                    '${stats.retained} od ${stats.retentionEligible} starijih od 7 dana '
                    'slušalo je ove sedmice',
              ),
            ],
          ),
        ),
        _Section(
          title: 'Slušanje',
          child: _TileGrid(
            tiles: [
              _StatTile(
                icon: Icons.timer,
                color: AppTheme.primaryDark,
                label: 'Danas ukupno',
                value: formatMinutes(stats.minutesToday),
                hint:
                    'Prosjek ${formatMinutes(stats.avgMinutesPerListenerToday)} po slušaocu',
              ),
              _StatTile(
                icon: Icons.av_timer,
                color: Colors.orange,
                label: 'Prosjek dnevno (7 dana)',
                value: formatMinutes(stats.avgDailyMinutesPerWeeklyListener),
                hint: 'Po korisniku koji je slušao te sedmice',
              ),
              _StatTile(
                icon: Icons.all_inclusive,
                color: Colors.brown,
                label: 'Ukupno odslušano',
                value: '${stats.totalMinutesAllTime ~/ 60} h',
                hint: 'Svi korisnici, od početka',
              ),
            ],
          ),
        ),
        _Section(
          title: 'Zadnjih 14 dana',
          child: Column(
            children: [
              _BarChart(
                title: 'Broj slušalaca po danu',
                days: stats.last14Days,
                valueOf: (d) => d.listeners,
                color: AppTheme.primary,
                format: (v) => '$v',
              ),
              const SizedBox(height: 24),
              _BarChart(
                title: 'Odslušano po danu',
                days: stats.last14Days,
                valueOf: (d) => d.minutes,
                color: Colors.blue,
                format: formatMinutes,
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final achievements = _Section(
              title: 'Značke',
              subtitle: 'Koliko korisnika je osvojilo koju značku',
              child: _AchievementList(stats: stats),
            );
            final songs = _Section(
              title: 'Najomiljenije pjesme',
              subtitle: 'Koliko korisnika ima pjesmu u omiljenim',
              child: _SongList(songs: stats.topFavorites),
            );
            if (constraints.maxWidth < 900) {
              return Column(children: [achievements, songs]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: achievements),
                const SizedBox(width: 20),
                Expanded(child: songs),
              ],
            );
          },
        ),
        _Section(
          title: 'Korisnici (${users.length})',
          child: _UsersTable(users: users),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, this.subtitle, required this.child});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 12, runSpacing: 12, children: tiles);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.hint,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              if (hint != null) ...[
                const SizedBox(height: 4),
                Text(
                  hint!,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.title,
    required this.days,
    required this.valueOf,
    required this.color,
    required this.format,
  });

  final String title;
  final List<DayStat> days;
  final int Function(DayStat day) valueOf;
  final Color color;
  final String Function(int value) format;

  @override
  Widget build(BuildContext context) {
    final values = days.map(valueOf).toList();
    final max = values.fold<int>(0, (a, b) => a > b ? a : b);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < days.length; i++)
                    Expanded(
                      child: Tooltip(
                        message:
                            '${formatDate(days[i].day)}: ${format(values[i])}',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                values[i] == 0 ? '' : format(values[i]),
                                style: const TextStyle(fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: max == 0 ? 2.0 : 2.0 + 118.0 * values[i] / max,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${days[i].day.day}.${days[i].day.month}.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementList extends StatelessWidget {
  const _AchievementList({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            for (final item in stats.topAchievements)
              ListTile(
                dense: true,
                leading: Text(
                  item.achievement.icon,
                  style: const TextStyle(fontSize: 22),
                ),
                title: Text(item.achievement.name),
                subtitle: LinearProgressIndicator(
                  value: stats.totalUsers == 0
                      ? 0
                      : item.users / stats.totalUsers,
                  color: item.achievement.color,
                  backgroundColor: Colors.grey.shade200,
                ),
                trailing: Text(
                  '${item.users} · '
                  '${formatPercent(stats.shareOfUsers(item.users))}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SongList extends StatelessWidget {
  const _SongList({required this.songs});

  final List<SongStat> songs;

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Još niko nema omiljenih pjesama.'),
        ),
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (index, song) in songs.indexed)
            ListTile(
              dense: true,
              leading: CircleAvatar(radius: 14, child: Text('${index + 1}')),
              title: Text(song.song),
              trailing: Text('${song.users}'),
            ),
        ],
      ),
    );
  }
}

enum _UserSort {
  points('Bodovi'),
  minutes('Odslušano'),
  lastListened('Zadnje slušanje'),
  newest('Najnoviji');

  const _UserSort(this.label);

  final String label;
}

class _UsersTable extends StatefulWidget {
  const _UsersTable({required this.users});

  final List<AdminUser> users;

  @override
  State<_UsersTable> createState() => _UsersTableState();
}

class _UsersTableState extends State<_UsersTable> {
  String _query = '';
  _UserSort _sort = _UserSort.points;

  List<AdminUser> get _visibleUsers {
    final query = _query.trim().toLowerCase();
    final list = widget.users
        .where((u) => query.isEmpty || u.name.toLowerCase().contains(query))
        .toList();
    int byDate(DateTime? a, DateTime? b) =>
        (b ?? DateTime(2000)).compareTo(a ?? DateTime(2000));
    switch (_sort) {
      case _UserSort.points:
        list.sort((a, b) => b.points.compareTo(a.points));
      case _UserSort.minutes:
        list.sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));
      case _UserSort.lastListened:
        list.sort((a, b) => byDate(a.lastListenedAt, b.lastListenedAt));
      case _UserSort.newest:
        list.sort((a, b) => byDate(a.createdAt, b.createdAt));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final users = _visibleUsers;
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Pretraži po imenu',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                DropdownButton<_UserSort>(
                  value: _sort,
                  onChanged: (value) {
                    if (value != null) setState(() => _sort = value);
                  },
                  items: [
                    for (final sort in _UserSort.values)
                      DropdownMenuItem(
                        value: sort,
                        child: Text('Sortiraj: ${sort.label}'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              showCheckboxColumn: false,
              columns: const [
                DataColumn(label: Text('Korisnik')),
                DataColumn(label: Text('Bodovi'), numeric: true),
                DataColumn(label: Text('Odslušano'), numeric: true),
                DataColumn(label: Text('Niz'), numeric: true),
                DataColumn(label: Text('Značke'), numeric: true),
                DataColumn(label: Text('Zadnje slušanje')),
                DataColumn(label: Text('Registrovan')),
              ],
              rows: [
                for (final user in users)
                  DataRow(
                    onSelectChanged: (_) => showDialog<void>(
                      context: context,
                      builder: (_) => _UserDetailDialog(user: user),
                    ),
                    cells: [
                      DataCell(Text(user.name)),
                      DataCell(Text('${user.points}')),
                      DataCell(Text(formatMinutes(user.totalMinutes))),
                      DataCell(Text('${user.streakOn(now)}')),
                      DataCell(Text('${user.achievements.length}')),
                      DataCell(Text(formatDate(user.lastListenedAt))),
                      DataCell(Text(formatDate(user.createdAt))),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserDetailDialog extends StatelessWidget {
  const _UserDetailDialog({required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final achievements = [...user.achievements]
      ..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
    return AlertDialog(
      title: Text(user.name),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow('Bodovi', '${user.points}'),
              _DetailRow('Odslušano ukupno', formatMinutes(user.totalMinutes)),
              _DetailRow('Danas', formatMinutes(user.minutesOn(now))),
              _DetailRow('Niz dana', '${user.streakOn(now)}'),
              _DetailRow('Dana slušanja', '${user.listeningDays}'),
              _DetailRow('Sesija', '${user.sessionCount}'),
              _DetailRow('Zadnje slušanje', formatDate(user.lastListenedAt)),
              _DetailRow('Registrovan', formatDate(user.createdAt)),
              if (user.contactEmail != null)
                _DetailRow('Email za novosti', user.contactEmail!),
              const SizedBox(height: 16),
              Text(
                'Značke (${achievements.length})',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (achievements.isEmpty) const Text('Još nema znački.'),
              for (final earned in achievements)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    '${earned.achievement.icon}  ${earned.achievement.name} '
                    '· ${formatDate(earned.earnedAt)}',
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Omiljene pjesme (${user.favorites.length})',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (user.favorites.isEmpty) const Text('Nema omiljenih pjesama.'),
              for (final song in user.favorites)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(song),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Zatvori'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 170,
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
