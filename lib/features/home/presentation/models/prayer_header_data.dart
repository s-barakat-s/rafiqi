import 'package:flutter/foundation.dart';

enum AppWeekday {
  sunday,
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
}

@immutable
class PrayerTimeData {
  const PrayerTimeData({
    required this.name,
    required this.time,
    this.isCurrent = false,
  });

  final String name;
  final String time;
  final bool isCurrent;
}

@immutable
class PrayerHeaderData {
  const PrayerHeaderData({
    required this.hijriDate,
    required this.weekday,
    required this.nowLabel,
    required this.currentPrayerName,
    required this.currentPrayerTime,
    required this.period,
    required this.prayerTimesActionLabel,
    required this.qiblaActionLabel,
    required this.prayerTimes,
    this.hijriMonth,
  });

  final String hijriDate;
  final String? hijriMonth;
  final AppWeekday weekday;
  final String nowLabel;
  final String currentPrayerName;
  final String currentPrayerTime;
  final String period;
  final String prayerTimesActionLabel;
  final String qiblaActionLabel;
  final List<PrayerTimeData> prayerTimes;
}
