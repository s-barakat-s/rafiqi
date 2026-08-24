import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tasbeh/app/formatters/arabic_numerals.dart';
import 'package:flutter/services.dart';
import 'package:tasbeh/app/theme/app_theme.dart';
import 'package:tasbeh/app/widgets/calligraphy_title.dart';
import 'package:tasbeh/features/adhkar/data/adhkar_progress_repository.dart';
import 'package:tasbeh/features/adhkar/domain/adhkar_data.dart';
import 'package:tasbeh/features/home/data/daily_journey_store.dart';

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
  final _progressRepository = AdhkarProgressRepository.instance;
  int _index = 0;
  late int _remaining = widget.category.items.first.repeatCount;
  Set<String> _completedStepIds = {};
  bool _isLoading = true;
  String _activeDayKey = AdhkarProgressRepository.localDayKey(DateTime.now());
  bool _isExiting = false;
  Future<void> _pendingProgressWrite = Future.value();
  int? _undoIndex;
  int? _undoRemaining;
  Set<String>? _undoCompletedStepIds;
  late final AnimationController _deckController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  bool get _isComplete => _index >= widget.category.items.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreProgress();
  }

  Future<void> _restoreProgress() async {
    final progress = await _progressRepository.load(widget.category);
    if (!mounted) return;
    final restoredIndex = progress.isCompleted
        ? widget.category.items.length
        : widget.category.items.indexWhere(
            (item) => item.id == progress.currentStepId,
          );
    setState(() {
      _index = restoredIndex < 0 ? 0 : restoredIndex;
      _remaining = progress.isCompleted ? 0 : progress.remainingCount;
      _completedStepIds = {...progress.completedStepIds};
      _activeDayKey = progress.dayKey;
      _isLoading = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _activeDayKey != AdhkarProgressRepository.localDayKey(DateTime.now())) {
      _restoreProgress();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deckController.dispose();
    super.dispose();
  }

  Future<void> _decrement() async {
    if (_isExiting || _isComplete) return;
    final todayKey = AdhkarProgressRepository.localDayKey(DateTime.now());
    if (_activeDayKey != todayKey) {
      await _restoreProgress();
      if (!mounted || _isComplete) return;
    }
    final currentItem = widget.category.items[_index];
    if (!currentItem.isPrelude && widget.vibrationEnabled) {
      HapticFeedback.selectionClick();
    }
    if (!currentItem.isPrelude && widget.soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    _undoIndex = _index;
    _undoRemaining = _remaining;
    _undoCompletedStepIds = {..._completedStepIds};
    if (_remaining > 1) {
      final nextRemaining = _remaining - 1;
      setState(() => _remaining = nextRemaining);
      await _persistProgress(_progressForCurrentStep(remaining: nextRemaining));
      return;
    }

    final completedAt = DateTime.now();
    final nextIndex = _index + 1;
    final completedIds = {..._completedStepIds, currentItem.id};
    final finished = nextIndex >= widget.category.items.length;
    final nextItem = finished ? null : widget.category.items[nextIndex];
    setState(() {
      _remaining = 0;
      _isExiting = true;
      _completedStepIds = completedIds;
    });
    final Future<void> progressWrite =
        _persistProgress(
          AdhkarReadingProgress(
            categoryId: widget.category.id,
            dayKey: AdhkarProgressRepository.localDayKey(DateTime.now()),
            currentStepId: nextItem?.id,
            remainingCount: nextItem?.repeatCount ?? 0,
            completedStepIds: completedIds,
            isCompleted: finished,
            lastUpdatedAt: completedAt,
            completedAt: finished ? completedAt : null,
          ),
        ).then((_) async {
          if (finished) {
            await DailyJourneyStore.instance.setAdhkarReaderCompletion(
              widget.category.id,
              true,
              day: completedAt,
            );
          }
        });
    await Future.wait<void>([_deckController.forward(from: 0), progressWrite]);
    if (!mounted) return;
    setState(() {
      _index = nextIndex;
      if (!_isComplete) {
        _remaining = widget.category.items[_index].repeatCount;
      }
      _deckController.reset();
      _isExiting = false;
    });
  }

  Future<void> _undo() async {
    if (_undoIndex == null ||
        _undoRemaining == null ||
        _undoCompletedStepIds == null ||
        _isExiting) {
      return;
    }
    final restoredIndex = _undoIndex!;
    final restoredRemaining = _undoRemaining!;
    final restoredCompletedIds = {..._undoCompletedStepIds!};
    setState(() {
      _index = restoredIndex;
      _remaining = restoredRemaining;
      _completedStepIds = restoredCompletedIds;
      _undoIndex = null;
      _undoRemaining = null;
      _undoCompletedStepIds = null;
    });
    await _persistProgress(
      _progressForCurrentStep(remaining: restoredRemaining),
    );
  }

  Future<void> _restart() async {
    await _progressRepository.clear(widget.category.id);
    if (!mounted) return;
    _deckController.reset();
    setState(() {
      _index = 0;
      _remaining = widget.category.items.first.repeatCount;
      _completedStepIds = {};
      _isExiting = false;
      _undoIndex = null;
      _undoRemaining = null;
      _undoCompletedStepIds = null;
    });
  }

  AdhkarReadingProgress _progressForCurrentStep({required int remaining}) {
    return AdhkarReadingProgress(
      categoryId: widget.category.id,
      dayKey: AdhkarProgressRepository.localDayKey(DateTime.now()),
      currentStepId: widget.category.items[_index].id,
      remainingCount: remaining,
      completedStepIds: {..._completedStepIds},
      isCompleted: false,
      lastUpdatedAt: DateTime.now(),
    );
  }

  Future<void> _persistProgress(AdhkarReadingProgress progress) {
    _pendingProgressWrite = _pendingProgressWrite.then(
      (_) => _progressRepository.save(progress),
    );
    return _pendingProgressWrite;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final colors = context.appColors;
    final total = widget.category.items.length;
    final progress = _isComplete ? 1.0 : _index / total;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'رجوع',
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                  Expanded(child: _ReaderTitle(category: widget.category)),
                  _HeaderAction(
                    icon: Icons.volume_up_outlined,
                    label: 'تشغيل الصوت',
                  ),
                  _HeaderAction(
                    icon: Icons.bookmark_border_rounded,
                    label: 'المفضلة',
                  ),
                  _HeaderAction(
                    icon: Icons.ios_share_outlined,
                    label: 'مشاركة',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: colors.divider.withValues(alpha: .45),
                        color: colors.progress,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'الذكر ${ArabicNumerals.integer(_isComplete ? total : _index + 1)} من ${ArabicNumerals.integer(total)}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Expanded(
                child: _isComplete
                    ? _CompletionState(total: total, onRestart: _restart)
                    : _ReaderDeck(
                        current: widget.category.items[_index],
                        next: _index + 1 < total
                            ? widget.category.items[_index + 1]
                            : null,
                        third: _index + 2 < total
                            ? widget.category.items[_index + 2]
                            : null,
                        fourth: _index + 3 < total
                            ? widget.category.items[_index + 3]
                            : null,
                        remaining: _remaining,
                        transition: _deckController,
                        onTap: _decrement,
                      ),
              ),
              if (!_isComplete) ...[
                const SizedBox(height: 12),
                Text(
                  'اضغط على البطاقة بعد كل تكرار',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.secondaryText),
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: _undoIndex == null ? null : _undo,
                  icon: const Icon(Icons.undo_rounded, size: 19),
                  label: const Text('تراجع'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderDeck extends StatelessWidget {
  const _ReaderDeck({
    required this.current,
    required this.next,
    required this.third,
    required this.fourth,
    required this.remaining,
    required this.transition,
    required this.onTap,
  });
  final DhikrItem current;
  final DhikrItem? next;
  final DhikrItem? third;
  final DhikrItem? fourth;
  final int remaining;
  final Animation<double> transition;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const nextPeek = 26.0;
    const thirdPeek = 16.0;
    const incomingPeek = 16.0;
    const deckReserve = nextPeek + thirdPeek + incomingPeek;
    return LayoutBuilder(
      builder: (context, constraints) {
        final fixedCardHeight = math.min(
          500.0,
          math.max(120.0, constraints.maxHeight - deckReserve),
        );

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: fixedCardHeight + deckReserve,
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                if (fourth != null)
                  _AnimatedDeckLayer(
                    key: ValueKey(fourth!.id),
                    transition: transition,
                    height: fixedCardHeight,
                    beginOffset: const Offset(0, deckReserve),
                    endOffset: const Offset(0, nextPeek + thirdPeek),
                    beginScale: 1,
                    endScale: 1,
                    beginOpacity: 0,
                    endOpacity: .72,
                    beginContentObscured: 1,
                    endContentObscured: 1,
                    beginSurface: colors.previewSurfaceBack,
                    endSurface: colors.previewSurfaceBack,
                    child: _DhikrCard(
                      key: ValueKey(fourth!.id),
                      item: fourth!,
                      remaining: fourth!.repeatCount,
                      enabled: false,
                    ),
                  ),
                if (third != null)
                  _AnimatedDeckLayer(
                    key: ValueKey(third!.id),
                    transition: transition,
                    height: fixedCardHeight,
                    beginOffset: const Offset(0, nextPeek + thirdPeek),
                    endOffset: const Offset(0, nextPeek),
                    beginScale: 1,
                    endScale: 1,
                    beginOpacity: .72,
                    endOpacity: .9,
                    beginContentObscured: 1,
                    endContentObscured: 1,
                    beginSurface: colors.previewSurfaceBack,
                    endSurface: colors.previewSurface,
                    child: _DhikrCard(
                      key: ValueKey(third!.id),
                      item: third!,
                      remaining: third!.repeatCount,
                      enabled: false,
                    ),
                  ),
                if (next != null)
                  _AnimatedDeckLayer(
                    key: ValueKey(next!.id),
                    transition: transition,
                    height: fixedCardHeight,
                    beginOffset: const Offset(0, nextPeek),
                    endOffset: Offset.zero,
                    beginScale: 1,
                    endScale: 1,
                    beginOpacity: .9,
                    endOpacity: 1,
                    beginContentObscured: 1,
                    endContentObscured: 0,
                    beginSurface: colors.previewSurface,
                    endSurface: colors.surfaceElevated,
                    child: _DhikrCard(
                      key: ValueKey(next!.id),
                      item: next!,
                      remaining: next!.repeatCount,
                      enabled: false,
                    ),
                  ),
                _AnimatedDeckLayer(
                  key: ValueKey(current.id),
                  transition: transition,
                  height: fixedCardHeight,
                  beginOffset: Offset.zero,
                  endOffset: const Offset(-1.25, 0),
                  beginScale: 1,
                  endScale: 1,
                  beginOpacity: 1,
                  endOpacity: 0,
                  beginContentObscured: 0,
                  endContentObscured: 0,
                  beginSurface: colors.surfaceElevated,
                  endSurface: colors.surfaceElevated,
                  horizontalOffsetFactor: true,
                  child: _DhikrCard(
                    key: ValueKey(current.id),
                    item: current,
                    remaining: remaining,
                    enabled: true,
                    onTap: onTap,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedDeckLayer extends StatelessWidget {
  const _AnimatedDeckLayer({
    required this.transition,
    required this.height,
    required this.beginOffset,
    required this.endOffset,
    required this.beginScale,
    required this.endScale,
    required this.beginOpacity,
    required this.endOpacity,
    required this.beginContentObscured,
    required this.endContentObscured,
    required this.beginSurface,
    required this.endSurface,
    required this.child,
    this.horizontalOffsetFactor = false,
    super.key,
  });

  final Animation<double> transition;
  final double height;
  final Offset beginOffset;
  final Offset endOffset;
  final double beginScale;
  final double endScale;
  final double beginOpacity;
  final double endOpacity;
  final double beginContentObscured;
  final double endContentObscured;
  final Color beginSurface;
  final Color endSurface;
  final bool horizontalOffsetFactor;
  final Widget child;

  @override
  Widget build(BuildContext context) => Positioned(
    top: 0,
    left: 0,
    right: 0,
    height: height,
    child: LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: transition,
        child: child,
        builder: (context, child) {
          final progress = Curves.easeInOutCubic.transform(transition.value);
          final offset = Offset(
            _lerp(beginOffset.dx, endOffset.dx, progress),
            _lerp(beginOffset.dy, endOffset.dy, progress),
          );
          final translatedOffset = horizontalOffsetFactor
              ? Offset(offset.dx * constraints.maxWidth, offset.dy)
              : offset;
          final surface = Color.lerp(beginSurface, endSurface, progress)!;
          return Transform.translate(
            offset: translatedOffset,
            child: Transform.scale(
              scale: _lerp(beginScale, endScale, progress),
              alignment: Alignment.topCenter,
              child: Opacity(
                opacity: _lerp(beginOpacity, endOpacity, progress),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      child!,
                      IgnorePointer(
                        child: Opacity(
                          opacity: _lerp(
                            beginContentObscured,
                            endContentObscured,
                            progress,
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

double _lerp(num start, num end, double t) =>
    start.toDouble() + (end.toDouble() - start.toDouble()) * t;

class _DhikrCard extends StatelessWidget {
  const _DhikrCard({
    required this.item,
    required this.remaining,
    required this.enabled,
    this.onTap,
    super.key,
  });
  final DhikrItem item;
  final int remaining;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final conciseSource = _conciseSource(item);
    final virtuePreview = item.virtuePreview ?? _virtuePreview(item.virtue);
    final hasMetadata = conciseSource.isNotEmpty || virtuePreview != null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineStrong),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.counterSurface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: colors.outline.withValues(alpha: .7),
                    ),
                  ),
                  child: Text(
                    item.isPrelude
                        ? 'مقدمة الورد'
                        : '${ArabicNumerals.integer(remaining)} ${remaining == 1 ? 'مرة متبقية' : 'مرات متبقية'}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isLight ? colors.secondary : AppPalette.drySage,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.instruction != null) ...[
                          _PracticeInstruction(text: item.instruction!),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          item.text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            height: 1.85,
                            fontWeight: FontWeight.w400,
                          ).copyWith(fontSize: _dhikrFontSize(item)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ...[
                Divider(color: colors.divider.withValues(alpha: .55)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (hasMetadata)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (conciseSource.isNotEmpty)
                              Text(
                                conciseSource,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontFamily: 'IBMPlexSansArabic',
                                      color: colors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            if (virtuePreview != null) ...[
                              if (conciseSource.isNotEmpty)
                                const SizedBox(height: 3),
                              Text(
                                'الفضل: $virtuePreview',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontFamily: 'IBMPlexSansArabic',
                                      color: colors.textSecondary,
                                      height: 1.45,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      )
                    else
                      const Spacer(),
                    IgnorePointer(
                      ignoring: !enabled,
                      child: IconButton(
                        onPressed: () => _showDhikrInfo(context, item),
                        tooltip: 'معلومات الذكر',
                        icon: const Icon(Icons.info_outline_rounded, size: 21),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PracticeInstruction extends StatelessWidget {
  const _PracticeInstruction({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      fontFamily: 'IBMPlexSansArabic',
      color: context.appColors.textSecondary,
      height: 1.55,
      fontWeight: FontWeight.w600,
    ),
  );
}

int _dhikrLength(DhikrItem item) => item.text.runes.length;

bool _isLongDhikr(DhikrItem item) => _dhikrLength(item) > 600;

bool _isMediumDhikr(DhikrItem item) => _dhikrLength(item) > 360;

double _dhikrFontSize(DhikrItem item) {
  if (_isLongDhikr(item)) return 22;
  if (_isMediumDhikr(item)) return 24;
  return 26;
}

String _conciseSource(DhikrItem item) {
  if (item.surah != null) {
    final ayah = item.ayahFrom == null
        ? ''
        : item.ayahTo != null && item.ayahTo != item.ayahFrom
        ? ': ${ArabicNumerals.integer(item.ayahFrom!)}–${ArabicNumerals.integer(item.ayahTo!)}'
        : ': ${ArabicNumerals.integer(item.ayahFrom!)}';
    return '${item.surah}$ayah';
  }
  return item.source ?? '';
}

String? _virtuePreview(String? virtue) {
  if (virtue == null) return null;
  var preview = virtue.trim();
  if (preview.isEmpty) return null;

  // A leading bracketed citation is useful in the details sheet, but the card
  // already has a dedicated concise source line.
  preview = preview.replaceFirst(RegExp(r'^\[[^\]]+\]\s*'), '').trim();
  if (preview.isEmpty) return null;
  const limit = 150;
  if (preview.runes.length <= limit) return preview;

  final shortened = String.fromCharCodes(preview.runes.take(limit));
  RegExpMatch? sentenceEnd;
  for (final match in RegExp(r'[.!؟؛]').allMatches(shortened)) {
    sentenceEnd = match;
  }
  if (sentenceEnd != null && sentenceEnd.end >= 70) {
    return shortened.substring(0, sentenceEnd.end).trim();
  }
  return '${shortened.trimRight()}…';
}

void _showDhikrInfo(BuildContext context, DhikrItem item) {
  final conciseSource = _conciseSource(item);
  final sections = <(String, String)>[
    if (conciseSource.isNotEmpty) ('المصدر', conciseSource),
    (
      'التكرار',
      item.countDescription ??
          '${ArabicNumerals.integer(item.repeatCount)} مرات',
    ),
    if (item.virtue != null) ('الفضل', item.virtue!),
  ];
  final hasFullReference =
      item.fullSource != null ||
      item.hadithText != null ||
      item.explanation != null;
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .58,
      maxChildSize: .88,
      minChildSize: .35,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: context.appColors.divider,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'معلومات الذكر',
            style: TextStyle(
              fontFamily: 'ArefRuqaa',
              fontSize: 27,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...sections.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.$1,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: context.appColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    section.$2,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          if (hasFullReference)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 12),
              title: const Text('عرض التخريج الكامل'),
              children: [
                if (item.fullSource != null)
                  _DetailedInfo(label: 'المرجع', value: item.fullSource!),
                if (item.hadithText != null)
                  _DetailedInfo(
                    label: 'الحديث / الدليل',
                    value: item.hadithText!,
                  ),
                if (item.explanation != null)
                  _DetailedInfo(
                    label: 'شرح المفردات',
                    value: item.explanation!,
                  ),
              ],
            ),
        ],
      ),
    ),
  );
}

class _DetailedInfo extends StatelessWidget {
  const _DetailedInfo({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: context.appColors.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(value, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _CompletionState extends StatelessWidget {
  const _CompletionState({required this.total, required this.onRestart});
  final int total;
  final VoidCallback onRestart;
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.selected.withValues(alpha: .24),
                border: Border.all(color: colors.outline),
              ),
              child: Icon(
                Icons.check_rounded,
                size: 38,
                color: colors.progress,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'تم وردك',
              style: TextStyle(
                fontFamily: 'ArefRuqaa',
                fontSize: 34,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${ArabicNumerals.integer(total)} / ${ArabicNumerals.integer(total)}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: colors.secondaryText),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('إعادة القراءة'),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.ios_share_outlined),
                  label: const Text('مشاركة'),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('إضافة إلى وردك اليومي'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: () {},
    tooltip: label,
    visualDensity: VisualDensity.compact,
    icon: Icon(icon, size: 21),
  );
}

class _ReaderTitle extends StatelessWidget {
  const _ReaderTitle({required this.category});

  final AdhkarCategory category;

  @override
  Widget build(BuildContext context) {
    final asset = switch (category.id) {
      'morning' => 'assets/calligraphy/morning_adhkar.png',
      'evening' => 'assets/calligraphy/evening_adhkar.png',
      'after_prayer' => 'assets/calligraphy/after_prayer_adhkar.png',
      _ => null,
    };
    if (asset == null) {
      return Text(
        category.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'ArefRuqaa',
          fontSize: 25,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return CalligraphyTitle(
      asset: asset,
      semanticLabel: category.title,
      height: 42,
    );
  }
}
