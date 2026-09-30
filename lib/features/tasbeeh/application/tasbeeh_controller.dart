import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_counter_logic.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_overlay_launcher.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_overlay_messenger.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_recording_service.dart';
import 'package:tasbeh/features/tasbeeh/data/repositories/tasbeeh_repository.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_settings.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_state.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_phrase.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_daily_record.dart';

enum FloatingTasbeehStartResult { started, permissionDenied }

class TasbeehController extends ChangeNotifier {
  TasbeehController({TasbeehRepository? repository})
    : _repository = repository ?? TasbeehRepository();

  final TasbeehRepository _repository;
  late final TasbeehRecordingService _recording = TasbeehRecordingService(
    repository: _repository,
  );
  TasbeehState _state = TasbeehState.initial();
  TasbeehSettings _settings = TasbeehSettings.initial();
  StreamSubscription<TasbeehStateMessage>? _stateSubscription;
  StreamSubscription<TasbeehSettingsMessage>? _settingsSubscription;

  /// Monotonic operation identity of the last accepted mutation (local or
  /// overlay). Orders deliveries and rejects duplicates/out-of-order state.
  int _revision = 0;
  int get revision => _revision;
  ReceivePort? _mainAppPort;
  List<TasbeehPhrase> _phrases = TasbeehPhrase.defaultPhrases;
  Future<void> _recordingQueue = Future<void>.value();
  int _localOperationSequence = 0;
  int _pendingLocalOperations = 0;
  late final String _operationPrefix =
      'app-${DateTime.now().microsecondsSinceEpoch}-'
      '${Random.secure().nextInt(1 << 32)}';

  TasbeehState get state => _state;
  TasbeehSettings get settings => _settings;
  List<TasbeehPhrase> get phrases => List.unmodifiable(_phrases);

  /// Whether [initialize] has completed at least once for this instance.
  bool get isInitialized => _initialized;
  bool _initialized = false;
  Future<void>? _initialization;

