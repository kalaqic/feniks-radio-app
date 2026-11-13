import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../utils/haptics.dart';

export '../utils/haptics.dart';

/// Colors for the current light/dark mode.
AppColors colorsOf(BuildContext context) =>
    AppColors.of(context.watch<ThemeProvider>().isDarkMode);

/// 4870 -> "4.870".
String formatNumber(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// The three brand colors as a thin line, used on top of screens
/// without the bottom navigation.
class BrandStripe extends StatelessWidget {
  const BrandStripe({super.key, this.height = 4});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: ColoredBox(color: AppTheme.raspberry)),
          Expanded(child: ColoredBox(color: AppTheme.coral)),
          Expanded(child: ColoredBox(color: AppTheme.blue)),
        ],
      ),
    );
  }
}

/// Big screen title that ends with a colored dot, like "94.7" on the site.
class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key, this.fontSize = 34});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return Text.rich(
      TextSpan(
        text: text,
        children: const [
          TextSpan(
            text: '.',
            style: TextStyle(color: AppTheme.raspberry),
          ),
        ],
      ),
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        height: 1.15,
        color: colors.ink,
      ),
    );
  }
}

/// Small grey label above a group of settings.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 1,
          color: colorsOf(context).muted,
        ),
      ),
    );
  }
}

/// Shrinks a little while pressed.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.96,
    this.haptic = Haptic.selection,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  /// Felt on every tap; see [Haptic] for which one fits where.
  final Haptic haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool value) {
    if (widget.onTap != null && _down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null
          ? null
          : () {
              Haptics.play(widget.haptic);
              onTap();
            },
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

enum PillStyle { dark, light, outline }

/// Rounded button used for every main action.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = PillStyle.dark,
    this.expand = true,
    this.loading = false,
    this.icon,
    this.height = 52,
    this.fontSize = 15,
    this.faded = false,
    this.haptic = Haptic.light,
  });

  /// Main buttons are felt a bit more than links.
  final Haptic haptic;

  final String label;
  final VoidCallback? onPressed;
  final PillStyle style;
  final bool expand;
  final bool loading;
  final IconData? icon;
  final double height;
  final double fontSize;

  /// Looks disabled but still reacts to taps (to show validation errors).
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final (Color bg, Color fg, BorderSide? border) = switch (style) {
      PillStyle.dark => (colors.button, colors.onButton, null),
      PillStyle.light => (Colors.white, AppTheme.ink, null),
      PillStyle.outline => (
        Colors.transparent,
        colors.ink,
        BorderSide(color: colors.ink),
      ),
    };
    final enabled = onPressed != null && !loading;

    final content = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w400,
                    color: fg,
                  ),
                ),
              ),
            ],
          );

    return Pressable(
      haptic: faded ? Haptic.warning : haptic,
      onTap: enabled ? onPressed : null,
      child: AnimatedOpacity(
        opacity: onPressed == null || faded ? 0.55 : 1,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: bg,
            shape: StadiumBorder(side: border ?? BorderSide.none),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Underlined text link, like the links on radiofeniks.com.
class TextLink extends StatelessWidget {
  const TextLink(
    this.label, {
    super.key,
    required this.onTap,
    this.fontSize = 14,
    this.color,
    this.muted = false,
    this.padding = const EdgeInsets.symmetric(vertical: 6),
  });

  final String label;
  final VoidCallback onTap;
  final double fontSize;
  final Color? color;
  final bool muted;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final c = color ?? (muted ? colors.muted : colors.ink);
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: muted ? FontWeight.w300 : FontWeight.w400,
            color: c,
            decoration: TextDecoration.underline,
            decorationColor: c,
            decorationThickness: 1,
          ),
        ),
      ),
    );
  }
}

