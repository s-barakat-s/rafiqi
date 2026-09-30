import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeh/features/home/domain/prayer_schedule.dart';

/// Phase 1 regression tests for the next-prayer countdown calculation.
///
/// All scenarios use explicit reference times against the demo schedule
/// (fajr 04:50, sunrise 06:23, dhuhr 12:05, asr 15:35, maghrib 18:12,
/// isha 19:42) so results are deterministic regardless of when they run.
void main() {
  DateTime day(int year, int month, int dayOfMonth, int hour, int minute) =>
      DateTime(year, month, dayOfMonth, hour, minute);

  group('next-prayer selection', () {
    test('before fajr: counts down to TODAY fajr (50 minutes at 04:00)', () {
      final now = day(2026, 9, 29, 4, 0);

      final status = PrayerSchedule.snapshot(now).status;

      expect(status.kind, PrayerStatusKind.upcoming);
      expect(status.prayer.type, PrayerItemType.fajr);
      // The actual date of the targeted prayer must be today, not tomorrow.
      expect(status.prayer.time, day(2026, 9, 29, 4, 50));
      expect(status.duration, const Duration(minutes: 50));
    });

    test('exactly at fajr: that prayer is ongoing with zero remaining', () {
      final now = day(2026, 9, 29, 4, 50);

      final status = PrayerSchedule.snapshot(now).status;

      expect(status.kind, PrayerStatusKind.ongoing);
      expect(status.prayer.type, PrayerItemType.fajr);
      expect(status.duration, Duration.zero);
    });

    test('just after fajr: fajr is ongoing inside its window', () {
      final now = day(2026, 9, 29, 5, 10);

      final status = PrayerSchedule.snapshot(now).status;

      expect(status.kind, PrayerStatusKind.ongoing);
      expect(status.prayer.type, PrayerItemType.fajr);
    });

    test('just after the fajr window: fajr "passed" up to 1h, then sunrise', () {
      // 05:21 is 31 min after fajr: outside the 30-min window but within the
      // 1-hour "recently passed" presentation.
      final passed = PrayerSchedule.snapshot(day(2026, 9, 29, 5, 21)).status;
      expect(passed.kind, PrayerStatusKind.passed);
      expect(passed.prayer.type, PrayerItemType.fajr);

      // 05:55 is more than 1h after fajr: countdown switches to sunrise.
      final upcoming = PrayerSchedule.snapshot(day(2026, 9, 29, 5, 55)).status;
      expect(upcoming.kind, PrayerStatusKind.upcoming);
      expect(upcoming.prayer.type, PrayerItemType.sunrise);
      expect(upcoming.duration, const Duration(minutes: 28));
    });

    test('mid-morning: dhuhr ongoing then passed, next upcoming is asr', () {
      // 12:20 is 15 minutes after dhuhr: inside the 30-min window.
      final ongoing = PrayerSchedule.snapshot(day(2026, 9, 29, 12, 20)).status;
      expect(ongoing.kind, PrayerStatusKind.ongoing);
      expect(ongoing.prayer.type, PrayerItemType.dhuhr);

      // 13:30 is past window and "recently passed": next upcoming is asr.
      final upcoming = PrayerSchedule.snapshot(day(2026, 9, 29, 13, 30)).status;
      expect(upcoming.prayer.type, PrayerItemType.asr);
      expect(
        upcoming.duration,
        const Duration(hours: 2, minutes: 5),
      );
    });

    test('exactly at isha (last prayer): isha is ongoing', () {
      final now = day(2026, 9, 29, 19, 42);

      final status = PrayerSchedule.snapshot(now).status;

      expect(status.kind, PrayerStatusKind.ongoing);
      expect(status.prayer.type, PrayerItemType.isha);
      expect(status.duration, Duration.zero);
    });

    test('after isha: passed presentation then countdown to tomorrow fajr', () {
      // 20:30 is 48 min after isha: still "recently passed".
      final passed = PrayerSchedule.snapshot(day(2026, 9, 29, 20, 30)).status;
      expect(passed.kind, PrayerStatusKind.passed);
      expect(passed.prayer.type, PrayerItemType.isha);

      // 21:00 is over an hour after isha: count down to tomorrow's fajr.
      final now = day(2026, 9, 29, 21, 0);
      final status = PrayerSchedule.snapshot(now).status;

      expect(status.kind, PrayerStatusKind.upcoming);
      expect(status.prayer.type, PrayerItemType.fajr);
      // Tomorrow = Sep 30, 04:50 → 7h50m from 21:00.
      expect(status.prayer.time, day(2026, 9, 30, 4, 50));
      expect(status.duration, const Duration(hours: 7, minutes: 50));
    });

    test('month rollover: isha on the last day of a month targets next month', () {
      final now = day(2026, 9, 30, 21, 0);

      final status = PrayerSchedule.snapshot(now).status;

      expect(status.prayer.type, PrayerItemType.fajr);
      expect(status.prayer.time, day(2026, 10, 1, 4, 50));
    });

    test('year rollover: isha on Dec 31 targets Jan 1 fajr', () {
      final now = day(2026, 12, 31, 21, 0);

      final status = PrayerSchedule.snapshot(now).status;

      expect(status.prayer.type, PrayerItemType.fajr);
      expect(status.prayer.time, day(2027, 1, 1, 4, 50));
    });

    test('midnight: before fajr of the new day, so today fajr is the target', () {
      final now = day(2026, 9, 29, 0, 5);

      final status = PrayerSchedule.snapshot(now).status;

      expect(status.kind, PrayerStatusKind.upcoming);
      expect(status.prayer.type, PrayerItemType.fajr);
      expect(status.prayer.time, day(2026, 9, 29, 4, 50));
      expect(status.duration, const Duration(hours: 4, minutes: 45));
    });

    test('highlighted type follows the same selection as the countdown', () {
      // Before fajr → highlight fajr (today), not yesterday's leftover.
      expect(
        PrayerSchedule.snapshot(day(2026, 9, 29, 4, 0)).highlightedType,
        PrayerItemType.fajr,
      );
      // Between dhuhr and asr → highlight asr.
      expect(
        PrayerSchedule.snapshot(day(2026, 9, 29, 13, 30)).highlightedType,
        PrayerItemType.asr,
      );
      // After isha → highlight fajr (tomorrow).
      expect(
        PrayerSchedule.snapshot(day(2026, 9, 29, 20, 30)).highlightedType,
        PrayerItemType.fajr,
      );
    });
  });

  group('formatDuration', () {
    test('formatDuration: characterization of known dual-form defect', () {
      // The defect produced "٢٤ ساعات و٥٠ دقيقة" at 04:00; the fix shows 50m.
      expect(
        PrayerSchedule.formatDuration(const Duration(minutes: 50)),
        '٥٠ دقيقة',
      );
      // KNOWN DEFECT (characterization, NOT acceptance): the formatter
      // prefixes the dual form with its numeral ("٢ ساعتين" instead of
      // "ساعتين"). This assertion pins the current wrong output so a future
      // formatting fix is a conscious change; it does not endorse it.
      expect(
        PrayerSchedule.formatDuration(const Duration(hours: 2, minutes: 5)),
        '٢ ساعتين و٥ دقائق',
      );
    });
  });
}
