import 'package:flutter_test/flutter_test.dart';
import 'package:feniksflutter/services/notification_service.dart';

void main() {
  test('there are 20 different daily messages', () {
    final messages = NotificationService.dailyMessages;
    expect(messages.length, 20);
    expect(messages.map((m) => m.$1).toSet().length, 20);
  });

  test('every day gets the next message, then it starts over', () {
    final start = DateTime(2026, 11, 7, 8, 0);
    final seen = <String>[];
    for (var i = 0; i < 20; i++) {
      final day = DateTime(start.year, start.month, start.day + i, 8, 0);
      seen.add(NotificationService.messageForDay(day).$1);
    }
    expect(seen.toSet().length, 20, reason: '20 days, 20 different messages');
    final day21 = DateTime(start.year, start.month, start.day + 20, 8, 0);
    expect(NotificationService.messageForDay(day21).$1, seen.first);
  });
}
