import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/log.dart';
import '../widgets/ui.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _nameController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      c.addListener(_refresh);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      if (auth.isAuthenticated && mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.home,
          (route) => false,
        );
      }
    });
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _generateEmail(String name) {
    final safe = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return 'feniks_${safe}_${DateTime.now().millisecondsSinceEpoch}@feniks.app';
  }

  void _showError(String message) {
    if (!mounted) return;
    Haptics.play(Haptic.warning);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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

    final authService = context.read<AuthService>();
    final taken = await FirestoreService.instance.isUsernameTaken(name);
    if (!mounted) return;
    if (taken) {
      _showError('Korisničko ime je već zauzeto.');
      return;
    }

    setState(() => _isLoading = true);

    try {
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
            await FirestoreService.instance.createOrUpdateUser(
              uid,
              name,
              email: email,
            );
          } on UsernameTakenException {
            try {
              await authService.user?.delete();
            } catch (e) {
              logError('Deleting half-created account', e);
            }
            await authService.signOut();
            if (mounted) _showError('Korisničko ime je već zauzeto.');
            return;
          }
        }
        if (mounted) {
          unawaited(
            Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.home,
              (route) => false,
            ),
          );
        }
      } else {
        _showError(
          authService.errorMessage ??
              'Greška pri kreiranju naloga. Pokušajte ponovo.',
        );
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
      if (kDebugMode) {
        debugPrint('WelcomePage _handleCreateAccount error: $e\n$stack');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final name = _nameController.text.trim();
    final password = _passwordController.text;
    final checks = [
      (
        'Korisničko ime od najmanje 3 slova, brojeva ili _',
        RegExp(r'^[a-zA-Z0-9_]{3,}$').hasMatch(name),
      ),
      ('Lozinka od najmanje 6 znakova', password.length >= 6),
      (
        'Lozinke se poklapaju',
        password.isNotEmpty && password == _confirmPasswordController.text,
      ),
    ];
    final ready = checks.every((c) => c.$2);

    return Form(
      key: _formKey,
      child: StripedPage(
        top: 24,
        horizontal: 28,
        gap: 28,
        children: [
          FadeSlideIn(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'lib/assets/png/horizontal_logo.png',
                width: 96,
              ),
            ),
          ),
          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageTitle('Napravi nalog'),
                const SizedBox(height: 8),
                Text(
                  'Treba ti samo korisničko ime i lozinka.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.55,
                    color: colors.text,
                  ),
                ),
              ],
            ),
          ),
          FadeSlideIn(
            delay: const Duration(milliseconds: 160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabeledField(
                  label: 'Korisničko ime',
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newUsername],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                    LengthLimitingTextInputFormatter(20),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Molimo unesite korisničko ime';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
                      return 'Samo slova, brojevi i _';
                    }
                    if (v.trim().length < 3) {
                      return 'Najmanje 3 karaktera';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),
                LabeledField(
                  label: 'Lozinka',
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Molimo unesite lozinku';
                    }
                    if (v.length < 6) return 'Najmanje 6 karaktera';
                    return null;
                  },
                ),
                const SizedBox(height: 22),
                LabeledField(
                  label: 'Ponovi lozinku',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: (_) => _isLoading ? null : _handleCreateAccount(),
                  validator: (v) => v != _passwordController.text
                      ? 'Lozinke se ne poklapaju'
                      : null,
                ),
                const SizedBox(height: 20),
                for (final (i, (label, ok)) in checks.indexed) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _Check(label: label, ok: ok),
                ],
              ],
            ),
          ),
          FadeSlideIn(
            delay: const Duration(milliseconds: 240),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
              children: [
                PillButton(
                  label: 'Napravi nalog',
                  height: 54,
                  fontSize: 16,
                  loading: _isLoading,
                  faded: !ready,
                  onPressed: _handleCreateAccount,
                ),
                const SizedBox(height: 18),
                TextLink(
                  'Već imaš nalog? Prijavi se',
                  padding: EdgeInsets.zero,
                  onTap: () => Navigator.pushNamed(context, Routes.login),
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One rule under the registration form; turns blue when it is met.
class _Check extends StatelessWidget {
  const _Check({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return Padding(
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          AnimatedScale(
            scale: ok ? 1 : .85,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: ok ? AppTheme.blue : colors.track,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 11, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: ok ? colors.ink : colors.muted,
              ),
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}
