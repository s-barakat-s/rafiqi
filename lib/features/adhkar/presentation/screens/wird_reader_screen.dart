import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tasbeh/core/assets/rafiqi_icons.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:flutter/services.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/domain/entities/wird_reader_mode.dart';
import 'package:tasbeh/features/adhkar/presentation/controllers/wird_reader_controller.dart';
import 'package:tasbeh/features/adhkar/presentation/screens/dhikr_details_screen.dart';
import 'package:tasbeh/features/adhkar_audio/application/dhikr_audio_controller.dart';
import 'package:tasbeh/features/adhkar_audio/application/dhikr_audio_runtime.dart';
import 'package:tasbeh/features/adhkar_audio/data/dhikr_audio_manifest_repository.dart';
import 'package:tasbeh/features/adhkar_audio/domain/dhikr_audio.dart';
import 'package:tasbeh/features/settings/data/repositories/app_preferences_repository.dart';
import 'package:tasbeh/shared/widgets/app_glass_surface.dart';
import 'package:tasbeh/shared/widgets/app_decorative_background.dart';
import 'package:tasbeh/shared/widgets/app_theme_artwork.dart';
import 'package:tasbeh/shared/widgets/rafiqi_svg_icon.dart';

part '../widgets/reader/dhikr_card.dart';
part '../widgets/reader/dhikr_deck.dart';
part '../widgets/reader/reader_chrome.dart';
part '../widgets/reader/focus_reader_view.dart';
part '../widgets/reader/list_reader_view.dart';
part '../widgets/reader/reading_reader_view.dart';
part '../widgets/reader/reader_mode_selector.dart';
part '../widgets/reader/dhikr_details_transition.dart';
part '../widgets/reader/audio_controls.dart';

class WirdReaderScreen extends StatefulWidget {
  const WirdReaderScreen({
    required this.category,
    required this.vibrationEnabled,
    required this.soundEnabled,
    this.morphTransition,
    super.key,
  });

  final AdhkarCategory category;
  final bool vibrationEnabled;
  final bool soundEnabled;

  /// When provided, the header morphs from the Adhkar Hub hero (same tag)
  /// and the body fades/slides in during the later part of the flight.
  final MorphTransitionSpec? morphTransition;

  /// Stable shared-element tag for the hub hero ↔ reader header morph.
  static String heroTagFor(String collectionId) =>
      'adhkar_header_$collectionId';

