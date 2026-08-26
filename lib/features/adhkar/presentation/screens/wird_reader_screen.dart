import 'package:flutter/material.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:flutter/services.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/shared/widgets/calligraphy_title.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/domain/entities/wird_reader_mode.dart';
import 'package:tasbeh/features/adhkar/presentation/controllers/wird_reader_controller.dart';
import 'package:tasbeh/features/adhkar/presentation/screens/dhikr_details_screen.dart';
import 'package:tasbeh/features/settings/data/repositories/app_preferences_repository.dart';

part '../widgets/reader/dhikr_card.dart';
part '../widgets/reader/dhikr_deck.dart';
part '../widgets/reader/reader_chrome.dart';
part '../widgets/reader/focus_reader_view.dart';
part '../widgets/reader/list_reader_view.dart';
part '../widgets/reader/reading_reader_view.dart';
part '../widgets/reader/reader_mode_selector.dart';
part '../widgets/reader/dhikr_details_transition.dart';

class WirdReaderScreen extends StatefulWidget {
  const WirdReaderScreen({
    required this.category,
    required this.vibrationEnabled,
    required this.soundEnabled,
    super.key,
  });

  final AdhkarCategory category;
  final bool vibrationEnabled;
  final bool soundEnabled;

  @override
  State<WirdReaderScreen> createState() => _WirdReaderScreenState();
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

  @override
  void initState() {
    super.initState();
    _deckController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    WidgetsBinding.instance.addObserver(this);
    _reader.addListener(_onReaderChanged);
    _preferences.addListener(_onPreferencesChanged);
    _reader.initialize();
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reader.resumeIfDayChanged();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reader.removeListener(_onReaderChanged);
    _preferences.removeListener(_onPreferencesChanged);
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

  Future<void> _toggleAudio() =>
      _preferences.setAdhkarSound(!_audioEnabled);

  Widget _buildHeader(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'رجوع',
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
        Expanded(child: _ReaderTitle(category: widget.category)),
        if (_mode != WirdReaderMode.reading)
          IconButton(
            onPressed: _reader.canUndo ? _undo : null,
            tooltip: 'تراجع خطوة',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.undo_rounded, size: 21),
          ),
        IconButton(
          onPressed: _toggleHaptic,
          tooltip: _hapticEnabled ? 'إيقاف الاهتزاز' : 'تشغيل الاهتزاز',
          visualDensity: VisualDensity.compact,
          icon: Icon(
            _hapticEnabled
                ? Icons.vibration_rounded
                : Icons.mobile_off_rounded,
            size: 21,
            color: _hapticEnabled ? colors.secondary : null,
          ),
        ),
        IconButton(
          onPressed: _toggleAudio,
          tooltip: _audioEnabled ? 'إيقاف الصوت' : 'تشغيل الصوت',
          visualDensity: VisualDensity.compact,
          icon: Icon(
            _audioEnabled
                ? Icons.volume_up_outlined
                : Icons.volume_off_outlined,
            size: 21,
            color: _audioEnabled ? colors.secondary : null,
          ),
        ),
        _ReaderModeButton(
          selected: _mode,
          hapticsEnabled: _hapticEnabled,
          onSelected: _selectMode,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_reader.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final colors = context.appColors;
    final total = _reader.total;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 10),
              ValueListenableBuilder<double>(
                valueListenable: _readingScrollProgress,
                builder: (context, readingProgress, _) => Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _mode == WirdReaderMode.reading
                              ? readingProgress
                              : _reader.progress,
                          minHeight: 6,
                          backgroundColor: colors.divider.withValues(
                            alpha: .45,
                          ),
                          color: colors.progress,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _mode == WirdReaderMode.reading
                          ? 'تقدم القراءة ${ArabicNumerals.integer((readingProgress * 100).round())}٪'
                          : '${ArabicNumerals.integer(_reader.remainingItems.length)} متبقٍ من ${ArabicNumerals.integer(total)}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
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
                          ),
                          WirdReaderMode.list => _ListReaderView(
                            key: const ValueKey('list-reader'),
                            reader: _reader,
                            onDecrement: _decrementItem,
                            onRestart: _restart,
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
          ),
        ),
      ),
    );
  }
}
