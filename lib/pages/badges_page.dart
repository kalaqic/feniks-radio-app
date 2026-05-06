import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/models/radio_player_model.dart';
import '../widgets/badge_info_modal.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../widgets/common_footer.dart';

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {

  @override
  void initState() {
    super.initState();
    // Removed automatic popup - user can access via info icon
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
    final earnedBadges = model.earnedBadges;
    final allBadges = model.allBadges;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Značke',
          style: TextStyle(
            color: isDarkMode ? Colors.white : null,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.transparent : null,
        elevation: isDarkMode ? 0 : null,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            color: isDarkMode ? Colors.white : Theme.of(context).colorScheme.primary,
            size: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: isDarkMode ? Colors.white : Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => _showBadgeExplanationModal(),
          ),
        ],
      ),
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Stats
                _buildStatsCard(earnedBadges.length, allBadges.length),
                const SizedBox(height: 24),
                
                // Earned Badges Section
                if (earnedBadges.isNotEmpty) ...[
                  _buildSectionTitle('Osvojene Značke', earnedBadges.length, isDarkMode),
                  const SizedBox(height: 16),
                  _buildBadgesGrid(earnedBadges, true, isDarkMode),
                  const SizedBox(height: 32),
                ],
                
                // All Badges by Section
                ...model.badgesGroupedBySection.entries.map((sectionEntry) {
                  final sectionName = sectionEntry.key;
                  final sectionBadges = sectionEntry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    key: ValueKey(sectionName),
                    children: [
                      _buildSectionTitle(sectionName, sectionBadges.length, isDarkMode),
                      const SizedBox(height: 16),
                      _buildBadgesGridWithEarned(sectionBadges, earnedBadges, isDarkMode),
                      const SizedBox(height: 24),
                    ],
                  );
                }),
                const SizedBox(height: 120), // Space for bottom nav
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CommonFooter(currentRoute: '/badges', isDark: isDarkMode),
    );
  }

  Widget _buildStatsCard(int earned, int total) {
    final percentage = total > 0 ? (earned / total * 100).round() : 0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryWithOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
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
            color: isDarkMode ? AppTheme.textPrimary : const Color(0xFF1F2937),
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

  Widget _buildBadgesGrid(List<Map<String, dynamic>> badges, bool isEarned, bool isDarkMode) {
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
        return _buildBadgeCard(badge, isEarned, isDarkMode);
      },
    );
  }

  Widget _buildBadgesGridWithEarned(List<Map<String, dynamic>> badges, List<Map<String, dynamic>> earnedBadges, bool isDarkMode) {
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
        final isEarned = earnedBadges.any((earned) => earned['id'] == badge['id']);
        return _buildBadgeCard(badge, isEarned, isDarkMode);
      },
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic> badge, bool isEarned, bool isDarkMode) {
    final badgeColor = Color(badge['color'] as int);
    
    return Container(
      decoration: BoxDecoration(
        color: isEarned 
          ? (isDarkMode ? AppTheme.cardBackground : Colors.white)
          : (isDarkMode ? AppTheme.background : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEarned 
              ? badgeColor.withValues(alpha: 0.3)
              : (isDarkMode ? AppTheme.cardBorder : Colors.grey.shade200),
          width: 2,
        ),
        boxShadow: isEarned ? [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ] : null,
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
                // Badge icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isEarned 
                        ? badgeColor.withValues(alpha: 0.1)
                        : (isDarkMode ? AppTheme.backgroundMedium : Colors.grey.shade100),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      badge['icon'] as String,
                      style: TextStyle(
                        fontSize: 24,
                        color: isEarned ? null : (isDarkMode ? AppTheme.textSecondary : Colors.grey.shade400),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Badge name
                Expanded(
                  child: Text(
                    badge['name'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isEarned 
                        ? (isDarkMode ? AppTheme.textPrimary : const Color(0xFF1F2937)) 
                        : (isDarkMode ? AppTheme.textSecondary : Colors.grey.shade500),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                if (isEarned) ...[
                  const SizedBox(height: 6),
                  Icon(
                    Icons.check_circle,
                    color: badgeColor,
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBadgeDetails(Map<String, dynamic> badge, bool isEarned, bool isDarkMode) {
    final badgeColor = Color(badge['color'] as int);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryDark, AppTheme.accentDark],
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
                  color: isEarned ? badgeColor : Colors.white.withValues(alpha: 0.25),
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
                  child: Text(
                    badge['icon'] as String,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
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
                badge['name'] as String,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                badge['description'] as String,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.95),
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (isEarned && badge.containsKey('earnedDate')) ...[
                const SizedBox(height: 16),
                Text(
                  'Osvojeno ${_formatDate(badge['earnedDate'] as String)}',
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

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'danas';
    } else if (difference.inDays == 1) {
      return 'juče';
    } else if (difference.inDays < 7) {
      return 'pre ${difference.inDays} dana';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}