import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/radio_player_model.dart';
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
                    context.read<RadioPlayerModel>().trackPageVisit('/home');
                    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                  }
                },
              ),
              FooterButton(
                icon: Icons.message_outlined,
                label: 'Muzička želja',
                isActive: currentRoute == '/ether-messages',
                isDark: isDark,
                onTap: () {
                  if (currentRoute != '/ether-messages') {
                    context.read<RadioPlayerModel>().trackPageVisit('/ether-messages');
                    Navigator.pushNamed(context, '/ether-messages');
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
                    context.read<RadioPlayerModel>().trackPageVisit('/profile');
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