import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/core/time/local_day.dart';
import 'package:tasbeh/features/daily_wird/data/repositories/daily_wird_repository.dart';
import 'package:tasbeh/features/daily_wird/domain/entities/daily_wird.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_controller.dart';
import 'package:tasbeh/features/tasbeeh/data/repositories/tasbeeh_repository.dart';

/// Phase 0 behavioral regression tests for Tasbeeh counting flows.
///
/// These exercise the real [TasbeehController] against mocked
/// SharedPreferences and a mocked overlay plugin channel, so they assert
/// behavior (state, persistence, daily records, linked-task progress) rather
/// than mocks.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const overlayChannel = MethodChannel('x-slayer/overlay_channel');
  const messageChannel = MethodChannel('x-slayer/overlay_message');
  const pluginChannel = MethodChannel('x-slayer/overlay');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    // The controller talks to the local overlay plugin on these channels.
    // In tests no overlay exists: report inactive and swallow sends.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(overlayChannel, (call) async {
          switch (call.method) {
            case 'isOverlayActive':
              return false;
            case 'checkPermission':
              return true;
            default:
              return null;
          }
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pluginChannel, (call) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(messageChannel, (call) async => null);

    await DailyWirdRepository.instance.initialize();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(overlayChannel, null)
      ..setMockMethodCallHandler(pluginChannel, null)
      ..setMockMethodCallHandler(messageChannel, null);
  });

  test(
    'accepted increment updates state and persists it exactly once',
    () async {
      final controller = TasbeehController();
      await controller.initialize();
      addTearDown(controller.dispose);

      expect(controller.state.currentCount, 0);

      final completed = await controller.increment();

      expect(completed, isFalse);
      expect(controller.state.currentCount, 1);
      expect(controller.state.totalCount, 1);
      expect(controller.state.dailyTotal, 1);

      // One tap => exactly one persisted daily activity record.
      final records = await TasbeehRepository().loadDailyRecords();
      final dayKey = LocalDay.key(DateTime.now());
      final record = records
          .where((r) => r.dayKey == dayKey)
          .where((r) => r.dhikrId == controller.state.selectedDhikrId)
          .single;
      expect(record.inAppCount, 1);
    },
  );

  test(
    'linked daily task progress advances with taps and reaches target',
    () async {
      final controller = TasbeehController();
      await controller.initialize();
      addTearDown(controller.dispose);

      final store = DailyWirdRepository.instance;
      await store.addTask(
        const DailyTask(
          id: 'task_subhan_allah_3',
          title: 'سبحان الله ثلاثًا',
          type: 'ذكر',
          taskType: DailyTask.tasbeehTargetTaskType,
          tasbeehPhraseId: 'subhan_allah',
          tasbeehPhraseText: 'سبحان الله',
          tasbeehTargetCount: 3,
        ),
      );

      var completed = false;
      for (var i = 0; i < 3; i++) {
        completed = await controller.increment();
      }

      // Third tap completes the linked task.
      expect(completed, isTrue);
      final item = store.todayRecord.items.firstWhere(
        (element) => element.id == 'task_subhan_allah_3',
      );
      expect(item.completed, isTrue);
      expect(item.progress, 3);
      expect(item.completionSource, 'tasbeeh');
    },
  );

  test(
    'undo reconciles counters, activity, and linked-task progress',
    () async {
      final controller = TasbeehController();
      await controller.initialize();
      addTearDown(controller.dispose);

      final store = DailyWirdRepository.instance;
      await store.addTask(
        const DailyTask(
          id: 'task_undo_3',
          title: 'ذكر ثلاث مرات',
          type: 'ذكر',
          taskType: DailyTask.tasbeehTargetTaskType,
          tasbeehPhraseId: 'subhan_allah',
          tasbeehPhraseText: 'سبحان الله',
          tasbeehTargetCount: 3,
        ),
      );

      for (var i = 0; i < 3; i++) {
        await controller.increment();
      }
      var item = store.todayRecord.items.firstWhere(
        (element) => element.id == 'task_undo_3',
      );
      expect(item.completed, isTrue);

      await controller.decrement();

      // Counters back off by one.
      expect(controller.state.currentCount, 2);
      expect(controller.state.dailyTotal, 2);

      // Daily activity record is reconciled, not left at 3.
      final dayKey = LocalDay.key(DateTime.now());
      final records = await TasbeehRepository().loadDailyRecords();
      final record = records
          .where((r) => r.dayKey == dayKey)
          .where((r) => r.dhikrId == 'subhan_allah')
          .single;
      expect(record.inAppCount, 2);

      // Linked task falls back below target and is no longer completed.
      item = store.todayRecord.items.firstWhere(
        (element) => element.id == 'task_undo_3',
      );
      expect(item.progress, 2);
      expect(item.completed, isFalse);
    },
  );

  test('undo persists and repeated undo stops at the lower bound', () async {
    final first = TasbeehController();
    await first.initialize();
    await first.increment();
    await first.decrement();
    await first.decrement();

    expect(first.state.currentCount, 0);
    expect(first.state.totalCount, 0);
    expect(first.state.dailyTotal, 0);
    first.dispose();

    final reopened = TasbeehController();
    await reopened.initialize();
    addTearDown(reopened.dispose);
    expect(reopened.state.currentCount, 0);
    expect(reopened.state.totalCount, 0);
    expect(reopened.revision, 2);

    final record = (await TasbeehRepository().loadDailyRecords()).single;
    expect(record.appCount, 0);
    expect(record.overlayCount, 0);
  });

  test(
    'reopening a session restores persisted state without stale totals',
    () async {
      final first = TasbeehController();
      await first.initialize();
      await first.increment();
      await first.flushPendingIncrements();
      first.dispose();

      // A fresh controller (like reopening the route or the app) reads the
      // persisted state and sees the accepted increment.
      final second = TasbeehController();
      await second.initialize();
      addTearDown(second.dispose);

      expect(second.state.currentCount, 1);
      expect(second.state.dailyTotal, 1);
      expect(second.state.totalCount, 1);
    },
  );
}
