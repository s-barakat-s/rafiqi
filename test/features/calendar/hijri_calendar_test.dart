import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/core/time/hijri_date.dart';
import 'package:tasbeh/features/calendar/presentation/screens/hijri_calendar_screen.dart';
import 'package:tasbeh/features/daily_wird/data/repositories/daily_wird_repository.dart';
import 'package:tasbeh/features/home/presentation/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DailyWirdRepository.instance.initialize();
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );
  }

  testWidgets(
    'HomeScreen displays dynamic date and opens HijriCalendar on tap',
    (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          HomeScreen(onOpenTasbeeh: () {}, onOpenAdhkar: (_) async {}),
        ),
      );
      await tester.pumpAndSettle();

      final todayHijri = HijriDate.now();
      final todayGregorian = DateTime.now();

      // Verify dynamic text is rendered
      expect(find.text(todayHijri.formatFull()), findsOneWidget);
      expect(
        find.text(HijriDate.formatGregorianDayMonth(todayGregorian)),
        findsOneWidget,
      );

      // Tap the date area
      await tester.tap(find.text(todayHijri.formatFull()));
      await tester.pumpAndSettle();

      // Verify HijriCalendarScreen is opened
      expect(find.text('التقويم الهجري'), findsOneWidget);
      expect(find.text(todayHijri.formatMonthYear()), findsOneWidget);
    },
  );

  testWidgets(
    'HijriCalendarScreen navigates months and displays Gregorian date on day tap',
    (tester) async {
      await tester.pumpWidget(createTestWidget(const HijriCalendarScreen()));
      await tester.pumpAndSettle();

      final todayHijri = HijriDate.now();

      // Verify title and month name
      expect(find.text('التقويم الهجري'), findsOneWidget);
      expect(find.text(todayHijri.formatMonthYear()), findsOneWidget);

      // Verify today's panel is present
      expect(find.text('يوافق'), findsOneWidget);
      expect(
        find.text(
          HijriDate.formatGregorianFull(
            todayHijri.toGregorian(),
            includeWeekday: true,
            includeSuffix: true,
          ),
        ),
        findsOneWidget,
      );

      // Navigate to next month
      await tester.tap(find.byTooltip('الشهر التالي'));
      await tester.pumpAndSettle();

      // "اليوم" button should now appear
      expect(find.text('اليوم'), findsOneWidget);

      // Tap "اليوم" to return to current month
      await tester.tap(find.text('اليوم'));
      await tester.pumpAndSettle();

      expect(find.text(todayHijri.formatMonthYear()), findsOneWidget);

      // Tap a specific day in the grid, e.g. day 5
      final day5String = ArabicNumerals.integer(5, groupThousands: false);
      final day5Finder = find.text(day5String);
      if (day5Finder.evaluate().isNotEmpty) {
        await tester.tap(day5Finder.first);
        await tester.pumpAndSettle();

        final day5Hijri = HijriDate(
          year: todayHijri.year,
          month: todayHijri.month,
          day: 5,
        );
        final day5Gregorian = day5Hijri.toGregorian();

        expect(
          find.text(
            HijriDate.formatGregorianFull(
              day5Gregorian,
              includeWeekday: true,
              includeSuffix: true,
            ),
          ),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets(
    'HijriCalendarScreen handles previous month and year boundary correctly',
    (tester) async {
      await tester.pumpWidget(createTestWidget(const HijriCalendarScreen()));
      await tester.pumpAndSettle();

      final todayHijri = HijriDate.now();

      // Tap previous month
      await tester.tap(find.byTooltip('الشهر السابق'));
      await tester.pumpAndSettle();

      final expectedPrevMonth = todayHijri.month == 1
          ? 12
          : todayHijri.month - 1;
      final expectedPrevYear = todayHijri.month == 1
          ? todayHijri.year - 1
          : todayHijri.year;
      final expectedPrevHijri = HijriDate(
        year: expectedPrevYear,
        month: expectedPrevMonth,
        day: 1,
      );

      expect(find.text(expectedPrevHijri.formatMonthYear()), findsOneWidget);

      // Tap back button
      await tester.tap(find.byTooltip('رجوع'));
      await tester.pumpAndSettle();
    },
  );
}
