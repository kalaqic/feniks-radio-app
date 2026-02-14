import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _showRegisterForm = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      if (auth.isAuthenticated && mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Firebase requires email; we generate one so user only enters name + password.
  String _generateEmail(String name) {
    final safe = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return 'feniks_${safe}_${DateTime.now().millisecondsSinceEpoch}@feniks.app';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleCreateAccount() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Molimo popunite sva polja ispravno.');
      return;
    }

    final name = _nameController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty) {
      _showError('Unesite korisničko ime.');
      return;
    }

    final taken = await FirestoreService.instance.isUsernameTaken(name);
    if (taken && mounted) {
      _showError('Korisničko ime je već zauzeto.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final email = _generateEmail(name);
      final success = await authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: name,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        final uid = authService.user?.uid;
        if (uid != null) {
          try {
            await FirestoreService.instance.createOrUpdateUser(uid, name, email: email);
          } on UsernameTakenException {
            if (mounted) _showError('Korisničko ime je već zauzeto.');
            return;
          }
        }
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } else {
        _showError(authService.errorMessage ?? 'Greška pri kreiranju naloga. Pokušajte ponovo.');
      }
    } on UsernameTakenException {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Korisničko ime je već zauzeto.');
      }
    } catch (e, stack) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Greška: $e');
      }
      if (kDebugMode) debugPrint('WelcomePage _handleCreateAccount error: $e\n$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'lib/assets/png/background_decoration.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: _showRegisterForm ? _buildRegisterForm(isDarkMode) : _buildWelcome(isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Image.asset(
            'lib/assets/png/horizontal_logo.png',
            height: 80,
            fit: BoxFit.contain,
          ),
          const Spacer(flex: 2),
          // Red button: Napravi svoj račun
          SizedBox(
            width: double.infinity,
            height: 56,
            child: Material(
              color: Colors.red,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _showRegisterForm = true),
                child: const Center(
                  child: Text(
                    'Napravi svoj račun',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: Text(
              'Već imate račun? Prijavite se',
              style: TextStyle(
                fontSize: 15,
                color: isDarkMode ? AppTheme.primaryLight : AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  InputDecoration _loginStyleDecoration(String label, {Widget? suffixIcon}) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;
    return InputDecoration(
      labelText: label,
      prefixIcon: label == 'Korisničko ime'
          ? const Icon(Icons.person_outline)
          : const Icon(Icons.lock_outline),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDarkMode ? AppTheme.cardBackground : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDarkMode ? AppTheme.cardBorder : Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDarkMode ? AppTheme.cardBorder : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppTheme.primary,
          width: 2,
        ),
      ),
    );
  }

  Widget _buildRegisterForm(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            IconButton(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.chevron_left,
                color: isDarkMode ? Colors.white : AppTheme.primary,
                size: 32,
              ),
              onPressed: () => setState(() => _showRegisterForm = false),
            ),
            const SizedBox(height: 8),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryWithOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.radio,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Napravi račun',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? AppTheme.textPrimary : const Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Unesite korisničko ime i lozinku',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? AppTheme.textSecondary : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
              ],
              decoration: _loginStyleDecoration('Korisničko ime'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Molimo unesite korisničko ime';
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
                  return 'Samo slova, brojeve i _ (bez razmaka ili specijalnih znakova)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: _loginStyleDecoration('Lozinka').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Molimo unesite lozinku';
                if (v.length < 6) return 'Lozinka mora imati najmanje 6 karaktera';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: _loginStyleDecoration('Potvrdi lozinku').copyWith(
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) {
                if (v != _passwordController.text) return 'Lozinke se ne poklapaju';
                return null;
              },
            ),
            const SizedBox(height: 24),
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryWithOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _isLoading ? null : () => _handleCreateAccount(),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Kreiraj račun',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Već imate račun? ',
                  style: TextStyle(
                    color: isDarkMode ? AppTheme.textSecondary : Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text(
                    'Prijavite se',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
