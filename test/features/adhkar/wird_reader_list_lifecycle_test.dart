import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/domain/entities/wird_reader_mode.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_progress_repository.dart';
import 'package:tasbeh/features/adhkar/presentation/screens/dhikr_details_screen.dart';
import 'package:tasbeh/features/adhkar/presentation/screens/wird_reader_screen.dart';
import 'package:tasbeh/features/settings/data/repositories/app_preferences_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferencesRepository.instance.setReaderMode(WirdReaderMode.list);
  });

  testWidgets('list cards can finish consecutively without lifecycle errors', (
    tester,
  ) async {
    await tester.pumpWidget(_readerApp(_category()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('one')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('three')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('three')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('three')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving while a list card exits does not use dead context', (
    tester,
  ) async {
    await tester.pumpWidget(_readerApp(_category()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('one')));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
  });

  testWidgets('long press opens details without decrementing the list item', (
    tester,
  ) async {
    final category = _category();
    await tester.pumpWidget(_readerApp(category));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const ValueKey('one')));
    await tester.pumpAndSettle();

    expect(find.byType(DhikrDetailsScreen), findsOneWidget);
    final progress = await AdhkarProgressRepository.instance.load(category);
    expect(progress.completedStepIds, isEmpty);
    expect(progress.remainingCount, 1);

    await tester.tap(
      find.descendant(
        of: find.byType(DhikrDetailsScreen),
        matching: find.byIcon(Icons.arrow_forward_rounded),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('one')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('focus long press is read-only and normal tap still decrements', (
    tester,
  ) async {
    await AppPreferencesRepository.instance.setReaderMode(WirdReaderMode.focus);
    final category = _focusCategory();
    await tester.pumpWidget(_readerApp(category));
    await tester.pumpAndSettle();
    final origin = find.byKey(
      const ValueKey('dhikr-details-focus-details-test-focus-three'),
    );

    await tester.longPress(origin);
    await tester.pumpAndSettle();
    expect(find.byType(DhikrDetailsScreen), findsOneWidget);
    var progress = await AdhkarProgressRepository.instance.load(category);
    expect(progress.remainingCount, 3);
    expect(progress.completedStepIds, isEmpty);

    await _closeDetails(tester);
    await tester.tap(origin);
    await tester.pumpAndSettle();
    progress = await AdhkarProgressRepository.instance.load(category);
    expect(progress.remainingCount, 2);
    expect(progress.completedStepIds, isEmpty);
  });

  testWidgets('reading details return to the same scroll offset', (
    tester,
  ) async {
    await AppPreferencesRepository.instance.setReaderMode(
      WirdReaderMode.reading,
    );
    final category = _readingCategory();
    await tester.pumpWidget(_readerApp(category));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    final origin = find.byKey(
      const ValueKey('dhikr-details-reading-scroll-test-reading-2'),
    );
    expect(origin, findsOneWidget);
    final scrollable = find.byType(Scrollable).first;
    final before = tester.state<ScrollableState>(scrollable).position.pixels;

    await tester.longPress(origin);
    await tester.pumpAndSettle();
    expect(find.byType(DhikrDetailsScreen), findsOneWidget);
    final progress = await AdhkarProgressRepository.instance.load(category);
    expect(progress.completedStepIds, isEmpty);

    await _closeDetails(tester);
    final after = tester.state<ScrollableState>(scrollable).position.pixels;
    expect(after, before);
  });

  testWidgets(
    'reading progress follows scroll visually and completes only on explicit button tap',
    (tester) async {
      await AppPreferencesRepository.instance.setReaderMode(
        WirdReaderMode.reading,
      );
      final category = _readingCategory();
      await tester.pumpWidget(_readerApp(category));
      await tester.pumpAndSettle();

      double progress() => tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value!;

      expect(progress(), 0);
      await tester.drag(find.byType(ListView), const Offset(0, -220));
      await tester.pump();
      final middleProgress = progress();
      expect(middleProgress, greaterThan(0));
      expect(middleProgress, lessThan(1));

      // Scrolling up decreases progress
      await tester.drag(find.byType(ListView), const Offset(0, 100));
      await tester.pump();
      expect(progress(), lessThan(middleProgress));

      // Scrolling to bottom reaches 1.0 but does NOT complete
      await tester.drag(find.byType(ListView), const Offset(0, -10000));
      await tester.pumpAndSettle();
      expect(progress(), 1);

      var stored = await AdhkarProgressRepository.instance.load(category);
      expect(stored.isCompleted, isFalse);
      expect(find.byType(ListView), findsOneWidget);

      // Explicit completion via button
      await tester.ensureVisible(find.text('أتممت قراءة الورد'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('أتممت قراءة الورد'));
      await tester.pumpAndSettle();

      stored = await AdhkarProgressRepository.instance.load(category);
      expect(stored.isCompleted, isTrue);
      expect(stored.completedStepIds.length, category.items.length);
      expect(find.byType(ListView), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(_readerApp(category));
      await tester.pumpAndSettle();
      expect(find.byType(ListView), findsNothing);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        1,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _closeDetails(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(DhikrDetailsScreen),
      matching: find.byIcon(Icons.arrow_forward_rounded),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _readerApp(AdhkarCategory category) => MaterialApp(
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

AdhkarCategory _category() => const AdhkarCategory(
  id: 'list-lifecycle-test',
  kind: AdhkarCategoryKind.sleep,
  title: 'أذكار النوم',
  subtitle: '',
  items: [
    DhikrItem(
      id: 'one',
      order: 1,
      category: 'sleep',
      text: 'ذكر قصير',
      repeatCount: 1,
      entryType: DhikrEntryType.single,
    ),
    DhikrItem(
      id: 'three',
      order: 2,
      category: 'sleep',
      text: 'ذكر يقال ثلاثًا',
      repeatCount: 3,
      entryType: DhikrEntryType.single,
    ),
    DhikrItem(
      id: 'last',
      order: 3,
      category: 'sleep',
      text: 'ذكر أخير',
      repeatCount: 1,
      entryType: DhikrEntryType.single,
    ),
  ],
);

AdhkarCategory _readingCategory() => AdhkarCategory(
  id: 'reading-scroll-test',
  kind: AdhkarCategoryKind.sleep,
  title: 'أذكار النوم',
  subtitle: '',
  items: List.generate(
    9,
    (index) => DhikrItem(
      id: 'reading-$index',
      order: index + 1,
      category: 'reading-scroll-test',
      text: 'ذكر مقروء لاختبار موضع التمرير',
      repeatCount: 1,
      entryType: DhikrEntryType.single,
    ),
  ),
);

AdhkarCategory _focusCategory() => const AdhkarCategory(
  id: 'focus-details-test',
  kind: AdhkarCategoryKind.sleep,
  title: 'أذكار النوم',
  subtitle: '',
  items: [
    DhikrItem(
      id: 'focus-three',
      order: 1,
      category: 'focus-details-test',
      text: 'ذكر يقال ثلاث مرات',
      repeatCount: 3,
      entryType: DhikrEntryType.single,
    ),
  ],
);
