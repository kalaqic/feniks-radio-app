import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/radio_player_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/currently_playing_card.dart';
import '../widgets/header_with_volume.dart';
import '../widgets/badges_card.dart';
import '../widgets/common_footer.dart';
import '../widgets/celebration_modal.dart';
import '../widgets/badge_earned_modal.dart';
import '../theme/theme_provider.dart';

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

      // Load user data from Firestore when logged in (points, hours, achievements, etc.)
      // Only once per user: reloading would overwrite progress that was
      // counted in memory but not yet saved.
      if (auth.isAuthenticated &&
          auth.user != null &&
          model.loadedUserId != auth.user!.uid) {
        try {
          await FirestoreService.instance.ensureUserProfile(
            auth.user!.uid,
            displayName: auth.user!.displayName,
            email: auth.user!.email,
          );
          final data = await FirestoreService.instance.loadUserAchievements(
            auth.user!.uid,
          );
          if (mounted) {
            // New users (data == null) start clean; progress made before the
            // data loaded is kept either way.
            model.loadUserProgress(auth.user!.uid, data);
            unawaited(model.syncNow());
          }
        } catch (_) {
          // Avoid hard crash when Firestore rules are not ready yet.
        }
      }

      if (!mounted) return;
      model.trackPageVisit('/home');

      // Show a popup when a badge is earned (the model saves it by itself;
      // the popup must not wait for the network).
      model.onAchievementEarned = (badge) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => BadgeEarnedModal(
            badge: badge,
            onDismiss: () {
              final bid = badge['id'] as String?;
              if (bid != null) {
                context.read<RadioPlayerModel>().markBadgeShown(bid);
              }
              Navigator.of(dialogContext).pop();
            },
          ),
        );
      };

      // Award anything the loaded progress already qualifies for
      model.checkAndAwardBadges();

      // Auto-play only once per app launch, not on every return to home.
      if (model.takeAutoPlay() && !model.playing) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!model.playing) model.play();
        });
      }

      if (model.shouldShowCelebration) {
        _showCelebrationModal();
      } else if (model.hasPendingBadges) {
        _showBadgeEarnedModal();
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

          // Check for pending badges after celebration
          if (model.hasPendingBadges) {
            _showBadgeEarnedModal();
          }
        },
      ),
    );
  }

  void _showBadgeEarnedModal() {
    final model = context.read<RadioPlayerModel>();
    if (!model.hasPendingBadges) return;

    final badgeId = model.getNextPendingBadge();
    final badge = model.allBadges[badgeId];

    if (badge != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => BadgeEarnedModal(
          badge: badge,
          onDismiss: () {
            final m = context.read<RadioPlayerModel>();
            m.markBadgeShown(badgeId);
            Navigator.of(dialogContext).pop();
            if (mounted && m.hasPendingBadges) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) _showBadgeEarnedModal();
              });
            }
          },
        ),
      );
    }
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
      body: Container(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 270,
              ), // Space for header + volume bar + padding
              CurrentlyPlayingCard(model: model),
              const SizedBox(height: 24),
              const BadgesCard(),
              const SizedBox(height: 140), // Space for bottom nav
            ],
          ),
        ),
      ),
      bottomNavigationBar: CommonFooter(
        currentRoute: '/home',
        isDark: isDarkMode,
      ),
    );
  }
}
