import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/routes.dart';
import '../models/radio_player_model.dart';
import '../pages/home_page.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'header_player.dart';
import 'ui.dart';

/// First screen on every launch: one big play button. Tapping it starts the
/// radio and the button flies into the header of the home screen.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  static const _shakeCycle = Duration(milliseconds: 2600);

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: _shakeCycle,
  )..repeat();
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  late final AnimationController _label = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  static const _colors = [AppTheme.coral, AppTheme.orange, AppTheme.blue];

  Timer? _labelTimer;
  Timer? _firstShakeTimer;
  Timer? _hapticTimer;
  bool _started = false;
  int _colorIndex = 0;

  Color get _color => _colors[_colorIndex % _colors.length];

  /// Every wiggle: a short vibration and the next brand color.
  void _onShake() {
    if (!mounted || _started) return;
    HapticFeedback.lightImpact();
    setState(() => _colorIndex++);
  }

  @override
  void initState() {
    super.initState();
    if (!context.read<AuthService>().isAuthenticated) {
      context.read<RadioPlayerModel>().achievementsEnabled = false;
    }
    _labelTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) _label.forward();
    });
    // The wiggle starts at 70 % of every shake cycle.
    _firstShakeTimer = Timer(_shakeCycle * .7, () {
      _onShake();
      _hapticTimer = Timer.periodic(_shakeCycle, (_) => _onShake());
    });
  }

  @override
  void dispose() {
    _labelTimer?.cancel();
    _firstShakeTimer?.cancel();
    _hapticTimer?.cancel();
    _shake.dispose();
    _intro.dispose();
    _label.dispose();
    super.dispose();
  }

  void _start() {
    if (_started) return;
    landingButtonColor = _color;
    setState(() => _started = true);
    HapticFeedback.mediumImpact();
    _shake.stop();
    unawaited(context.read<RadioPlayerModel>().play());
    Navigator.pushReplacementNamed(
      context,
      Routes.home,
      arguments: HomePage.landingArgument,
    );
  }

  /// Short wiggle at the end of every cycle, still the rest of the time.
  Offset _shakeOffset(double t) {
    if (t < .7 || t > .9) return Offset.zero;
    final x = (t - .7) / .2;
    final damp = 1 - x;
    return Offset(math.sin(x * math.pi * 8) * 3 * damp, 0);
  }

  double _shakeAngle(double t) {
    if (t < .7 || t > .9) return 0;
    final x = (t - .7) / .2;
    return math.sin(x * math.pi * 8) * .07 * (1 - x);
  }

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: SizedBox.expand(
        child: Stack(
        alignment: Alignment.center,
        children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!_started)
                    for (final delay in const [0.0, 0.5])
                      _PulseRing(
                        animation: _shake,
                        delay: delay,
                        color: _color,
                      ),
                  FadeTransition(
                    opacity: _intro,
                    child: ScaleTransition(
                      scale: Tween(begin: .85, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _intro,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: AnimatedBuilder(
                        animation: _shake,
                        builder: (context, child) => Transform.translate(
                          offset: _shakeOffset(_shake.value),
                          child: Transform.rotate(
                            angle: _shakeAngle(_shake.value),
                            child: child,
                          ),
                        ),
                        child: Semantics(
                          button: true,
                          label: 'Pusti radio',
                          child: GestureDetector(
                            onTap: _start,
                            child: Hero(
                              tag: playButtonHeroTag,
                              flightShuttleBuilder: playButtonFlight,
                              child: _PaintedButton(color: _color),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              // Just under the button, which stays in the exact middle.
              offset: const Offset(0, 52 + 26 + 12),
              child: FadeTransition(
              opacity: Tween(begin: 0.0, end: .6).animate(
                CurvedAnimation(parent: _label, curve: Curves.easeInOut),
              ),
              child: const Text(
                'Klikni da pustiš radio!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.blue,
                ),
              ),
            ),
            ),
        ],
      ),
      ),
    );
  }
}

/// Thin ring that grows out of the button and fades away.
class _PulseRing extends StatelessWidget {
  const _PulseRing({
    required this.animation,
    required this.delay,
    required this.color,
  });

  final Animation<double> animation;
  final double delay;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = (animation.value + delay) % 1.0;
        return Opacity(
          opacity: (1 - t) * .6,
          child: Transform.scale(
            scale: 1 + t * .9,
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Round play button. When [color] changes, the new color is painted over
/// the old one with a brush stroke from left to right.
class _PaintedButton extends StatefulWidget {
  const _PaintedButton({required this.color});

  final Color color;

  @override
  State<_PaintedButton> createState() => _PaintedButtonState();
}

class _PaintedButtonState extends State<_PaintedButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stroke = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    value: 1,
  );
  late Color _from = widget.color;
  late Color _to = widget.color;

  /// Every new stroke goes the other way: left to right, then right to left.
  bool _fromLeft = false;

  @override
  void didUpdateWidget(_PaintedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.color != _to) {
      _from = _to;
      _to = widget.color;
      _fromLeft = !_fromLeft;
      _stroke.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _stroke.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: ClipOval(
        child: AnimatedBuilder(
          animation: _stroke,
          builder: (context, child) => CustomPaint(
            painter: _BrushPainter(
              from: _from,
              to: _to,
              fromLeft: _fromLeft,
              progress: Curves.easeInOutCubic.transform(_stroke.value),
            ),
            child: child,
          ),
          child: const Center(
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 46,
            ),
          ),
        ),
      ),
    );
  }
}

/// Old color underneath, new color on top up to a wavy, slightly slanted
/// brush edge that moves from left to right.
class _BrushPainter extends CustomPainter {
  _BrushPainter({
    required this.from,
    required this.to,
    required this.progress,
    required this.fromLeft,
  });

  final Color from;
  final Color to;
  final double progress;
  final bool fromLeft;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = from);
    if (progress <= 0) return;

    final w = size.width;
    final h = size.height;
    // The edge starts fully left of the button and ends fully right of it.
    final edge = -w * .35 + progress * w * 1.7;
    final path = Path()..moveTo(0, 0);
    const steps = 24;
    for (var i = 0; i <= steps; i++) {
      final y = h * i / steps;
      final wave = math.sin(i / steps * math.pi * 3) * w * .05;
      final slant = (i / steps - .5) * w * .3;
      path.lineTo(edge + wave + slant, y);
    }
    path
      ..lineTo(0, h)
      ..close();
    if (!fromLeft) {
      // Mirror the stroke so it starts on the right side.
      canvas
        ..save()
        ..translate(w, 0)
        ..scale(-1, 1);
    }
    canvas.drawPath(path, Paint()..color = to);
    if (!fromLeft) canvas.restore();
  }

  @override
  bool shouldRepaint(_BrushPainter old) =>
      old.progress != progress ||
      old.from != from ||
      old.to != to ||
      old.fromLeft != fromLeft;
}
