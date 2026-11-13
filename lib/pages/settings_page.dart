import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../config/routes.dart';
import '../models/radio_player_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../utils/log.dart';
import '../widgets/ui.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RadioPlayerModel>().trackPageVisit(Routes.settings);
      }
    });
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final model = context.watch<RadioPlayerModel>();
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthService>();
    var delay = 0;
    Duration next() => Duration(milliseconds: delay += 40);

    return StripedPage(
      gap: 12,
      children: [
        const FadeSlideIn(child: BackLink('Nazad na profil')),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FadeSlideIn(delay: next(), child: const PageTitle('Postavke')),
        ),
        if (!auth.isAuthenticated)
          FadeSlideIn(delay: next(), child: const _SignInNotice()),
        FadeSlideIn(delay: next(), child: const SectionLabel('Izgled')),
        FadeSlideIn(
          delay: next(),
          child: _Block(
            children: [
              _SwitchRow(
                title: 'Tamni režim',
                subtitle: 'Lakše za oči tokom noći',
                value: themeProvider.isDarkMode,
                onChanged: themeProvider.toggleTheme,
              ),
            ],
          ),
        ),
        FadeSlideIn(
          delay: next(),
          child: const Padding(
            padding: EdgeInsets.only(top: 12),
            child: SectionLabel('Notifikacije'),
          ),
        ),
        FadeSlideIn(
          delay: next(),
          child: _Block(
            children: [
              _SwitchRow(
                title: 'Dnevni podsjetnik',
                subtitle: 'Jedna kratka poruka dnevno da se uključiš',
                value: model.notificationsEnabled,
                onChanged: (value) => _setNotificationsEnabled(model, value),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: model.notificationsEnabled
                    ? _TimeRow(
                        time:
                            '${_two(model.notificationHour)}:'
                            '${_two(model.notificationMinute)}',
                        onEarlier: () => _shiftReminder(model, -15),
                        onLater: () => _shiftReminder(model, 15),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
        FadeSlideIn(
          delay: next(),
          child: const Padding(
            padding: EdgeInsets.only(top: 12),
            child: SectionLabel('Audio'),
          ),
        ),
        FadeSlideIn(
          delay: next(),
          child: _Block(
            children: [
              _SwitchRow(
                title: 'Automatsko puštanje',
                subtitle: 'Radio kreće čim otvoriš aplikaciju',
                value: model.autoPlay,
                onChanged: (value) => model.autoPlay = value,
              ),
            ],
          ),
        ),
        FadeSlideIn(
          delay: next(),
          child: const Padding(
            padding: EdgeInsets.only(top: 12),
            child: SectionLabel('O aplikaciji'),
          ),
        ),
        FadeSlideIn(
          delay: next(),
          child: _Block(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Verzija',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: colors.ink,
                        ),
                      ),
                    ),
                    Text(
                      AppConfig.appVersion,
                      style: TextStyle(fontSize: 15, color: colors.muted),
                    ),
                  ],
                ),
              ),
              NavRow(
                label: 'Podrška putem emaila',
                onTap: _openEmailSupport,
              ),
              NavRow(
                label: 'Ostavi feedback ili predloži ideju',
                onTap: _openFeedbackEmail,
              ),
              NavRow(label: 'Uslovi korištenja', onTap: _showTermsOfService),
            ],
          ),
        ),
        if (auth.isAuthenticated) ...[
          FadeSlideIn(
            delay: next(),
            child: const Padding(
              padding: EdgeInsets.only(top: 12),
              child: SectionLabel('Nalog'),
            ),
          ),
          FadeSlideIn(
            delay: next(),
            child: _Block(
              children: [
                NavRow(
                  label: 'Promijeni lozinku',
                  showDivider: false,
                  onTap: () =>
                      Navigator.pushNamed(context, Routes.changePassword),
                ),
                _ActionRow(label: 'Odjavi se', onTap: () => _logout(auth)),
                _ActionRow(
                  label: 'Obriši nalog',
                  color: AppTheme.raspberry,
                  onTap: () => _confirmDeleteAccount(auth),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _logout(AuthService auth) async {
    final confirmed = await showAppDialog<bool>(
      context,
      builder: (dialogContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PageTitle('Odjava', fontSize: 28),
          const SizedBox(height: 12),
          Text(
            'Poeni i značke ostaju sačuvani na tvom nalogu.',
            style: TextStyle(
              fontSize: 16,
              height: 1.55,
              color: colorsOf(dialogContext).text,
            ),
          ),
          const SizedBox(height: 22),
          PillButton(
            label: 'Odjavi me',
            haptic: Haptic.medium,
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextLink(
              'Ostani prijavljen',
              onTap: () => Navigator.pop(dialogContext, false),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final model = context.read<RadioPlayerModel>();
    await model.syncNow().timeout(const Duration(seconds: 5), onTimeout: () {});
    await model.waitForPendingSync();
    await auth.signOut();
    model.resetProgress();
    if (mounted) {
      unawaited(
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.login,
          (route) => false,
        ),
      );
    }
  }

  Future<void> _confirmDeleteAccount(AuthService auth) async {
    // The dialog owns its text field, so the field is only disposed after
    // the closing animation has finished.
    final password = await showAppDialog<String>(
      context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (password == null || password.isEmpty || !mounted) return;

    final model = context.read<RadioPlayerModel>();
    final messenger = ScaffoldMessenger.of(context);

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
    if (!mounted) return;
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    messenger.showSnackBar(const SnackBar(content: Text('Nalog je obrisan.')));
    unawaited(
      Navigator.pushNamedAndRemoveUntil(context, Routes.home, (r) => false),
    );
  }


  Future<void> _shiftReminder(RadioPlayerModel model, int minutes) async {
    final total =
        (model.notificationHour * 60 + model.notificationMinute + minutes) %
        (24 * 60);
    model.setNotificationTime(total ~/ 60, total % 60);
    await _scheduleReminder(model);
  }

  Future<void> _scheduleReminder(RadioPlayerModel model) async {
    try {
      await NotificationService.instance.scheduleDailyReminders(
        hour: model.notificationHour,
        minute: model.notificationMinute,
      );
    } catch (_) {
      if (mounted) {
        _snack('Podsjetnik nije moguće podesiti na ovom uređaju.');
      }
    }
  }

  Future<void> _setNotificationsEnabled(
    RadioPlayerModel model,
    bool value,
  ) async {
    if (!value) {
      model.notificationsEnabled = false;
      await NotificationService.instance.cancelDailyReminders();
      if (mounted) _snack('Podsjetnik je isključen');
      return;
    }
    final granted = await NotificationService.instance.requestPermission();
    if (!mounted) return;
    if (!granted) {
      _snack(
        'Notifikacije su isključene u postavkama telefona. '
        'Uključite ih za Feniks Radio.',
      );
      return;
    }
    model.notificationsEnabled = true;
    await _scheduleReminder(model);
    if (mounted) {
      _snack(
        'Podsjetnik je uključen za ${_two(model.notificationHour)}:'
        '${_two(model.notificationMinute)}',
      );
    }
  }

  Future<void> _openFeedbackEmail() async {
    const subject = 'Feedback / prijedlog - Feniks Radio aplikacija';
    const body =
        'Zdravo Feniks ekipa,\n\n'
        'Šta mi se sviđa:\n\n\n'
        'Šta bih promijenio/la ili dodao/la:\n\n\n'
        '(Verzija aplikacije: ${AppConfig.appVersion})';
    final uri = Uri(
      scheme: 'mailto',
      path: AppConfig.supportEmail,
      query:
          'subject=${Uri.encodeComponent(subject)}'
          '&body=${Uri.encodeComponent(body)}',
    );
    bool opened;
    try {
      opened = await launchUrl(uri);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      _snack(
        'Nije pronađena aplikacija za email. '
        'Pišite nam na ${AppConfig.supportEmail}',
      );
    }
  }

  void _openEmailSupport() {
    final uri = Uri(
      scheme: 'mailto',
      path: AppConfig.supportEmail,
      query: 'subject=${Uri.encodeComponent('Podrška - Feniks Radio')}',
    );
    launchUrl(uri);
  }

  void _showTermsOfService() {
    showAppSheet<void>(
      context,
      builder: (sheetContext) {
        final colors = colorsOf(sheetContext);
        final style = TextStyle(fontSize: 15, height: 1.6, color: colors.text);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const PageTitle('Uslovi korištenja', fontSize: 26),
            const SizedBox(height: 14),
            Text(
              'Sav sadržaj u aplikaciji vlasništvo je Feniks Radija.',
              style: style,
            ),
            const SizedBox(height: 14),
            Text('Zabranjeno je restreamovanje programa.', style: style),
            const SizedBox(height: 14),
            Text(
              'Zabranjeno je kopiranje sadržaja u bilo kojem obliku.',
              style: style,
            ),
            const SizedBox(height: 24),
            PillButton(
              label: 'Razumijem, zatvori',
              onPressed: () => Navigator.pop(sheetContext),
            ),
          ],
        );
      },
    );
  }
}

/// Asks for the password before the account is deleted. Pops with the
/// password, or with nothing when cancelled.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const PageTitle('Obriši nalog', fontSize: 28),
        const SizedBox(height: 12),
        Text(
          'Nalog, poeni, značke i omiljene pjesme biće trajno obrisani. '
          'Ovo se ne može poništiti.',
          style: TextStyle(fontSize: 15, height: 1.55, color: colors.text),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _password,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Lozinka za potvrdu'),
        ),
        const SizedBox(height: 22),
        PillButton(
          label: 'Obriši nalog zauvijek',
          haptic: Haptic.heavy,
          onPressed: () => Navigator.pop(context, _password.text),
        ),
        const SizedBox(height: 6),
        Center(
          child: TextLink('Otkaži', onTap: () => Navigator.pop(context)),
        ),
      ],
    );
  }
}

/// Raspberry row for logged-out users: settings are kept only with an
/// account.
class _SignInNotice extends StatelessWidget {
  const _SignInNotice();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Postavke se ne čuvaju dok nisi prijavljen. Prijavi se.',
      child: Pressable(
        scale: .98,
        onTap: () => Navigator.pushNamed(context, Routes.login),
        child: Container(
          color: AppTheme.raspberry,
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
          child: const Row(
            children: [
              Icon(Icons.cloud_off_outlined, size: 22, color: Colors.white),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Postavke se ne čuvaju dok nisi prijavljen',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Prijavi se da ih sačuvaš',
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row inside a block that does something right here, without an arrow.
class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.label, required this.onTap, this.color});

  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Haptics.play(Haptic.selection);
          onTap();
        },
        highlightColor: colors.surfaceHover,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.divider)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: color ?? colors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorsOf(context).surface,
      child: Column(children: children),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: colors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FlatSwitch(value: value, onChanged: onChanged, label: title),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.time,
    required this.onEarlier,
    required this.onLater,
  });

  final String time;
  final VoidCallback onEarlier;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);

    Widget stepper(String sign, String label, VoidCallback onTap) => Semantics(
      button: true,
      label: label,
      child: Pressable(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.track),
          ),
          child: Text(
            sign,
            style: TextStyle(fontSize: 18, color: colors.ink),
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Vrijeme podsjetnika',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: colors.ink,
              ),
            ),
          ),
          stepper('−', 'Podsjetnik ranije', onEarlier),
          const SizedBox(width: 6),
          SizedBox(
            width: 64,
            child: Text(
              time,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: colors.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 6),
          stepper('+', 'Podsjetnik kasnije', onLater),
        ],
      ),
    );
  }
}
