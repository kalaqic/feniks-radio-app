import 'package:flutter/material.dart';

import '../config/routes.dart';
import '../theme/app_theme.dart';
import 'footer_button.dart';

class CommonFooter extends StatelessWidget {
  final String currentRoute;
  final bool isDark;

  const CommonFooter({
    super.key,
    required this.currentRoute,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 105,
      decoration: BoxDecoration(
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
                isActive: currentRoute == Routes.home,
                isDark: isDark,
                onTap: () {
                  if (currentRoute != Routes.home) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      Routes.home,
                      (route) => false,
                    );
                  }
                },
              ),
              FooterButton(
                icon: Icons.leaderboard_rounded,
                label: 'Ljestvica',
                isActive: currentRoute == Routes.leaderboard,
                isDark: isDark,
                onTap: () {
                  if (currentRoute != Routes.leaderboard) {
                    Navigator.pushNamed(context, Routes.leaderboard);
                  }
                },
              ),
              FooterButton(
                icon: Icons.person_outline_rounded,
                label: 'Moj profil',
                isActive: currentRoute == Routes.profile,
                isDark: isDark,
                onTap: () {
                  if (currentRoute != Routes.profile) {
                    Navigator.pushNamed(context, Routes.profile);
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
