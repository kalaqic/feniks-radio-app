import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../widgets/common_footer.dart';

class EtherMessagesPage extends StatefulWidget {
  const EtherMessagesPage({super.key});

  @override
  State<EtherMessagesPage> createState() => _EtherMessagesPageState();
}

class _EtherMessagesPageState extends State<EtherMessagesPage>
    with TickerProviderStateMixin {
  static const Duration _cooldown = Duration(minutes: 10);

  final _messageController = TextEditingController();
  bool _isSending = false;

  Duration _remaining = Duration.zero;
  Timer? _countdownTimer;
  bool _initialCheckDone = false;

  late final AnimationController _bgController;
  late final Animation<double> _bgShift;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      if (mounted) setState(() {});
    });
    _bgController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);
    _bgShift = Tween<double>(begin: -0.25, end: 0.25).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialCooldown());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _bgController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialCooldown() async {
    final auth = context.read<AuthService>();
    final user = auth.user;
    if (user == null) {
      if (mounted) setState(() => _initialCheckDone = true);
      return;
    }
    try {
      final last = await FirestoreService.instance.getLastMessageAt(user.uid);
      if (!mounted) return;
      if (last != null) {
        final elapsed = DateTime.now().difference(last);
        if (elapsed < _cooldown) {
          _startCountdown(_cooldown - elapsed);
        }
      }
    } catch (_) {
      // Ignore: rate-limit will be re-enforced on submit.
    } finally {
      if (mounted) setState(() => _initialCheckDone = true);
    }
  }

  void _startCountdown(Duration remaining) {
    _countdownTimer?.cancel();
    setState(() => _remaining = remaining);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final next = _remaining - const Duration(seconds: 1);
      if (next <= Duration.zero) {
        _countdownTimer?.cancel();
        setState(() => _remaining = Duration.zero);
      } else {
        setState(() => _remaining = next);
      }
    });
  }

  String _formatRemaining(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    final auth = context.read<AuthService>();
    final user = auth.user;
    final text = _messageController.text.trim();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prijavite se da pošaljete poruku.')),
      );
      return;
    }
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unesite poruku ili naziv pjesme.')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await FirestoreService.instance.submitMessageRequest(
        uid: user.uid,
        displayName: user.displayName ?? 'Anonim',
        message: text,
        cooldown: _cooldown,
      );
      if (!mounted) return;
      _messageController.clear();
      _startCountdown(_cooldown);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poruka je poslana. Hvala vam!')),
      );
    } on RateLimitedException catch (e) {
      if (!mounted) return;
      _startCountdown(e.remaining);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Možete poslati novu poruku za ${_formatRemaining(e.remaining)}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška pri slanju poruke: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;
    final titleColor = isDarkMode ? Colors.white : const Color(0xFF1F2937);
    final subtitleColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.8)
        : const Color(0xFF6B7280);
    final cardColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.white.withValues(alpha: 0.92);
    final textFieldFill =
        isDarkMode ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF3F4F6);
    final hintColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.55)
        : const Color(0xFF9CA3AF);

    final isCoolingDown = _remaining > Duration.zero;
    final isSubmitDisabled = _isSending ||
        isCoolingDown ||
        _messageController.text.trim().isEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDarkMode ? Colors.transparent : null,
        elevation: isDarkMode ? 0 : null,
        title: Text(
          'Muzička želja',
          style: TextStyle(
            color: titleColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SizedBox(
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _bgShift,
          builder: (context, child) {
            return Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isDarkMode
                          ? AppTheme.backgroundGradient
                          : const LinearGradient(
                              colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                    ),
                  ),
                ),
                Positioned(
                  top: -120 + (_bgShift.value * 40),
                  right: -80,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary
                          .withValues(alpha: isDarkMode ? 0.12 : 0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -140 - (_bgShift.value * 35),
                  left: -90,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryDark
                          .withValues(alpha: isDarkMode ? 0.10 : 0.06),
                    ),
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        _buildIntroCard(
                          titleColor: titleColor,
                          subtitleColor: subtitleColor,
                          cardColor: cardColor,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 18),
                        _buildFormCard(
                          titleColor: titleColor,
                          subtitleColor: subtitleColor,
                          cardColor: cardColor,
                          textFieldFill: textFieldFill,
                          hintColor: hintColor,
                          isDarkMode: isDarkMode,
                          isCoolingDown: isCoolingDown,
                          isSubmitDisabled: isSubmitDisabled,
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar:
          CommonFooter(currentRoute: '/ether-messages', isDark: isDarkMode),
    );
  }

  Widget _buildIntroCard({
    required Color titleColor,
    required Color subtitleColor,
    required Color cardColor,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark, AppTheme.accentDark],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? AppTheme.cardBorder : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: (isDarkMode ? Colors.black : Colors.black12)
                  .withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryDark],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Muzička želja',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pošaljite pozdrav ili muzičku želju. Poruke puštamo redom u programu.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: subtitleColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard({
    required Color titleColor,
    required Color subtitleColor,
    required Color cardColor,
    required Color textFieldFill,
    required Color hintColor,
    required bool isDarkMode,
    required bool isCoolingDown,
    required bool isSubmitDisabled,
  }) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark, AppTheme.accentDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDarkMode ? AppTheme.cardBorder : const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDarkMode ? Colors.black : Colors.black12)
                  .withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.headset_mic_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pošalji svoju poruku',
                    style: TextStyle(
                      fontSize: 20,
                      color: titleColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Možete poslati jednu poruku svakih 10 minuta.',
              style: TextStyle(fontSize: 13, color: subtitleColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              minLines: 3,
              maxLines: 6,
              maxLength: 280,
              enabled: !isCoolingDown,
              style: TextStyle(color: titleColor),
              decoration: InputDecoration(
                labelText: 'Poruka ili muzička želja',
                hintText: 'Npr. Pozdrav ekipi i može jedna pjesma...',
                hintStyle: TextStyle(color: hintColor),
                prefixIcon: Icon(Icons.edit_rounded, size: 18, color: hintColor),
                filled: true,
                fillColor: textFieldFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode
                        ? AppTheme.cardBorder
                        : const Color(0xFFD1D5DB),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primary,
                    width: 1.5,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode
                        ? AppTheme.cardBorder
                        : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (isCoolingDown) _buildCooldownBanner(isDarkMode: isDarkMode),
            const SizedBox(height: 4),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: isSubmitDisabled ? null : _submit,
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isCoolingDown
                            ? Icons.timer_outlined
                            : Icons.send_rounded,
                        size: 18,
                      ),
                label: Text(
                  isCoolingDown
                      ? 'Sačekajte ${_formatRemaining(_remaining)}'
                      : 'Pošalji poruku',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDarkMode
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFFE5E7EB),
                  disabledForegroundColor: isDarkMode
                      ? Colors.white.withValues(alpha: 0.6)
                      : const Color(0xFF6B7280),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (!_initialCheckDone) ...[
              const SizedBox(height: 12),
              Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: subtitleColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCooldownBanner({required bool isDarkMode}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: isDarkMode ? 0.18 : 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top_rounded,
                size: 18, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sljedeću poruku možete poslati za ${_formatRemaining(_remaining)}.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
