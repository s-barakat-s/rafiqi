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
    this.revision = 0,
  });

  final TasbeehState state;
  final String source;

  /// Persisted monotonic version of the accepted state. This orders snapshots;
  /// operation identity is carried separately and is never inferred from time.
  final int revision;
}

class TasbeehIncrementOperation {
  const TasbeehIncrementOperation({required this.operationId});

  final String operationId;
}

class TasbeehOperationReply {
  const TasbeehOperationReply({
    required this.accepted,
    required this.duplicate,
    required this.state,
    required this.revision,
  });

  final bool accepted;
  final bool duplicate;
  final TasbeehState? state;
  final int revision;
}

class TasbeehSettingsMessage {
  const TasbeehSettingsMessage({required this.settings, required this.source});

  final TasbeehSettings settings;
  final String source;
}

class TasbeehOverlayMessenger {
  const TasbeehOverlayMessenger._();

  static const sourceApp = 'app';
  static const sourceOverlay = 'overlay';
  static const _mainAppPortName = 'tasbeeh_main_app_state_port';

  static final Stream<Object?> _messages = FlutterOverlayWindow.overlayListener
      .asBroadcastStream();

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
    int revision = 0,
  }) async {
    await FlutterOverlayWindow.shareData(
      _stateUpdateMap(state, source, revision: revision),
    );
  }

  static Future<TasbeehOperationReply?> sendIncrementOperation(
    String operationId,
  ) async {
    final rawReply = await FlutterOverlayWindow.shareData({
      'type': 'increment_operation',
      'source': sourceOverlay,
      'opId': operationId,
    });
    if (rawReply is! Map || rawReply['type'] != 'operation_reply') {
      return null;
    }
    final rawState = rawReply['state'];
    return TasbeehOperationReply(
      accepted: rawReply['accepted'] == true,
      duplicate: rawReply['duplicate'] == true,
      state: rawState is Map
          ? TasbeehState.fromJson(Map<String, Object?>.from(rawState))
          : null,
      revision: rawReply['revision'] is int ? rawReply['revision'] as int : 0,
    );
  }

  static void registerOperationProcessor(
    Future<TasbeehOperationReply> Function(TasbeehIncrementOperation operation)
    processor,
  ) {
    FlutterOverlayWindow.setMessageProcessor((message) async {
      final operation = _incrementOperationFromObject(message);
      if (operation == null) return null;
      final reply = await processor(operation);
      return {
        'type': 'operation_reply',
        'accepted': reply.accepted,
        'duplicate': reply.duplicate,
        'revision': reply.revision,
        if (reply.state != null) 'state': reply.state!.toJson(),
      };
    });
  }

  static void unregisterOperationProcessor() {
    FlutterOverlayWindow.setMessageProcessor(null);
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

  static Map<String, Object?> _stateUpdateMap(
    TasbeehState state,
    String source, {
    int revision = 0,
  }) {
    return {...state.toJson(), 'source': source, 'revision': revision};
  }

  static TasbeehIncrementOperation? _incrementOperationFromObject(
    Object? message,
  ) {
    if (message is! Map ||
        message['type'] != 'increment_operation' ||
        message['source'] != sourceOverlay) {
      return null;
    }
    final operationId = message['opId'];
    if (operationId is! String || operationId.isEmpty) return null;
    return TasbeehIncrementOperation(operationId: operationId);
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
    final rawRevision = message['revision'];
    return TasbeehStateMessage(
      state: TasbeehState.fromJson({
        'currentCount': message['currentCount'],
        'totalCount': message['totalCount'],
        'dailyTotal': message['dailyTotal'],
        'dailyDateKey': message['dailyDateKey'],
        'targetMode': message['targetMode'],
        'selectedDhikrId': message['selectedDhikrId'],
        'selectedDhikrText': message['selectedDhikrText'],
        'sessionCounts': message['sessionCounts'],
      }),
      source: source is String ? source : '',
      revision: rawRevision is int ? rawRevision : 0,
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
