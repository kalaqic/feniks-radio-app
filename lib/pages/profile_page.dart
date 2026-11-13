import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../models/radio_player_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/log.dart';
import '../widgets/common_footer.dart';
import '../widgets/ui.dart';

const _months = [
  'januara',
  'februara',
  'marta',
  'aprila',
  'maja',
  'juna',
  'jula',
  'avgusta',
  'septembra',
  'oktobra',
  'novembra',
  'decembra',
];

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _emailController = TextEditingController();
  bool _savingEmail = false;
  bool _emailSaved = false;
  Timer? _savedTimer;
  int? _rank;

  @override
  void initState() {
    super.initState();
    _loadDisplayEmail();
    _loadRank();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RadioPlayerModel>().trackPageVisit(Routes.profile);
      }
    });
  }

  @override
  void dispose() {
    _savedTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadDisplayEmail() async {
    final auth = context.read<AuthService>();
    final uid = auth.user?.uid;
    if (uid == null) return;
    try {
      final email = await FirestoreService.instance.getUserDisplayEmail(uid);
      if (mounted && email != null) _emailController.text = email;
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') return;
    } catch (e) {
      logError('Loading display email', e);
    }
  }

  Future<void> _loadRank() async {
    if (!context.read<AuthService>().isAuthenticated) return;
    final points = context.read<RadioPlayerModel>().totalFeniksPoints;
    try {
      final rank = await FirestoreService.instance.getMyRank(points);
      if (mounted) setState(() => _rank = rank);
    } catch (e) {
      logError('Loading leaderboard rank', e);
    }
  }

  Future<void> _saveDisplayEmail() async {
    final uid = context.read<AuthService>().user?.uid;
    if (uid == null) return;
    FocusScope.of(context).unfocus();
    setState(() => _savingEmail = true);
    final value = _emailController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirestoreService.instance.setUserDisplayEmail(
        uid,
        value.isEmpty ? null : value,
      );
      if (!mounted) return;
      setState(() {
        _savingEmail = false;
        _emailSaved = true;
      });
      _savedTimer?.cancel();
      _savedTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _emailSaved = false);
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(value.isEmpty ? 'Email uklonjen.' : 'Email sačuvan.'),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _savingEmail = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'permission-denied'
                ? 'Nemate dozvolu za ovu radnju (Firestore pravila).'
                : 'Greška pri čuvanju emaila.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _savingEmail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final auth = context.watch<AuthService>();
    final model = context.watch<RadioPlayerModel>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeSlideIn(
                child: Row(
                  children: [
                    const Expanded(child: PageTitle('Moj profil')),
                    Semantics(
                      button: true,
                      label: 'Otvori postavke',
                      child: Pressable(
                        onTap: () =>
                            Navigator.pushNamed(context, Routes.settings),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.settings_outlined,
                            color: colors.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (!auth.isAuthenticated || user == null) ...[
                const FadeSlideIn(
                  delay: Duration(milliseconds: 80),
                  child: LoginPrompt(
                    title: 'Prijavi se da vidiš svoj profil',
                    message:
                        'Tvoji poeni, značke i omiljene pjesme čuvaju se na '
                        'tvom nalogu.',
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextLink(
                      'Nemaš nalog? Napravi ga za minut',
                      padding: EdgeInsets.zero,
                      onTap: () => Navigator.pushNamed(context, Routes.welcome),
                    ),
                  ),
                ),
              ] else ...[
                FadeSlideIn(
                  delay: const Duration(milliseconds: 40),
                  child: _Identity(
                    name: user.displayName ?? 'Korisnik',
                    since: user.metadata.creationTime,
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: Pressable(
                    scale: .98,
                    onTap: () =>
                        Navigator.pushNamed(context, Routes.leaderboard),
                    child: Container(
                      color: AppTheme.raspberry,
                      padding: const EdgeInsets.all(22),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Moji Feniks poeni',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                CountUp(
                                  value: model.totalFeniksPoints,
                                  style: const TextStyle(
                                    fontSize: 40,
                                    height: 1,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _rank == null
                                ? 'Pogledaj ljestvicu'
                                : '#$_rank na ljestvici',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 125),
                  child: _ListeningStats(model: model),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 150),
                  child: Container(
                    color: colors.surface,
                    child: Column(
                      children: [
                        NavRow(
                          label: 'Moje značke',
                          trailing:
                              '${model.earnedAchievements.length} / '
                              '${model.allAchievements.length}',
                          showDivider: false,
                          horizontal: 22,
                          onTap: () =>
                              Navigator.pushNamed(context, Routes.badges),
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: hasNewFavorite,
                          builder: (context, isNew, _) => NavRow(
                            label: 'Omiljene pjesme',
                            trailing: '${model.favoriteSongs.length}',
                            dot: isNew,
                            horizontal: 22,
                            onTap: () => Navigator.pushNamed(
                              context,
                              Routes.favorites,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: _EmailBlock(
                    controller: _emailController,
                    saving: _savingEmail,
                    saved: _emailSaved,
                    onSave: _saveDisplayEmail,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CommonFooter(currentRoute: Routes.profile),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.name, required this.since});

  final String name;
  final DateTime? since;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final since = this.since;
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppTheme.raspberry,
            shape: BoxShape.circle,
          ),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: colors.ink,
                ),
              ),
              if (since != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Slušalac od ${_months[since.month - 1]} ${since.year}.',
                  style: TextStyle(fontSize: 14, color: colors.muted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Three numbers about listening, counted up when the profile opens.
class _ListeningStats extends StatelessWidget {
  const _ListeningStats({required this.model});

  final RadioPlayerModel model;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final hours = model.totalListeningMinutes ~/ 60;
    final (int value, String label) time = hours >= 10
        ? (hours, 'sati slušanja')
        : (model.totalListeningMinutes, 'minuta slušanja');

    Widget stat(int value, String label, int delay) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CountUp(
            value: value,
            delay: Duration(milliseconds: delay),
            style: TextStyle(
              fontSize: 26,
              height: 1.1,
              fontWeight: FontWeight.w500,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: colors.muted)),
        ],
      ),
    );

    return Container(
      color: colors.surface,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          stat(time.$1, time.$2, 350),
          Container(width: 1, height: 40, color: colors.divider),
          const SizedBox(width: 16),
          stat(model.consecutiveDays, 'dana zaredom', 450),
          Container(width: 1, height: 40, color: colors.divider),
          const SizedBox(width: 16),
          stat(model.totalListeningDays, 'dana s Feniksom', 550),
        ],
      ),
    );
  }
}

/// "Ostanimo u kontaktu": one closed row that opens into the email form.
class _EmailBlock extends StatefulWidget {
  const _EmailBlock({
    required this.controller,
    required this.saving,
    required this.saved,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool saving;
  final bool saved;
  final VoidCallback onSave;

  @override
  State<_EmailBlock> createState() => _EmailBlockState();
}

class _EmailBlockState extends State<_EmailBlock> {
  bool _open = false;

  @override
  void initState() {
    super.initState();
    // The saved email arrives a moment later; show it in the closed row.
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const ink = AppTheme.ink;
    final email = widget.controller.text.trim();
    return Container(
      color: AppTheme.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _open,
            child: Pressable(
              scale: .99,
              haptic: _open ? Haptic.selection : Haptic.light,
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
                child: Row(
                  children: [
                    const Icon(Icons.mail_outline_rounded, size: 20, color: ink),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ostanimo u kontaktu',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: ink,
                            ),
                          ),
                          Text(
                            email.isEmpty ? 'Novosti i specijalne emisije' : email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: ink),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _open ? .25 : 0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      child: const Icon(Icons.chevron_right, size: 20, color: ink),
                    ),
                  ],
                ),
              ),
            ),
          ),
          RevealDrawer(
            open: _open,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                child: _form(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _form(BuildContext context) {
    const ink = AppTheme.ink;
    final controller = widget.controller;
    final saving = widget.saving;
    final saved = widget.saved;
    final onSave = widget.onSave;
    return Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
            labelStyle: const TextStyle(fontSize: 15, color: ink),
            floatingLabelStyle: const TextStyle(fontSize: 15, color: ink),
            hintStyle: TextStyle(color: ink.withValues(alpha: .6)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: ink.withValues(alpha: .35)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: ink, width: 1.5),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ostavi email i prvi saznaj za specijalne emisije i novosti na '
              'Feniks Radiju.',
              style: TextStyle(fontSize: 14, height: 1.55, color: ink),
            ),
            const SizedBox(height: 12),
            Semantics(
              label: 'Email adresa',
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: ink,
                ),
                cursorColor: ink,
                decoration: const InputDecoration(hintText: 'vas@email.com'),
                onSubmitted: (_) => onSave(),
              ),
            ),
            const SizedBox(height: 18),
            PillButton(
              label: saved ? 'Email je sačuvan' : 'Sačuvaj email',
              icon: saved ? Icons.check : null,
              expand: false,
              height: 44,
              fontSize: 14,
              loading: saving,
              onPressed: onSave,
            ),
          ],
        ),
    );
  }
}
