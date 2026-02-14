import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/radio_player_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/common_footer.dart';
import '../widgets/achievement_modal.dart';
import '../theme/app_theme.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int? _myRank;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final model = context.read<RadioPlayerModel>();
      if (model.shouldShowAchievementModal) {
        _showAchievementModal();
      }
      _loadMyRank();
    });
  }

  Future<void> _loadMyRank() async {
    final auth = context.read<AuthService>();
    final model = context.read<RadioPlayerModel>();
    if (!auth.isAuthenticated || auth.user == null) return;
    final rank = await FirestoreService.instance.getMyRank(model.totalFeniksPoints);
    if (mounted) setState(() => _myRank = rank);
  }

  void _showAchievementModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AchievementModal(
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
    final averageDaily = totalWeeklyMinutes > 0 ? (totalWeeklyMinutes / 7).round() : 0;
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
              if (_myRank != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#$_myRank',
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      'Top 10 po Feniks poenima',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D1D1F),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Puna ljestvica na Leaderboard stranici',
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
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/leaderboard'),
              icon: const Icon(Icons.leaderboard_outlined, size: 20),
              label: const Text('Otvori Leaderboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}