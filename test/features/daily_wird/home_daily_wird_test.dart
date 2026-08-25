import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_progress_repository.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/presentation/controllers/wird_reader_controller.dart';
import 'package:tasbeh/features/daily_wird/data/repositories/daily_wird_repository.dart';
import 'package:tasbeh/features/daily_wird/domain/entities/daily_wird.dart';
import 'package:tasbeh/features/home/presentation/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Stage 2 — Home & Daily Wird Logic', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await DailyWirdRepository.instance.initialize();
    });

    test(
      'Morning/Evening can be completed manually and toggled back to incomplete',
      () async {
        final repository = DailyWirdRepository.instance;
        await repository.initialize();

        expect(
          repository.todayRecord.items
              .firstWhere((i) => i.id == 'morning_adhkar')
              .completed,
          isFalse,
        );

        // Complete manually
        await repository.setCompleted('morning_adhkar', true, source: 'manual');
        expect(
          repository.todayRecord.items
              .firstWhere((i) => i.id == 'morning_adhkar')
              .completed,
          isTrue,
        );

        // Uncomplete
        await repository.setCompleted('morning_adhkar', false);
        expect(
          repository.todayRecord.items
              .firstWhere((i) => i.id == 'morning_adhkar')
              .completed,
          isFalse,
        );
      },
    );

    test(
      'Reader completion sets Daily item, and manual uncheck does NOT reset Reader progress',
      () async {
        final repository = DailyWirdRepository.instance;
        await repository.initialize();

        const morningCategory = AdhkarCategory(
          id: 'morning',
          kind: AdhkarCategoryKind.morning,
          title: 'أذكار الصباح',
          subtitle: '',
          items: [
            DhikrItem(
              id: 'm1',
              order: 1,
              category: 'morning',
              text: 'ذكر',
              repeatCount: 1,
              entryType: DhikrEntryType.single,
            ),
          ],
        );

        final reader = WirdReaderController(category: morningCategory);
        await reader.initialize();
        await reader.decrementItem('m1');

        expect(reader.isComplete, isTrue);
        expect(
          repository.todayRecord.items
              .firstWhere((i) => i.id == 'morning_adhkar')
              .completed,
          isTrue,
        );

        // User unchecks the Daily item on Home
        await repository.setCompleted('morning_adhkar', false);
        expect(
          repository.todayRecord.items
              .firstWhere((i) => i.id == 'morning_adhkar')
              .completed,
          isFalse,
        );

        // Reader progress is still complete and untouched
        final storedReaderProgress = await AdhkarProgressRepository.instance
            .load(morningCategory);
        expect(storedReaderProgress.isCompleted, isTrue);

        // Reopening repository / app restart does not re-force completion
        await repository.initialize();
        expect(
          repository.todayRecord.items
              .firstWhere((i) => i.id == 'morning_adhkar')
              .completed,
          isFalse,
        );
      },
    );

    test(
      'Today is complete only when Morning, Evening, and custom tasks are all completed',
      () async {
        final repository = DailyWirdRepository.instance;
        await repository.initialize();

        await repository.addTask(
          const DailyTask(
            id: 'custom_quran',
            title: 'ورد القرآن',
            type: 'تلاوة',
          ),
        );

        // Morning complete
        await repository.setCompleted('morning_adhkar', true);
        expect(repository.todayRecord.completed, isFalse);
        expect(repository.readyForStreak, isFalse);

        // Evening complete
        await repository.setCompleted('evening_adhkar', true);
        expect(repository.todayRecord.completed, isFalse);
        expect(repository.readyForStreak, isFalse);

        // Custom task complete -> All completed
        await repository.setCompleted('custom_quran', true);
        expect(repository.todayRecord.completed, isTrue);
        expect(repository.readyForStreak, isTrue);

        // Unchecking any item reverts today completion
        await repository.setCompleted('morning_adhkar', false);
        expect(repository.todayRecord.completed, isFalse);
        expect(repository.readyForStreak, isFalse);
      },
    );
  });

  group('HomeScreen Daily Wird UI', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await DailyWirdRepository.instance.initialize();
    });

    Widget createTestHome() => MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: HomeScreen(onOpenTasbeeh: () {}, onOpenAdhkar: (_) async {}),
      ),
    );

    testWidgets(
      'Tapping incomplete base task shows confirmation dialog, tapping completed task unchecks immediately',
      (tester) async {
        await tester.pumpWidget(createTestHome());
        await tester.pumpAndSettle();

        // Tap on morning_adhkar row (أذكار الصباح)
        await tester.tap(find.text('أذكار الصباح').last);
        await tester.pumpAndSettle();

        // Confirmation dialog appears
        expect(find.text('هل أتممت هذا الورد خارج التطبيق؟'), findsOneWidget);

        // Confirm
        await tester.tap(find.text('نعم، تم'));
        await tester.pumpAndSettle();

        expect(
          DailyWirdRepository.instance.todayRecord.items
              .firstWhere((i) => i.id == 'morning_adhkar')
              .completed,
          isTrue,
        );

        // Tap again on morning_adhkar row
        await tester.tap(find.text('أذكار الصباح').last);
        await tester.pumpAndSettle();

        // Dialog does NOT appear; task is immediately unchecked
        expect(find.text('هل أتممت هذا الورد خارج التطبيق؟'), findsNothing);
        expect(
          DailyWirdRepository.instance.todayRecord.items
              .firstWhere((i) => i.id == 'morning_adhkar')
              .completed,
          isFalse,
        );
      },
    );
  });
}
