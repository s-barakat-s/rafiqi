import 'package:flutter/foundation.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/time/local_day.dart';

/// Prayer types shown in the Home daily strip, in RTL display order.
enum PrayerItemType { fajr, sunrise, dhuhr, asr, maghrib, isha }

/// A single prayer/sun event shown in the strip.
@immutable
class PrayerTimeItem {
  const PrayerTimeItem({
    required this.type,
    required this.name,
    required this.time,
  });

  final PrayerItemType type;
  final String name;
  final DateTime time;
}

/// State of the current moment relative to prayer times.
enum PrayerStatusKind {
  /// Inside the [PrayerSchedule.prayerWindow] of a prayer, e.g. "حان الآن وقت الشروق".
  ongoing,

  /// Waiting for the next prayer, e.g. "باقي على الظهر ...".
  upcoming,

  /// A prayer just passed, e.g. "مرّ على الظهر ...".
  passed,
}

@immutable
class PrayerStatus {
  const PrayerStatus({
    required this.kind,
    required this.prayer,
    this.duration = Duration.zero,
  });

  final PrayerStatusKind kind;

  /// The prayer the status refers to (ongoing/upcoming/passed one).
  final PrayerTimeItem prayer;

  /// Remaining time for [PrayerStatusKind.upcoming], elapsed for
  /// [PrayerStatusKind.passed]; zero for [PrayerStatusKind.ongoing].
  final Duration duration;
}

/// Immutable snapshot used by the Home top section.
@immutable
class PrayerScheduleSnapshot {
  const PrayerScheduleSnapshot({
    required this.items,
    required this.status,
    required this.highlightedType,
  });

  final List<PrayerTimeItem> items;
  final PrayerStatus status;

  /// The single prayer the strip should highlight.
  final PrayerItemType highlightedType;
}

/// Presentation source for the Home prayer header.
///
/// Currently backed by placeholder times and a placeholder location; replace
/// [timesFor] and [locationLabel] with a real prayer-time/location provider
/// without touching the UI.
abstract final class PrayerSchedule {
  /// Grace period after a prayer during which it counts as "ongoing".
  static const Duration prayerWindow = Duration(minutes: 30);

  /// A prayer counts as "just passed" only for this long; afterwards the UI
  /// switches to counting down to the next prayer.
  static const Duration recentlyPassed = Duration(hours: 1);

  /// Placeholder until a real location source is available.
  static const String locationLabel = 'الرياض، المملكة العربية السعودية';

  static const Map<PrayerItemType, String> _names = {
    PrayerItemType.fajr: 'الفجر',
    PrayerItemType.sunrise: 'الشروق',
    PrayerItemType.dhuhr: 'الظهر',
    PrayerItemType.asr: 'العصر',
    PrayerItemType.maghrib: 'المغرب',
    PrayerItemType.isha: 'العشاء',
  };

  // Placeholder times (24h). Replace with a real calculation/provider.
  static const Map<PrayerItemType, TimeOfDayish> _placeholderTimes = {
    PrayerItemType.fajr: TimeOfDayish(4, 50),
    PrayerItemType.sunrise: TimeOfDayish(6, 23),
    PrayerItemType.dhuhr: TimeOfDayish(12, 5),
    PrayerItemType.asr: TimeOfDayish(15, 35),
    PrayerItemType.maghrib: TimeOfDayish(18, 12),
    PrayerItemType.isha: TimeOfDayish(19, 42),
  };

  /// Builds the day's prayer items ordered fajr → isha.
  static List<PrayerTimeItem> timesFor(DateTime day) {
    final local = LocalDay.date(day);
    return PrayerItemType.values.map((type) {
      final time = _placeholderTimes[type]!;
      return PrayerTimeItem(
        type: type,
        name: _names[type]!,
        time: DateTime(local.year, local.month, local.day, time.hour, time.minute),
      );
    }).toList();
  }

  static PrayerScheduleSnapshot snapshot(DateTime now) {
    final items = timesFor(now);
    var status = _statusFor(items, now);
    return PrayerScheduleSnapshot(
      items: items,
      status: status,
      highlightedType: _highlightedType(items, status, now),
    );
  }

  static PrayerStatus _statusFor(List<PrayerTimeItem> items, DateTime now) {
    PrayerTimeItem? last;
    for (final item in items) {
      if (!now.isBefore(item.time) &&
          now.isBefore(item.time.add(prayerWindow))) {
        return PrayerStatus(kind: PrayerStatusKind.ongoing, prayer: item);
      }
      if (now.isBefore(item.time)) {
        final elapsed = last == null ? null : now.difference(last.time);
        if (last != null && elapsed! <= recentlyPassed) {
          return PrayerStatus(
            kind: PrayerStatusKind.passed,
            prayer: last,
            duration: elapsed,
          );
        }
        // Before today's fajr (last == null) or between two prayers:
        // the next prayer is this day's item. Tomorrow's fajr is handled
        // by the after-isha branch below.
        final target = item;
        return PrayerStatus(
          kind: PrayerStatusKind.upcoming,
          prayer: target,
          duration: target.time.difference(now),
        );
      }
      last = item;
    }
    // After isha: either it just passed, or count down to tomorrow's fajr.
    final isha = items.last;
    final elapsed = now.difference(isha.time);
    final tomorrowFajr = _tomorrowFajr(items.first);
    if (elapsed <= recentlyPassed) {
      return PrayerStatus(
        kind: PrayerStatusKind.passed,
        prayer: isha,
        duration: elapsed,
      );
    }
    return PrayerStatus(
      kind: PrayerStatusKind.upcoming,
      prayer: tomorrowFajr,
      duration: tomorrowFajr.time.difference(now),
    );
  }

  static PrayerTimeItem _tomorrowFajr(PrayerTimeItem todayFajr) =>
      PrayerTimeItem(
        type: todayFajr.type,
        name: todayFajr.name,
        time: todayFajr.time.add(const Duration(days: 1)),
      );

  static PrayerItemType _highlightedType(
    List<PrayerTimeItem> items,
    PrayerStatus status,
    DateTime now,
  ) {
    if (status.kind == PrayerStatusKind.ongoing) return status.prayer.type;
    // For upcoming/passed states the relevant prayer is the next one ahead.
    for (final item in items) {
      if (now.isBefore(item.time)) return item.type;
    }
    return PrayerItemType.fajr;
  }

  /// Formats a duration in Arabic, e.g. "٥ ساعات و٢٧ دقيقة" / "٣٥ دقيقة".
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final parts = <String>[
      if (hours > 0)
        '${ArabicNumerals.integer(hours)} ${_hoursWord(hours)}',
      if (minutes > 0)
        '${ArabicNumerals.integer(minutes)} ${_minutesWord(minutes)}',
    ];
    if (parts.isEmpty) return 'الآن';
    return parts.join(' و');
  }

  static String _hoursWord(int hours) => switch (hours) {
        1 => 'ساعة',
        2 => 'ساعتين',
        <= 10 => 'ساعات',
        _ => 'ساعة',
      };

  static String _minutesWord(int minutes) => switch (minutes) {
        1 => 'دقيقة',
        2 => 'دقيقتين',
        <= 10 => 'دقائق',
        _ => 'دقيقة',
      };
}

/// Minimal hour/minute holder for the placeholder schedule.
@immutable
class TimeOfDayish {
  const TimeOfDayish(this.hour, this.minute);
  final int hour;
  final int minute;
}
