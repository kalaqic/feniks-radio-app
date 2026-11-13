import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final c in [_currentController, _newController, _confirmController]) {
      c.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await context.read<AuthService>().changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );
    if (!mounted) return;
    Haptics.play(error == null ? Haptic.success : Haptic.warning);
    setState(() {
      _saving = false;
      _error = error;
      _done = error == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final current = _currentController.text;
    final next = _newController.text;
    final checks = [
      ('Nova lozinka ima najmanje 6 znakova', next.length >= 6),
      (
        'Nova lozinka je drugačija od trenutne',
        next.isNotEmpty && next != current,
      ),
      (
        'Nove lozinke se poklapaju',
        next.isNotEmpty && next == _confirmController.text,
      ),
    ];
    final ready = current.isNotEmpty && checks.every((c) => c.$2);

    return StripedPage(
      top: 12,
      gap: 22,
      children: [
        const FadeSlideIn(child: BackLink('Nazad na profil')),
        const FadeSlideIn(
          delay: Duration(milliseconds: 40),
          child: PageTitle('Promjena lozinke'),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: .94, end: 1.0).animate(animation),
              child: child,
            ),
          ),
          child: _done
              ? _Success(onBack: () => Navigator.pop(context))
              : FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          color: colors.surface,
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              LabeledField(
                                label: 'Trenutna lozinka',
                                controller: _currentController,
                                obscureText: true,
                                textInputAction: TextInputAction.next,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Unesite trenutnu lozinku'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              LabeledField(
                                label: 'Nova lozinka',
                                controller: _newController,
                                obscureText: true,
                                textInputAction: TextInputAction.next,
                                validator: (v) {
                                  if (v == null || v.length < 6) {
                                    return 'Najmanje 6 karaktera';
                                  }
                                  if (v == current) {
                                    return 'Nova lozinka mora biti drugačija';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              LabeledField(
                                label: 'Ponovi novu lozinku',
                                controller: _confirmController,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                                validator: (v) => v != next
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
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _error!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.raspberry,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        PillButton(
                          label: _saving ? 'Čuvam…' : 'Sačuvaj novu lozinku',
                          height: 54,
                          fontSize: 16,
                          loading: _saving,
                          faded: !ready,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

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
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: ok ? colors.ink : colors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Success extends StatelessWidget {
  const _Success({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('done'),
      color: AppTheme.blue,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: .4, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, s, child) =>
                Transform.scale(scale: s, child: child),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppTheme.ink,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Lozinka je promijenjena',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Sljedeći put se prijavljuješ novom lozinkom.',
            style: TextStyle(fontSize: 15, height: 1.55, color: AppTheme.ink),
          ),
          const SizedBox(height: 16),
          TextLink(
            'Nazad na profil',
            color: AppTheme.ink,
            fontSize: 15,
            padding: EdgeInsets.zero,
            onTap: onBack,
          ),
        ],
      ),
    );
  }
}
