import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/core/time/local_day.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_progress_repository.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar_progress.dart';
import 'package:tasbeh/features/adhkar/presentation/controllers/wird_reader_controller.dart';
import 'package:tasbeh/features/daily_wird/data/repositories/daily_wird_repository.dart';
import 'package:tasbeh/features/daily_wird/domain/entities/daily_wird.dart';
import 'package:tasbeh/features/journey/presentation/screens/journey_screen.dart';
import 'package:tasbeh/features/tasbeeh/data/repositories/tasbeeh_repository.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_daily_record.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_settings.dart';
import 'package:tasbeh/features/tasbeeh/presentation/screens/floating_tasbeeh_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const overlayChannel = MethodChannel('x-slayer/overlay_channel');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(overlayChannel, (call) async {
          if (call.method == 'isOverlayActive') return false;
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(overlayChannel, null);
  });

  test(
    'legacy Tasbeeh activity migrates once and tap uses indexed record',
    () async {
      final day = LocalDay.key(DateTime.now());
      final legacy = TasbeehDailyRecord(
        dayKey: day,
        dhikrId: 'subhan_allah',
        dhikrTextSnapshot: 'سبحان الله',
        appCount: 2,
        overlayCount: 1,
      );
      SharedPreferences.setMockInitialValues({
        'tasbeeh.dailyRecords.v1': [jsonEncode(legacy.toJson())],
      });
      final repository = TasbeehRepository();

      expect((await repository.loadDailyRecords()).single.inAppCount, 3);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('tasbeeh.dailyRecords.v1', ['not-json']);

      final updated = await repository.recordIncrement(
        dhikrId: 'subhan_allah',
        dhikrText: 'سبحان الله',
        source: TasbeehActivitySource.app,
      );
      expect(updated.appCount, 3);
      expect(updated.overlayCount, 1);
    },
  );

  testWidgets('rendering Journey does not create missing history', (
    tester,
  ) async {
    final repository = DailyWirdRepository.instance;
    await repository.initialize();
    final before = repository.history.keys.toSet();

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const JourneyScreen()),
    );
    await tester.pumpAndSettle();

    expect(repository.history.keys.toSet(), before);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList('journey_daily_history_v2.index')?.toSet(),
      before,
    );
  });

  test(
    'legacy Journey history migrates idempotently to indexed days',
    () async {
      final yesterday = LocalDay.date(
        DateTime.now(),
      ).subtract(const Duration(days: 1));
      final legacy = DailyHistoryRecord(
        dateKey: LocalDay.key(yesterday),
        items: const [],
      );
      SharedPreferences.setMockInitialValues({
        'journey_daily_history_v1': [jsonEncode(legacy.toJson())],
      });

      final repository = DailyWirdRepository.instance;
      await repository.initialize();
      await repository.initialize();

      expect(repository.recordFor(yesterday)?.dateKey, legacy.dateKey);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getStringList('journey_daily_history_v2.index'),
        contains(legacy.dateKey),
      );
    },
  );

  test('reader queue continues after one failed write', () async {
    final progress = _FailOnceProgressRepository();
    final controller = WirdReaderController(
      category: _category,
      progressRepository: progress,
    );
    await controller.initialize();

    await expectLater(controller.decrementItem('item'), throwsStateError);
    await controller.decrementItem('item');

    expect(progress.attempts, 2);
    expect(progress.saved.single.remainingCount, 1);
  });

  test(
    'accepted reader persistence finishes after controller disposal',
    () async {
      final progress = _BlockingProgressRepository();
      final controller = WirdReaderController(
        category: _category,
        progressRepository: progress,
      );
      await controller.initialize();

    final write = controller.completeFromReading();
      await progress.started.future;
      controller.dispose();
      progress.release.complete();
      await write;

      expect(progress.saved, hasLength(1));
    },
  );

  testWidgets('slider previews freely but persists only its final value', (
    tester,
  ) async {
    final repository = _CountingTasbeehRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: FloatingTasbeehSettingsScreen(
          initialSettings: TasbeehSettings.initial(),
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final opacity = tester.widgetList<Slider>(find.byType(Slider)).elementAt(1);
    opacity.onChanged?.call(.5);
    opacity.onChanged?.call(.6);
    opacity.onChanged?.call(.7);
    await tester.pump();
    expect(repository.saveCount, 0);

    opacity.onChangeEnd?.call(.7);
    await tester.pumpAndSettle();
    expect(repository.saveCount, 1);
    expect(repository.lastSaved?.opacity, .7);
  });
}

const _category = AdhkarCategory(
  id: 'phase3-reader',
  kind: AdhkarCategoryKind.morning,
  title: 'اختبار',
  subtitle: '',
  items: [
    DhikrItem(
      id: 'item',
      order: 1,
      category: 'phase3-reader',
      text: 'ذكر',
      repeatCount: 3,
      entryType: DhikrEntryType.single,
    ),
  ],
);

class _FailOnceProgressRepository implements AdhkarProgressRepository {
  int attempts = 0;
  final List<AdhkarReadingProgress> saved = [];

  @override
  Future<AdhkarReadingProgress> load(
    AdhkarCategory category, {
    DateTime? day,
  }) async => AdhkarReadingProgress.initial(category, day: day);

  @override
  Future<void> save(AdhkarReadingProgress progress) async {
    attempts += 1;
    if (attempts == 1) throw StateError('first write failed');
    saved.add(progress);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _BlockingProgressRepository implements AdhkarProgressRepository {
  final started = Completer<void>();
  final release = Completer<void>();
  final List<AdhkarReadingProgress> saved = [];

  @override
  Future<AdhkarReadingProgress> load(
    AdhkarCategory category, {
    DateTime? day,
  }) async => AdhkarReadingProgress.initial(category, day: day);

  @override
  Future<void> save(AdhkarReadingProgress progress) async {
    if (!started.isCompleted) started.complete();
    await release.future;
    saved.add(progress);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CountingTasbeehRepository extends TasbeehRepository {
  int saveCount = 0;
  TasbeehSettings? lastSaved;

  @override
  Future<void> saveSettings(TasbeehSettings settings) async {
    saveCount += 1;
    lastSaved = settings;
  }
}
