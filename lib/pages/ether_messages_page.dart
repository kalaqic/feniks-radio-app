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

class _EtherMessagesPageState extends State<EtherMessagesPage> with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  double _amount = 2.5;
  bool _isSending = false;
  late final AnimationController _bgController;
  late final Animation<double> _bgShift;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      // Rebuild to enable/disable the submit button as the input changes.
      if (mounted) setState(() {});
    });
    _bgController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);
    _bgShift = Tween<double>(begin: -0.25, end: 0.25).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _messageController.dispose();
    super.dispose();
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
        amountEur: _amount,
      );
      if (!mounted) return;
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Poruka poslana (${_amount.toStringAsFixed(2)} EUR).')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Neuspješno slanje. Provjerite Firebase pravila.')),
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
    final subtitleColor = isDarkMode ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF6B7280);
    final cardColor = isDarkMode ? Colors.white.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.92);
    final textFieldFill = isDarkMode ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF3F4F6);
    final hintColor = isDarkMode ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF9CA3AF);
    final sliderInactive = isDarkMode ? Colors.white24 : const Color(0xFFD1D5DB);
    final amountEmoji = _amount < 20
        ? '🙂'
        : _amount < 50
            ? '🎶'
            : '🔥';

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
      body: Container(
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
                      color: AppTheme.primary.withValues(alpha: isDarkMode ? 0.12 : 0.08),
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
                      color: AppTheme.primaryDark.withValues(alpha: isDarkMode ? 0.10 : 0.06),
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
                        Container(
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
                                  color: (isDarkMode ? Colors.black : Colors.black12).withValues(alpha: 0.10),
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
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
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
                                  'Pošaljite pozdrav ili muzičku želju. Vaše poruke puštamo redom u programu.',
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
                        ),
                        const SizedBox(height: 18),
                        Container(
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
                                  color: (isDarkMode ? Colors.black : Colors.black12).withValues(alpha: 0.12),
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
                                    Icon(
                                      Icons.headset_mic_rounded,
                                      color: AppTheme.primary,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Muzička želja',
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
                                  'Minimalni iznos je 2.50 EUR',
                                  style: TextStyle(fontSize: 14, color: subtitleColor),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _messageController,
                                  minLines: 2,
                                  maxLines: 4,
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
                                        color: isDarkMode ? AppTheme.cardBorder : const Color(0xFFD1D5DB),
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppTheme.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Iznos: ${_amount.toStringAsFixed(2)} EUR',
                                  style: TextStyle(
                                    color: titleColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 8,
                                    thumbShape: _EmojiThumbShape(emoji: amountEmoji),
                                  ),
                                  child: SizedBox(
                                    height: 44,
                                    child: Slider(
                                      value: _amount,
                                      min: 2.5,
                                      max: 100,
                                      divisions: 39,
                                      activeColor: AppTheme.primary,
                                      inactiveColor: sliderInactive,
                                      label: '${_amount.toStringAsFixed(2)} EUR',
                                      onChanged: (v) => setState(() => _amount = v),
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '2.50 EUR',
                                      style: TextStyle(fontSize: 12, color: subtitleColor),
                                    ),
                                    Text(
                                      '100 EUR',
                                      style: TextStyle(fontSize: 12, color: subtitleColor),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: (_isSending || _messageController.text.trim().isEmpty)
                                        ? null
                                        : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isSending
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Pošalji poruku'),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
      bottomNavigationBar: CommonFooter(currentRoute: '/ether-messages', isDark: isDarkMode),
    );
  }
}

class _EmojiThumbShape extends SliderComponentShape {
  final String emoji;

  const _EmojiThumbShape({required this.emoji});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(40, 40);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final borderColor = sliderTheme.thumbColor ?? AppTheme.primary;
    final fillPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 15, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 15, borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: const TextStyle(fontSize: 16),
      ),
      textDirection: textDirection,
    )..layout();

    final emojiOffset = center - Offset(textPainter.width / 2, textPainter.height / 2 + 1);
    textPainter.paint(canvas, emojiOffset);
  }
}
