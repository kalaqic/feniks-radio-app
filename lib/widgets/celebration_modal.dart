import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/radio_player_model.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

/// "Dobrodošli natrag" popup with the listening streak, shown once per launch.
/// Meant to be shown with [showAppDialog].
class CelebrationModal extends StatelessWidget {
  const CelebrationModal({
    super.key,
    required this.onContinue,
    required this.onClose,
  });

  /// Main button: keeps (or starts) the radio playing.
  final VoidCallback onContinue;

  /// Secondary link: just closes the popup.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    final model = context.watch<RadioPlayerModel>();
    // The streak only includes today after a few minutes of listening.
    // Opening the app today continues it, so today is shown as the next day.
    final pastDays = model.listenedToday
        ? model.consecutiveDays - 1
        : model.consecutiveDays;
    final streak = pastDays + 1;
    final firstDay = streak <= 1;
    final today = DateTime.now().weekday; // 1 = Monday

    // A badge that today's listening would complete still counts as "next".
    final reached = model.listenedToday ? streak : pastDays;
    final nextBadge = Achievements.streaks
        .where((a) => a.requirement > reached)
        .firstOrNull;
    final daysLeft = nextBadge == null ? 0 : nextBadge.requirement - streak;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeSlideIn(
          delay: const Duration(milliseconds: 150),
          offset: const Offset(0, 8),
          child: Text(
            firstDay ? 'Dobrodošli' : 'Dobrodošli natrag',
            style: TextStyle(fontSize: 13, color: colors.muted),
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: const Duration(milliseconds: 220),
          offset: const Offset(0, 8),
          child: PageTitle(
            firstDay ? 'Prvi dan slušanja' : '$streak. dan zaredom',
            fontSize: 30,
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: const Duration(milliseconds: 300),
          offset: const Offset(0, 8),
          child: Text.rich(
            nextBadge == null
                ? const TextSpan(text: 'Bravo, niz ide dalje!')
                : daysLeft == 0
                ? TextSpan(
                    text: 'Uzmi dnevnu dozu Feniksa još danas do značke ',
                    children: [
                      TextSpan(
                        text: nextBadge.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const TextSpan(text: '!'),
                    ],
                  )
                : TextSpan(
                    text:
                        'Još $daysLeft ${daysLeft == 1 ? 'dan' : 'dana'} '
                        'do značke ',
                    children: [
                      TextSpan(
                        text: nextBadge.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
            style: TextStyle(fontSize: 16, height: 1.6, color: colors.text),
          ),
        ),
        const SizedBox(height: 20),
        _WeekBars(today: today, pastDays: pastDays),
        const SizedBox(height: 28),
        FadeSlideIn(
          delay: const Duration(milliseconds: 500),
          offset: const Offset(0, 8),
          child: Column(
            children: [
              PillButton(
                label: model.playing
                    ? 'Nastavi slušanje'
                    : 'Pusti radio i nastavi niz',
                onPressed: onContinue,
              ),
              const SizedBox(height: 16),
              TextLink(
                'Samo otvori početni ekran',
                padding: EdgeInsets.zero,
                onTap: onClose,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.today, required this.pastDays});

  /// 1 = Monday … 7 = Sunday.
  final int today;

  /// Days in a row right before today with listening.
  final int pastDays;

  static const _labels = ['P', 'U', 'S', 'Č', 'P', 'S', 'N'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var day = 1; day <= 7; day++) ...[
          if (day > 1) const SizedBox(width: 6),
          Expanded(
            child: _DayBar(
              label: _labels[day - 1],
              isToday: day == today,
              listened: day < today && today - day <= pastDays,
              delay: Duration(milliseconds: 450 + day * 70),
            ),
          ),
        ],
      ],
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.label,
    required this.isToday,
    required this.listened,
    required this.delay,
  });

  final String label;
  final bool isToday;
  final bool listened;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final c = colorsOf(context);
    final height = isToday ? 40.0 : listened ? 28.0 : 4.0;
    final color = isToday
        ? AppTheme.raspberry
        : listened ? AppTheme.blue : c.track;
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FadeSlideIn(
              delay: delay,
              duration: const Duration(milliseconds: 500),
              offset: const Offset(0, 10),
              child: Container(
                width: double.infinity,
                height: height,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isToday ? FontWeight.w500 : FontWeight.w300,
            color: isToday ? c.ink : c.muted,
          ),
        ),
      ],
    );
  }
}