  /// Idempotent initialization.
  ///
  /// The main-app named port and overlay subscriptions are registered only
  /// once per instance lifetime; repeated calls (e.g. reopening a route) do
  /// not replace the port mapping and do not overwrite newer in-memory state
  /// with a stale full reload while an initialize is already in flight.
  Future<void> initialize() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    _mainAppPort = TasbeehOverlayMessenger.registerMainAppPort(
      _applyIncomingState,
    );
    TasbeehOverlayMessenger.registerOperationProcessor(acceptOverlayOperation);
    _stateSubscription = TasbeehOverlayMessenger.stateMessages.listen(
      _applyIncomingState,
    );
    _settingsSubscription = TasbeehOverlayMessenger.settingsMessages.listen(
      _applyIncomingSettings,
    );
    await reload();
    _initialized = true;
  }

  Future<void> reload() async {
    final results = await Future.wait<Object>([
      _repository.load(),
      _repository.loadSettings(),
      _repository.loadPhrases(),
      _repository.loadRevision(),
    ]);
    _state = results[0] as TasbeehState;
    _settings = results[1] as TasbeehSettings;
    _phrases = results[2] as List<TasbeehPhrase>;
    _revision = results[3] as int;
    notifyListeners();
  }

  Future<bool> increment() {
    final next = _recording.nextState(_state);
    _localOperationSequence += 1;
    _pendingLocalOperations += 1;
    final operationSequence = _localOperationSequence;
    final operationId = '$_operationPrefix-$operationSequence';
    _state = next;
    notifyListeners();

    final completion = Completer<bool>();
    _recordingQueue = _recordingQueue.then((_) async {
      try {
        final result = await _recording.recordIncrementOperation(
          operationId: operationId,
          source: TasbeehActivitySource.app,
        );
        _pendingLocalOperations -= 1;
        _revision = result.revision;
        if (operationSequence == _localOperationSequence) {
          _state = result.state;
          notifyListeners();
          unawaited(_notifyOverlay(_state));
        }
        completion.complete(result.completedTask);
      } catch (error, stackTrace) {
        _pendingLocalOperations -= 1;
        // One failed operation must not poison later queued work: the queue
        // continues with the next entry after this handler returns.
        completion.completeError(error, stackTrace);
      }
    });
    return completion.future;
  }

  Future<void> resetSession() async {
    await _recordingQueue;
    await _applyState(TasbeehCounterLogic.resetSession(_state));
  }

  Future<void> decrement() {
    final completion = Completer<void>();
    _recordingQueue = _recordingQueue.then((_) async {
      try {
        final result = await _recording.undoIncrement(
          source: TasbeehActivitySource.app,
        );
        _revision = result.revision;
        if (result.reversed && _pendingLocalOperations == 0) {
          _state = result.state;
          notifyListeners();
          unawaited(_notifyOverlay(_state));
        }
        completion.complete();
      } catch (error, stackTrace) {
        completion.completeError(error, stackTrace);
      }
    });
    return completion.future;
  }

  Future<void> selectDhikr(TasbeehPhrase phrase) async {
    await _recordingQueue;
    if (!_phrases.any((item) => item.id == phrase.id)) {
      await _repository.ensureCustomPhrase(phrase);
      _phrases = [..._phrases, phrase];
    }
    await _applyState(
      TasbeehCounterLogic.selectDhikr(_state, id: phrase.id, text: phrase.text),
    );
  }

  Future<TasbeehPhrase> addCustomPhrase(String text) async {
    final phrase = await _repository.addCustomPhrase(text);
    _phrases = [..._phrases, phrase];
    await selectDhikr(phrase);
    return phrase;
  }

  Future<bool> recordPhysicalManual({
    required TasbeehPhrase phrase,
    required int count,
  }) async {
    await _recordingQueue;
    final result = await _recording.addPhysicalManual(
      dhikrId: phrase.id,
      dhikrText: phrase.text,
      count: count,
    );
    notifyListeners();
    return result.completedTask;
  }

  Future<void> replaceSettings(TasbeehSettings settings) async {
    _settings = settings;
    await _repository.saveSettings(settings);
    notifyListeners();
  }

  Future<FloatingTasbeehStartResult> startFloating() async {
    var granted = await FlutterOverlayWindow.isPermissionGranted();
    if (!granted) {
      granted = await FlutterOverlayWindow.requestPermission() ?? false;
      if (!granted) return FloatingTasbeehStartResult.permissionDenied;
    }

    _settings = _settings.copyWith(
      overlayMode: TasbeehSettings.overlayModeExpanded,
    );
    await _repository.saveSettings(_settings);
    notifyListeners();
    await TasbeehOverlayLauncher.restartOverlay(settings: _settings);
    // Initial counter state always comes from the current authority, tagged
    // with its opId; settings ride their own message type and cannot carry
    // or reset counters.
    await TasbeehOverlayMessenger.sendStateUpdate(
      _state,
      source: TasbeehOverlayMessenger.sourceApp,
      revision: _revision,
    );
    await TasbeehOverlayMessenger.sendSettingsUpdate(
      _settings,
      source: TasbeehOverlayMessenger.sourceApp,
    );
    return FloatingTasbeehStartResult.started;
  }

  Future<void> stopFloating() => FlutterOverlayWindow.closeOverlay();

  Future<void> flushPendingIncrements() => _recordingQueue;

  Future<void> _applyState(
    TasbeehState state, {
    bool notifyOverlay = true,
    bool persist = true,
  }) async {
    if (persist) {
      _revision += 1;
      await _repository.save(state, revision: _revision);
    }
    _state = state;
    notifyListeners();
    if (notifyOverlay && await FlutterOverlayWindow.isActive()) {
      await TasbeehOverlayMessenger.sendStateUpdate(
        state,
        source: TasbeehOverlayMessenger.sourceApp,
        revision: _revision,
      );
    }
  }

  Future<void> _notifyOverlay(TasbeehState state) async {
    if (await FlutterOverlayWindow.isActive()) {
      await TasbeehOverlayMessenger.sendStateUpdate(
        state,
        source: TasbeehOverlayMessenger.sourceApp,
        revision: _revision,
      );
    }
  }

  /// Rejects the pre-2B overlay snapshot protocol so a delayed snapshot can
  /// never roll back the authoritative state.
  Future<void> _applyIncomingState(TasbeehStateMessage message) async {
    // Legacy overlay snapshots are intentionally ignored. Overlay mutations
    // are accepted only as idempotent operations by [acceptOverlayOperation].
    return;
  }

  Future<TasbeehOperationReply> acceptOverlayOperation(
    TasbeehIncrementOperation operation,
  ) {
    final completion = Completer<TasbeehOperationReply>();
    _recordingQueue = _recordingQueue.then((_) async {
      try {
        final result = await _recording.recordIncrementOperation(
          operationId: operation.operationId,
          source: TasbeehActivitySource.overlay,
        );
        _revision = result.revision;
        if (_pendingLocalOperations == 0) {
          _state = result.state;
          notifyListeners();
        }
        completion.complete(
          TasbeehOperationReply(
            accepted: true,
            duplicate: result.duplicate,
            state: result.state,
            revision: result.revision,
          ),
        );
      } catch (error, stackTrace) {
        completion.completeError(error, stackTrace);
      }
    });
    return completion.future;
  }

  Future<void> _applyIncomingSettings(TasbeehSettingsMessage message) async {
    if (message.source != TasbeehOverlayMessenger.sourceOverlay) return;
    // Settings ONLY: this path must never touch counter state.
    await _repository.saveSettings(message.settings);
    _settings = message.settings;
    notifyListeners();
  }

  @override
  void dispose() {
    _initialization = null;
    unawaited(flushPendingIncrements());
    _stateSubscription?.cancel();
    _settingsSubscription?.cancel();
    _mainAppPort?.close();
    TasbeehOverlayMessenger.unregisterMainAppPort();
    TasbeehOverlayMessenger.unregisterOperationProcessor();
    super.dispose();
  }
}
