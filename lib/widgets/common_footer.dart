import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'footer_button.dart';

class CommonFooter extends StatelessWidget {
  final String currentRoute;
  final bool isDark;
  
  const CommonFooter({super.key, required this.currentRoute, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 105,
      decoration: BoxDecoration(
        color: isDark 
          ? Colors.black.withValues(alpha: 0.8)
          : Colors.white.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: isDark 
              ? AppTheme.primaryWithOpacity(0.3)
              : const Color(0xFFE5E5E7),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FooterButton(
                icon: Icons.home_filled,
                label: 'Početna',
                isActive: currentRoute == '/home',
                isDark: isDark,
                onTap: () {
                  if (currentRoute != '/home') {
                    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                  }
                },
              ),
              FooterButton(
                icon: Icons.leaderboard_outlined,
                label: 'Leaderboard',
                isActive: currentRoute == '/leaderboard',
                isDark: isDark,
                onTap: () {
                  if (currentRoute != '/leaderboard') {
                    Navigator.pushNamed(context, '/leaderboard');
                  }
                },
              ),
              FooterButton(
                icon: Icons.dynamic_feed_rounded,
                label: 'Feed',
                isActive: currentRoute == '/feed',
                isDark: isDark,
                onTap: () {
                  if (currentRoute != '/feed') {
                    Navigator.pushNamed(context, '/feed');
                  }
                },
              ),
              FooterButton(
                icon: Icons.settings_outlined,
                label: 'Postavke',
                isActive: currentRoute == '/settings',
                isDark: isDark,
                onTap: () {
                  if (currentRoute != '/settings') {
                    Navigator.pushNamed(context, '/settings');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}