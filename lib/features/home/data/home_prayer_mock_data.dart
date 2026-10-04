import 'package:tasbeh/features/home/presentation/models/prayer_header_data.dart';

/// Temporary presentation input. Replace this constant with a mapper from the
/// real prayer/date state without changing the prayer header widgets.
abstract final class HomePrayerMockData {
  static const header = PrayerHeaderData(
    hijriDate: '22 شوال 1447 هـ',
    hijriMonth: 'شوال',
    weekday: AppWeekday.wednesday,
    nowLabel: 'الآن',
    currentPrayerName: 'العصـــــر',
    currentPrayerTime: '3:31',
    period: 'PM',
    prayerTimesActionLabel: 'المزيد من مواقيت الصلاة',
    qiblaActionLabel: 'تحديد اتجاه القبلة',
    prayerTimes: [
      PrayerTimeData(name: 'الفجر', time: '05:17'),
      PrayerTimeData(name: 'الظهر', time: '01:07'),
      PrayerTimeData(name: 'العصر', time: '03:31', isCurrent: true),
      PrayerTimeData(name: 'المغرب', time: '07:31'),
      PrayerTimeData(name: 'العشاء', time: '08:31'),
    ],
  );
}
