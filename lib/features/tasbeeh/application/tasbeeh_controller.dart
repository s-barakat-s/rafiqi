import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_counter_logic.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_overlay_launcher.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_overlay_messenger.dart';
import 'package:tasbeh/features/tasbeeh/data/repositories/tasbeeh_repository.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_settings.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_state.dart';

enum FloatingTasbeehStartResult { started, permissionDenied }

class TasbeehController extends ChangeNotifier {
  TasbeehController({TasbeehRepository? repository})
    : _repository = repository ?? TasbeehRepository();

  final TasbeehRepository _repository;
  TasbeehState _state = TasbeehState.initial();
  TasbeehSettings _settings = TasbeehSettings.initial();
  StreamSubscription<TasbeehStateMessage>? _stateSubscription;
  StreamSubscription<TasbeehSettingsMessage>? _settingsSubscription;
  ReceivePort? _mainAppPort;

  TasbeehState get state => _state;
  TasbeehSettings get settings => _settings;

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
    ]);
    _state = results[0] as TasbeehState;
    _settings = results[1] as TasbeehSettings;
    notifyListeners();
  }

  Future<void> increment() =>
      _applyState(TasbeehCounterLogic.increment(_state));

  Future<void> resetSession() =>
      _applyState(TasbeehCounterLogic.resetSession(_state));

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

  Future<void> _applyState(
    TasbeehState state, {
    bool notifyOverlay = true,
  }) async {
    await _repository.save(state);
    _state = state;
    notifyListeners();
    if (notifyOverlay && await FlutterOverlayWindow.isActive()) {
      await TasbeehOverlayMessenger.sendStateUpdate(
        state,
        source: TasbeehOverlayMessenger.sourceApp,
      );
    }
  }

  Future<void> _applyIncomingState(TasbeehStateMessage message) async {
    if (message.source != TasbeehOverlayMessenger.sourceOverlay) return;
    await _repository.save(message.state);
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
    _stateSubscription?.cancel();
    _settingsSubscription?.cancel();
    _mainAppPort?.close();
    TasbeehOverlayMessenger.unregisterMainAppPort();
    super.dispose();
  }
}
