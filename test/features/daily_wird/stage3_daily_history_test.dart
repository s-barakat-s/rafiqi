import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/time/local_day.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/daily_wird/data/repositories/daily_wird_repository.dart';
import 'package:tasbeh/features/daily_wird/domain/entities/daily_wird.dart';
import 'package:tasbeh/features/journey/presentation/screens/journey_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Stage 3 — Daily History & Grace Days Domain/Data', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Historical daily snapshot immutability', () async {
      final repository = DailyWirdRepository.instance;
      await repository.initialize();

      final today = LocalDay.date(DateTime.now());
      final yesterday = today.subtract(const Duration(days: 1));

      // Check yesterday items
      final pastRecord = repository.recordFor(yesterday);
      expect(pastRecord, isNotNull);
      final initialPastCount = pastRecord!.items.length;

      // Add a new task today
      await repository.addTask(
        const DailyTask(id: 'new_task_today', title: 'عمل جديد', type: 'ذكر'),
      );

      // Today should have the new task
      expect(
        repository.todayRecord.items.any((i) => i.id == 'new_task_today'),
        isTrue,
      );

      // Yesterday should NOT be modified
      final pastRecordAfter = repository.recordFor(yesterday);
      expect(pastRecordAfter!.items.length, initialPastCount);
      expect(
        pastRecordAfter.items.any((i) => i.id == 'new_task_today'),
        isFalse,
      );
    });

    test(
      'Past day editing toggles items and recalculates streak and completion',
      () async {
        final repository = DailyWirdRepository.instance;
        await repository.initialize();

        final today = LocalDay.date(DateTime.now());
        final day1 = today.subtract(const Duration(days: 1));
        final day2 = today.subtract(const Duration(days: 2));

        // Day 2 complete
        await repository.setCompleted('morning_adhkar', true, day: day2);
        await repository.setCompleted('evening_adhkar', true, day: day2);
        expect(repository.recordFor(day2)!.completed, isTrue);

        // Day 1 incomplete
        expect(repository.recordFor(day1)!.completed, isFalse);
        expect(repository.currentStreak, 0);

        // Edit Day 1: complete morning & evening
        await repository.setCompleted('morning_adhkar', true, day: day1);
        await repository.setCompleted('evening_adhkar', true, day: day1);
        expect(repository.recordFor(day1)!.completed, isTrue);

        // Now streak connects day 2 and day 1 -> 2 days!
        expect(repository.currentStreak, 2);

        // Unchecking one item on day 1 breaks the streak again
        await repository.setCompleted('morning_adhkar', false, day: day1);
        expect(repository.recordFor(day1)!.completed, isFalse);
        expect(repository.currentStreak, 0);
      },
    );

    test(
      'Grace days preserve streak continuity without marking day as genuinely completed',
      () async {
        final repository = DailyWirdRepository.instance;
        await repository.initialize();

        final today = LocalDay.date(DateTime.now());
        final day1 = today.subtract(const Duration(days: 1));
        final day2 = today.subtract(const Duration(days: 2));

        // Day 2 complete
        await repository.setCompleted('morning_adhkar', true, day: day2);
        await repository.setCompleted('evening_adhkar', true, day: day2);
        expect(repository.recordFor(day2)!.completed, isTrue);

        // Day 1 incomplete, but use grace day
        expect(repository.remainingGraceDaysInMonth(day1), 2);
        await repository.setGraceUsed(day1, true);

        final record1 = repository.recordFor(day1)!;
        expect(record1.graceUsed, isTrue);
        expect(record1.completed, isFalse); // Grace is NOT completion!
        expect(repository.remainingGraceDaysInMonth(day1), 1);

        // Streak is preserved through Day 1 grace!
        expect(repository.currentStreak, 2);
      },
    );

    test(
      'Grace refund: completing all items on a grace day clears grace and refunds allowance',
      () async {
        final repository = DailyWirdRepository.instance;
        await repository.initialize();

        final today = LocalDay.date(DateTime.now());
        final day1 = today.subtract(const Duration(days: 1));

        // Use grace on Day 1
        await repository.setGraceUsed(day1, true);
        expect(repository.remainingGraceDaysInMonth(day1), 1);
        expect(repository.recordFor(day1)!.graceUsed, isTrue);

        // Later, user completes all required items on Day 1
        await repository.setCompleted('morning_adhkar', true, day: day1);
        await repository.setCompleted('evening_adhkar', true, day: day1);

        // Record is now completed and grace is refunded
        final updatedRecord = repository.recordFor(day1)!;
        expect(updatedRecord.completed, isTrue);
        expect(updatedRecord.graceUsed, isFalse);
        expect(repository.remainingGraceDaysInMonth(day1), 2);
      },
    );

    test('Grace limit: maximum 2 grace days per calendar month', () async {
      final repository = DailyWirdRepository.instance;
      await repository.initialize();

      final today = LocalDay.date(DateTime.now());
      final day1 = today.subtract(const Duration(days: 1));
      final day2 = today.subtract(const Duration(days: 2));
      final day3 = today.subtract(const Duration(days: 3));

      expect(repository.remainingGraceDaysInMonth(today), 2);

      // Use 1st grace day
      await repository.setGraceUsed(day1, true);
      expect(repository.remainingGraceDaysInMonth(today), 1);

      // Use 2nd grace day
      await repository.setGraceUsed(day2, true);
      expect(repository.remainingGraceDaysInMonth(today), 0);

      // Attempt 3rd grace day in the same month -> rejected / ignored
      await repository.setGraceUsed(day3, true);
      expect(repository.recordFor(day3)!.graceUsed, isFalse);
      expect(repository.remainingGraceDaysInMonth(today), 0);
    });

    test('Cannot use grace day on current or future day', () async {
      final repository = DailyWirdRepository.instance;
      await repository.initialize();

      final today = LocalDay.date(DateTime.now());
      await repository.setGraceUsed(today, true);
      expect(repository.recordFor(today)!.graceUsed, isFalse);
    });

    test(
      'Backward compatibility: old JSON without graceUsed defaults to false',
      () {
        final json = {
          'date': '2026-08-20',
          'completed': true,
          'items': [
            {
              'id': 'morning_adhkar',
              'title': 'أذكار الصباح',
              'type': 'ذكر',
              'completed': true,
            },
          ],
        };

        final record = DailyHistoryRecord.fromJson(json);
        expect(record.graceUsed, isFalse);
        expect(record.completed, isTrue);
      },
    );
  });

  group('Journey Screen Day Details & Grace UI', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await DailyWirdRepository.instance.initialize();
    });

    Widget createTestJourney() => MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const Scaffold(body: JourneyScreen()),
    );

    testWidgets(
      'Tapping a past day opens DayDetails and allows item editing and grace toggle',
      (tester) async {
        final repository = DailyWirdRepository.instance;
        final today = LocalDay.date(DateTime.now());
        final yesterday = today.subtract(const Duration(days: 1));

        await tester.pumpWidget(createTestJourney());
        await tester.pumpAndSettle();

        // Tap yesterday in calendar (yesterday's day number in Arabic numerals)
        final yesterdayFinder = find.text(
          ArabicNumerals.integer(yesterday.day),
        );
        expect(yesterdayFinder, findsWidgets);
        await tester.ensureVisible(yesterdayFinder.first);
        await tester.pumpAndSettle();
        await tester.tap(yesterdayFinder.first);
        await tester.pumpAndSettle();

        // Day details bottom sheet opened
        expect(find.text('أذكار الصباح'), findsOneWidget);
        expect(find.text('أذكار المساء'), findsOneWidget);
        expect(find.text('استخدام يوم سماح'), findsOneWidget);

        // Tap "استخدام يوم سماح"
        await tester.tap(find.text('استخدام يوم سماح'));
        await tester.pumpAndSettle();

        expect(repository.recordFor(yesterday)!.graceUsed, isTrue);
        expect(find.text('إلغاء السماح'), findsOneWidget);

        // Toggle item to complete
        await tester.tap(find.text('أذكار الصباح'));
        await tester.pumpAndSettle();
        expect(
          repository
              .recordFor(yesterday)!
              .items
              .firstWhere((i) => i.id == 'morning_adhkar')
              .completed,
          isTrue,
        );
      },
    );
  });
}
