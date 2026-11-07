import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../models/radio_player_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../widgets/badge_info_modal.dart';
import '../widgets/common_footer.dart';
import '../widgets/gradient_card.dart';

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RadioPlayerModel>().trackPageVisit(Routes.badges);
      }
    });
  }

  void _showBadgeExplanationModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BadgeInfoModal(
        onDismiss: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<RadioPlayerModel>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;
    final earned = model.earnedAchievements;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Značke'),
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            color: isDarkMode
                ? Colors.white
                : Theme.of(context).colorScheme.primary,
            size: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: isDarkMode
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
            ),
            onPressed: _showBadgeExplanationModal,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsCard(earned.length, model.allAchievements.length),
              const SizedBox(height: 24),

              if (earned.isNotEmpty) ...[
                _buildSectionTitle(
                  'Osvojene Značke',
                  earned.length,
                  isDarkMode,
                ),
                const SizedBox(height: 16),
                _buildBadgesGrid([
                  for (final e in earned) e.achievement,
                ], isDarkMode),
                const SizedBox(height: 32),
              ],

              for (final MapEntry(key: category, value: badges)
                  in model.achievementsByCategory.entries)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  key: ValueKey(category),
                  children: [
                    _buildSectionTitle(
                      category.title,
                      badges.length,
                      isDarkMode,
                    ),
                    const SizedBox(height: 16),
                    _buildBadgesGrid(badges, isDarkMode),
                    const SizedBox(height: 24),
                  ],
                ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CommonFooter(
        currentRoute: Routes.badges,
        isDark: isDarkMode,
      ),
    );
  }

  Widget _buildStatsCard(int earned, int total) {
    final percentage = total > 0 ? (earned / total * 100).round() : 0;

    return GradientCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$earned / $total',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Značaka osvojeno',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            borderRadius: BorderRadius.circular(8),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count, bool isDarkMode) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.of(isDarkMode).primaryText,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryWithOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesGrid(List<Achievement> badges, bool isDarkMode) {
    final model = context.watch<RadioPlayerModel>();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return _buildBadgeCard(badge, model.hasAchievement(badge), isDarkMode);
      },
    );
  }

  Widget _buildBadgeCard(Achievement badge, bool isEarned, bool isDarkMode) {
    final badgeColor = badge.color;

    return Container(
      decoration: BoxDecoration(
        color: isEarned
            ? (AppColors.of(isDarkMode).card)
            : (isDarkMode ? AppTheme.background : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEarned
              ? badgeColor.withValues(alpha: 0.3)
              : (AppColors.of(isDarkMode).border),
          width: 2,
        ),
        boxShadow: isEarned
            ? [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showBadgeDetails(badge, isEarned, isDarkMode),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isEarned
                        ? badgeColor.withValues(alpha: 0.1)
                        : (isDarkMode
                              ? AppTheme.backgroundMedium
                              : Colors.grey.shade100),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      badge.icon,
                      style: TextStyle(
                        fontSize: 24,
                        color: isEarned
                            ? null
                            : (AppColors.of(isDarkMode).mutedText),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: Text(
                    badge.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isEarned
                          ? (AppColors.of(isDarkMode).primaryText)
                          : (AppColors.of(isDarkMode).mutedText),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                if (isEarned) ...[
                  const SizedBox(height: 6),
                  Icon(Icons.check_circle, color: badgeColor, size: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBadgeDetails(Achievement badge, bool isEarned, bool isDarkMode) {
    final badgeColor = badge.color;
    final earnedAt = context
        .read<RadioPlayerModel>()
        .earnedAchievements
        .where((e) => e.id == badge.id)
        .firstOrNull
        ?.earnedAt;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppTheme.primary,
                AppTheme.primaryDark,
                AppTheme.accentDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isEarned
                      ? badgeColor
                      : Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(badge.icon, style: const TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  isEarned ? 'Osvojeno' : 'Zaključano',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                badge.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                badge.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.95),
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (earnedAt != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Osvojeno ${_formatDate(earnedAt)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'U redu',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final days = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime.utc(date.year, date.month, date.day)).inDays;
    if (days <= 0) return 'danas';
    if (days == 1) return 'juče';
    if (days < 7) return 'prije $days dana';
    return '${date.day}.${date.month}.${date.year}.';
  }
}
