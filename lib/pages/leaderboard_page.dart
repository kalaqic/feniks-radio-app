import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../models/leaderboard_entry.dart';
import '../models/radio_player_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/log.dart';
import '../widgets/common_footer.dart';
import '../widgets/ui.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<LeaderboardEntry> _leaderboard = [];
  int? _myRank;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RadioPlayerModel>().trackPageVisit(Routes.leaderboard);
      }
    });
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthService>();
      final model = context.read<RadioPlayerModel>();

      try {
        await model.syncNow().timeout(const Duration(seconds: 3));
      } catch (e) {
        logError('Saving progress before loading the leaderboard', e);
      }
      final top = await FirestoreService.instance.getLeaderboardTop(limit: 3);
      int? myRank;
      if (auth.isAuthenticated && auth.user != null) {
        myRank = await FirestoreService.instance.getMyRank(
          model.totalFeniksPoints,
        );
      }
      if (mounted) {
        setState(() {
          _leaderboard = top;
          _myRank = myRank;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Greška pri učitavanju. Povucite za osvježavanje.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final model = context.watch<RadioPlayerModel>();
    final loggedIn = context.watch<AuthService>().isAuthenticated;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.raspberry,
          onRefresh: _loadLeaderboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FadeSlideIn(child: PageTitle('Ljestvica')),
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: loggedIn
                      ? _MyPoints(model: model, rank: _myRank)
                      : const LoginPrompt(
                          title: 'Želiš i ti na ljestvicu?',
                          message:
                              'Prijavi se i svaki minut slušanja donosi ti '
                              '${ProgressRules.pointsPerMinute} poena.',
                        ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: _TopThree(
                    entries: _leaderboard,
                    loading: _loading,
                    error: _error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CommonFooter(currentRoute: Routes.leaderboard),
    );
  }
}

/// My points and rank. A tap opens where the points come from.
class _MyPoints extends StatefulWidget {
  const _MyPoints({required this.model, required this.rank});

  final RadioPlayerModel model;
  final int? rank;

  @override
  State<_MyPoints> createState() => _MyPointsState();
}

class _MyPointsState extends State<_MyPoints> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final rank = widget.rank;
    const white = TextStyle(color: Colors.white);
    return Semantics(
      button: true,
      expanded: _open,
      label: 'Detalji poena',
      child: Pressable(
        scale: .99,
        haptic: _open ? Haptic.selection : Haptic.light,
        onTap: () => setState(() => _open = !_open),
        child: Container(
          color: AppTheme.raspberry,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Moji Feniks poeni',
                          style: white.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        CountUp(
                          value: model.totalFeniksPoints,
                          style: white.copyWith(
                            fontSize: 40,
                            height: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (rank != null)
                        Text(
                          '#$rank na ljestvici',
                          style: white.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _open ? 'Manje' : 'Detalji',
                            style: white.copyWith(fontSize: 12),
                          ),
                          AnimatedRotation(
                            turns: _open ? .5 : 0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            child: const Icon(
                              Icons.expand_more,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              RevealDrawer(open: _open, children: _details(model, white)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _details(RadioPlayerModel model, TextStyle white) {
    return [
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 16),
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: .3),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _Stat(
                value: model.totalListeningMinutes,
                label: 'Minuta slušanja',
              ),
            ),
            Expanded(
              child: _Stat(
                value: model.listeningPoints,
                label: 'Poeni od slušanja',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _Stat(
                value: model.earnedAchievements.length,
                label: 'Značke',
              ),
            ),
            Expanded(
              child: _Stat(
                value: model.achievementPoints,
                label: 'Poeni od znački',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Svaki minut slušanja donosi ${ProgressRules.pointsPerMinute} '
          'poena, a svaka značka dodatne poene.',
          style: white.copyWith(fontSize: 13, height: 1.5),
        ),
    ];
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CountUp(
          value: value,
          delay: const Duration(milliseconds: 500),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _TopThree extends StatelessWidget {
  const _TopThree({
    required this.entries,
    required this.loading,
    required this.error,
  });

  final List<LeaderboardEntry> entries;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);

    final Widget body;
    if (loading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (error != null || entries.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Text(
          error ?? 'Još nema podataka. Budi prvi na ljestvici!',
          style: TextStyle(fontSize: 15, color: colors.muted),
        ),
      );
    } else {
      LeaderboardEntry? at(int rank) =>
          entries.where((e) => e.rank == rank).firstOrNull;
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _Podium(
              entry: at(2),
              place: 2,
              height: 96,
              color: AppTheme.blue,
              delay: 450,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Podium(
              entry: at(1),
              place: 1,
              height: 136,
              color: AppTheme.raspberry,
              delay: 300,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Podium(
              entry: at(3),
              place: 3,
              height: 70,
              color: AppTheme.coral,
              delay: 600,
            ),
          ),
        ],
      );
    }

    return Container(
      color: colors.surface,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 3',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Najbolji slušaoci svih vremena',
            style: TextStyle(fontSize: 14, color: colors.muted),
          ),
          const SizedBox(height: 20),
          body,
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({
    required this.entry,
    required this.place,
    required this.height,
    required this.color,
    required this.delay,
  });

  final LeaderboardEntry? entry;
  final int place;
  final double height;
  final Color color;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final entry = this.entry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry?.shortName ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry == null ? '' : '${formatNumber(entry.points)} p',
                style: TextStyle(fontSize: 12, color: colors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _Grow(
          delay: Duration(milliseconds: delay),
          child: Container(
            width: double.infinity,
            height: height,
            color: color,
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.all(10),
            child: Text(
              '$place',
              style: TextStyle(
                fontSize: switch (place) {
                  1 => 40,
                  2 => 32,
                  _ => 28,
                },
                height: 1,
                fontWeight: FontWeight.w700,
                color: AppTheme.onBrand(color),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Grows its child up from the bottom once.
class _Grow extends StatefulWidget {
  const _Grow({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<_Grow> createState() => _GrowState();
}

class _GrowState extends State<_Grow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.diagonal3Values(1, _curve.value, 1),
        child: child,
      ),
    );
  }
}
