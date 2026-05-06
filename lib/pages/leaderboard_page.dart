import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/radio_player_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/common_footer.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

const _avatars = ['🎵', '🎧', '🎼', '🎤', '🎸', '🥁', '🎹', '🎺', '🎻', '🪕'];

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<Map<String, dynamic>> _leaderboard = [];
  int? _myRank;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final top = await FirestoreService.instance.getLeaderboardTop(limit: 10);
      final auth = context.read<AuthService>();
      final model = context.read<RadioPlayerModel>();
      int? myRank;
      if (auth.isAuthenticated && auth.user != null) {
        myRank = await FirestoreService.instance.getMyRank(model.totalFeniksPoints);
      }
      if (mounted) {
        setState(() {
          _leaderboard = top;
          _myRank = myRank;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Greška pri učitavanju. Povucite za osvježavanje.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<RadioPlayerModel>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
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
          child: RefreshIndicator(
            onRefresh: _loadLeaderboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
      ),
      bottomNavigationBar: CommonFooter(currentRoute: '/leaderboard', isDark: isDarkMode),
    );
  }

  Widget _buildPersonalPointsSection(RadioPlayerModel model) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;
    final myRank = _myRank;
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
              if (myRank != null)
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
          // Breakdown: badges earned, badge points, minutes listened, listening points
          Row(
            children: [
              Expanded(
                child: _buildPointsCard(
                  'Značke (broj)',
                  '${model.earnedBadges.length}',
                  Icons.military_tech_rounded,
                  Colors.white.withValues(alpha: 0.9),
                  const Color(0xFFFFD700),
                  isDarkMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPointsCard(
                  'Poeni od znački',
                  '${model.badgePoints}',
                  Icons.star_rounded,
                  Colors.white.withValues(alpha: 0.9),
                  const Color(0xFFFFD700),
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
                  'Minuta slušanja',
                  '${model.totalListeningMinutes}',
                  Icons.headphones_rounded,
                  Colors.white.withValues(alpha: 0.9),
                  AppTheme.primary,
                  isDarkMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPointsCard(
                  'Poeni od slušanja',
                  '${model.listeningPoints}',
                  Icons.graphic_eq_rounded,
                  Colors.white.withValues(alpha: 0.9),
                  AppTheme.primary,
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
                    const SizedBox(height: 4),
                    Text(
                      'Top 10 slušalaca objavljuje se na kraju mjeseca.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? AppTheme.textMuted : const Color(0xFF8E8E93),
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ljestvica će biti ažurirana u sljedećem ažuriranju.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? AppTheme.textMuted : const Color(0xFF8E8E93),
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _error!,
                style: TextStyle(
                  color: isDarkMode ? AppTheme.textSecondary : Colors.grey.shade600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else if (_leaderboard.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Još nema podataka. Budite prvi na ljestvici!',
                style: TextStyle(
                  color: isDarkMode ? AppTheme.textSecondary : Colors.grey.shade600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            if (_leaderboard.length >= 3) _buildTopThreePodium(),
            if (_leaderboard.length > 3) const SizedBox(height: 24),
            ...List.generate(
              _leaderboard.length > 3 ? _leaderboard.length - 3 : 0,
              (index) {
                final user = _leaderboard[index + 3];
                final auth = context.read<AuthService>();
                final isCurrentUser = auth.isAuthenticated &&
                    auth.user != null &&
                    user['uid'] == auth.user!.uid;
                return _buildLeaderboardItem(user, isCurrentUser);
              },
            ),
          ],
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
              _avatars[(place - 1) % _avatars.length],
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          ((user['name'] as String?) ?? 'Anonim').split(' ').first,
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
                _avatars[(((user['rank'] as int?) ?? 1) - 1) % _avatars.length],
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
                  user['name'] as String? ?? 'Anonim',
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