import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_controller.dart';

class TasbeehFocusBehavior extends StatefulWidget {
  const TasbeehFocusBehavior({
    required this.controller,
    required this.active,
    required this.onExit,
    required this.child,
    super.key,
  });
  final bool active;
  final Future<void> Function() onExit;
  final Widget child;

  final TasbeehController controller;

  @override
  State<TasbeehFocusBehavior> createState() => _TasbeehFocusBehaviorState();
}

class _TasbeehFocusBehaviorState extends State<TasbeehFocusBehavior>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _holdDuration = Duration(seconds: 3);
  static const _screenChannel = MethodChannel('tasbeh/focus_mode');

  late final AnimationController _holdProgress;

  Timer? _instructionTimer;
  Timer? _completionTimer;
  int? _activePointer;
  Offset? _holdPosition;
  bool _showInstructions = true;
  bool _showCompletion = false;
  bool _holdCompleted = false;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    // Create the ticker while the element is active, never on first use in dispose.
    _holdProgress = AnimationController(vsync: this, duration: _holdDuration)
      ..addStatusListener(_onHoldStatusChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant TasbeehFocusBehavior oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _exiting = false;
      _showInstructions = true;
      unawaited(_applyFocusEnvironment());
      _instructionTimer?.cancel();
      _instructionTimer = Timer(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => _showInstructions = false);
      });
    } else if (!widget.active && oldWidget.active) {
      _instructionTimer?.cancel();
      _completionTimer?.cancel();
      _showCompletion = false;
      _resetHold();
      unawaited(_restoreEnvironment());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.active && !_exiting) {
      unawaited(_applyFocusEnvironment());
    } else if (state == AppLifecycleState.detached) {
      unawaited(_restoreEnvironment());
    }
  }

  Future<void> _applyFocusEnvironment() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
    if (_exiting || !mounted || !widget.active) {
      await _restoreEnvironment();
      return;
    }
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (_exiting || !mounted || !widget.active) {
      await _restoreEnvironment();
      return;
    }
    try {
      await _screenChannel.invokeMethod<void>('setKeepScreenOn', true);
    } on MissingPluginException {
      // Focus Mode remains usable on platforms without the Android bridge.
    } on PlatformException {
      // A lifecycle transition may temporarily make the activity unavailable.
    }
    if (_exiting || !mounted || !widget.active) await _restoreEnvironment();
  }

  Future<void> _restoreEnvironment() async {
    try {
      await _screenChannel.invokeMethod<void>('setKeepScreenOn', false);
    } on MissingPluginException {
      // No platform wake-lock was acquired.
    } on PlatformException {
      // The activity is already leaving; the window flag will be discarded.
    }
    await SystemChrome.setPreferredOrientations(const []);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_exiting || _activePointer != null) return;
    _activePointer = event.pointer;
    _holdPosition = event.localPosition;
    _holdCompleted = false;
    setState(() {});
    _holdProgress.forward(from: 0);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer || _exiting) return;
    setState(() => _holdPosition = event.localPosition);
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointer) return;
    final shouldCount = !_holdCompleted && !_exiting;
    _resetHold();
    if (shouldCount) _countOnce();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer == _activePointer) _resetHold();
  }

  void _onHoldStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || _exiting) return;
    _holdCompleted = true;
    unawaited(_exit(confirmWithHaptic: true));
  }

  void _resetHold() {
    _holdProgress.stop();
    _holdProgress.value = 0;
    _activePointer = null;
    _holdPosition = null;
    if (mounted) setState(() {});
  }

  void _countOnce() {
    if (_exiting) return;
    if (widget.controller.settings.hapticFeedbackEnabled) {
      unawaited(HapticFeedback.lightImpact());
    }
    unawaited(
      widget.controller.increment().then((completedTask) {
        if (mounted && completedTask) _showDailyCompletion();
      }),
    );
  }

  void _showDailyCompletion() {
    _completionTimer?.cancel();
    setState(() => _showCompletion = true);
    _completionTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _showCompletion = false);
    });
  }

  Future<void> _exit({bool confirmWithHaptic = false}) async {
    if (!mounted || _exiting) return;
    _exiting = true;
    _resetHold();
    if (confirmWithHaptic && widget.controller.settings.hapticFeedbackEnabled) {
      await HapticFeedback.mediumImpact();
    }
    if (!mounted) return;
    await widget.onExit();
  }

  @override
  void dispose() {
    _instructionTimer?.cancel();
    _completionTimer?.cancel();
    _holdProgress
      ..removeStatusListener(_onHoldStatusChanged)
      ..dispose();
    WidgetsBinding.instance.removeObserver(this);
    if (widget.active) unawaited(_restoreEnvironment());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final size = MediaQuery.sizeOf(context);
    final progressPosition = _holdPosition;

    return PopScope(
      canPop: !widget.active,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.active) unawaited(_exit());
      },
      child: Material(
        type: MaterialType.transparency,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Semantics(
            button: widget.active,
            excludeSemantics: widget.active,
            label: widget.active ? 'شاشة وضع التركيز للتسبيح' : null,
            value: widget.active
                ? ArabicNumerals.integer(widget.controller.state.currentCount)
                : null,
            hint: widget.active
                ? 'اضغط للتسبيح. استخدم زر الرجوع للخروج.'
                : null,
            onTap: widget.active ? _countOnce : null,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: widget.active ? _onPointerDown : null,
              onPointerMove: widget.active ? _onPointerMove : null,
              onPointerUp: widget.active ? _onPointerUp : null,
              onPointerCancel: widget.active ? _onPointerCancel : null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  IgnorePointer(ignoring: widget.active, child: widget.child),
                  if (widget.active)
                    Positioned(
                      left: 24,
                      right: 24,
                      top: 40,
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                          excluding: !_showInstructions,
                          child: AnimatedOpacity(
                            opacity: _showInstructions ? 1 : 0,
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeOutCubic,
                            child: Text(
                              'اضغط في أي مكان للتسبيح\n'
                              'اضغط مطولًا ٣ ثوانٍ للخروج',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 15,
                                height: 1.7,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (widget.active)
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 48,
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                          excluding: !_showCompletion,
                          child: Semantics(
                            liveRegion: true,
                            child: AnimatedOpacity(
                              opacity: _showCompletion ? 1 : 0,
                              duration: const Duration(milliseconds: 280),
                              child: Text(
                                'أحسنت، اكتمل ورد اليوم ✓',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colors.success,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (progressPosition != null)
                    Positioned(
                      left: (progressPosition.dx - 22)
                          .clamp(8.0, size.width - 52)
                          .toDouble(),
                      top: (progressPosition.dy - 68)
                          .clamp(8.0, size.height - 52)
                          .toDouble(),
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child: SizedBox.square(
                            dimension: 44,
                            child: AnimatedBuilder(
                              animation: _holdProgress,
                              builder: (_, _) => CircularProgressIndicator(
                                value: _holdProgress.value,
                                strokeWidth: 2.5,
                                color: colors.primary,
                                backgroundColor: colors.progressTrack,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
