import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../models/radio_player_model.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

/// Hero tag shared by the landing play button and the header play button.
const playButtonHeroTag = 'feniks-play-button';

/// Color the landing play button had when it was tapped; the flight into
/// the header starts from it.
Color landingButtonColor = AppTheme.raspberry;

/// What the play button looks like while it flies from the landing screen
/// into the header: raspberry with a white play icon at the start, white with
/// a dark stop icon at the end.
Widget playButtonFlight(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      final t = Curves.easeInOutCubic.transform(animation.value);
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Color.lerp(landingButtonColor, Colors.white, t),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: (1 - t * 2).clamp(0, 1).toDouble(),
              child: const FractionallySizedBox(
                widthFactor: .42,
                heightFactor: .42,
                child: FittedBox(
                  child: Icon(Icons.play_arrow_rounded, color: Colors.white),
                ),
              ),
            ),
            Opacity(
              opacity: (t * 2 - 1).clamp(0, 1).toDouble(),
              child: const FractionallySizedBox(
                widthFactor: .34,
                heightFactor: .34,
                child: FittedBox(
                  child: Icon(Icons.stop_rounded, color: AppTheme.ink),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Coral header of the home screen: logo, name, live status, play/stop and
/// a thin sound wave that moves while the radio plays.
///
/// With [entrance] the background slides down and the content fades in, used
/// right after the landing screen.
class HeaderPlayer extends StatefulWidget {
  const HeaderPlayer({super.key, this.entrance = false});

  final bool entrance;

  @override
  State<HeaderPlayer> createState() => _HeaderPlayerState();
}

class _HeaderPlayerState extends State<HeaderPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
    value: widget.entrance ? 0 : 1,
  );

  late final Animation<double> _slide = CurvedAnimation(
    parent: _controller,
    curve: const Interval(.25, .75, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _contentFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(.6, .9, curve: Curves.easeOut),
  );
  late final Animation<double> _waveFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(.7, 1, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    if (widget.entrance) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<RadioPlayerModel>();

    return StreamBuilder<PlayerState>(
      stream: model.playerStateStream,
      builder: (context, _) {
        final playing = model.playing;
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Stack(
            children: [
              Positioned.fill(
                child: FractionalTranslation(
                  translation: Offset(0, _slide.value - 1),
                  child: const ColoredBox(color: AppTheme.coral),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Opacity(
                              opacity: _contentFade.value,
                              child: _StationInfo(playing: playing),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Hero(
                            tag: playButtonHeroTag,
                            flightShuttleBuilder: playButtonFlight,
                            child: _PlayStopButton(
                              playing: playing,
                              onPressed: () =>
                                  playing ? model.stop() : model.play(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Opacity(
                        opacity: _waveFade.value,
                        child: _SoundWave(playing: playing),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StationInfo extends StatelessWidget {
  const _StationInfo({required this.playing});

  final bool playing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'lib/assets/png/logo_red.png',
          width: 60,
          height: 60,
          color: Colors.white,
          colorBlendMode: BlendMode.srcIn,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text.rich(
                TextSpan(
                  text: 'Feniks Radio ',
                  children: [
                    TextSpan(
                      text: '94.7',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  LiveDot(active: playing),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      playing ? 'Uživo' : 'Zaustavljeno',
                      key: ValueKey(playing),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayStopButton extends StatelessWidget {
  const _PlayStopButton({required this.playing, required this.onPressed});

  final bool playing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: playing ? 'Zaustavi radio' : 'Pusti radio',
      child: Pressable(
        onTap: onPressed,
        scale: .9,
        haptic: Haptic.medium,
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: Tween(begin: .6, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(
              playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
              key: ValueKey(playing),
              size: playing ? 20 : 24,
              color: AppTheme.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Two thin white waves that roll while the radio plays and calm down to a
/// flat line when it stops.
class _SoundWave extends StatefulWidget {
  const _SoundWave({required this.playing});

  final bool playing;

  @override
  State<_SoundWave> createState() => _SoundWaveState();
}

class _SoundWaveState extends State<_SoundWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _phase = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void initState() {
    super.initState();
    if (widget.playing) _phase.repeat();
  }

  @override
  void didUpdateWidget(_SoundWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing && !_phase.isAnimating) _phase.repeat();
  }

  @override
  void dispose() {
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: widget.playing ? 1 : 0),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic,
        onEnd: () {
          if (!widget.playing) _phase.stop();
        },
        builder: (context, amplitude, _) => AnimatedBuilder(
          animation: _phase,
          builder: (context, _) => CustomPaint(
            size: const Size(double.infinity, 22),
            painter: _WavePainter(
              phase: _phase.value,
              amplitude: amplitude,
            ),
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.phase, required this.amplitude});

  final double phase;
  final double amplitude;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    void wave(double speed, double length, double height, double alpha) {
      final path = Path();
      for (var x = 0.0; x <= size.width; x += 3) {
        // Quieter at both ends so the line fades into the edges.
        final edge = math.sin(math.pi * x / size.width);
        final y =
            mid +
            math.sin(x / length + phase * math.pi * 2 * speed) *
                height *
                amplitude *
                edge;
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: alpha),
      );
    }

    wave(1, 26, 7, .55);
    wave(-2, 17, 4, .3);
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.phase != phase || old.amplitude != amplitude;
}
