import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../config/app_config.dart';
import '../models/radio_player_model.dart';
import '../theme/app_theme.dart';

const _liveColor = Color(0xFF34C759);
const _stopColor = Color(0xFFFF3B30);

class HeaderPlayer extends StatelessWidget implements PreferredSizeWidget {
  const HeaderPlayer({super.key, required this.model});

  final RadioPlayerModel model;

  @override
  Size get preferredSize => const Size.fromHeight(200);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary,
            blurRadius: 25,
            offset: Offset(0, 8),
            spreadRadius: -10,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),

          child: StreamBuilder<PlayerState>(
            stream: model.playerStateStream,
            builder: (context, _) {
              final playing = model.playing;
              return Row(
                children: [
                  _StationLogo(playing: playing),
                  const SizedBox(width: 20),
                  Expanded(child: _StationInfo(playing: playing)),
                  _PlayStopButton(
                    playing: playing,
                    onPressed: () => playing ? model.stop() : model.play(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StationLogo extends StatelessWidget {
  const _StationLogo({required this.playing});

  final bool playing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (playing)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Image.asset(
              'lib/assets/png/logo_red.png',
              width: 32,
              height: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _StationInfo extends StatelessWidget {
  const _StationInfo({required this.playing});

  final bool playing;

  @override
  Widget build(BuildContext context) {
    final statusColor = playing ? _liveColor : Colors.orange;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          AppConfig.appName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: statusColor, blurRadius: 8, spreadRadius: 1),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              playing ? 'Uživo' : 'Zaustavljeno',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Icon(
            playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
            color: playing ? _stopColor : _liveColor,
            size: 28,
          ),
        ),
      ),
    );
  }
}
