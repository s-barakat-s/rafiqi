import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeh/core/time/hijri_date.dart';

void main() {
  test('HijriDate correctly converts from and to Gregorian', () {
    final gregorian = DateTime(2026, 8, 25);
    final hijri = HijriDate.fromGregorian(gregorian);

    expect(hijri.year, greaterThan(1440));
    expect(hijri.month, isIn([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]));
    expect(hijri.day, greaterThanOrEqualTo(1));
    expect(hijri.day, lessThanOrEqualTo(30));

    final backToGregorian = hijri.toGregorian();
    expect(backToGregorian.year, equals(2026));
    expect(backToGregorian.month, equals(8));
    expect(backToGregorian.day, equals(25));
  });

  test('HijriDate formats strings with Arabic numerals', () {
    final date = DateTime(2026, 8, 25);
    final hijri = HijriDate.fromGregorian(date);

    final full = hijri.formatFull();
    expect(full, contains('هـ'));
    expect(full, contains(hijri.monthName));

    final gregDayMonth = HijriDate.formatGregorianDayMonth(date);
    expect(gregDayMonth, contains('الثلاثاء'));
    expect(gregDayMonth, contains('أغسطس'));
    expect(gregDayMonth, contains('٢٥'));

    final gregFull = HijriDate.formatGregorianFull(date);
    expect(gregFull, contains('٢٥'));
    expect(gregFull, contains('أغسطس'));
    expect(gregFull, contains('٢٠٢٦'));
    expect(gregFull, contains('م'));
  });
}
