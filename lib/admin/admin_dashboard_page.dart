import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/badge_style.dart';
import '../widgets/ui.dart';
import 'admin_app.dart';
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

const _brand = [AppTheme.raspberry, AppTheme.coral, AppTheme.blue];

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

  /// Changes on every reload so the numbers count up again.
  int _generation = 0;

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
      _generation++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: FutureBuilder<List<AdminUser>>(
        future: _users,
        builder: (context, usersSnapshot) {
          if (usersSnapshot.hasError) {
            return _Message(
              'Podaci se ne mogu učitati. Provjeri da su objavljena nova '
              'Firestore pravila.\n\n${usersSnapshot.error}',
            );
          }
          if (!usersSnapshot.hasData) return const AdminLoading();
          return StreamBuilder<List<PresenceEntry>>(
            stream: _presence,
            builder: (context, presenceSnapshot) {
              final users = usersSnapshot.data!;
              final stats = AdminStats.compute(
                users,
                presenceSnapshot.data ?? const [],
                DateTime.now(),
              );
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _Header(
                      listeningNow: stats.listeningNow,
                      activeNow: stats.activeNow,
                      onReload: _reload,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: _Dashboard(
                          key: ValueKey(_generation),
                          users: users,
                          stats: stats,
                          loadedAt: _loadedAt,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Coral header like on the app's home screen, with the live numbers.
class _Header extends StatelessWidget {
  const _Header({
    required this.listeningNow,
    required this.activeNow,
    required this.onReload,
  });

  final int listeningNow;
  final int activeNow;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    const white = TextStyle(color: Colors.white);
    return ColoredBox(
      color: AppTheme.coral,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'lib/assets/png/logo_red.png',
                        width: 40,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'Feniks ',
                            children: [
                              TextSpan(
                                text: 'Admin',
                                style: white.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          style: white.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                      _HeaderAction(
                        label: 'Osvježi',
                        onTap: onReload,
                      ),
                      const SizedBox(width: 8),
                      _HeaderAction(
                        label: 'Odjavi se',
                        onTap: () => FirebaseAuth.instance.signOut(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 40,
                    runSpacing: 16,
                    children: [
                      _LiveNumber(
                        value: listeningNow,
                        label: 'sluša sada u aplikaciji',
                        live: true,
                      ),
                      _LiveNumber(
                        value: activeNow,
                        label: 'aktivno u aplikaciji',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// White outlined pill in the header; a smaller one on narrow screens.
class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 600;
    return Semantics(
      button: true,
      label: label,
      child: Pressable(
        onTap: onTap,
        child: Container(
          height: 38,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: wide ? 20 : 14),
          decoration: const ShapeDecoration(
            shape: StadiumBorder(side: BorderSide(color: Colors.white)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: wide ? 14 : 13,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Big white number in the header; [live] adds a blinking dot.
class _LiveNumber extends StatelessWidget {
  const _LiveNumber({
    required this.value,
    required this.label,
    this.live = false,
  });

  final int value;
  final String label;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, .3),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                '$value',
                key: ValueKey(value),
                style: const TextStyle(
                  fontSize: 48,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            if (live) ...[
              const SizedBox(width: 12),
              LiveDot(active: value > 0),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
      ],
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    super.key,
    required this.users,
    required this.stats,
    required this.loadedAt,
  });

  final List<AdminUser> users;
  final AdminStats stats;
  final DateTime loadedAt;

  @override
  Widget build(BuildContext context) {
    var delay = 0;
    Duration next() => Duration(milliseconds: delay += 80);
    String two(int n) => n.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Section(
            delay: next(),
            title: 'Korisnici',
            subtitle:
                'Podaci učitani u ${two(loadedAt.hour)}:${two(loadedAt.minute)}',
            child: _TileGrid(
              tiles: [
                _StatTile(
                  label: 'Registrovanih korisnika',
                  value: stats.totalUsers,
                  hint: '+${stats.newUsersLast7Days} u zadnjih 7 dana',
                ),
                _StatTile(
                  label: 'Slušali danas',
                  value: stats.listenedToday,
                  hint:
                      '${formatPercent(stats.shareOfUsers(stats.listenedToday))}'
                      ' korisnika',
                ),
                _StatTile(
                  label: 'Slušali zadnjih 7 dana',
                  value: stats.listenedLast7Days,
                  hint:
                      '${formatPercent(stats.shareOfUsers(stats.listenedLast7Days))}'
                      ' korisnika',
                ),
                _StatTile(
                  label: 'Slušali zadnjih 30 dana',
                  value: stats.listenedLast30Days,
                  hint:
                      '${formatPercent(stats.shareOfUsers(stats.listenedLast30Days))}'
                      ' korisnika',
                ),
                _StatTile(
                  label: 'Slušaju svaki dan',
                  value: stats
                      .shareOfUsers(stats.listenedEveryDayLast7)
                      .round(),
                  suffix: '%',
                  hint:
                      '${stats.listenedEveryDayLast7} korisnika, svih 7 '
                      'prethodnih dana',
                ),
                _StatTile(
                  label: 'Vraćaju se',
                  value: stats.retentionPercent.round(),
                  suffix: '%',
                  hint:
                      '${stats.retained} od ${stats.retentionEligible} starijih '
                      'od 7 dana slušalo je ove sedmice',
                ),
              ],
            ),
          ),
          _Section(
            delay: next(),
            title: 'Slušanje',
            child: _TileGrid(
              tiles: [
                _StatTile(
                  label: 'Danas ukupno',
                  value: stats.minutesToday,
                  format: formatMinutes,
                  hint:
                      'Prosjek ${formatMinutes(stats.avgMinutesPerListenerToday)}'
                      ' po slušaocu',
                ),
                _StatTile(
                  label: 'Prosjek dnevno (7 dana)',
                  value: stats.avgDailyMinutesPerWeeklyListener.round(),
                  format: formatMinutes,
                  hint: 'Po korisniku koji je slušao te sedmice',
                ),
                _StatTile(
                  label: 'Ukupno odslušano',
                  value: stats.totalMinutesAllTime ~/ 60,
                  suffix: ' h',
                  hint: 'Svi korisnici, od početka',
                ),
              ],
            ),
          ),
          _Section(
            delay: next(),
            title: 'Zadnjih 14 dana',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final listeners = _BarChart(
                  title: 'Slušalaca po danu',
                  days: stats.last14Days,
                  valueOf: (d) => d.listeners,
                  color: AppTheme.raspberry,
                  format: (v) => '$v',
                );
                final minutes = _BarChart(
                  title: 'Odslušano po danu',
                  days: stats.last14Days,
                  valueOf: (d) => d.minutes,
                  color: AppTheme.blue,
                  format: formatMinutes,
                );
                if (constraints.maxWidth < 900) {
                  return Column(
                    children: [listeners, const SizedBox(height: 16), minutes],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: listeners),
                    const SizedBox(width: 16),
                    Expanded(child: minutes),
                  ],
                );
              },
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final achievements = _Section(
                delay: next(),
                title: 'Značke',
                subtitle: 'Koliko korisnika je osvojilo koju značku',
                child: _AchievementList(stats: stats),
              );
              final songs = _Section(
                delay: next(),
                title: 'Najomiljenije pjesme',
                subtitle: 'Koliko korisnika ima pjesmu u omiljenim',
                child: _SongList(songs: stats.topFavorites),
              );
              if (constraints.maxWidth < 900) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [achievements, songs],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: achievements),
                  const SizedBox(width: 16),
                  Expanded(child: songs),
                ],
              );
            },
          ),
          _Section(
            delay: next(),
            title: 'Korisnici (${users.length})',
            subtitle: 'Klikni na korisnika za sve detalje',
            child: _UsersTable(users: users),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageTitle('Nešto nije u redu', fontSize: 28),
              const SizedBox(height: 12),
              SelectableText(
                text,
                style: TextStyle(fontSize: 14, height: 1.55, color: colors.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    required this.delay,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: FadeSlideIn(
        delay: delay,
        offset: const Offset(0, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageTitle(title, fontSize: 24),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  subtitle!,
                  style: TextStyle(fontSize: 13, color: colors.muted),
                ),
              ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// Tiles in as many equal columns as fit (at most four).
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    const gap = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 250).floor().clamp(1, 4);
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (i, tile) in tiles.indexed)
              SizedBox(
                width: width,
                child: _TileAccent(color: _brand[i % _brand.length], child: tile),
              ),
          ],
        );
      },
    );
  }
}

/// Colored line on top of a tile that draws itself in.
class _TileAccent extends StatelessWidget {
  const _TileAccent({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => FractionallySizedBox(
              widthFactor: v,
              child: Container(height: 3, color: color),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _StatTile extends StatefulWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.hint,
    this.format = formatNumber,
    this.suffix = '',
  });

  final String label;
  final int value;
  final String? hint;
  final String Function(int) format;
  final String suffix;

  @override
  State<_StatTile> createState() => _StatTileState();
}

class _StatTileState extends State<_StatTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: _hover ? colors.surfaceHover : colors.surface,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: TextStyle(fontSize: 13, color: colors.muted),
            ),
            const SizedBox(height: 8),
            CountUp(
              value: widget.value,
              format: widget.format,
              suffix: widget.suffix,
              style: TextStyle(
                fontSize: 32,
                height: 1.1,
                fontWeight: FontWeight.w500,
                color: colors.ink,
              ),
            ),
            if (widget.hint != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.hint!,
                style: TextStyle(fontSize: 12, height: 1.4, color: colors.soft),
              ),
            ],
          ],
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
    final colors = colorsOf(context);
    final values = days.map(valueOf).toList();
    final max = values.fold<int>(0, (a, b) => a > b ? a : b);
    return Container(
      color: colors.surface,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < days.length; i++)
                  Expanded(
                    child: Tooltip(
                      message: '${formatDate(days[i].day)}: ${format(values[i])}',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              values[i] == 0 ? '' : format(values[i]),
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.soft,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                            ),
                            const SizedBox(height: 4),
                            // Bars grow one after another, today in coral.
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: Duration(milliseconds: 700 + i * 45),
                              curve: Curves.easeOutCubic,
                              builder: (context, t, _) => Container(
                                height:
                                    (max == 0
                                        ? 2.0
                                        : 2.0 + 118.0 * values[i] / max) *
                                    t,
                                color: i == days.length - 1
                                    ? AppTheme.coral
                                    : color,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${days[i].day.day}.${days[i].day.month}.',
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.muted,
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
    );
  }
}

class _AchievementList extends StatelessWidget {
  const _AchievementList({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return Container(
      color: colors.surface,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (final (i, item) in stats.topAchievements.indexed)
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : Border(top: BorderSide(color: colors.divider)),
              ),
              child: Row(
                children: [
                  // Always in color here; badges nobody has yet are only
                  // a bit lighter, so every icon stays readable.
                  Opacity(
                    opacity: item.users > 0 ? 1 : .45,
                    child: BadgeIcon(
                      achievement: item.achievement,
                      earned: true,
                      size: 34,
                      earnedForeground: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.achievement.name,
                          style: TextStyle(fontSize: 14, color: colors.ink),
                        ),
                        const SizedBox(height: 8),
                        ProgressLine(
                          value: stats.totalUsers == 0
                              ? 0
                              : item.users / stats.totalUsers,
                          color: BadgeStyle.color(item.achievement),
                          track: colors.track,
                          delay: Duration(milliseconds: 300 + i * 40),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 76,
                    child: Text(
                      '${item.users} · '
                      '${formatPercent(stats.shareOfUsers(item.users))}',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 13, color: colors.soft),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SongList extends StatelessWidget {
  const _SongList({required this.songs});

  final List<SongStat> songs;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    if (songs.isEmpty) {
      return Container(
        color: colors.surface,
        padding: const EdgeInsets.all(18),
        child: Text(
          'Još niko nema omiljenih pjesama.',
          style: TextStyle(fontSize: 14, color: colors.text),
        ),
      );
    }
    return Container(
      color: colors.surface,
      child: Column(
        children: [
          for (final (i, song) in songs.indexed)
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : Border(top: BorderSide(color: colors.divider)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    color: _brand[i % _brand.length],
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: _SongText(song.song)),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.favorite,
                    size: 14,
                    color: AppTheme.raspberry,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${song.users}',
                    style: TextStyle(fontSize: 14, color: colors.ink),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// "Title - Artist" as the title with the artist in grey.
class _SongText extends StatelessWidget {
  const _SongText(this.song);

  final String song;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final dash = song.indexOf(' - ');
    final title = dash < 0 ? song : song.substring(0, dash);
    final artist = dash < 0 ? '' : song.substring(dash + 3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14, color: colors.ink),
        ),
        if (artist.isNotEmpty)
          Text(
            artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: colors.muted),
          ),
      ],
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
  final _search = TextEditingController();
  String _query = '';
  _UserSort _sort = _UserSort.points;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

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
    final colors = colorsOf(context);
    final now = DateTime.now();
    final users = _visibleUsers;
    final header = TextStyle(fontSize: 12, color: colors.muted);
    final cell = TextStyle(fontSize: 14, color: colors.ink);

    return Container(
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Wrap(
              spacing: 24,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(
                  width: 280,
                  child: LabeledField(
                    label: 'Pretraži po imenu',
                    controller: _search,
                    hint: 'Korisničko ime',
                    fontSize: 15,
                    onSubmitted: (_) {},
                    trailing: const Icon(Icons.search, size: 20),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final sort in _UserSort.values)
                      _SortPill(
                        label: sort.label,
                        selected: sort == _sort,
                        onTap: () => setState(() => _sort = sort),
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
              headingTextStyle: header,
              dataTextStyle: cell,
              dividerThickness: 1,
              horizontalMargin: 18,
              headingRowHeight: 44,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 52,
              dataRowColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.hovered)
                    ? colors.surfaceHover
                    : null,
              ),
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
                    onSelectChanged: (_) => showAppDialog<void>(
                      context,
                      builder: (_) => _UserDetail(user: user),
                    ),
                    cells: [
                      DataCell(
                        Text(
                          user.name,
                          style: cell.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      DataCell(Text(formatNumber(user.points))),
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
          if (users.isEmpty)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Nema korisnika s tim imenom.',
                style: TextStyle(fontSize: 14, color: colors.muted),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      if (_search.text != _query) setState(() => _query = _search.text);
    });
  }
}

class _SortPill extends StatelessWidget {
  const _SortPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: ShapeDecoration(
          color: selected ? colors.button : Colors.transparent,
          shape: StadiumBorder(
            side: BorderSide(
              color: selected ? colors.button : colors.fieldLine,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: selected ? colors.onButton : colors.ink,
          ),
        ),
      ),
    );
  }
}

/// Everything about one user, in the app's dialog.
class _UserDetail extends StatelessWidget {
  const _UserDetail({required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final now = DateTime.now();
    final achievements = [...user.achievements]
      ..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
    final label = TextStyle(fontSize: 13, color: colors.muted);

    Widget number(String value, String text) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(text, style: label),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        PageTitle(user.name, fontSize: 28),
        const SizedBox(height: 4),
        Text(
          'Registrovan ${formatDate(user.createdAt)} · zadnje slušanje '
          '${formatDate(user.lastListenedAt)}',
          style: label,
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            number(formatNumber(user.points), 'bodova'),
            number(formatMinutes(user.totalMinutes), 'ukupno'),
            number(formatMinutes(user.minutesOn(now)), 'danas'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            number('${user.streakOn(now)}', 'dana zaredom'),
            number('${user.listeningDays}', 'dana slušanja'),
            number('${user.sessionCount}', 'sesija'),
          ],
        ),
        if (user.contactEmail != null) ...[
          const SizedBox(height: 16),
          Text('Email za novosti', style: label),
          SelectableText(
            user.contactEmail!,
            style: TextStyle(fontSize: 15, color: colors.ink),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Značke (${achievements.length})',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: colors.ink,
          ),
        ),
        const SizedBox(height: 10),
        if (achievements.isEmpty)
          Text('Još nema znački.', style: label)
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final earned in achievements)
                Tooltip(
                  message:
                      '${earned.achievement.name} · ${formatDate(earned.earnedAt)}',
                  child: BadgeIcon(
                    achievement: earned.achievement,
                    earned: true,
                    size: 36,
                    earnedForeground: AppTheme.ink,
                  ),
                ),
            ],
          ),
        const SizedBox(height: 24),
        Text(
          'Omiljene pjesme (${user.favorites.length})',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: colors.ink,
          ),
        ),
        const SizedBox(height: 8),
        if (user.favorites.isEmpty)
          Text('Nema omiljenih pjesama.', style: label)
        else
          _FavoritesPreview(songs: user.favorites.reversed.toList()),
        const SizedBox(height: 24),
        PillButton(
          label: 'Zatvori',
          style: PillStyle.outline,
          height: 46,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

/// The newest five favorites; the rest open with a button.
class _FavoritesPreview extends StatefulWidget {
  const _FavoritesPreview({required this.songs});

  /// Newest first.
  final List<String> songs;

  @override
  State<_FavoritesPreview> createState() => _FavoritesPreviewState();
}

class _FavoritesPreviewState extends State<_FavoritesPreview> {
  static const _shown = 5;
  bool _all = false;

  Widget _row(String song) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: _SongText(song),
  );

  @override
  Widget build(BuildContext context) {
    final songs = widget.songs;
    final rest = songs.length - _shown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final song in songs.take(_shown)) _row(song),
        if (rest > 0) ...[
          RevealDrawer(
            open: _all,
            children: [for (final song in songs.skip(_shown)) _row(song)],
          ),
          const SizedBox(height: 4),
          TextLink(
            _all ? 'Prikaži manje' : 'Prikaži sve omiljene ($rest više)',
            fontSize: 13,
            onTap: () => setState(() => _all = !_all),
          ),
        ],
      ],
    );
  }
}
