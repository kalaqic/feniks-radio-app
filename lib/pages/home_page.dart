import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../models/radio_player_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/theme_provider.dart';
import '../utils/log.dart';
import '../widgets/badge_earned_modal.dart';
import '../widgets/badges_card.dart';
import '../widgets/celebration_modal.dart';
import '../widgets/common_footer.dart';
import '../widgets/currently_playing_card.dart';
import '../widgets/header_with_volume.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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

      if (model.shouldShowCelebration) {
        _showCelebrationModal();
      } else {
        _showNextPendingAchievement();
      }
    });
  }

  void _showCelebrationModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CelebrationModal(
        onDismiss: () async {
          final model = context.read<RadioPlayerModel>();
          model.markCelebrationShown();
          Navigator.of(context).pop();
          await model.play();

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
    showDialog(
      context: context,
      barrierDismissible: false,
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
    final model = context.watch<RadioPlayerModel>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const HeaderWithVolume(),
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 270,
            ),
            CurrentlyPlayingCard(model: model),
            const SizedBox(height: 24),
            const BadgesCard(),
            const SizedBox(height: 140),
          ],
        ),
      ),
      bottomNavigationBar: CommonFooter(
        currentRoute: Routes.home,
        isDark: isDarkMode,
      ),
    );
  }
}
