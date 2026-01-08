import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/radio_player_model.dart';
import '../widgets/common_footer.dart';
import '../widgets/achievement_modal.dart';
import '../theme/app_theme.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  // Mock leaderboard data
  final List<Map<String, dynamic>> _leaderboard = [
    {'name': 'Marko Petrović', 'minutes': 245, 'avatar': '🎵', 'rank': 1},
    {'name': 'Ana Jovanović', 'minutes': 238, 'avatar': '🎧', 'rank': 2},
    {'name': 'Stefan Nikolić', 'minutes': 225, 'avatar': '🎼', 'rank': 3},
    {'name': 'Milica Stojanović', 'minutes': 218, 'avatar': '🎤', 'rank': 4},
    {'name': 'Nemanja Milic', 'minutes': 205, 'avatar': '🎸', 'rank': 5},
    {'name': 'Jovana Radić', 'minutes': 198, 'avatar': '🥁', 'rank': 6},
    {'name': 'Luka Maksimović', 'minutes': 187, 'avatar': '🎹', 'rank': 7},
    {'name': 'Tamara Vuković', 'minutes': 175, 'avatar': '🎺', 'rank': 8},
    {'name': 'Miloš Đurić', 'minutes': 168, 'avatar': '🎻', 'rank': 9},
    {'name': 'Jelena Stanković', 'minutes': 155, 'avatar': '🪕', 'rank': 10},
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
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('Statistike'),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
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
                
                // Personal Stats Section
                _buildPersonalStatsSection(model),
                
                const SizedBox(height: 24),
                
                // Weekly Leaderboard Section
                _buildLeaderboardSection(),
                
                const SizedBox(height: 120), // Space for bottom nav
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CommonFooter(currentRoute: '/statistics'),
    );
  }

  Widget _buildPersonalStatsSection(RadioPlayerModel model) {
    final totalWeeklyMinutes = model.weeklyListeningData.values.reduce((a, b) => a + b);
    final averageDaily = (totalWeeklyMinutes / 7).round();
    final myRank = 4; // Mock current user rank
    final myWeeklyMinutes = totalWeeklyMinutes + model.todayListeningMinutes;
    
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
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Moje statistike',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Ovosjedmični pregled',
                      style: TextStyle(
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
          
          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Danas',
                  '${model.todayListeningMinutes} min',
                  Icons.today_rounded,
                  Colors.white.withValues(alpha: 0.9),
                  AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Ovaj tjedan',
                  '$myWeeklyMinutes min',
                  Icons.calendar_view_week_rounded,
                  Colors.white.withValues(alpha: 0.9),
                  AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Prosek',
                  '$averageDaily min/dan',
                  Icons.trending_up_rounded,
                  Colors.white.withValues(alpha: 0.9),
                  AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Streak',
                  '${model.consecutiveDays} dana',
                  Icons.local_fire_department_rounded,
                  Colors.white.withValues(alpha: 0.9),
                  const Color(0xFFFF3B30),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top 10 ovaj tjedan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D1D1F),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Najaktivniji slušaoci',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8E8E93),
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
          '${user['minutes']} min',
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser 
          ? AppTheme.primaryWithOpacity(0.1)
          : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser 
            ? AppTheme.primaryWithOpacity(0.3)
            : Colors.grey.shade200,
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ovaj tjedan',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user['minutes']} min',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              Text(
                '${(user['minutes'] / 7).round()} min/dan',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
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