  /// Shared flight shuttle: cross-fades hub hero content into the compact
  /// reader header while the Hero system animates the rect. Wrapped in a
  /// transparent Material so nothing flashes white and clipping stays stable.
  static Widget heroFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final fromChild = (fromHeroContext.widget as Hero).child;
    final toChild = (toHeroContext.widget as Hero).child;
    final fromSize = (fromHeroContext.findRenderObject()! as RenderBox).size;
    final toSize = (toHeroContext.findRenderObject()! as RenderBox).size;
    // Keep each endpoint at its natural layout size throughout the flight.
    // In particular, never lay out the Hub's Column at the compact bar height.
    Widget endpoint(Widget child, Size size) => FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(width: size.width, height: size.height, child: child),
    );
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value.clamp(0.0, 1.0);
          return Stack(
            fit: StackFit.expand,
            children: [
              endpoint(
                flightDirection == HeroFlightDirection.push
                    ? fromChild
                    : toChild,
                flightDirection == HeroFlightDirection.push ? fromSize : toSize,
              ),
              Opacity(
                opacity: t,
                child: endpoint(
                  flightDirection == HeroFlightDirection.push
                      ? toChild
                      : fromChild,
                  flightDirection == HeroFlightDirection.push
                      ? toSize
                      : fromSize,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  State<WirdReaderScreen> createState() => _WirdReaderScreenState();
}

/// Parameters handed to the reader so the hub hero and the reader header can
/// participate in one continuous shared-element transition.
class MorphTransitionSpec {
  const MorphTransitionSpec({required this.controller});

  final Animation<double> controller;
}

class _WirdReaderScreenState extends State<WirdReaderScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final WirdReaderController _reader = WirdReaderController(
    category: widget.category,
  );
  late final AnimationController _deckController;
  final _preferences = AppPreferencesRepository.instance;
  late WirdReaderMode _mode = _preferences.value.readerMode;
  late bool _hapticEnabled = _preferences.value.adhkarVibrationEnabled;
  late bool _audioEnabled = _preferences.value.adhkarSoundEnabled;
  final ValueNotifier<double> _readingScrollProgress = ValueNotifier(0);
  int _readingSessionGeneration = 0;
  DhikrAudioRuntime? _audioRuntime;
  bool _audioListenersAttached = false;
  bool _audioUpdatePending = false;

  DhikrAudioController? get _audio => _audioRuntime?.playback;

  Animation<double>? get _morph => widget.morphTransition?.controller;

  @override
  void initState() {
    super.initState();
    _deckController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    WidgetsBinding.instance.addObserver(this);
    _reader.addListener(_onReaderChanged);
    _preferences.adhkarFeedbackChanges.addListener(_onPreferencesChanged);
    _preferences.readerModeChanges.addListener(_onPreferencesChanged);
    _reader.initialize();
    _ensureAudio();
  }

  void _onReaderChanged() {
    if (_reader.isComplete &&
        _mode == WirdReaderMode.reading &&
        _readingScrollProgress.value != 1) {
      _readingScrollProgress.value = 1;
    }
    if (mounted) setState(() {});
  }

  void _onPreferencesChanged() {
    if (!mounted) return;
    final value = _preferences.value;
    if (_mode == value.readerMode &&
        _hapticEnabled == value.adhkarVibrationEnabled &&
        _audioEnabled == value.adhkarSoundEnabled) {
      return;
    }
    setState(() {
      _mode = value.readerMode;
      _hapticEnabled = value.adhkarVibrationEnabled;
      _audioEnabled = value.adhkarSoundEnabled;
    });
  }

  void _onAudioChanged() {
    if (!mounted) return;
    final phase = WidgetsBinding.instance.schedulerPhase;
    final isBuilding = phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;
    if (isBuilding) {
      if (_audioUpdatePending) return;
      _audioUpdatePending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _audioUpdatePending = false;
        if (!mounted) return;
        setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  Future<DhikrAudioRuntime?> _ensureAudio() async {
    if (_audioRuntime != null) {
      _attachAudioListeners(_audioRuntime!);
      return _audioRuntime;
    }
    try {
      final runtime = DhikrAudioRuntime.instance;
      await runtime.initialize();
      if (!mounted) return null;
      _attachAudioListeners(runtime);
      if (_audioRuntime != runtime) {
        setState(() => _audioRuntime = runtime);
      }
      return runtime;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تهيئة تشغيل الأذكار الصوتية')),
        );
      }
      return null;
    }
  }

  void _attachAudioListeners(DhikrAudioRuntime runtime) {
    if (!_audioListenersAttached) {
      _audioListenersAttached = true;
      runtime.playback.addListener(_onAudioChanged);
      runtime.downloads.addListener(_onAudioChanged);
    }
  }

  void _detachAudioListeners() {
    if (_audioListenersAttached && _audioRuntime != null) {
      _audioRuntime!.playback.removeListener(_onAudioChanged);
      _audioRuntime!.downloads.removeListener(_onAudioChanged);
      _audioListenersAttached = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reader.resumeIfDayChanged();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reader.removeListener(_onReaderChanged);
    _preferences.adhkarFeedbackChanges.removeListener(_onPreferencesChanged);
    _preferences.readerModeChanges.removeListener(_onPreferencesChanged);
    _detachAudioListeners();
    _reader.dispose();
    _deckController.dispose();
    _readingScrollProgress.dispose();
    super.dispose();
  }

  Future<void> _decrement() async {
    if (_reader.isTransitioning || _reader.isComplete) return;
    await _reader.resumeIfDayChanged();
    if (!mounted || _reader.isComplete) return;
    final currentItem = _reader.current;
    if (!currentItem.isPrelude && _hapticEnabled) {
      HapticFeedback.selectionClick();
    }
    if (!currentItem.isPrelude && _audioEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    await _reader.decrement(
      animateExit: () => _deckController.forward(from: 0),
      resetTransition: _deckController.reset,
    );
  }

  Future<void> _undo() async {
    if (!_reader.canUndo) return;
    _deckController.reset();
    await _reader.undo();
  }

  Future<void> _restart() async {
    _deckController.reset();
    if (_mode == WirdReaderMode.reading) {
      _readingScrollProgress.value = 0;
      setState(() => _readingSessionGeneration++);
    }
    await _reader.restart();
  }

  Future<void> _decrementItem(
    DhikrItem item, {
    Future<void> Function()? animateRemoval,
  }) async {
    if (_reader.isTransitioning || _reader.isItemCompleted(item.id)) return;
    if (!item.isPrelude && _hapticEnabled) {
      HapticFeedback.selectionClick();
    }
    if (!item.isPrelude && _audioEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    await _reader.decrementItem(item.id, animateRemoval: animateRemoval);
  }

  Future<void> _selectMode(WirdReaderMode mode) async {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    if (mode == WirdReaderMode.reading && _reader.isComplete) {
      _readingScrollProgress.value = 1;
    }
    await _preferences.setReaderMode(mode);
  }

  Future<void> _toggleHaptic() =>
      _preferences.setAdhkarVibration(!_hapticEnabled);

  Future<void> _openAudioOptions({DhikrItem? item}) async {
    final runtime = await _ensureAudio();
    if (!mounted || runtime == null) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _ReciterSelectorSheet(
        runtime: runtime,
        collectionId: widget.category.id,
        dhikrId: item?.id,
        onPlay: (mode) async {
          Navigator.of(context).pop();
          if (item == null && _mode == WirdReaderMode.focus) {
            await _selectMode(WirdReaderMode.list);
          }
          final played = item == null
              ? await runtime.playback.playAll(
                  collectionId: widget.category.id,
                  items: widget.category.items,
                  playbackMode: mode,
                )
              : await runtime.playback.playOne(
                  collectionId: widget.category.id,
                  item: item,
                  playbackMode: mode,
                );
          if (!played && mounted) {
            ScaffoldMessenger.of(this.context).showSnackBar(
              const SnackBar(
                content: Text('الصوت غير متاح أو لم يُنزّل لهذا الذكر'),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return _MorphingReaderHeader(
      category: widget.category,
      morph: _morph,
      onBackPressed: () => Navigator.of(context).pop(),
      mode: _mode,
      onModeSelected: _selectMode,
      canUndo: _reader.canUndo,
      onUndo: _undo,
      hapticEnabled: _hapticEnabled,
      onToggleHaptic: _toggleHaptic,
      progress: _reader.progress,
      readingProgress: _readingScrollProgress,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final total = _reader.total;
    final morph = _morph;
    final body = _reader.isLoading
        ? const Center(child: CircularProgressIndicator())
        : _buildReaderBody(
            context,
            colors: colors,
            total: total,
            includeHeader: false,
          );
    final readerBody = SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: body,
      ),
    );
    final presentedBody = morph == null
        ? readerBody
        : AnimatedBuilder(
            animation: morph,
            child: readerBody,
            builder: (context, child) {
              final bodyT = const Interval(
                .65,
                1,
                curve: Curves.easeOutCubic,
              ).transform(morph.value.clamp(0.0, 1.0));
              return IgnorePointer(
                ignoring: morph.status != AnimationStatus.completed,
                child: Opacity(
                  opacity: bodyT,
                  child: Transform.translate(
                    offset: Offset(0, 14 * (1 - bodyT)),
                    child: child,
                  ),
                ),
              );
            },
          );
    return AppDecorativeBackground(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemStatusBarContrastEnforced: false,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              _buildHeader(context),
              Expanded(child: presentedBody),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReaderBody(
    BuildContext context, {
    required AppColors colors,
    required int total,
    bool includeHeader = true,
  }) {
    return Column(
      children: [
        if (includeHeader) _buildHeader(context),
        const SizedBox(height: 12),
        _CollectionAudioBar(
          audio: _audio,
          manifests:
              _audioRuntime?.manifests ?? const DhikrAudioManifestRepository(),
          collectionId: widget.category.id,
          onOpen: () => _openAudioOptions(),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: BackdropGroup(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _reader.isComplete
                  ? _CompletionState(
                      key: const ValueKey('reader-complete'),
                      total: total,
                      onRestart: _restart,
                    )
                  : switch (_mode) {
                      WirdReaderMode.focus => _FocusReaderView(
                        key: const ValueKey('focus-reader'),
                        reader: _reader,
                        transition: _deckController,
                        onTap: _decrement,
                        onRestart: _restart,
                        audio: _audio,
                        onAudioPressed: (item) => _openAudioOptions(item: item),
                      ),
                      WirdReaderMode.list => _ListReaderView(
                        key: const ValueKey('list-reader'),
                        reader: _reader,
                        onDecrement: _decrementItem,
                        onRestart: _restart,
                        audio: _audio,
                        onAudioPressed: (item) => _openAudioOptions(item: item),
                      ),
                      WirdReaderMode.reading => _ReadingReaderView(
                        key: ValueKey(
                          'reading-reader-$_readingSessionGeneration',
                        ),
                        category: widget.category,
                        sessionGeneration: _readingSessionGeneration,
                        onProgressChanged: (value) {
                          _readingScrollProgress.value = value;
                        },
                        onComplete: _reader.completeFromReading,
                      ),
                    },
            ),
          ),
        ),
        if (_mode == WirdReaderMode.focus && !_reader.isComplete) ...[
          const SizedBox(height: 12),
          Text(
            'اضغط على البطاقة بعد كل تكرار',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.secondaryText),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}
