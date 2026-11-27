import 'package:ai_multilingual_messenger/core/utils/date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 15, 18);

  group('DateFormatter.listTimestamp', () {
    test('shows the time for today', () {
      final result = DateFormatter.listTimestamp(
        DateTime(2026, 10, 15, 9, 5),
        now: now,
      );
      expect(result, contains('9:05'));
    });

    test('shows "Yesterday" for the previous day', () {
      final result = DateFormatter.listTimestamp(
        DateTime(2026, 10, 14, 23, 59),
        now: now,
      );
      expect(result, 'Yesterday');
    });

    test('shows day and month for older dates', () {
      final result = DateFormatter.listTimestamp(
        DateTime(2026, 10, 5, 12),
        now: now,
      );
      expect(result, '5 Oct');
    });
  });

  group('DateFormatter.dayLabel', () {
    test('labels today and yesterday', () {
      expect(DateFormatter.dayLabel(DateTime(2026, 10, 15, 1), now: now), 'Today');
      expect(
        DateFormatter.dayLabel(DateTime(2026, 10, 14, 1), now: now),
        'Yesterday',
      );
    });
  });

  group('DateFormatter.isSameDay', () {
    test('compares calendar days', () {
      expect(
        DateFormatter.isSameDay(
          DateTime(2026, 10, 15, 1),
          DateTime(2026, 10, 15, 23),
        ),
        isTrue,
      );
      expect(
        DateFormatter.isSameDay(
          DateTime(2026, 10, 15, 23),
          DateTime(2026, 10, 16, 1),
        ),
        isFalse,
      );
    });
  });
}
