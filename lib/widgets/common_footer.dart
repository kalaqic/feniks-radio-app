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
        // Solid, so the background circles never show through the footer.
        color: isDark ? const Color(0xFF0B0B0F) : Colors.white,
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
                icon: Icons.leaderboard_rounded,
                label: 'Ljestvica',
                isActive: currentRoute == '/leaderboard',
                isDark: isDark,
                onTap: () {
                  if (currentRoute != '/leaderboard') {
                    Navigator.pushNamed(context, '/leaderboard');
                  }
                },
              ),
              FooterButton(
                icon: Icons.person_outline_rounded,
                label: 'Moj profil',
                isActive: currentRoute == '/profile',
                isDark: isDark,
                onTap: () {
                  if (currentRoute != '/profile') {
                    Navigator.pushNamed(context, '/profile');
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