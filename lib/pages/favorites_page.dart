import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../models/radio_player_model.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../widgets/common_footer.dart';
import '../widgets/login_required_dialog.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RadioPlayerModel>().trackPageVisit(Routes.favorites);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<RadioPlayerModel>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;
    final favoriteSongs = model.favoriteSongs;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Omiljene Pjesme'),
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
      ),
      body: SafeArea(
        child: favoriteSongs.isEmpty
            ? _buildEmptyState(isDarkMode)
            : _buildFavoritesList(favoriteSongs, model, isDarkMode),
      ),
      bottomNavigationBar: CommonFooter(
        currentRoute: Routes.favorites,
        isDark: isDarkMode,
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.of(isDarkMode).surface,
                shape: BoxShape.circle,
                border: isDarkMode
                    ? Border.all(color: AppTheme.cardBorder)
                    : null,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 60,
                color: AppColors.of(isDarkMode).mutedText,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nema omiljenih pjesama',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? AppTheme.textPrimary : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dodajte pjesme u omiljene tokom slušanja Feniks Radija',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.of(isDarkMode).mutedText,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(
    List<String> favoriteSongs,
    RadioPlayerModel model,
    bool isDarkMode,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: favoriteSongs.length,
      itemBuilder: (context, index) {
        final song = favoriteSongs[index];
        final parts = song.split(' - ');
        final title = parts.isNotEmpty ? parts[0] : song;
        final artist = parts.length > 1 ? parts[1] : 'Nepoznat izvođač';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: isDarkMode
                ? LinearGradient(
                    colors: [
                      AppTheme.cardBackground,
                      AppTheme.backgroundMedium.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.of(isDarkMode).shadow,
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: AppColors.of(isDarkMode).border,
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () =>
                  _showSongDetails(title, artist, song, model, isDarkMode),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    // Music Note Icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryWithOpacity(0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.music_note_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Song Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.of(isDarkMode).primaryText,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            artist,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.of(isDarkMode).secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Remove from favorites button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.red.withValues(alpha: 0.15)
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.red.withValues(alpha: 0.25)
                              : Colors.red.shade100,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            final authService = context.read<AuthService>();
                            if (!authService.isAuthenticated) {
                              LoginRequiredDialog.show(
                                context,
                                'brisanje omiljenih pjesama',
                              );
                              return;
                            }
                            _removeFavorite(song, model);
                          },
                          child: Icon(
                            Icons.favorite,
                            color: Colors.red.shade400,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSongDetails(
    String title,
    String artist,
    String fullSong,
    RadioPlayerModel model,
    bool isDarkMode,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.of(isDarkMode).card,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: isDarkMode ? Border.all(color: AppTheme.cardBorder) : null,
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppTheme.textSecondary
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Large Music Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryWithOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),

            // Song Title
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.of(isDarkMode).primaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Artist
            Text(
              artist,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.of(isDarkMode).secondaryText,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200, width: 1),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          final authService = context.read<AuthService>();
                          if (!authService.isAuthenticated) {
                            Navigator.pop(context); // Close dialog first
                            LoginRequiredDialog.show(
                              context,
                              'brisanje omiljenih pjesama',
                            );
                            return;
                          }
                          _removeFavorite(fullSong, model);
                          Navigator.pop(context);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.heart_broken_rounded,
                              color: Colors.red.shade600,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ukloni iz omiljenih',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _removeFavorite(String song, RadioPlayerModel model) {
    model.removeFavorite(song);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.heart_broken_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Uklonjeno iz omiljenih'),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
