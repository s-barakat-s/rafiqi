import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:tasbeh/features/daily_wird/data/repositories/daily_wird_repository.dart';
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
  ReceivePort? _mainAppPort;
  List<TasbeehPhrase> _phrases = TasbeehPhrase.defaultPhrases;
  Future<void> _recordingQueue = Future<void>.value();

  TasbeehState get state => _state;
  TasbeehSettings get settings => _settings;
  List<TasbeehPhrase> get phrases => List.unmodifiable(_phrases);

  Future<void> initialize() async {
    _mainAppPort = TasbeehOverlayMessenger.registerMainAppPort(
      _applyIncomingState,
    );
    _stateSubscription = TasbeehOverlayMessenger.stateMessages.listen(
      _applyIncomingState,
    );
    _settingsSubscription = TasbeehOverlayMessenger.settingsMessages.listen(
      _applyIncomingSettings,
    );
    await reload();
  }

  Future<void> reload() async {
    final results = await Future.wait<Object>([
      _repository.load(),
      _repository.loadSettings(),
      _repository.loadPhrases(),
    ]);
    _state = results[0] as TasbeehState;
    _settings = results[1] as TasbeehSettings;
    _phrases = results[2] as List<TasbeehPhrase>;
    notifyListeners();
  }

  Future<bool> increment() {
    final next = _recording.nextState(_state);
    _state = next;
    notifyListeners();
    unawaited(_notifyOverlay(_state));

    final completion = Completer<bool>();
    _recordingQueue = _recordingQueue.then((_) async {
      try {
        final result = await _recording.recordIncrement(
          next,
          source: TasbeehActivitySource.app,
        );
        completion.complete(result.completedTask);
      } catch (error, stackTrace) {
        completion.completeError(error, stackTrace);
      }
    });
    return completion.future;
  }

  Future<void> resetSession() async {
    await _recordingQueue;
    await _applyState(TasbeehCounterLogic.resetSession(_state));
  }

  Future<void> decrement() async {
    await _recordingQueue;
    if (_state.currentCount <= 0) return;
    await _applyState(TasbeehCounterLogic.decrement(_state));
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
    await TasbeehOverlayMessenger.sendStateUpdate(
      _state,
      source: TasbeehOverlayMessenger.sourceApp,
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
    if (persist) await _repository.save(state);
    _state = state;
    notifyListeners();
    if (notifyOverlay && await FlutterOverlayWindow.isActive()) {
      await TasbeehOverlayMessenger.sendStateUpdate(
        state,
        source: TasbeehOverlayMessenger.sourceApp,
      );
    }
  }

  Future<void> _notifyOverlay(TasbeehState state) async {
    if (await FlutterOverlayWindow.isActive()) {
      await TasbeehOverlayMessenger.sendStateUpdate(
        state,
        source: TasbeehOverlayMessenger.sourceApp,
      );
    }
  }

  Future<void> _applyIncomingState(TasbeehStateMessage message) async {
    if (message.source != TasbeehOverlayMessenger.sourceOverlay) return;
    await _repository.save(message.state);
    await DailyWirdRepository.instance.initialize();
    _state = message.state;
    notifyListeners();
  }

  Future<void> _applyIncomingSettings(TasbeehSettingsMessage message) async {
    if (message.source != TasbeehOverlayMessenger.sourceOverlay) return;
    await _repository.saveSettings(message.settings);
    _settings = message.settings;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(flushPendingIncrements());
    _stateSubscription?.cancel();
    _settingsSubscription?.cancel();
    _mainAppPort?.close();
    TasbeehOverlayMessenger.unregisterMainAppPort();
    super.dispose();
  }
}
