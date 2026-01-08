import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../models/radio_player_model.dart';
import '../pages/favorites_page.dart';
import '../utils/text_formatting.dart';

class CurrentlyPlayingCard extends StatelessWidget {
  const CurrentlyPlayingCard({super.key, required this.model});
  final RadioPlayerModel model;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;
    
    return Consumer<RadioPlayerModel>(
      builder: (context, model, child) {
        // Format song and artist names
        final formattedInfo = TextFormatting.formatSongInfo(
          model.currentSong, 
          model.currentArtist,
        );
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode 
                ? AppTheme.cardBorder
                : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Trenutno svira',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? AppTheme.textSecondary : const Color(0xFF2D2D30),
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              
              // Song info and favorite button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedInfo['title'] ?? model.currentSong,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode ? AppTheme.textPrimary : const Color(0xFF1D1D1F),
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((formattedInfo['artist'] ?? model.currentArtist).isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            formattedInfo['artist'] ?? model.currentArtist,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? AppTheme.textSecondary : const Color(0xFF6D6D70),
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (formattedInfo['feat']?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF007AFF).withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'feat. ${formattedInfo['feat']}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Compact favorite button
                  Container(
                    decoration: BoxDecoration(
                      gradient: model.isFavorite(model.currentSongDisplay)
                        ? const LinearGradient(
                            colors: [Color(0xFFFF3B30), Color(0xFFFF6B6B)],
                          )
                        : LinearGradient(
                            colors: [
                              const Color(0xFF8E8E93).withValues(alpha: 0.1),
                              const Color(0xFF8E8E93).withValues(alpha: 0.05),
                            ],
                          ),
                      borderRadius: BorderRadius.circular(8),
                      border: model.isFavorite(model.currentSongDisplay) 
                        ? null
                        : Border.all(
                            color: const Color(0xFF8E8E93).withValues(alpha: 0.3),
                            width: 1,
                          ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => model.toggleFavorite(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                model.isFavorite(model.currentSongDisplay)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                                color: model.isFavorite(model.currentSongDisplay)
                                  ? Colors.white
                                  : isDarkMode ? AppTheme.textSecondary : const Color(0xFF6D6D70),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                model.isFavorite(model.currentSongDisplay)
                                  ? 'Ukloni iz omiljenih'
                                  : 'Dodaj u omiljene',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: model.isFavorite(model.currentSongDisplay)
                                    ? Colors.white
                                    : const Color(0xFF6D6D70),
                                  letterSpacing: -0.1,
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
              
              // View favorites button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF8E8E93).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF8E8E93).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FavoritesPage(),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.playlist_play_rounded,
                            color: Color(0xFF6D6D70),
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Pogledaj omiljene',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6D6D70),
                              letterSpacing: -0.1,
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
        );
      },
    );
  }
}