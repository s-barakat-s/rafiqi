import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/presentation/controllers/wird_reader_controller.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_progress_repository.dart';
import 'package:tasbeh/features/daily_wird/data/repositories/daily_wird_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('focus and list operations share persisted per-item progress', () async {
    SharedPreferences.setMockInitialValues({});
    final category = AdhkarCategory(
      id: 'shared-progress-test',
      kind: AdhkarCategoryKind.sleep,
      title: 'اختبار',
      subtitle: '',
      items: const [
        DhikrItem(
          id: 'a',
          order: 1,
          category: 'test',
          text: 'الذكر الأول',
          repeatCount: 3,
          entryType: DhikrEntryType.single,
        ),
        DhikrItem(
          id: 'b',
          order: 2,
          category: 'test',
          text: 'الذكر الثاني',
          repeatCount: 2,
          entryType: DhikrEntryType.single,
        ),
        DhikrItem(
          id: 'c',
          order: 3,
          category: 'test',
          text: 'الذكر الثالث',
          repeatCount: 1,
          entryType: DhikrEntryType.single,
        ),
      ],
    );

    final controller = WirdReaderController(category: category);
    await controller.initialize();
    await controller.decrementItem('a');

    expect(controller.remaining, 2);
    expect(controller.remainingFor('a'), 2);

    await controller.decrementItem('c');
    expect(controller.isItemCompleted('c'), isTrue);
    expect(controller.current.id, 'a');

    final restored = WirdReaderController(category: category);
    await restored.initialize();

    expect(restored.current.id, 'a');
    expect(restored.remainingFor('a'), 2);
    expect(restored.isItemCompleted('c'), isTrue);
    expect(restored.remainingItems.map((item) => item.id), ['a', 'b']);
  });

  test(
    'reading completion persists the shared completed reader state',
    () async {
      SharedPreferences.setMockInitialValues({});
      await DailyWirdRepository.instance.initialize();
      final category = AdhkarCategory(
        id: 'morning',
        kind: AdhkarCategoryKind.morning,
        title: 'أذكار الصباح',
        subtitle: '',
        items: const [
          DhikrItem(
            id: 'morning-a',
            order: 1,
            category: 'morning',
            text: 'الذكر الأول',
            repeatCount: 3,
            entryType: DhikrEntryType.single,
          ),
          DhikrItem(
            id: 'morning-b',
            order: 2,
            category: 'morning',
            text: 'الذكر الثاني',
            repeatCount: 1,
            entryType: DhikrEntryType.single,
          ),
        ],
      );
      final controller = WirdReaderController(category: category);
      await controller.initialize();
      await controller.decrementItem('morning-a');

      await controller.completeFromReading();

      expect(controller.isComplete, isTrue);
      final stored = await AdhkarProgressRepository.instance.load(category);
      expect(stored.isCompleted, isTrue);
      expect(stored.currentStepId, isNull);
      expect(stored.remainingCount, 0);
      expect(stored.completedStepIds, {'morning-a', 'morning-b'});

      final reopened = WirdReaderController(category: category);
      await reopened.initialize();
      expect(reopened.isComplete, isTrue);

      await reopened.restart();
      final morningDaily = DailyWirdRepository.instance.todayRecord.items
          .firstWhere((item) => item.id == 'morning_adhkar');
      expect(morningDaily.completed, isTrue);
    },
  );
}
