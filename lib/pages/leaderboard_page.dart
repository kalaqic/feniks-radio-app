import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/radio_player_model.dart';
import '../widgets/common_footer.dart';
import '../widgets/achievement_modal.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  // Mock leaderboard data with Feniks Points
  final List<Map<String, dynamic>> _leaderboard = [
    {'name': 'Marko Petrović', 'points': 2450, 'avatar': '🎵', 'rank': 1, 'badges': 8},
    {'name': 'Ana Jovanović', 'points': 2380, 'avatar': '🎧', 'rank': 2, 'badges': 7},
    {'name': 'Stefan Nikolić', 'points': 2250, 'avatar': '🎼', 'rank': 3, 'badges': 6},
    {'name': 'Milica Stojanović', 'points': 2180, 'avatar': '🎤', 'rank': 4, 'badges': 5},
    {'name': 'Nemanja Milic', 'points': 2050, 'avatar': '🎸', 'rank': 5, 'badges': 4},
    {'name': 'Jovana Radić', 'points': 1980, 'avatar': '🥁', 'rank': 6, 'badges': 5},
    {'name': 'Luka Maksimović', 'points': 1870, 'avatar': '🎹', 'rank': 7, 'badges': 3},
    {'name': 'Tamara Vuković', 'points': 1750, 'avatar': '🎺', 'rank': 8, 'badges': 4},
    {'name': 'Miloš Đurić', 'points': 1680, 'avatar': '🎻', 'rank': 9, 'badges': 3},
    {'name': 'Jelena Stanković', 'points': 1550, 'avatar': '🪕', 'rank': 10, 'badges': 2},
  ];

  @override
  void initState() {
    super.initState();
    // Show achievement modal after page loads, but only first time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final model = context.read<RadioPlayerModel>();
      if (model.shouldShowAchievementModal) {
        _showAchievementModal();
      }
    });
  }

  void _showAchievementModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AchievementModal(
        percentage: '4%',
        onDismiss: () {
          final model = context.read<RadioPlayerModel>();
          model.markAchievementModalShown();
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
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDarkMode ? AppTheme.background : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          'Feniks Leaderboard',
          style: TextStyle(
            color: isDarkMode ? Colors.white : null,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: isDarkMode ? Colors.transparent : null,
        elevation: isDarkMode ? 0 : null,
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Personal Points Section
                _buildPersonalPointsSection(model),
                
                const SizedBox(height: 24),
                
                // Feniks Points Leaderboard Section
                _buildLeaderboardSection(),
                
                const SizedBox(height: 120), // Space for bottom nav
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CommonFooter(currentRoute: '/leaderboard', isDark: isDarkMode),
    );
  }

  Widget _buildPersonalPointsSection(RadioPlayerModel model) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;
    final myRank = 4; // Mock current user rank
    final myPoints = model.totalFeniksPoints;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryWithOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Moji Feniks Poeni',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Ukupno: $myPoints poena',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#$myRank',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Points Breakdown
          Row(
            children: [
              Expanded(
                child: _buildPointsCard(
                  'Slušanje',
                  '${model.listeningPoints}',
                  Icons.headphones_rounded,
                  Colors.white.withValues(alpha: 0.9),
                  AppTheme.primary,
                  isDarkMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPointsCard(
                  'Poruke',
                  '${model.messagesSent * 10}',
                  Icons.message_rounded,
                  Colors.white.withValues(alpha: 0.9),
                  AppTheme.primary,
                  isDarkMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPointsCard(
                  'Značke',
                  '${model.badgePoints}',
                  Icons.military_tech_rounded,
                  Colors.white.withValues(alpha: 0.9),
                  const Color(0xFFFFD700),
                  isDarkMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPointsCard(
                  'Poruke',
                  '${model.messagesSent}',
                  Icons.chat_bubble_outline_rounded,
                  Colors.white.withValues(alpha: 0.9),
                  const Color(0xFF32D74B),
                  isDarkMode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard(String label, String value, IconData icon, Color bgColor, Color iconColor, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.cardBackground : bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode 
            ? AppTheme.cardBorder
            : Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? AppTheme.textPrimary : const Color(0xFF1D1D1F),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? AppTheme.textSecondary : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection() {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.cardBackground : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDarkMode ? AppTheme.cardBorder : Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.leaderboard_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top 10 Feniks Poeni',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? AppTheme.textPrimary : const Color(0xFF1D1D1F),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Najbolji slušaoci ovog mjeseca',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? AppTheme.textSecondary : const Color(0xFF8E8E93),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Top 3 Podium
          _buildTopThreePodium(),
          
          const SizedBox(height: 24),
          
          // Rest of leaderboard (4-10)
          ...List.generate(7, (index) {
            final user = _leaderboard[index + 3];
            return _buildLeaderboardItem(user, index + 3 == 0); // highlight current user if needed
          }),
        ],
      ),
    );
  }

  Widget _buildTopThreePodium() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd Place
        _buildPodiumPlace(_leaderboard[1], 2, 80, const Color(0xFFE5E7EB)),
        // 1st Place
        _buildPodiumPlace(_leaderboard[0], 1, 100, const Color(0xFFFBBF24)),
        // 3rd Place
        _buildPodiumPlace(_leaderboard[2], 3, 60, const Color(0xFFCD7F32)),
      ],
    );
  }

  Widget _buildPodiumPlace(Map<String, dynamic> user, int place, double height, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              user['avatar'],
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          user['name'].split(' ')[0], // First name only
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '${user['points']} p',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Text(
              '$place',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> user, bool isCurrentUser) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser 
          ? AppTheme.primaryWithOpacity(0.1)
          : isDarkMode ? AppTheme.cardBackground : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser 
            ? AppTheme.primaryWithOpacity(0.3)
            : isDarkMode ? AppTheme.cardBorder : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getRankColor(user['rank']).withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getRankColor(user['rank']),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '${user['rank']}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _getRankColor(user['rank']),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                user['avatar'],
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? AppTheme.textPrimary : const Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${user['badges']} znački',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? AppTheme.textSecondary : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user['points']} p',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? AppTheme.textPrimary : const Color(0xFF1D1D1F),
                ),
              ),
              Text(
                'Feniks Poeni',
                style: TextStyle(
                  fontSize: 11,
                  color: isDarkMode ? AppTheme.textSecondary : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFBBF24);
      case 2:
        return const Color(0xFFE5E7EB);
      case 3:
        return const Color(0xFFCD7F32);
      case 4:
        return AppTheme.primary; // Current user highlight
      default:
        return const Color(0xFF8E8E93);
    }
  }
}