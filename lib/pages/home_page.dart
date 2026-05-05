import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/radio_player_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/currently_playing_card.dart';
import '../widgets/header_with_volume.dart';
import '../widgets/ether_messages_card.dart';
import '../widgets/badges_card.dart';
import '../widgets/common_footer.dart';
import '../widgets/celebration_modal.dart';
import '../widgets/badge_earned_modal.dart';
import '../theme/app_theme.dart';
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
      if (auth.isAuthenticated && auth.user != null) {
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
            if (data != null) {
              model.loadAchievementData(data);
            } else {
              // New user: start with clean state and save to DB
              model.loadAchievementData({});
              await FirestoreService.instance.saveUserAchievements(
                auth.user!.uid,
                model.getAchievementData(),
              );
            }
            await FirestoreService.instance.updateLeaderboardEntry(
              auth.user!.uid,
              auth.user!.displayName ?? 'Anonim',
              model.totalFeniksPoints,
              model.earnedBadges.length,
            );
          }
        } catch (_) {
          // Avoid hard crash when Firestore rules are not ready yet.
        }
      }

      // Set up achievement popup and save to Firestore when a badge is earned
      model.onAchievementEarned = (badge) {
        if (!mounted) return;
        // Save immediately so the badge is persisted; then show popup
        _saveAchievementsToFirestore().then((_) {
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => BadgeEarnedModal(
              badge: badge,
              onDismiss: () {
                final bid = badge['id'] as String?;
                if (bid != null)
                  context.read<RadioPlayerModel>().markBadgeShown(bid);
                Navigator.of(dialogContext).pop();
                if (mounted) _saveAchievementsToFirestore();
              },
            ),
          );
        });
      };

      // Save progress to Firestore when it changes (favorites, session end, etc.)
      model.onProgressChanged = () {
        if (mounted) _saveAchievementsToFirestore();
      };

      // Check for badges first
      model.checkAndAwardBadges();

      // Auto-play if enabled
      if (model.autoPlay) {
        Future.delayed(const Duration(milliseconds: 500), () {
          model.play();
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

  Future<void> _saveAchievementsToFirestore() async {
    final auth = context.read<AuthService>();
    final uid = auth.user?.uid;
    if (uid != null) {
      final model = context.read<RadioPlayerModel>();
      try {
        await FirestoreService.instance.saveUserAchievements(
          uid,
          model.getAchievementData(),
        );
        final name = auth.user?.displayName ?? 'Anonim';
        await FirestoreService.instance.updateLeaderboardEntry(
          uid,
          name,
          model.totalFeniksPoints,
          model.earnedBadges.length,
        );
      } catch (_) {
        // Ignore save failures caused by backend permission setup.
      }
    }
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
            if (mounted) _saveAchievementsToFirestore();
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
      backgroundColor: isDarkMode
          ? AppTheme.background
          : const Color(0xFFF2F2F7),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode
              ? AppTheme.backgroundGradient
              : const LinearGradient(
                  colors: [Color(0xFFF2F2F7), Color(0xFFFFFFFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 1.0],
                ),
        ),
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
              const SizedBox(height: 24),
              const EtherMessagesCard(),
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