/// "‹ Nazad na …" at the top of screens without the bottom navigation.
class BackLink extends StatelessWidget {
  const BackLink(this.label, {super.key, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Pressable(
        onTap: onTap ?? () => Navigator.maybePop(context),
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left, size: 20, color: colors.ink),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Flat colored block that asks a logged-out user to sign in.
class LoginPrompt extends StatelessWidget {
  const LoginPrompt({
    super.key,
    required this.title,
    required this.message,
    this.color = AppTheme.raspberry,
    this.titleSize = 24,
  });

  final String title;
  final String message;
  final Color color;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    const fg = Colors.white;
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: fg,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(fontSize: 15, height: 1.55, color: fg),
          ),
          const SizedBox(height: 18),
          Pressable(
            onTap: () => Navigator.pushNamed(context, Routes.login),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: const ShapeDecoration(
                color: Colors.white,
                shape: StadiumBorder(),
              ),
              child: const Text(
                'Prijavi se',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Page without the bottom navigation: the three-color line sits right under
/// the status bar, the content scrolls below it.
class StripedPage extends StatelessWidget {
  const StripedPage({
    super.key,
    required this.children,
    this.top = 12,
    this.horizontal = 24,
    this.gap = 16,
  });

  final List<Widget> children;

  /// Space between the status bar and the first child.
  final double top;
  final double horizontal;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const BrandStripe(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(horizontal, top, horizontal, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < children.length; i++) ...[
                      if (i > 0) SizedBox(height: gap),
                      children[i],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small grey label above an underlined text field.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
    this.trailing,
    this.keyboardType,
    this.autofillHints,
    this.inputFormatters,
    this.hint,
    this.fontSize = 17,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final String? hint;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final field = TextFormField(
      controller: controller,
      obscureText: obscureText,
      autocorrect: false,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w300,
        color: colors.ink,
      ),
      decoration: InputDecoration(hintText: hint),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: colors.muted,
          ),
        ),
        const SizedBox(height: 2),
        if (trailing == null)
          field
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: field),
              const SizedBox(width: 8),
              Padding(padding: const EdgeInsets.only(top: 4), child: trailing),
            ],
          ),
      ],
    );
  }
}

/// Flat on/off switch: 48 × 28, raspberry when on.
class FlatSwitch extends StatelessWidget {
  const FlatSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return Semantics(
      toggled: value,
      label: label,
      child: GestureDetector(
        onTap: () {
          // Turning something on is felt a bit more than turning it off.
          Haptics.play(value ? Haptic.selection : Haptic.light);
          onChanged(!value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: ShapeDecoration(
            color: value ? AppTheme.raspberry : colors.track,
            shape: const StadiumBorder(),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades and slides its child in once, after [delay].
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 700),
    this.offset = const Offset(0, 14),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Start position in logical pixels.
  final Offset offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final t = _curve.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: widget.offset * (1 - t),
            child: child,
          ),
        );
      },
    );
  }
}

/// Counts from 0 up to [value] once, then follows later changes.
class CountUp extends StatefulWidget {
  const CountUp({
    super.key,
    required this.value,
    required this.style,
    this.delay = const Duration(milliseconds: 300),
    this.duration = const Duration(milliseconds: 1400),
    this.format = formatNumber,
    this.suffix = '',
    this.suffixStyle,
  });

  final int value;
  final TextStyle style;
  final Duration delay;
  final Duration duration;
  final String Function(int) format;
  final String suffix;

  /// Style of [suffix]; defaults to [style].
  final TextStyle? suffixStyle;

  @override
  State<CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<CountUp> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, _) => Text.rich(
        TextSpan(
          text: widget.format((widget.value * _curve.value).round()),
          children: [
            if (widget.suffix.isNotEmpty)
              TextSpan(text: widget.suffix, style: widget.suffixStyle),
          ],
        ),
        style: widget.style.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Thin progress line that fills once when it appears.
class ProgressLine extends StatelessWidget {
  const ProgressLine({
    super.key,
    required this.value,
    required this.color,
    required this.track,
    this.height = 2,
    this.delay = const Duration(milliseconds: 400),
  });

  final double value;
  final Color color;
  final Color track;
  final double height;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: track,
      alignment: Alignment.centerLeft,
      child: _DelayedTween(
        delay: delay,
        end: value.clamp(0, 1).toDouble(),
        builder: (v) => FractionallySizedBox(
          widthFactor: v,
          child: Container(height: height, color: color),
        ),
      ),
    );
  }
}

class _DelayedTween extends StatefulWidget {
  const _DelayedTween({
    required this.delay,
    required this.end,
    required this.builder,
  });

  final Duration delay;
  final double end;
  final Widget Function(double value) builder;

  @override
  State<_DelayedTween> createState() => _DelayedTweenState();
}

class _DelayedTweenState extends State<_DelayedTween> {
  bool _started = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _started = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: _started ? widget.end : 0),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => widget.builder(v),
    );
  }
}

