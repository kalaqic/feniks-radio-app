import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/ui.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = await FirestoreService.instance.getEmailByUsername(
        _usernameController.text,
      );
      if (!mounted) return;
      if (email == null) {
        setState(() => _isLoading = false);
        _showError('Korisničko ime ili lozinka nisu ispravni.');
        return;
      }

      final authService = context.read<AuthService>();
      final success = await authService.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        unawaited(
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.home,
            (route) => false,
          ),
        );
      } else {
        _showError(
          authService.errorMessage ??
              'Korisničko ime ili lozinka nisu ispravni.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Greška pri prijavi. Pokušajte ponovo.');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    Haptics.play(Haptic.warning);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);

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
                const PageTitle('Prijavi se'),
                const SizedBox(height: 8),
                Text(
                  'Skupljaj poene, značke i omiljene pjesme na svom nalogu.',
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
              children: [
                LabeledField(
                  label: 'Korisničko ime',
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Molimo unesite korisničko ime';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),
                LabeledField(
                  label: 'Lozinka',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _isLoading ? null : _handleSubmit(),
                  trailing: _ShowToggle(
                    obscured: _obscurePassword,
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Molimo unesite lozinku';
                    }
                    if (value.length < 6) {
                      return 'Lozinka mora imati najmanje 6 karaktera';
                    }
                    return null;
                  },
                ),
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
                    label: 'Prijavi se',
                    height: 54,
                    fontSize: 16,
                    loading: _isLoading,
                    onPressed: _handleSubmit,
                  ),
                  const SizedBox(height: 18),
                  TextLink(
                    'Nemaš nalog? Napravi ga',
                    padding: EdgeInsets.zero,
                    onTap: () => Navigator.pushNamed(context, Routes.welcome),
                  ),
                  const SizedBox(height: 18),
                  TextLink(
                    'Nastavi slušati bez prijave',
                    muted: true,
                    fontSize: 13,
                    padding: EdgeInsets.zero,
                    onTap: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      Routes.home,
                      (route) => false,
                    ),
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

/// "Prikaži / Sakrij" next to a password field.
class _ShowToggle extends StatelessWidget {
  const _ShowToggle({required this.obscured, required this.onTap});

  final bool obscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          obscured ? 'Prikaži' : 'Sakrij',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: colors.ink,
            decoration: TextDecoration.underline,
            decorationColor: colors.ink,
          ),
        ),
      ),
    );
  }
}
