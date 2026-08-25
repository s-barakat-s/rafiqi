import 'package:hijri/hijri_calendar.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/time/local_day.dart';

/// Representation of a Hijri date and formatting helpers.
class HijriDate {
  const HijriDate({required this.year, required this.month, required this.day});

  final int year;
  final int month;
  final int day;

  static const List<String> monthNames = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  static const List<String> gregorianMonthNames = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  static const List<String> weekdayNames = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  static const List<String> shortWeekdayNames = [
    'س',
    'ح',
    'ن',
    'ث',
    'ر',
    'خ',
    'ج',
  ];

  String get monthName => monthNames[month - 1];

  /// Creates a [HijriDate] from a Gregorian [DateTime].
  factory HijriDate.fromGregorian(DateTime date) {
    HijriCalendar.setLocal('ar');
    final local = LocalDay.date(date);
    final hijri = HijriCalendar.fromDate(local);
    return HijriDate(year: hijri.hYear, month: hijri.hMonth, day: hijri.hDay);
  }

  /// Creates a [HijriDate] for today in local time.
  factory HijriDate.now() => HijriDate.fromGregorian(DateTime.now());

  /// Converts this [HijriDate] back to its Gregorian [DateTime] representation.
  DateTime toGregorian() {
    HijriCalendar.setLocal('ar');
    final hijri = HijriCalendar()
      ..hYear = year
      ..hMonth = month
      ..hDay = day;
    final gregorian = hijri.hijriToGregorian(year, month, day);
    return LocalDay.date(gregorian);
  }

  /// Returns the number of days in the given Hijri year and month (29 or 30).
  static int getDaysInMonth(int year, int month) {
    HijriCalendar.setLocal('ar');
    final hijri = HijriCalendar();
    return hijri.getDaysInMonth(year, month);
  }

  /// Formatted Hijri date with Arabic-Indic numerals, e.g. "١٧ صفر ١٤٤٨ هـ".
  String formatFull({bool includeSuffix = true}) {
    final formattedDay = ArabicNumerals.integer(day, groupThousands: false);
    final formattedYear = ArabicNumerals.integer(year, groupThousands: false);
    final suffix = includeSuffix ? ' هـ' : '';
    return '$formattedDay $monthName $formattedYear$suffix';
  }

  /// Formatted Hijri month and year, e.g. "صفر ١٤٤٨ هـ".
  String formatMonthYear({bool includeSuffix = true}) {
    final formattedYear = ArabicNumerals.integer(year, groupThousands: false);
    final suffix = includeSuffix ? ' هـ' : '';
    return '$monthName $formattedYear$suffix';
  }

  /// Formats a Gregorian [DateTime] into Arabic weekday and date string,
  /// e.g. "الثلاثاء، ٢٥ أغسطس".
  static String formatGregorianDayMonth(DateTime date) {
    final local = LocalDay.date(date);
    final weekday = weekdayNames[local.weekday - 1];
    final day = ArabicNumerals.integer(local.day, groupThousands: false);
    final month = gregorianMonthNames[local.month - 1];
    return '$weekday، $day $month';
  }

  /// Formats a Gregorian [DateTime] into full Arabic date with year,
  /// e.g. "٢٥ أغسطس ٢٠٢٦ م" or "الثلاثاء، ٢٥ أغسطس ٢٠٢٦ م".
  static String formatGregorianFull(
    DateTime date, {
    bool includeWeekday = false,
    bool includeSuffix = true,
  }) {
    final local = LocalDay.date(date);
    final day = ArabicNumerals.integer(local.day, groupThousands: false);
    final month = gregorianMonthNames[local.month - 1];
    final year = ArabicNumerals.integer(local.year, groupThousands: false);
    final suffix = includeSuffix ? ' م' : '';
    if (includeWeekday) {
      final weekday = weekdayNames[local.weekday - 1];
      return '$weekday، $day $month $year$suffix';
    }
    return '$day $month $year$suffix';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HijriDate &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => '$year/$month/$day AH';
}
