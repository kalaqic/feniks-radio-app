import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../widgets/ui.dart';
import 'admin_dashboard_page.dart';
import 'admin_data.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Same theme and shared widgets as the app; they read the colors from
    // a ThemeProvider.
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MaterialApp(
        title: 'Feniks Admin',
        debugShowCheckedModeBanner: false,
        theme: ThemeProvider.lightTheme,
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AdminLoading();
        }
        final user = snapshot.data;
        if (user == null) return const AdminLoginPage();
        return FutureBuilder<bool>(
          key: ValueKey(user.uid),
          future: AdminRepository().isAdmin(user.uid),
          builder: (context, admin) {
            if (admin.connectionState != ConnectionState.done) {
              return const AdminLoading();
            }
            if (admin.data == true) return const AdminDashboardPage();
            return const _NotAdmin();
          },
        );
      },
    );
  }
}

/// Bouncing equalizer bars while something loads.
class AdminLoading extends StatelessWidget {
  const AdminLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EqualizerBars(
              active: true,
              height: 28,
              color: AppTheme.raspberry,
            ),
            const SizedBox(height: 14),
            Text(
              'Učitavanje…',
              style: TextStyle(fontSize: 13, color: colors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// White card in the middle of the screen with the brand stripe on top.
class _CenterCard extends StatelessWidget {
  const _CenterCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FadeSlideIn(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                color: colors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BrandStripe(height: 6),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: children,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotAdmin extends StatelessWidget {
  const _NotAdmin();

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return _CenterCard(
      children: [
        const Icon(Icons.lock_outline_rounded, size: 36, color: AppTheme.coral),
        const SizedBox(height: 18),
        const PageTitle('Nema pristupa', fontSize: 28),
        const SizedBox(height: 10),
        Text(
          'Ovaj nalog nema admin pristup. Prijavi se nalogom koji je dodan u '
          'listu admina.',
          style: TextStyle(fontSize: 15, height: 1.55, color: colors.text),
        ),
        const SizedBox(height: 24),
        PillButton(
          label: 'Odjavi se',
          style: PillStyle.outline,
          onPressed: () => FirebaseAuth.instance.signOut(),
        ),
      ],
    );
  }
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final email = await FirestoreService.instance.getEmailByUsername(
        _username.text,
      );
      if (email == null) throw FirebaseAuthException(code: 'user-not-found');
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _password.text,
      );
    } on FirebaseAuthException {
      _error = 'Pogrešno korisničko ime ili lozinka.';
    } catch (_) {
      _error = 'Prijava nije uspjela. Provjeri internet konekciju.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return _CenterCard(
      children: [
        Center(
          child: Image.asset(
            'lib/assets/png/horizontal_logo.png',
            width: 150,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 28),
        const PageTitle('Admin', fontSize: 30),
        const SizedBox(height: 6),
        Text(
          'Statistika slušanja Feniks Radija.',
          style: TextStyle(fontSize: 14, color: colors.muted),
        ),
        const SizedBox(height: 26),
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledField(
                label: 'Korisničko ime',
                controller: _username,
                autofillHints: const [AutofillHints.username],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              LabeledField(
                label: 'Lozinka',
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _signIn(),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: _error == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.raspberry,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 26),
        PillButton(label: 'Prijavi se', loading: _busy, onPressed: _signIn),
      ],
    );
  }
}
