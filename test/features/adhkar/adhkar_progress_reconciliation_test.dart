import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_collection_overrides_repository.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_progress_repository.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar_collection_overrides.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('completed progress reopens only newly added stable ids', () async {
    final repository = AdhkarProgressRepository.instance;
    final day = DateTime(2026, 9, 29);
    await repository.save(
      AdhkarReadingProgress(
        categoryId: 'morning',
        dayKey: AdhkarProgressRepository.localDayKey(day),
        currentStepId: null,
        remainingCount: 0,
        completedStepIds: const {'a', 'b'},
        isCompleted: true,
        lastUpdatedAt: day,
        completedAt: day,
      ),
    );

    final reconciled = await repository.load(
      _category('morning', const [('b', 1), ('a', 1), ('new', 3)]),
      day: day,
    );

    expect(reconciled.completedStepIds, {'a', 'b'});
    expect(reconciled.currentStepId, 'new');
    expect(reconciled.remainingCount, 3);
    expect(reconciled.isCompleted, isFalse);
  });

  test(
    'current stable id survives reorder and repeat changes are clamped',
    () async {
      final repository = AdhkarProgressRepository.instance;
      final day = DateTime(2026, 9, 29);
      await repository.save(
        AdhkarReadingProgress(
          categoryId: 'evening',
          dayKey: AdhkarProgressRepository.localDayKey(day),
          currentStepId: 'b',
          remainingCount: 4,
          completedStepIds: const {'a'},
          remainingCounts: const {'b': 4},
          isCompleted: false,
          lastUpdatedAt: day,
        ),
      );

      final reconciled = await repository.load(
        _category('evening', const [('c', 1), ('b', 2)]),
        day: day,
      );

      expect(reconciled.completedStepIds, isEmpty);
      expect(reconciled.currentStepId, 'b');
      expect(reconciled.remainingCount, 2);
      expect(reconciled.remainingCounts['b'], 2);
    },
  );

  test('hiding the current id advances to the next visible id', () async {
    final repository = AdhkarProgressRepository.instance;
    final day = DateTime(2026, 9, 29);
    await repository.save(
      AdhkarReadingProgress(
        categoryId: 'morning',
        dayKey: AdhkarProgressRepository.localDayKey(day),
        currentStepId: 'hidden',
        remainingCount: 2,
        completedStepIds: const {'done'},
        isCompleted: false,
        lastUpdatedAt: day,
      ),
    );

    final reconciled = await repository.load(
      _category('morning', const [('next', 4)]),
      day: day,
    );

    expect(reconciled.completedStepIds, isEmpty);
    expect(reconciled.currentStepId, 'next');
    expect(reconciled.remainingCount, 4);
  });

  test('progress notifications are scoped to the changed category', () async {
    final repository = AdhkarProgressRepository.instance;
    final morning = repository.changesFor('morning');
    final evening = repository.changesFor('evening');
    var morningNotifications = 0;
    var eveningNotifications = 0;
    void onMorning() => morningNotifications++;
    void onEvening() => eveningNotifications++;
    morning.addListener(onMorning);
    evening.addListener(onEvening);
    addTearDown(() {
      morning.removeListener(onMorning);
      evening.removeListener(onEvening);
    });

    final day = DateTime(2026, 9, 29);
    await repository.save(
      AdhkarReadingProgress.initial(
        _category('morning', const [('a', 3)]),
        day: day,
      ),
    );

    expect(morningNotifications, 1);
    expect(eveningNotifications, 0);
  });

  test(
    'customization notifications are scoped to the changed category',
    () async {
      final repository = AdhkarCollectionOverridesRepository.instance;
      final morning = repository.changesFor('morning');
      final evening = repository.changesFor('evening');
      var morningNotifications = 0;
      var eveningNotifications = 0;
      void onMorning() => morningNotifications++;
      void onEvening() => eveningNotifications++;
      morning.addListener(onMorning);
      evening.addListener(onEvening);
      addTearDown(() {
        morning.removeListener(onMorning);
        evening.removeListener(onEvening);
      });

      await repository.save(
        'morning',
        const AdhkarCollectionOverrides(hiddenDhikrIds: {'a'}),
      );

      expect(morningNotifications, 1);
      expect(eveningNotifications, 0);
    },
  );

  test('progress starts fresh on the local day after midnight', () async {
    final repository = AdhkarProgressRepository.instance;
    final category = _category('morning', const [('a', 3)]);
    final firstDay = DateTime(2026, 9, 29, 23, 59);
    await repository.save(
      AdhkarReadingProgress(
        categoryId: category.id,
        dayKey: AdhkarProgressRepository.localDayKey(firstDay),
        currentStepId: 'a',
        remainingCount: 1,
        completedStepIds: const {},
        isCompleted: false,
        lastUpdatedAt: firstDay,
      ),
    );

    final nextDay = await repository.load(category, day: DateTime(2026, 9, 30));

    expect(nextDay.remainingCount, 3);
    expect(nextDay.completedStepIds, isEmpty);
    expect(nextDay.dayKey, '2026-09-30');
  });
}

AdhkarCategory _category(String id, List<(String, int)> definitions) =>
    AdhkarCategory(
      id: id,
      title: id,
      subtitle: '',
      kind: id == 'morning'
          ? AdhkarCategoryKind.morning
          : AdhkarCategoryKind.evening,
      items: [
        for (var index = 0; index < definitions.length; index++)
          DhikrItem(
            id: definitions[index].$1,
            order: index,
            category: id,
            text: definitions[index].$1,
            repeatCount: definitions[index].$2,
            entryType: DhikrEntryType.single,
          ),
      ],
    );
