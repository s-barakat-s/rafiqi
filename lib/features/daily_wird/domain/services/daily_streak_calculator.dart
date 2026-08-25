import 'package:tasbeh/core/time/local_day.dart';
import 'package:tasbeh/features/daily_wird/domain/entities/daily_wird.dart';

abstract final class DailyStreakCalculator {
  static int current(Map<String, DailyHistoryRecord> history, {DateTime? now}) {
    final today = LocalDay.date(now ?? DateTime.now());
    final todayRecord = history[LocalDay.key(today)];
    var cursor =
        ((todayRecord?.completed ?? false) || (todayRecord?.graceUsed ?? false))
        ? today
        : today.subtract(const Duration(days: 1));
    var streak = 0;
    while (true) {
      final record = history[LocalDay.key(cursor)];
      if (record == null) break;
      final continues = record.completed || record.graceUsed;
      if (!continues) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int longest(Map<String, DailyHistoryRecord> history) {
    final records = history.values.toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    var longest = 0;
    var running = 0;
    DateTime? previous;
    for (final record in records) {
      final date = LocalDay.parse(record.dateKey);
      final consecutive =
          previous != null && date.difference(previous).inDays == 1;
      final continues = record.completed || record.graceUsed;
      running = continues ? (consecutive ? running + 1 : 1) : 0;
      if (running > longest) longest = running;
      previous = date;
    }
    return longest;
  }

  static int completedBetween(
    Map<String, DailyHistoryRecord> history,
    DateTime start,
    DateTime end,
  ) {
    var count = 0;
    var cursor = LocalDay.date(start);
    final last = LocalDay.date(end);
    while (!cursor.isAfter(last)) {
      if (history[LocalDay.key(cursor)]?.completed ?? false) count++;
      cursor = cursor.add(const Duration(days: 1));
    }
    return count;
  }
}
