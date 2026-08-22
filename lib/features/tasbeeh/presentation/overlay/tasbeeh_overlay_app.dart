import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_counter_logic.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_overlay_layout_controller.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_overlay_messenger.dart';
import 'package:tasbeh/features/tasbeeh/data/tasbeeh_local_storage.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_settings.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_state.dart';
import 'package:tasbeh/features/tasbeeh/presentation/overlay/floating_tasbeeh_overlay.dart';
import 'package:tasbeh/features/tasbeeh/presentation/overlay/overlay_dimensions.dart';

class TasbeehOverlayApp extends StatelessWidget {
  const TasbeehOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        type: MaterialType.transparency,
        color: Colors.transparent,
        child: _TasbeehOverlayStateHost(),
      ),
    );
  }
}

class _TasbeehOverlayStateHost extends StatefulWidget {
  const _TasbeehOverlayStateHost();

  @override
  State<_TasbeehOverlayStateHost> createState() =>
      _TasbeehOverlayStateHostState();
}

class _TasbeehOverlayStateHostState extends State<_TasbeehOverlayStateHost> {
  final _storage = TasbeehLocalStorage();
  TasbeehState _state = TasbeehState.initial();
  TasbeehSettings _settings = TasbeehSettings.initial();
  StreamSubscription<TasbeehStateMessage>? _mainAppStateSubscription;
  StreamSubscription<TasbeehSettingsMessage>? _mainAppSettingsSubscription;
  Timer? _collapseTimer;
  bool _isCollapsed = false;
  bool _useEdgeGestureInsetFallback = false;
  String _windowAnchorSide = TasbeehSettings.sideRight;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _mainAppStateSubscription = TasbeehOverlayMessenger.stateMessages.listen(
      _applyIncomingMainAppStateMessage,
    );
    _mainAppSettingsSubscription = TasbeehOverlayMessenger.settingsMessages
        .listen(_applyIncomingMainAppSettingsMessage);
  }

  @override
  void dispose() {
    unawaited(TasbeehOverlayLayoutController.disableGestureExclusion());
    _collapseTimer?.cancel();
    _mainAppStateSubscription?.cancel();
    _mainAppSettingsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final loadedState = await _storage.load();
    final loadedSettings = await _storage.loadSettings();
    if (!mounted) return;

    debugPrint(
      'Overlay settings loaded: '
      'sizeScale=${loadedSettings.sizeScale.toStringAsFixed(2)}, '
      'autoCollapse=${loadedSettings.autoCollapseSeconds}, '
      'floatingSide=${loadedSettings.floatingSide}, '
      'overlayMode=${loadedSettings.overlayMode}',
    );

    setState(() {
      _state = loadedState;
      _settings = loadedSettings;
      _isCollapsed =
          loadedSettings.overlayMode == TasbeehSettings.overlayModeCollapsed;
      _windowAnchorSide = loadedSettings.floatingSide;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint('Overlay first frame rendered; starting inactivity timer');
        unawaited(_applyNativeLayoutForCurrentMode());
        _restartInactivityTimer();
      }
    });
  }

  Future<void> _applyIncomingMainAppStateMessage(
    TasbeehStateMessage message,
  ) async {
    if (message.source != TasbeehOverlayMessenger.sourceApp) {
      return;
    }

    await _storage.save(message.state);
    if (!mounted) return;

    setState(() {
      _state = message.state;
    });
    _restartInactivityTimer();
  }

  Future<void> _applyIncomingMainAppSettingsMessage(
    TasbeehSettingsMessage message,
  ) async {
    if (message.source != TasbeehOverlayMessenger.sourceApp) {
      return;
    }

    await _storage.saveSettings(message.settings);
    if (!mounted) return;

    setState(() {
      _settings = message.settings;
      _isCollapsed =
          message.settings.overlayMode == TasbeehSettings.overlayModeCollapsed;
      _windowAnchorSide = message.settings.floatingSide;
    });

    if (!_settings.autoCollapseEnabled && _isCollapsed) {
      await _expandOverlay();
      return;
    }

    unawaited(_applyNativeLayoutForCurrentMode());
    _restartInactivityTimer();
  }

  Future<void> _increment() async {
    if (_isCollapsed) {
      return;
    }

    final nextState = TasbeehCounterLogic.increment(_state);
    await _storage.save(nextState);
    if (!mounted) return;

    setState(() {
      _state = nextState;
    });

    _restartInactivityTimer();
    TasbeehOverlayMessenger.sendStateToMainApp(nextState);
    await TasbeehOverlayMessenger.sendStateUpdate(
      nextState,
      source: TasbeehOverlayMessenger.sourceOverlay,
    );
  }

  void _restartInactivityTimer() {
    debugPrint(
      'Restart inactivity timer requested: '
      'isCollapsed=$_isCollapsed, '
      'autoCollapseEnabled=${_settings.autoCollapseEnabled}, '
      'seconds=${_settings.autoCollapseSeconds}',
    );
    _collapseTimer?.cancel();

    if (_isCollapsed || !_settings.autoCollapseEnabled) {
      debugPrint('Inactivity timer skipped');
      return;
    }

    _collapseTimer = Timer(
      Duration(seconds: _settings.autoCollapseSeconds),
      () {
        debugPrint('Inactivity timer fired');
        unawaited(_collapseOverlay());
      },
    );
    debugPrint(
      'Inactivity timer started for ${_settings.autoCollapseSeconds}s',
    );
  }

  Future<void> _collapseOverlay() async {
    debugPrint('Collapse overlay requested');
    if (!mounted) {
      debugPrint('Collapse skipped: widget is not mounted');
      return;
    }
    if (_isCollapsed) {
      debugPrint('Collapse skipped: already collapsed');
      return;
    }
    if (!_settings.autoCollapseEnabled) {
      debugPrint('Collapse skipped: auto-collapse is disabled');
      return;
    }

    _collapseTimer?.cancel();
    final nextSettings = _settings.copyWith(
      overlayMode: TasbeehSettings.overlayModeCollapsed,
    );
    await _storage.saveSettings(nextSettings);
    if (!mounted) return;

    await _logCurrentOverlayPosition('before collapse');
    final nativeCollapsed =
        await TasbeehOverlayLayoutController.applyCollapsedLayout(nextSettings);
    if (!nativeCollapsed) {
      debugPrint(
        'Native collapsed resize failed; using internal UI-only fallback',
      );
    }
    final gestureExcluded =
        await TasbeehOverlayLayoutController.enableCollapsedGestureExclusion(
          nextSettings,
        );
    if (!gestureExcluded) {
      debugPrint(
        'System gesture exclusion unavailable; using inset fallback for handle',
      );
    }
    if (!mounted) return;

    setState(() {
      _settings = nextSettings;
      _isCollapsed = true;
      _useEdgeGestureInsetFallback = !gestureExcluded;
      _windowAnchorSide = nextSettings.floatingSide;
    });
    debugPrint('Overlay collapsed internally');

    await TasbeehOverlayMessenger.sendSettingsUpdate(
      nextSettings,
      source: TasbeehOverlayMessenger.sourceOverlay,
    );
  }

  Future<void> _expandOverlay() async {
    debugPrint('Expand overlay requested: wasCollapsed=$_isCollapsed');
    _collapseTimer?.cancel();
    unawaited(TasbeehOverlayLayoutController.disableGestureExclusion());

    final nextSettings = _settings.copyWith(
      overlayMode: TasbeehSettings.overlayModeExpanded,
    );
    await _storage.saveSettings(nextSettings);
    if (!mounted) return;

    final nativeExpanded =
        await TasbeehOverlayLayoutController.applyExpandedLayout(nextSettings);
    if (!nativeExpanded) {
      debugPrint('Native expanded resize failed; expanding Flutter UI only');
    }
    if (!mounted) return;

    setState(() {
      _settings = nextSettings;
      _isCollapsed = false;
      _useEdgeGestureInsetFallback = false;
      _windowAnchorSide = nextSettings.floatingSide;
    });
    debugPrint('Overlay expanded internally: isCollapsed=$_isCollapsed');

    debugPrint('Restarting inactivity timer after expand');
    _restartInactivityTimer();

    await TasbeehOverlayMessenger.sendSettingsUpdate(
      nextSettings,
      source: TasbeehOverlayMessenger.sourceOverlay,
    );
  }

  void _handleOverlayDragEnd() {
    unawaited(_saveFloatingSideFromCurrentPosition());
  }

  Future<void> _saveFloatingSideFromCurrentPosition() async {
    final config = configForScale(_settings.sizeScale);

    // Let the plugin finish its PositionGravity.auto edge animation first.
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;

    final OverlayPosition position;
    try {
      position = await FlutterOverlayWindow.getOverlayPosition();
    } catch (error) {
      debugPrint('Unable to read overlay position after drag: $error');
      return;
    }
    if (!mounted) return;

    final sameAsAnchor = position.x.abs() <= config.overlayWidth;
    final side = sameAsAnchor
        ? _windowAnchorSide
        : _oppositeSide(_windowAnchorSide);

    debugPrint(
      'Overlay drag ended: position=$position, '
      'anchorSide=$_windowAnchorSide, resolvedSide=$side',
    );

    if (side == _settings.floatingSide) {
      _restartInactivityTimer();
      return;
    }

    final nextSettings = _settings.copyWith(floatingSide: side);
    await _storage.saveSettings(nextSettings);
    if (!mounted) return;

    setState(() {
      _settings = nextSettings;
      _windowAnchorSide = side;
    });

    _restartInactivityTimer();
    await TasbeehOverlayMessenger.sendSettingsUpdate(
      nextSettings,
      source: TasbeehOverlayMessenger.sourceOverlay,
    );
  }

  Future<void> _logCurrentOverlayPosition(String label) async {
    try {
      final position = await FlutterOverlayWindow.getOverlayPosition();
      debugPrint(
        'Overlay position $label: position=$position, '
        'side=${_settings.floatingSide}',
      );
    } catch (error) {
      debugPrint('Unable to read overlay position $label: $error');
    }
  }

  Future<void> _applyNativeLayoutForCurrentMode() async {
    final success = _isCollapsed
        ? await TasbeehOverlayLayoutController.applyCollapsedLayout(_settings)
        : await TasbeehOverlayLayoutController.applyExpandedLayout(_settings);

    var gestureExcluded = false;
    if (_isCollapsed) {
      gestureExcluded =
          await TasbeehOverlayLayoutController.enableCollapsedGestureExclusion(
            _settings,
          );
    } else {
      unawaited(TasbeehOverlayLayoutController.disableGestureExclusion());
    }

    if (!success) {
      debugPrint(
        'Native layout update failed for '
        '${_isCollapsed ? 'collapsed' : 'expanded'} mode; '
        'continuing with Flutter UI fallback',
      );
    }

    if (_isCollapsed && mounted) {
      setState(() {
        _useEdgeGestureInsetFallback = !gestureExcluded;
      });
    }
  }

  String _oppositeSide(String side) {
    return side == TasbeehSettings.sideLeft
        ? TasbeehSettings.sideRight
        : TasbeehSettings.sideLeft;
  }

  @override
  Widget build(BuildContext context) {
    final config = configForScale(_settings.sizeScale);
    final rootWidth = _isCollapsed
        ? config.collapsedWindowWidth
        : config.overlayWidth;
    final rootHeight = _isCollapsed
        ? TasbeehOverlayLayoutController.collapsedWindowHeight(
            _settings,
            config,
          )
        : config.overlayHeight;

    // The patched plugin can resize the native WindowManager layout at runtime.
    // If that call fails on a device, the internal Flutter collapsed state still
    // works visually, but the native touch window may remain expanded-sized.
    return SizedBox(
      width: rootWidth,
      height: rootHeight,
      child: FloatingTasbeehOverlay(
        state: _state,
        settings: _settings,
        sizeConfig: config,
        isCollapsed: _isCollapsed,
        useEdgeGestureInsetFallback: _useEdgeGestureInsetFallback,
        onTap: _increment,
        onPullExpand: _expandOverlay,
        onDragEnd: _handleOverlayDragEnd,
      ),
    );
  }
}
