import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_settings.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_state.dart';

class TasbeehStateMessage {
  const TasbeehStateMessage({
    required this.state,
    required this.source,
  });

  final TasbeehState state;
  final String source;
}

class TasbeehSettingsMessage {
  const TasbeehSettingsMessage({
    required this.settings,
    required this.source,
  });

  final TasbeehSettings settings;
  final String source;
}

class TasbeehOverlayMessenger {
  const TasbeehOverlayMessenger._();

  static const sourceApp = 'app';
  static const sourceOverlay = 'overlay';
  static const _mainAppPortName = 'tasbeeh_main_app_state_port';

  static final Stream<Object?> _messages =
      FlutterOverlayWindow.overlayListener.asBroadcastStream();

  static Stream<TasbeehStateMessage> get stateMessages {
    return _messages
        .map(_stateMessageFromObject)
        .where((message) => message != null)
        .cast<TasbeehStateMessage>();
  }

  static Stream<TasbeehSettingsMessage> get settingsMessages {
    return _messages
        .map(_settingsMessageFromObject)
        .where((message) => message != null)
        .cast<TasbeehSettingsMessage>();
  }

  static Future<void> sendStateUpdate(
    TasbeehState state, {
    required String source,
  }) async {
    await FlutterOverlayWindow.shareData(_stateUpdateMap(state, source));
  }

  static Future<void> sendSettingsUpdate(
    TasbeehSettings settings, {
    required String source,
  }) async {
    await FlutterOverlayWindow.shareData(_settingsUpdateMap(settings, source));
  }

  static ReceivePort registerMainAppPort(
    void Function(TasbeehStateMessage message) onMessage,
  ) {
    IsolateNameServer.removePortNameMapping(_mainAppPortName);
    final receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(
      receivePort.sendPort,
      _mainAppPortName,
    );
    receivePort.listen((message) {
      final parsedMessage = _stateMessageFromObject(message);
      if (parsedMessage != null) {
        onMessage(parsedMessage);
      }
    });
    return receivePort;
  }

  static void unregisterMainAppPort() {
    IsolateNameServer.removePortNameMapping(_mainAppPortName);
  }

  static void sendStateToMainApp(TasbeehState state) {
    final sendPort = IsolateNameServer.lookupPortByName(_mainAppPortName);
    sendPort?.send(_stateUpdateMap(state, sourceOverlay));
  }

  static Map<String, Object?> _stateUpdateMap(
    TasbeehState state,
    String source,
  ) {
    return {
      ...state.toJson(),
      'source': source,
    };
  }

  static Map<String, Object?> _settingsUpdateMap(
    TasbeehSettings settings,
    String source,
  ) {
    return {
      'type': 'settings_update',
      'settings': settings.toJson(),
      'source': source,
    };
  }

  static TasbeehStateMessage? _stateMessageFromObject(Object? message) {
    if (message is! Map || message['type'] != 'state_update') {
      return null;
    }

    final source = message['source'];
    return TasbeehStateMessage(
      state: TasbeehState.fromJson({
        'currentCount': message['currentCount'],
        'totalCount': message['totalCount'],
        'targetMode': message['targetMode'],
      }),
      source: source is String ? source : '',
    );
  }

  static TasbeehSettingsMessage? _settingsMessageFromObject(Object? message) {
    if (message is! Map || message['type'] != 'settings_update') {
      return null;
    }

    final source = message['source'];
    final rawSettings = message['settings'];
    final settingsJson = rawSettings is Map
        ? Map<String, Object?>.from(rawSettings)
        : Map<String, Object?>.from(message);

    return TasbeehSettingsMessage(
      settings: TasbeehSettings.fromJson(settingsJson),
      source: source is String ? source : '',
    );
  }
}