/// Three bars that bounce while the radio plays.
class EqualizerBars extends StatefulWidget {
  const EqualizerBars({
    super.key,
    required this.active,
    this.color,
    this.height = 12,
  });

  final bool active;
  final Color? color;
  final double height;

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(EqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? colorsOf(context).ink;
    const phases = [0.0, 0.4, 0.7];
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final phase in phases) ...[
              Container(
                width: 2,
                height: widget.height *
                    (widget.active ? _barHeight(_controller.value, phase) : .2),
                color: color,
              ),
              if (phase != phases.last) const SizedBox(width: 2),
            ],
          ],
        ),
      ),
    );
  }

  double _barHeight(double t, double phase) {
    final x = (t + phase) % 1.0;
    final wave = x < .5 ? x * 2 : 2 - x * 2;
    return .25 + .75 * Curves.easeInOut.transform(wave);
  }
}

/// Small dot that slowly blinks while [active].
class LiveDot extends StatefulWidget {
  const LiveDot({super.key, required this.active, this.color = Colors.white});

  final bool active;
  final Color color;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(LiveDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Opacity(
        opacity: widget.active ? 1 - _controller.value * .65 : .45,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Row inside a white block that opens another screen.
class NavRow extends StatelessWidget {
  const NavRow({
    super.key,
    required this.label,
    required this.onTap,
    this.trailing,
    this.showDivider = true,
    this.horizontal = 20,
    this.dot = false,
  });

  final String label;
  final VoidCallback onTap;
  final String? trailing;

  /// Small raspberry notification dot next to [trailing].
  final bool dot;
  final bool showDivider;
  final double horizontal;

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
        hoverColor: colors.surfaceHover,
        highlightColor: colors.surfaceHover,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 18),
          decoration: BoxDecoration(
            border: showDivider
                ? Border(top: BorderSide(color: colors.divider))
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: colors.ink,
                  ),
                ),
              ),
              AnimatedScale(
                scale: dot ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    color: AppTheme.raspberry,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              if (trailing != null) ...[
                Text(
                  trailing!,
                  style: TextStyle(fontSize: 15, color: colors.muted),
                ),
                const SizedBox(width: 8),
              ],
              Icon(Icons.chevron_right, size: 18, color: colors.ink),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet with the app's flat look.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    barrierColor: const Color(0x66151515),
    builder: (context) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
        child: builder(context),
      ),
    ),
  );
}

/// Centered dialog with the app's flat look and a brand stripe on top.
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: 'Zatvori',
    barrierColor: const Color(0x73151515),
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (context, _, _) => SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            color: colorsOf(context).surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BrandStripe(height: 6),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(26, 32, 26, 28),
                      child: builder(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, .04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Opens like a drawer: the space grows, then every line swings down into
/// place one after another, like cards folding open. Closing folds it all
/// back up quickly.
class RevealDrawer extends StatefulWidget {
  const RevealDrawer({
    super.key,
    required this.open,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final bool open;
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  State<RevealDrawer> createState() => _RevealDrawerState();
}

class _RevealDrawerState extends State<RevealDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
    reverseDuration: const Duration(milliseconds: 320),
    value: widget.open ? 1 : 0,
  );
  late final Animation<double> _size = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, .55, curve: Curves.easeOutCubic),
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void didUpdateWidget(RevealDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open != oldWidget.open) {
      unawaited(widget.open ? _controller.forward() : _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _line(int index, Widget child) {
    final start = (.12 + index * .08).clamp(0.0, .55);
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        start,
        (start + .45).clamp(0.0, 1.0),
        curve: Curves.easeOutBack,
      ),
      reverseCurve: Curves.easeIn,
    );
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = animation.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -10 * (1 - t)),
            child: Transform(
              alignment: Alignment.topCenter,
              // A little perspective so the line swings down from its top.
              transform: Matrix4.identity()
                ..setEntry(3, 2, .0015)
                ..rotateX(-(1 - t) * 1.1),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => _controller.isDismissed
          ? const SizedBox(width: double.infinity)
          : child!,
      child: SizeTransition(
        sizeFactor: _size,
        axisAlignment: -1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: widget.crossAxisAlignment,
          children: [
            for (final (i, child) in widget.children.indexed) _line(i, child),
          ],
        ),
      ),
    );
  }
}
