import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_progress_repository.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/domain/entities/wird_reader_mode.dart';
import 'package:tasbeh/features/adhkar/presentation/controllers/wird_reader_controller.dart';
import 'package:tasbeh/features/adhkar/presentation/screens/dhikr_details_screen.dart';
import 'package:tasbeh/features/adhkar/presentation/screens/wird_reader_screen.dart';
import 'package:tasbeh/features/daily_wird/data/repositories/daily_wird_repository.dart';
import 'package:tasbeh/features/settings/data/repositories/app_preferences_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WirdReaderController multi-step Undo', () {
    late AdhkarCategory testCategory;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      testCategory = const AdhkarCategory(
        id: 'undo-test',
        kind: AdhkarCategoryKind.morning,
        title: 'أذكار الصباح',
        subtitle: '',
        items: [
          DhikrItem(
            id: 'item-a',
            order: 1,
            category: 'undo-test',
            text: 'الذكر أ',
            repeatCount: 3,
            entryType: DhikrEntryType.single,
          ),
          DhikrItem(
            id: 'item-b',
            order: 2,
            category: 'undo-test',
            text: 'الذكر ب',
            repeatCount: 1,
            entryType: DhikrEntryType.single,
          ),
          DhikrItem(
            id: 'item-c',
            order: 3,
            category: 'undo-test',
            text: 'الذكر ج',
            repeatCount: 2,
            entryType: DhikrEntryType.single,
          ),
        ],
      );
    });

    test('Scenario 1 — Repetitions within single item', () async {
      final controller = WirdReaderController(category: testCategory);
      await controller.initialize();

      expect(controller.canUndo, isFalse);
      expect(controller.remainingFor('item-a'), 3);
      expect(controller.current.id, 'item-a');

      // Tap 1: 3 -> 2
      await controller.decrementItem('item-a');
      expect(controller.canUndo, isTrue);
      expect(controller.remainingFor('item-a'), 2);
      expect(controller.remaining, 2);

      // Tap 2: 2 -> 1
      await controller.decrementItem('item-a');
      expect(controller.remainingFor('item-a'), 1);
      expect(controller.remaining, 1);

      // Tap 3: 1 -> completed (moves to item-b)
      await controller.decrementItem('item-a');
      expect(controller.isItemCompleted('item-a'), isTrue);
      expect(controller.current.id, 'item-b');
      expect(controller.remaining, 1);

      // Undo 1: item-a restored with remaining 1
      await controller.undo();
      expect(controller.isItemCompleted('item-a'), isFalse);
      expect(controller.current.id, 'item-a');
      expect(controller.remainingFor('item-a'), 1);
      expect(controller.remaining, 1);

      // Undo 2: item-a restored with remaining 2
      await controller.undo();
      expect(controller.current.id, 'item-a');
      expect(controller.remainingFor('item-a'), 2);
      expect(controller.remaining, 2);

      // Undo 3: item-a restored with remaining 3
      await controller.undo();
      expect(controller.current.id, 'item-a');
      expect(controller.remainingFor('item-a'), 3);
      expect(controller.remaining, 3);
      expect(controller.canUndo, isFalse);

      // Undo again does nothing
      await controller.undo();
      expect(controller.current.id, 'item-a');
      expect(controller.remainingFor('item-a'), 3);
    });

    test('Scenario 2 — Multi-step Undo across items', () async {
      final controller = WirdReaderController(category: testCategory);
      await controller.initialize();

      // Complete A (3 taps)
      await controller.decrementItem('item-a');
      await controller.decrementItem('item-a');
      await controller.decrementItem('item-a');
      expect(controller.isItemCompleted('item-a'), isTrue);
      expect(controller.current.id, 'item-b');

      // Complete B (1 tap)
      await controller.decrementItem('item-b');
      expect(controller.isItemCompleted('item-b'), isTrue);
      expect(controller.current.id, 'item-c');
      expect(controller.remaining, 2);

      // Undo 1 -> return to B, remaining 1
      await controller.undo();
      expect(controller.current.id, 'item-b');
      expect(controller.isItemCompleted('item-b'), isFalse);
      expect(controller.remainingFor('item-b'), 1);
      expect(controller.remaining, 1);

      // Undo 2 -> return to A, remaining 1
      await controller.undo();
      expect(controller.current.id, 'item-a');
      expect(controller.isItemCompleted('item-a'), isFalse);
      expect(controller.remainingFor('item-a'), 1);
      expect(controller.remaining, 1);

      // Undo 3 -> A remaining 2
      await controller.undo();
      expect(controller.current.id, 'item-a');
      expect(controller.remainingFor('item-a'), 2);
      expect(controller.remaining, 2);

      // Undo 4 -> A remaining 3
      await controller.undo();
      expect(controller.current.id, 'item-a');
      expect(controller.remainingFor('item-a'), 3);
      expect(controller.remaining, 3);
      expect(controller.canUndo, isFalse);
    });

    test(
      'Scenario 5 — State produced by Undo is persisted correctly',
      () async {
        final controller = WirdReaderController(category: testCategory);
        await controller.initialize();

        // Complete item-a (3 taps) and item-b (1 tap)
        await controller.decrementItem('item-a');
        await controller.decrementItem('item-a');
        await controller.decrementItem('item-a');
        await controller.decrementItem('item-b');

        // Undo twice -> item-a with remaining 1
        await controller.undo(); // B restored
        await controller.undo(); // A restored with remaining 1

        expect(controller.current.id, 'item-a');
        expect(controller.remainingFor('item-a'), 1);
        expect(controller.isItemCompleted('item-a'), isFalse);
        expect(controller.isItemCompleted('item-b'), isFalse);

        // Reopen session via fresh controller instance
        final reopened = WirdReaderController(category: testCategory);
        await reopened.initialize();

        expect(reopened.current.id, 'item-a');
        expect(reopened.remainingFor('item-a'), 1);
        expect(reopened.isItemCompleted('item-a'), isFalse);
        expect(reopened.isItemCompleted('item-b'), isFalse);
        expect(reopened.remainingItems.map((i) => i.id), [
          'item-a',
          'item-b',
          'item-c',
        ]);
      },
    );

    test(
      'Scenario 8 — Reader completion reversal does not uncheck Daily Wird',
      () async {
        await DailyWirdRepository.instance.initialize();
        const morningCategory = AdhkarCategory(
          id: 'morning',
          kind: AdhkarCategoryKind.morning,
          title: 'أذكار الصباح',
          subtitle: '',
          items: [
            DhikrItem(
              id: 'morning-1',
              order: 1,
              category: 'morning',
              text: 'ذكر الصباح ١',
              repeatCount: 1,
              entryType: DhikrEntryType.single,
            ),
          ],
        );
        final controller = WirdReaderController(category: morningCategory);
        await controller.initialize();

        // Complete the final Dhikr
        await controller.decrementItem('morning-1');

        expect(controller.isComplete, isTrue);

        // Daily wird today record is now completed for morning_adhkar
        final dailyItem = DailyWirdRepository.instance.todayRecord.items
            .firstWhere((i) => i.id == 'morning_adhkar');
        expect(dailyItem.completed, isTrue);

        // Undo final tap -> morning-1 restored with remaining 1
        await controller.undo();
        expect(controller.isComplete, isFalse);
        expect(controller.current.id, 'morning-1');
        expect(controller.remainingFor('morning-1'), 1);

        // Daily wird today record remains completed (not uncompleted by undo)
        final dailyAfterUndo = DailyWirdRepository.instance.todayRecord.items
            .firstWhere((i) => i.id == 'morning_adhkar');
        expect(dailyAfterUndo.completed, isTrue);

        // Check persisted reader progress is marked not completed
        final stored = await AdhkarProgressRepository.instance.load(
          morningCategory,
        );
        expect(stored.isCompleted, isFalse);
        expect(stored.currentStepId, 'morning-1');
        expect(stored.remainingCount, 1);
      },
    );

    test('Restart clears undo history', () async {
      final controller = WirdReaderController(category: testCategory);
      await controller.initialize();

      await controller.decrementItem('item-a');
      expect(controller.canUndo, isTrue);

      await controller.restart();
      expect(controller.canUndo, isFalse);
    });
  });

  group('WirdReaderScreen Undo UI widgets', () {
    late AdhkarCategory testCategory;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AppPreferencesRepository.instance.setReaderMode(
        WirdReaderMode.focus,
      );
      testCategory = const AdhkarCategory(
        id: 'widget-undo-test',
        kind: AdhkarCategoryKind.evening,
        title: 'أذكار المساء',
        subtitle: '',
        items: [
          DhikrItem(
            id: 'item-1',
            order: 1,
            category: 'widget-undo-test',
            text: 'الذكر الأول المسائي',
            repeatCount: 2,
            entryType: DhikrEntryType.single,
          ),
          DhikrItem(
            id: 'item-2',
            order: 2,
            category: 'widget-undo-test',
            text: 'الذكر الثاني المسائي',
            repeatCount: 5,
            entryType: DhikrEntryType.single,
          ),
        ],
      );
    });

    Widget createTestApp(AdhkarCategory category) => MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: WirdReaderScreen(
        category: category,
        vibrationEnabled: false,
        soundEnabled: false,
      ),
    );

    Finder findUndoButton() =>
        find.widgetWithIcon(IconButton, Icons.undo_rounded);

    testWidgets(
      'Header shows compact Undo icon in Focus mode; bottom button is removed',
      (tester) async {
        await tester.pumpWidget(createTestApp(testCategory));
        await tester.pumpAndSettle();

        // Undo icon exists in header
        final undoFinder = findUndoButton();
        expect(undoFinder, findsOneWidget);

        // Old bottom TextButton "تراجع" is removed
        expect(find.widgetWithText(TextButton, 'تراجع'), findsNothing);

        // Initially disabled
        IconButton button = tester.widget(undoFinder);
        expect(button.onPressed, isNull);

        // Tap on card to decrement
        await tester.tap(find.text('الذكر الأول المسائي'));
        await tester.pumpAndSettle();

        // Now enabled
        button = tester.widget(undoFinder);
        expect(button.onPressed, isNotNull);

        // Tap Undo in header
        await tester.tap(undoFinder);
        await tester.pumpAndSettle();

        // Disabled again
        button = tester.widget(undoFinder);
        expect(button.onPressed, isNull);
      },
    );

    testWidgets('Scenario 3 — Cross-mode Undo between Focus and List', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(testCategory));
      await tester.pumpAndSettle();

      // Tap once in Focus: item-1 remaining becomes 1
      await tester.tap(find.text('الذكر الأول المسائي'));
      await tester.pumpAndSettle();
      expect(find.text('١ مرة متبقية'), findsOneWidget);

      // Switch to List mode
      await AppPreferencesRepository.instance.setReaderMode(
        WirdReaderMode.list,
      );
      await tester.pumpAndSettle();

      expect(find.text('الذكر الأول المسائي'), findsOneWidget);
      expect(find.text('١ مرة متبقية'), findsOneWidget);

      // Tap Undo in header while in List mode
      final undoFinder = findUndoButton();
      expect(undoFinder, findsOneWidget);
      await tester.tap(undoFinder);
      await tester.pumpAndSettle();

      // List mode shows restored 2 remaining
      expect(find.text('٢ مرات متبقية'), findsOneWidget);

      // Switch back to Focus mode
      await AppPreferencesRepository.instance.setReaderMode(
        WirdReaderMode.focus,
      );
      await tester.pumpAndSettle();

      // Focus mode also shows restored 2 remaining
      expect(find.text('٢ مرات متبقية'), findsOneWidget);
    });

    testWidgets(
      'Scenario 4 — List card restored at canonical position on Undo',
      (tester) async {
        await AppPreferencesRepository.instance.setReaderMode(
          WirdReaderMode.list,
        );
        await tester.pumpWidget(createTestApp(testCategory));
        await tester.pumpAndSettle();

        // Tap item-1 twice to finish it
        await tester.tap(find.text('الذكر الأول المسائي'));
        await tester.pump();
        await tester.tap(find.text('الذكر الأول المسائي'));
        await tester.pumpAndSettle();

        // item-1 disappeared from list
        expect(find.text('الذكر الأول المسائي'), findsNothing);
        expect(find.text('الذكر الثاني المسائي'), findsOneWidget);

        // Tap Undo in header
        final undoFinder = findUndoButton();
        await tester.tap(undoFinder);
        await tester.pumpAndSettle();

        // item-1 reappears at canonical position before item-2 with remaining 1
        expect(find.text('الذكر الأول المسائي'), findsOneWidget);
        expect(find.text('الذكر الثاني المسائي'), findsOneWidget);
        expect(find.text('١ مرة متبقية'), findsOneWidget);
      },
    );

    testWidgets(
      'Scenario 6 — Long press details does not affect Undo history',
      (tester) async {
        await tester.pumpWidget(createTestApp(testCategory));
        await tester.pumpAndSettle();

        // Tap once: remaining becomes 1
        await tester.tap(find.text('الذكر الأول المسائي'));
        await tester.pumpAndSettle();

        final origin = find.byKey(
          const ValueKey('dhikr-details-widget-undo-test-item-1'),
        );

        // Long press to open details
        await tester.longPress(origin);
        await tester.pumpAndSettle();
        expect(find.byType(DhikrDetailsScreen), findsOneWidget);

        // Close details
        await tester.tap(
          find.descendant(
            of: find.byType(DhikrDetailsScreen),
            matching: find.byIcon(Icons.arrow_forward_rounded),
          ),
        );
        await tester.pumpAndSettle();

        // Undo button is still enabled and works
        final undoFinder = findUndoButton();
        final IconButton button = tester.widget(undoFinder);
        expect(button.onPressed, isNotNull);

        await tester.tap(undoFinder);
        await tester.pumpAndSettle();

        expect(find.text('٢ مرات متبقية'), findsOneWidget);
      },
    );

    testWidgets('Scenario 7 — Reading mode does not show Undo button', (
      tester,
    ) async {
      await AppPreferencesRepository.instance.setReaderMode(
        WirdReaderMode.reading,
      );
      await tester.pumpWidget(createTestApp(testCategory));
      await tester.pumpAndSettle();

      // No Undo button in Reading mode
      expect(findUndoButton(), findsNothing);
    });
  });
}
