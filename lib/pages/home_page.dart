import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../models/radio_player_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/log.dart';
import '../widgets/badge_earned_modal.dart';
import '../widgets/badges_card.dart';
import '../widgets/celebration_modal.dart';
import '../widgets/common_footer.dart';
import '../widgets/currently_playing_card.dart';
import '../widgets/header_player.dart';
import '../widgets/ui.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.fromLanding = false});

  /// Route argument that marks the opening right after the landing screen.
  static const landingArgument = 'fromLanding';

  /// Plays the long entrance animation that continues the landing screen.
  final bool fromLanding;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final model = context.read<RadioPlayerModel>();
      final auth = context.read<AuthService>();

      if (auth.isAuthenticated &&
          auth.user != null &&
          model.loadedUserId != auth.user!.uid) {
        try {
          await FirestoreService.instance.ensureUserProfile(
            auth.user!.uid,
            displayName: auth.user!.displayName,
            email: auth.user!.email,
            createdAt: auth.user!.metadata.creationTime,
          );
          final data = await FirestoreService.instance.loadUserAchievements(
            auth.user!.uid,
          );
          if (mounted) {
            model.loadUserProgress(auth.user!.uid, data);
            unawaited(model.syncNow());
          }
        } catch (e) {
          logError('Loading saved progress', e);
        }
      }

      if (!mounted) return;
      // Badges are only unlocked for logged-in users.
      if (!auth.isAuthenticated) model.achievementsEnabled = false;
      model.trackPageVisit(Routes.home);

      model.onAchievementEarned = (earned) {
        if (mounted) _showAchievementPopup(earned.achievement);
      };

      model.checkAchievements();

      if (model.takeAutoPlay() && !model.playing) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!model.playing) model.play();
        });
      }

      // Let the entrance animation finish before any popup covers it.
      if (widget.fromLanding) {
        await Future<void>.delayed(const Duration(milliseconds: 1800));
        if (!mounted) return;
      }

      if (model.shouldShowCelebration) {
        _showCelebrationModal();
      } else {
        _showNextPendingAchievement();
      }
    });
  }

  void _showCelebrationModal() {
    final model = context.read<RadioPlayerModel>();
    Haptics.play(Haptic.light);
    showAppDialog<void>(
      context,
      dismissible: false,
      builder: (dialogContext) => CelebrationModal(
        onContinue: () async {
          model.markCelebrationShown();
          Navigator.of(dialogContext).pop();
          if (!model.playing) await model.play();
          _showNextPendingAchievement();
        },
        onClose: () {
          model.markCelebrationShown();
          Navigator.of(dialogContext).pop();
          _showNextPendingAchievement();
        },
      ),
    );
  }

  void _showNextPendingAchievement() {
    if (!mounted) return;
    final next = context.read<RadioPlayerModel>().nextPendingAchievement;
    if (next != null) _showAchievementPopup(next, thenShowNext: true);
  }

  void _showAchievementPopup(
    Achievement achievement, {
    bool thenShowNext = false,
  }) {
    // A badge is a reward: two quick taps.
    Haptics.play(Haptic.success);
    showAppDialog<void>(
      context,
      dismissible: false,
      builder: (dialogContext) => BadgeEarnedModal(
        badge: achievement,
        onDismiss: () {
          context.read<RadioPlayerModel>().markAchievementShown(achievement);
          Navigator.of(dialogContext).pop();
          if (thenShowNext) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) _showNextPendingAchievement();
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final landing = widget.fromLanding;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          HeaderPlayer(entrance: landing),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Column(
                children: [
                  FadeSlideIn(
                    delay: Duration(milliseconds: landing ? 1150 : 40),
                    duration: const Duration(milliseconds: 800),
                    offset: Offset(landing ? -420 : -60, 0),
                    child: const CurrentlyPlayingCard(),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    delay: Duration(milliseconds: landing ? 1350 : 140),
                    duration: const Duration(milliseconds: 800),
                    offset: Offset(landing ? 420 : 60, 0),
                    child: const BadgesCard(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CommonFooter(currentRoute: Routes.home),
    );
  }
}
