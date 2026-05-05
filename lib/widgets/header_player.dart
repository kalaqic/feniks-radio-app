import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/radio_player_model.dart';
import '../theme/app_theme.dart';

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
          child: Row(
            children: [
              // Radio icon with pulsing effect
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulsing background
                    StreamBuilder<PlayerState>(
                      stream: model.playerStateStream,
                      builder: (context, snapshot) {
                        if (model.playing) {
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
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
              ),
              const SizedBox(width: 20),
              // Station info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Feniks Radio',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    StreamBuilder<PlayerState>(
                      stream: model.playerStateStream,
                      builder: (context, snapshot) {
                        final playing = model.playing;
                        return Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: playing
                                    ? const Color(0xFF34C759)
                                    : Colors.orange,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: playing
                                        ? const Color(0xFF34C759)
                                        : Colors.orange,
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
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
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Control buttons
              StreamBuilder<PlayerState>(
                stream: model.playerStateStream,
                builder: (context, snapshot) {
                  final playing = model.playing;
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
                        borderRadius: BorderRadius.circular(26),
                        onTap: () => playing ? model.stop() : model.play(),
                        child: Icon(
                          playing
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          color: playing
                              ? const Color(0xFFFF3B30)
                              : const Color(0xFF34C759),
                          size: 28,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
