import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/radio_player_model.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import 'header_player.dart';

class HeaderWithVolume extends StatelessWidget implements PreferredSizeWidget {
  const HeaderWithVolume({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(250);

  @override
  Widget build(BuildContext context) {
    final model = context.watch<RadioPlayerModel>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;
    
    return Column(
      children: [
        HeaderPlayer(model: model),
        _buildVolumeSlider(context, model, isDarkMode),
      ],
    );
  }

  Widget _buildVolumeSlider(BuildContext context, RadioPlayerModel model, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        gradient: isDarkMode 
          ? LinearGradient(
              colors: [
                AppTheme.primaryDark.withValues(alpha: 0.8),
                AppTheme.primary.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : LinearGradient(
              colors: [
                AppTheme.primaryDark.withValues(alpha: 0.9),
                AppTheme.primary.withValues(alpha: 0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
              ? Colors.black.withValues(alpha: 0.3)
              : AppTheme.primary.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Icon(
              Icons.volume_up_outlined,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  trackHeight: 4,
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: model.volume,
                  onChanged: (value) => model.volume = value,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              alignment: Alignment.centerRight,
              child: Text(
                '${(model.volume * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}