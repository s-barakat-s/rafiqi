import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/features/daily_wird/data/repositories/daily_wird_repository.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_controller.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_overlay_messenger.dart';
import 'package:tasbeh/features/tasbeeh/data/repositories/tasbeeh_repository.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const overlayChannel = MethodChannel('x-slayer/overlay_channel');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(overlayChannel, (call) async {
          if (call.method == 'isOverlayActive') return false;
          if (call.method == 'checkPermission') return true;
          return null;
        });
    await DailyWirdRepository.instance.initialize();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(overlayChannel, null);
  });

  test(
    'duplicate overlay operation is acknowledged and recorded once',
    () async {
      final controller = TasbeehController();
      await controller.initialize();
      addTearDown(controller.dispose);

      final first = await _deliver({
        'type': 'increment_operation',
        'source': TasbeehOverlayMessenger.sourceOverlay,
        'opId': 'stable-op-1',
      });
      final duplicate = await _deliver({
        'type': 'increment_operation',
        'source': TasbeehOverlayMessenger.sourceOverlay,
        'opId': 'stable-op-1',
      });

      expect(first?['accepted'], isTrue);
      expect(first?['duplicate'], isFalse);
      expect(duplicate?['accepted'], isTrue);
      expect(duplicate?['duplicate'], isTrue);
      expect(controller.state.currentCount, 1);

      final records = await TasbeehRepository().loadDailyRecords();
      expect(records.single.overlayCount, 1);
    },
  );

  test('delayed legacy snapshot cannot roll back accepted state', () async {
    final controller = TasbeehController();
    await controller.initialize();
    addTearDown(controller.dispose);

    await _deliver({
      'type': 'increment_operation',
      'source': TasbeehOverlayMessenger.sourceOverlay,
      'opId': 'stable-op-2',
    });
    expect(controller.state.currentCount, 1);

    await _deliver({
      ...controller.state
          .copyWith(totalCount: 0, dailyTotal: 0, sessionCounts: const {})
          .toJson(),
      'source': TasbeehOverlayMessenger.sourceOverlay,
      'revision': 0,
    });
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.currentCount, 1);
    expect((await TasbeehRepository().load()).currentCount, 1);
  });

  test('delayed pre-undo state cannot restore the reverted count', () async {
    final controller = TasbeehController();
    await controller.initialize();
    addTearDown(controller.dispose);

    await controller.increment();
    final beforeUndo = controller.state;
    final beforeUndoRevision = controller.revision;
    await controller.decrement();
    expect(controller.state.currentCount, 0);

    await _deliver({
      ...beforeUndo.toJson(),
      'source': TasbeehOverlayMessenger.sourceOverlay,
      'revision': beforeUndoRevision,
    });
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.currentCount, 0);
    expect((await TasbeehRepository().load()).currentCount, 0);
    expect(controller.revision, beforeUndoRevision + 1);
  });

  test('settings message cannot mutate counters', () async {
    final controller = TasbeehController();
    await controller.initialize();
    addTearDown(controller.dispose);
    await controller.increment();
    final acceptedState = controller.state;

    final settings = TasbeehSettings.initial().copyWith(opacity: .4);
    await _deliver({
      'type': 'settings_update',
      'source': TasbeehOverlayMessenger.sourceOverlay,
      'settings': settings.toJson(),
      'currentCount': 999,
      'totalCount': 999,
    });
    await Future<void>.delayed(Duration.zero);

    expect(controller.settings.opacity, .4);
    expect(controller.state.currentCount, acceptedState.currentCount);
    expect(controller.state.totalCount, acceptedState.totalCount);
  });

  test(
    'reopening reconciles a previously accepted overlay operation',
    () async {
      final first = TasbeehController();
      await first.initialize();
      await _deliver({
        'type': 'increment_operation',
        'source': TasbeehOverlayMessenger.sourceOverlay,
        'opId': 'stable-op-reconnect',
      });
      first.dispose();

      final reopened = TasbeehController();
      await reopened.initialize();
      addTearDown(reopened.dispose);

      expect(reopened.state.currentCount, 1);
      expect(reopened.revision, 1);
      expect(
        (await TasbeehRepository().loadDailyRecords()).single.overlayCount,
        1,
      );
    },
  );

  test(
    'concurrent app and overlay operations are serialized without loss',
    () async {
      final controller = TasbeehController();
      await controller.initialize();
      addTearDown(controller.dispose);

      final overlay = controller.acceptOverlayOperation(
        const TasbeehIncrementOperation(operationId: 'concurrent-overlay-op'),
      );
      final app = controller.increment();
      await Future.wait([overlay, app]);

      expect(controller.state.currentCount, 2);
      expect(controller.state.totalCount, 2);
      final record = (await TasbeehRepository().loadDailyRecords()).single;
      expect(record.overlayCount, 1);
      expect(record.appCount, 1);
    },
  );
}

Future<Map<Object?, Object?>?> _deliver(Map<String, Object?> message) async {
  const codec = JSONMessageCodec();
  final completer = Completer<Map<Object?, Object?>?>();
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        'x-slayer/overlay_messenger',
        codec.encodeMessage(message),
        (ByteData? data) {
          final decoded = codec.decodeMessage(data);
          completer.complete(
            decoded is Map ? Map<Object?, Object?>.from(decoded) : null,
          );
        },
      );
  return completer.future;
}
