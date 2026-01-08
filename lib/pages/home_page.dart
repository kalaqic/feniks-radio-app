import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/radio_player_model.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final model = context.read<RadioPlayerModel>();
      
      // Set up immediate achievement popup callback
      model.onAchievementEarned = (badge) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => BadgeEarnedModal(
              badge: badge,
              onDismiss: () {
                Navigator.of(context).pop();
              },
            ),
          );
        }
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
          // Auto-play disabled for testing purposes
          // await model.play();
          
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
        builder: (context) => BadgeEarnedModal(
          badge: badge,
          onDismiss: () {
            final model = context.read<RadioPlayerModel>();
            model.markBadgeShown(badgeId);
            Navigator.of(context).pop();
            
            // Check for more pending badges
            if (model.hasPendingBadges) {
              Future.delayed(const Duration(milliseconds: 500), () {
                _showBadgeEarnedModal();
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
      backgroundColor: isDarkMode ? AppTheme.background : const Color(0xFFF2F2F7),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode 
            ? AppTheme.backgroundGradient
            : const LinearGradient(
                colors: [
                  Color(0xFFF2F2F7),
                  Color(0xFFFFFFFF),
                ],
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
              const SizedBox(height: 270), // Space for header + volume bar + padding
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
      bottomNavigationBar: CommonFooter(currentRoute: '/home', isDark: isDarkMode),
    );
  }
}