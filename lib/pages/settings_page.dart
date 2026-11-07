import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../config/routes.dart';
import '../models/radio_player_model.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool get _isDarkMode => context.watch<ThemeProvider>().isDarkMode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RadioPlayerModel>().trackPageVisit(Routes.settings);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<RadioPlayerModel>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          padding: const EdgeInsets.only(left: 12),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.chevron_left_rounded, size: 28),

          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Postavke'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              _buildSettingSection(
                title: 'Izgled',
                icon: Icons.palette_outlined,
                iconColors: [AppTheme.primary, AppTheme.primaryDark],
                children: [
                  _buildToggleSetting(
                    'Tamni režim',
                    'Aktiviraj tamnu temu za lakše korišćenje noću',
                    Icons.dark_mode_outlined,
                    _isDarkMode,
                    themeProvider.toggleTheme,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _buildSettingSection(
                title: 'Notifikacije',
                icon: Icons.notifications_outlined,
                iconColors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                children: [
                  _buildToggleSetting(
                    'Omogući notifikacije',
                    'Dobij podsjetnik da se uključiš u program i slušaš uživo',
                    Icons.notifications_active_outlined,
                    model.notificationsEnabled,
                    (value) => _setNotificationsEnabled(model, value),
                  ),
                  if (model.notificationsEnabled) ...[
                    const SizedBox(height: 16),
                    _buildNotificationTimePicker(model),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              _buildSettingSection(
                title: 'Audio',
                icon: Icons.volume_up_outlined,
                iconColors: [const Color(0xFF10B981), const Color(0xFF059669)],
                children: [
                  _buildToggleSetting(
                    'Automatsko puštanje',
                    'Počni reprodukciju čim se otvori aplikacija',
                    Icons.play_circle_outline,
                    model.autoPlay,
                    (value) => model.autoPlay = value,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _buildSettingSection(
                title: 'O aplikaciji',
                icon: Icons.info_outline,
                iconColors: [const Color(0xFF8E8E93), const Color(0xFFA8A8A8)],
                children: [
                  _buildInfoSetting(
                    'Verzija',
                    AppConfig.appVersion,
                    Icons.system_update_outlined,
                    null,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoSetting(
                    'Podrška',
                    AppConfig.supportEmail,
                    Icons.email_outlined,
                    _openEmailSupport,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoSetting(
                    'Ostavi feedback',
                    'Predloži ideju',
                    Icons.lightbulb_outline,
                    _openFeedbackEmail,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoSetting(
                    'Uslovi korišćenja',
                    'Prikaži',
                    Icons.description_outlined,
                    _showTermsOfService,
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _buildBackToProfileButton(_isDarkMode),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingSection({
    required String title,
    required IconData icon,
    required List<Color> iconColors,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: iconColors),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggleSetting(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: value
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: value
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildInfoSetting(
    String title,
    String value,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.outline,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTimePicker(RadioPlayerModel model) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.of(_isDarkMode).surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.of(_isDarkMode).border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vrijeme dnevne notifikacije',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.of(_isDarkMode).secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showHourPicker(model),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.of(_isDarkMode).inputFill,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.of(_isDarkMode).border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Sat',
                          style: TextStyle(
                            color: AppColors.of(_isDarkMode).secondaryText,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          model.notificationHour.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _isDarkMode
                                ? AppTheme.primary
                                : const Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                ':',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _isDarkMode
                      ? AppTheme.primary
                      : const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showMinutePicker(model),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.of(_isDarkMode).inputFill,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.of(_isDarkMode).border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Minuta',
                          style: TextStyle(
                            color: AppColors.of(_isDarkMode).secondaryText,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          model.notificationMinute.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _isDarkMode
                                ? AppTheme.primary
                                : const Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  await _scheduleReminder(model);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Notifikacija podešena za ${model.notificationHour.toString().padLeft(2, '0')}:${model.notificationMinute.toString().padLeft(2, '0')}',
                        ),
                        backgroundColor: const Color(0xFF6366F1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Center(
                  child: Text(
                    'Sačuvaj',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHourPicker(RadioPlayerModel model) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        height: 200,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Izaberi sat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 24,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      '${index.toString().padLeft(2, '0')}:00',
                      textAlign: TextAlign.center,
                    ),
                    onTap: () {
                      model.setNotificationTime(
                        index,
                        model.notificationMinute,
                      );
                      Navigator.pop(context);
                      _scheduleReminder(model);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMinutePicker(RadioPlayerModel model) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        height: 200,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Izaberi minutu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 12,
                itemBuilder: (context, index) {
                  final minute = index * 5;
                  return ListTile(
                    title: Text(
                      '${model.notificationHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                      textAlign: TextAlign.center,
                    ),
                    onTap: () {
                      model.setNotificationTime(model.notificationHour, minute);
                      Navigator.pop(context);
                      _scheduleReminder(model);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scheduleReminder(RadioPlayerModel model) async {
    try {
      await NotificationService.instance.scheduleDailyReminders(
        hour: model.notificationHour,
        minute: model.notificationMinute,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Podsjetnik nije moguće podesiti na ovom uređaju.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
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
      return;
    }
    final granted = await NotificationService.instance.requestPermission();
    if (!mounted) return;
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notifikacije su isključene u postavkama telefona. Uključite ih za Feniks Radio.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    model.notificationsEnabled = true;
    await _scheduleReminder(model);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nije pronađena aplikacija za email. Pišite nam na ${AppConfig.supportEmail}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uslovi korišćenja'),
        content: const SingleChildScrollView(
          child: Text(
            'Korišćenjem Feniks Radio aplikacije slažete se sa sljedećim uslovima:\n\n'
            '1. Aplikacija je besplatna za korišćenje\n'
            '   Sve funkcije aplikacije dostupne su bez naknade. Aplikacija ne sadrži plaćanja niti kupovine.\n\n'
            '2. Sav sadržaj je vlasništvo Feniks Radija ili njegovih partnera\n'
            '   Audio stream, vizuelni elementi, logo i tekstualni sadržaj zaštićeni su autorskim i srodnim pravima.\n\n'
            '3. Zabranjena je neovlaštena redistribucija sadržaja\n'
            '   Nije dozvoljeno kopiranje, javno ponovno emitovanje, prodaja ili distribucija sadržaja bez pismene dozvole.\n\n'
            '4. Feniks poeni i ljestvica\n'
            '   Poeni se dobijaju slušanjem programa i osvajanjem znački. Ljestvica prikazuje korisnike sa najviše poena od početka korišćenja. Pokušaji vještačkog povećavanja poena mogu dovesti do uklanjanja sa ljestvice.\n\n'
            '5. Privatnost i obrada podataka\n'
            '   Feniks Radio može obrađivati osnovne podatke naloga i statistiku korišćenja (npr. postignuća, omiljene pjesme) radi rada aplikacije.\n\n'
            '6. Feniks Radio zadržava pravo izmjene uslova\n'
            '   Uslovi korišćenja mogu biti ažurirani radi usklađivanja sa funkcionalnostima aplikacije i važećim pravilima.\n\n'
            'Za više informacija kontaktirajte ${AppConfig.supportEmail}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Prihvatam'),
          ),
        ],
      ),
    );
  }

  Widget _buildBackToProfileButton(bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.person_outline_rounded, size: 20),
        label: const Text('Nazad na profil'),
        style: OutlinedButton.styleFrom(
          foregroundColor: isDarkMode ? AppTheme.primary : AppTheme.primaryDark,
          side: BorderSide(
            color: isDarkMode
                ? AppTheme.primaryWithOpacity(0.6)
                : AppTheme.primary.withValues(alpha: 0.8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
