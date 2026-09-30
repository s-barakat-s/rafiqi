import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/daily_wird/data/repositories/daily_wird_repository.dart';
import 'package:tasbeh/features/daily_wird/domain/entities/daily_wird.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_app_scope.dart';
import 'package:tasbeh/features/tasbeeh/data/repositories/tasbeeh_repository.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_phrase.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_task_context.dart';
import 'package:tasbeh/features/tasbeeh/presentation/screens/tasbeeh_home_screen.dart';
import 'package:tasbeh/features/tasbeeh/presentation/screens/tasbeeh_task_session_screen.dart';

/// Phase 2A regression tests: one authoritative Tasbeeh controller inside the
/// main Flutter engine; ordinary and task routes observe it; the main-app
/// port is registered once and survives route changes.
///
/// Mocks only external boundaries (SharedPreferences, overlay plugin
/// channels); ownership/recording behavior is exercised for real.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const overlayChannel = MethodChannel('x-slayer/overlay_channel');
  const messageChannel = MethodChannel('x-slayer/overlay_message');
  const pluginChannel = MethodChannel('x-slayer/overlay');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TasbeehAppScope.resetForTesting();

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
    TasbeehAppScope.resetForTesting();
  });

  Widget app(Widget home) => MaterialApp(
    theme: AppTheme.light(),
    builder: (context, child) => Directionality(
      textDirection: TextDirection.rtl,
      child: child ?? const SizedBox.shrink(),
    ),
    home: Scaffold(body: home),
  );

  Future<void> pumpPhone(WidgetTester tester, Widget home) async {
    // Phone-like surface: the counter hero is designed for tall viewports.
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(home));
    await tester.pumpAndSettle();
  }

  TasbeehHomeScreen ordinaryScreen() => TasbeehHomeScreen(
    state: TasbeehAppScope.controller.state,
    onIncrement: () async {
      await TasbeehAppScope.controller.increment();
    },
    onResetSession: TasbeehAppScope.controller.resetSession,
    onOpenSettings: () {},
    phrases: TasbeehAppScope.controller.phrases,
    onSelectDhikr: TasbeehAppScope.controller.selectDhikr,
    onAddCustomPhrase: (text) async {},
    onOpenStatistics: () {},
    onOpenManualLog: () {},
    focusController: TasbeehAppScope.controller,
    hapticEnabled: TasbeehAppScope.controller.settings.hapticFeedbackEnabled,
    onHapticChanged: (enabled) async {},
  );

  TasbeehTaskSessionScreen taskScreen(String taskId) =>
      TasbeehTaskSessionScreen(
        taskContext: TasbeehTaskContext(
          taskId: taskId,
          phraseId: 'alhamdulillah',
          phraseText: 'الحمد لله',
          targetCount: 3,
          initialProgress: 0,
        ),
      );

  Finder countText() => find.byKey(const ValueKey('tasbeeh-counter-tap-area'));

  testWidgets('tap updates the visible count without rebuilding the route', (
    tester,
  ) async {
    await TasbeehAppScope.ensureInitialized();

    await pumpPhone(tester, ordinaryScreen());
    await tester.pumpAndSettle();
    expect(TasbeehAppScope.controller.state.currentCount, 0);

    await tester.tap(countText());
    await tester.pumpAndSettle();

    // The route subscribed to the authority: the visible count advanced.
    expect(find.text('١'), findsWidgets);
    expect(TasbeehAppScope.controller.state.currentCount, 1);
  });

  testWidgets('phrase change updates visible selection and session count', (
    tester,
  ) async {
    await TasbeehAppScope.ensureInitialized();
    await pumpPhone(tester, ordinaryScreen());
    await tester.pumpAndSettle();

    await tester.tap(countText());
    await tester.pumpAndSettle();
    expect(TasbeehAppScope.controller.state.currentCount, 1);

    await TasbeehAppScope.controller.selectDhikr(
      TasbeehPhrase.defaultPhrases.firstWhere((p) => p.id == 'allahu_akbar'),
    );
    await tester.pumpAndSettle();

    // Switching phrase restores that phrase's own session count (0), and the
    // route reflects the change live.
    expect(TasbeehAppScope.controller.state.currentCount, 0);
    expect(find.text('٠'), findsWidgets);

    // Previous phrase session is preserved, not reset.
    await TasbeehAppScope.controller.selectDhikr(
      TasbeehPhrase.defaultPhrases.first,
    );
    await tester.pumpAndSettle();
    expect(TasbeehAppScope.controller.state.currentCount, 1);
  });

  testWidgets('ordinary route → linked task → return keeps one shared state', (
    tester,
  ) async {
    await TasbeehAppScope.ensureInitialized();
    await DailyWirdRepository.instance.addTask(
      const DailyTask(
        id: 'task_shared',
        title: 'ذكر مشترك',
        type: 'ذكر',
        taskType: DailyTask.tasbeehTargetTaskType,
        tasbeehPhraseId: 'alhamdulillah',
        tasbeehPhraseText: 'الحمد لله',
        tasbeehTargetCount: 3,
      ),
    );

    // Ordinary route first: two taps on the shared authority.
    await pumpPhone(tester, ordinaryScreen());
    await tester.pumpAndSettle();
    await tester.tap(countText());
    await tester.pumpAndSettle();
    await tester.tap(countText());
    await tester.pumpAndSettle();
    final countAfterOrdinary = TasbeehAppScope.controller.state.currentCount;
    expect(countAfterOrdinary, 2);

    // Open the task route: it inherits the same authority, same count.
    await pumpPhone(tester, taskScreen('task_shared'));
    await tester.pumpAndSettle();
    expect(TasbeehAppScope.controller.state.selectedDhikrId, 'alhamdulillah');
    // Alhamdulillah session had no taps; its own session count is 0.
    expect(TasbeehAppScope.controller.state.currentCount, 0);

    // Task tap records through the same single authority.
    await tester.tap(countText());
    await tester.pumpAndSettle();
    expect(TasbeehAppScope.controller.state.currentCount, 1);

    // Back to ordinary route: the authority still holds the task's accepted
    // increment (same owner), and the subhan_allah session is intact.
    await pumpPhone(tester, ordinaryScreen());
    await tester.pumpAndSettle();
    expect(TasbeehAppScope.controller.state.sessionCounts['subhan_allah'], 2);
    expect(TasbeehAppScope.controller.state.sessionCounts['alhamdulillah'], 1);
  });

  testWidgets('task-first navigation: ordinary route sees current state', (
    tester,
  ) async {
    await TasbeehAppScope.ensureInitialized();
    await DailyWirdRepository.instance.addTask(
      const DailyTask(
        id: 'task_first',
        title: 'مهمة أولًا',
        type: 'ذكر',
        taskType: DailyTask.tasbeehTargetTaskType,
        tasbeehPhraseId: 'alhamdulillah',
        tasbeehPhraseText: 'الحمد لله',
        tasbeehTargetCount: 3,
      ),
    );

    await pumpPhone(tester, taskScreen('task_first'));
    await tester.pumpAndSettle();
    await tester.tap(countText());
    await tester.pumpAndSettle();

    // Ordinary route opened afterwards observes the task's accepted state.
    await pumpPhone(tester, ordinaryScreen());
    await tester.pumpAndSettle();
    expect(TasbeehAppScope.controller.state.currentCount, 1);
    expect(find.text('١'), findsWidgets);
  });

  testWidgets('one increment is recorded exactly once across route changes', (
    tester,
  ) async {
    await TasbeehAppScope.ensureInitialized();
    final dayKey = _dayKey();

    await pumpPhone(tester, ordinaryScreen());
    await tester.pumpAndSettle();
    await tester.tap(countText());
    await tester.pumpAndSettle();

    // Open and close a task route (creates + disposes a session adapter).
    await pumpPhone(tester, taskScreen('task_record_once'));
    await tester.pumpAndSettle();
    await pumpPhone(tester, ordinaryScreen());
    await tester.pumpAndSettle();

    final records = await TasbeehRepository().loadDailyRecords();
    final mine = records
        .where((r) => r.dayKey == dayKey)
        .where((r) => r.dhikrId == 'subhan_allah')
        .toList();
    expect(mine, hasLength(1));
    expect(mine.single.inAppCount, 1);
  });

  testWidgets('closing a task keeps the authority and main-app port alive', (
    tester,
  ) async {
    await TasbeehAppScope.ensureInitialized();
    final controllerBefore = TasbeehAppScope.controller;

    await pumpPhone(tester, taskScreen('task_close'));
    await tester.pumpAndSettle();

    // Simulate route close: unmount the task screen.
    await tester.pumpWidget(app(const SizedBox.shrink()));
    await tester.pumpAndSettle();

    // The application authority survived the route close, still initialized
    // (port + subscriptions registered), and usable.
    expect(identical(TasbeehAppScope.controller, controllerBefore), isTrue);
    expect(controllerBefore.isInitialized, isTrue);

    await controllerBefore.increment();
    expect(controllerBefore.state.currentCount, 1);
  });

  testWidgets('task undo is observed by the ordinary route', (tester) async {
    await TasbeehAppScope.ensureInitialized();
    await pumpPhone(tester, taskScreen('task_undo_shared'));
    await tester.pumpAndSettle();

    await TasbeehAppScope.controller.increment();
    await TasbeehAppScope.controller.decrement();
    expect(TasbeehAppScope.controller.state.currentCount, 0);

    await pumpPhone(tester, ordinaryScreen());
    await tester.pumpAndSettle();
    expect(TasbeehAppScope.controller.state.currentCount, 0);
    expect(find.text('٠'), findsWidgets);
  });

  testWidgets('repeated initialization never replaces state with stale data', (
    tester,
  ) async {
    await TasbeehAppScope.ensureInitialized();
    final controller = TasbeehAppScope.controller;

    await controller.increment();
    final accepted = controller.state;
    expect(accepted.currentCount, 1);

    // Multiple concurrent re-initializations (as rapid navigation triggers).
    await Future.wait([
      TasbeehAppScope.ensureInitialized(),
      TasbeehAppScope.ensureInitialized(),
      controller.initialize(),
    ]);

    // The accepted increment was not rolled back by a stale reload.
    expect(TasbeehAppScope.controller.state.currentCount, 1);
    expect(identical(TasbeehAppScope.controller.state, accepted), isTrue);
  });
}

String _dayKey() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}
