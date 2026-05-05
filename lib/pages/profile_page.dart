import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/radio_player_model.dart';
import '../widgets/common_footer.dart';

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
      final email = await FirestoreService.instance.getUserDisplayEmail(auth.user!.uid);
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
    } catch (_) {}
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
      backgroundColor: isDarkMode ? AppTheme.background : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          'Moj profil',
          style: TextStyle(
            color: isDarkMode ? Colors.white : null,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: isDarkMode ? Colors.transparent : null,
        elevation: isDarkMode ? 0 : null,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: isDarkMode ? Colors.white : null,
              size: 24,
            ),
            onPressed: () {
              model.trackPageVisit('/settings');
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode
              ? AppTheme.backgroundGradient
              : const LinearGradient(
                  colors: [Color(0xFFF2F2F7), Color(0xFFFFFFFF)],
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
                if (auth.isAuthenticated && auth.user != null) ...[
                  _buildProfileCard(context, auth, model, isDarkMode),
                  const SizedBox(height: 16),
                  _buildEmailSection(context, auth, isDarkMode),
                  const SizedBox(height: 24),
                  _buildPointsCard(context, model, isDarkMode),
                  const SizedBox(height: 32),
                  _buildLogoutButton(context, auth, isDarkMode),
                ] else ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 64,
                            color: isDarkMode ? AppTheme.textSecondary : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Prijavite se da biste vidjeli profil',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? AppTheme.textSecondary : Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, '/login'),
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
      ),
      bottomNavigationBar: CommonFooter(currentRoute: '/profile', isDark: isDarkMode),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    AuthService auth,
    RadioPlayerModel model,
    bool isDarkMode,
  ) {
    final displayName = auth.user?.displayName ?? 'Korisnik';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.cardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black26 : Colors.black12,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDarkMode ? AppTheme.cardBorder : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
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
                        color: isDarkMode ? AppTheme.textPrimary : const Color(0xFF1D1D1F),
                      ),
                    ),
                    if (_displayEmail != null && _displayEmail!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _displayEmail!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode ? AppTheme.textSecondary : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSection(BuildContext context, AuthService auth, bool isDarkMode) {
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
                colors: [
                  Color(0xFFFFF8F5),
                  Color(0xFFF5F0FF),
                ],
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
            color: (isDarkMode ? Colors.black : AppTheme.primary).withValues(alpha: isDarkMode ? 0.2 : 0.06),
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
              Text(
                '💜',
                style: TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ostanimo u kontaktu!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? AppTheme.textPrimary : const Color(0xFF2D1B4E),
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
              color: isDarkMode ? AppTheme.textSecondary : const Color(0xFF5C4D6B),
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
                color: isDarkMode ? AppTheme.textSecondary : const Color(0xFF8B7B9A),
              ),
              hintStyle: TextStyle(
                fontSize: 14,
                color: isDarkMode ? AppTheme.textSecondary : Colors.grey.shade500,
              ),
              filled: true,
              fillColor: isDarkMode ? AppTheme.backgroundMedium : Colors.white.withValues(alpha: 0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDarkMode ? AppTheme.cardBorder : const Color(0xFFE0D4E8),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDarkMode ? AppTheme.cardBorder : const Color(0xFFE0D4E8),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppTheme.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            style: TextStyle(
              fontSize: 15,
              color: isDarkMode ? AppTheme.textPrimary : const Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savingEmail
                  ? null
                  : () => _saveDisplayEmail(),
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
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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

  Widget _buildPointsCard(BuildContext context, RadioPlayerModel model, bool isDarkMode) {
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
              Icon(Icons.emoji_events_rounded, color: Colors.white.withValues(alpha: 0.9), size: 28),
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

  Widget _buildLogoutButton(BuildContext context, AuthService authService, bool isDarkMode) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
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
                content: const Text('Da li ste sigurni da želite da se odjavite?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Otkaži'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Odjavi se'),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
