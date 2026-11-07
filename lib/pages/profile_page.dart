import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../models/radio_player_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../utils/log.dart';
import '../widgets/app_card.dart';
import '../widgets/common_footer.dart';
import '../widgets/gradient_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _displayEmail;
  final _emailController = TextEditingController();
  bool _savingEmail = false;

  @override
  void initState() {
    super.initState();
    _loadDisplayEmail();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RadioPlayerModel>().trackPageVisit(Routes.profile);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadDisplayEmail() async {
    final auth = context.read<AuthService>();
    if (auth.user?.uid == null) return;
    try {
      final email = await FirestoreService.instance.getUserDisplayEmail(
        auth.user!.uid,
      );
      if (mounted) {
        setState(() {
          _displayEmail = email;
          if (email != null) _emailController.text = email;
        });
      }
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') return;
      if (mounted) {
        setState(() {
          _displayEmail = null;
        });
      }
    } catch (e) {
      logError('Loading display email', e);
    }
  }

  Future<void> _saveDisplayEmail() async {
    final auth = context.read<AuthService>();
    if (auth.user?.uid == null) return;
    setState(() => _savingEmail = true);
    final value = _emailController.text.trim();
    try {
      await FirestoreService.instance.setUserDisplayEmail(
        auth.user!.uid,
        value.isEmpty ? null : value,
      );
      if (mounted) {
        setState(() {
          _displayEmail = value.isEmpty ? null : value;
          _savingEmail = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value.isEmpty ? 'Email uklonjen.' : 'Email sačuvan.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() => _savingEmail = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'permission-denied'
                  ? 'Nemate dozvolu za ovu radnju (Firestore pravila).'
                  : 'Greška pri čuvanju emaila.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _savingEmail = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<RadioPlayerModel>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;
    final auth = context.watch<AuthService>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Moj profil'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              if (auth.isAuthenticated && auth.user != null) ...[
                _buildProfileCard(context, auth, model, isDarkMode),
                const SizedBox(height: 16),
                _buildEmailSection(context, auth, isDarkMode),
                const SizedBox(height: 24),
                _buildPointsCard(context, model, isDarkMode),
                const SizedBox(height: 32),
                _buildLogoutButton(context, auth, isDarkMode),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => _confirmDeleteAccount(context, auth),
                    child: Text(
                      'Obriši nalog',
                      style: TextStyle(
                        color: AppColors.of(isDarkMode).secondaryText,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 64,
                          color: AppColors.of(isDarkMode).mutedText,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Prijavite se da biste vidjeli profil',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.of(isDarkMode).secondaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, Routes.login),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Prijavi se'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CommonFooter(
        currentRoute: Routes.profile,
        isDark: isDarkMode,
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    AuthService auth,
    RadioPlayerModel model,
    bool isDarkMode,
  ) {
    final displayName = auth.user?.displayName ?? 'Korisnik';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.of(isDarkMode).primaryText,
                      ),
                    ),
                    if (_displayEmail != null && _displayEmail!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _displayEmail!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.of(isDarkMode).secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.settings_rounded,
                  size: 22,
                  color: isDarkMode
                      ? AppTheme.textPrimary
                      : const Color(0xFF4B5563),
                ),
                tooltip: 'Postavke',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: () {
                  Navigator.pushNamed(context, Routes.settings);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSection(
    BuildContext context,
    AuthService auth,
    bool isDarkMode,
  ) {
    if (auth.user?.uid == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: isDarkMode
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.cardBackground,
                  AppTheme.primaryWithOpacity(0.08),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF8F5), Color(0xFFF5F0FF)],
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? AppTheme.primaryWithOpacity(0.25)
              : const Color(0xFFE8D5F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? Colors.black : AppTheme.primary).withValues(
              alpha: isDarkMode ? 0.2 : 0.06,
            ),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💜', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ostanimo u kontaktu!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode
                        ? AppTheme.textPrimary
                        : const Color(0xFF2D1B4E),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Dajte nam svoj email da vas prvi obavijestimo o novostima, specijalnim emisijama i svemu što se dešava na Feniks radiju! ✨📻',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: isDarkMode
                  ? AppTheme.textSecondary
                  : const Color(0xFF5C4D6B),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: 'vas@email.com',
              prefixIcon: Icon(
                Icons.mail_outline_rounded,
                size: 22,
                color: isDarkMode
                    ? AppTheme.textSecondary
                    : const Color(0xFF8B7B9A),
              ),
              hintStyle: TextStyle(
                fontSize: 14,
                color: AppColors.of(isDarkMode).mutedText,
              ),
              filled: true,
              fillColor: isDarkMode
                  ? AppTheme.backgroundMedium
                  : Colors.white.withValues(alpha: 0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDarkMode
                      ? AppTheme.cardBorder
                      : const Color(0xFFE0D4E8),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDarkMode
                      ? AppTheme.cardBorder
                      : const Color(0xFFE0D4E8),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.of(isDarkMode).primaryText,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savingEmail ? null : _saveDisplayEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _savingEmail
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('✨', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 8),
                        Text('Sačuvaj i budi u toku'),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard(
    BuildContext context,
    RadioPlayerModel model,
    bool isDarkMode,
  ) {
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Moji Feniks Poeni',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${model.totalFeniksPoints} poena',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    AuthService auth,
  ) async {
    final passwordController = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obriši nalog'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nalog, poeni, značke i omiljene pjesme biće trajno obrisani. '
              'Ovo se ne može poništiti.\n\nZa potvrdu unesite lozinku:',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Lozinka'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Otkaži'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, passwordController.text),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Obriši zauvijek'),
          ),
        ],
      ),
    );
    if (password == null || password.isEmpty || !context.mounted) return;

    final model = context.read<RadioPlayerModel>();

    model.resetProgress();
    await model.waitForPendingSync();
    final error = await auth.deleteAccount(password);
    if (error != null) {
      final uid = auth.user?.uid;
      if (uid != null) {
        try {
          final data = await FirestoreService.instance.loadUserAchievements(
            uid,
          );
          model.loadUserProgress(uid, data);
        } catch (e) {
          logError('Restoring progress after a failed deletion', e);
        }
      }
    }
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nalog je obrisan.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    unawaited(
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.welcome,
        (route) => false,
      ),
    );
  }

  Widget _buildLogoutButton(
    BuildContext context,
    AuthService authService,
    bool isDarkMode,
  ) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Odjava'),
                content: const Text(
                  'Da li ste sigurni da želite da se odjavite?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Otkaži'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Odjavi se'),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              final model = context.read<RadioPlayerModel>();
              await model.syncNow().timeout(
                const Duration(seconds: 5),
                onTimeout: () {},
              );
              await model.waitForPendingSync();
              await authService.signOut();
              model.resetProgress();
              if (context.mounted) {
                unawaited(
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    Routes.login,
                    (route) => false,
                  ),
                );
              }
            }
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'Odjavi se',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
