import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeh/core/time/local_day.dart';
import 'package:tasbeh/features/daily_wird/domain/entities/daily_wird.dart';
import 'package:tasbeh/features/daily_wird/domain/services/daily_streak_calculator.dart';

void main() {
  DailyHistoryRecord record(DateTime day, {required bool completed}) {
    return DailyHistoryRecord(
      dateKey: LocalDay.key(day),
      items: [
        DailyItemSnapshot(
          id: 'morning_adhkar',
          title: 'أذكار الصباح',
          type: 'ذكر',
          completed: completed,
        ),
      ],
    );
  }

  test('current streak uses completed history and skips incomplete today', () {
    final today = DateTime(2026, 8, 25);
    final history = {
      LocalDay.key(today): record(today, completed: false),
      LocalDay.key(today.subtract(const Duration(days: 1))): record(
        today.subtract(const Duration(days: 1)),
        completed: true,
      ),
      LocalDay.key(today.subtract(const Duration(days: 2))): record(
        today.subtract(const Duration(days: 2)),
        completed: true,
      ),
    };

    expect(DailyStreakCalculator.current(history, now: today), 2);
    expect(DailyStreakCalculator.longest(history), 2);
  });

  test(
    'grace days preserve streak continuity in current and longest calculation',
    () {
      final today = DateTime(2026, 8, 25);
      final day1 = today.subtract(const Duration(days: 1));
      final day2 = today.subtract(const Duration(days: 2));
      final day3 = today.subtract(const Duration(days: 3));

      final history = {
        LocalDay.key(today): record(today, completed: false),
        LocalDay.key(day1): record(day1, completed: true),
        LocalDay.key(day2): DailyHistoryRecord(
          dateKey: LocalDay.key(day2),
          completedAt: null,
          graceUsed: true,
          items: const [
            DailyItemSnapshot(
              id: 'morning_adhkar',
              title: 'أذكار الصباح',
              type: 'ذكر',
              completed: false,
            ),
          ],
        ),
        LocalDay.key(day3): record(day3, completed: true),
      };

      expect(DailyStreakCalculator.current(history, now: today), 3);
      expect(DailyStreakCalculator.longest(history), 3);
      expect(DailyStreakCalculator.completedBetween(history, day3, today), 2);
    },
  );
}
