import 'package:tasbeh/features/home/presentation/models/prayer_header_data.dart';

abstract final class WeekdayAssets {
  static const root = 'assets/image/home/days';

  static const paths = <AppWeekday, String>{
    AppWeekday.sunday: '$root/الاحد.png',
    AppWeekday.monday: '$root/الاثنين.png',
    AppWeekday.tuesday: '$root/الثلاثاء.png',
    AppWeekday.wednesday: '$root/الاربعاء.png',
    AppWeekday.thursday: '$root/الخميس.png',
    AppWeekday.friday: '$root/الجمعة.png',
    AppWeekday.saturday: '$root/السبت.png',
  };

  static String pathFor(AppWeekday weekday) => paths[weekday]!;
}
