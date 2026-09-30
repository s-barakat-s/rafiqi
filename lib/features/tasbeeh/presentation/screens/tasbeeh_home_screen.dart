import 'package:flutter/material.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_controller.dart';
import 'package:tasbeh/features/tasbeeh/presentation/screens/tasbeeh_focus_screen.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/core/assets/rafiqi_icons.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_state.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_phrase.dart';

import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_task_context.dart';
import 'package:tasbeh/shared/widgets/rafiqi_svg_icon.dart';

part '../widgets/tasbeeh_counter_hero.dart';

class TasbeehHomeScreen extends StatefulWidget {
  const TasbeehHomeScreen({
    required this.state,
    required this.onIncrement,
    required this.onResetSession,
    this.onDecrement,
    required this.onOpenSettings,
    required this.phrases,
    required this.onSelectDhikr,
    required this.onAddCustomPhrase,
    required this.onOpenStatistics,
    required this.onOpenManualLog,
    required this.focusController,
    required this.hapticEnabled,
    required this.onHapticChanged,
    this.taskContext,
    this.taskProgress,
    this.onBack,
    super.key,
  });

  final TasbeehState state;
  final VoidCallback onIncrement;
  final VoidCallback onResetSession;
  final VoidCallback? onDecrement;
  final VoidCallback onOpenSettings;
  final List<TasbeehPhrase> phrases;
  final ValueChanged<TasbeehPhrase> onSelectDhikr;
  final Future<void> Function(String text) onAddCustomPhrase;
  final VoidCallback onOpenStatistics;
  final VoidCallback onOpenManualLog;
  final TasbeehController focusController;
  final bool hapticEnabled;
  final ValueChanged<bool> onHapticChanged;
  final TasbeehTaskContext? taskContext;
  final int? taskProgress;
  final VoidCallback? onBack;

  @override
  State<TasbeehHomeScreen> createState() => _TasbeehHomeScreenState();
}

class _TasbeehHomeScreenState extends State<TasbeehHomeScreen>
    with SingleTickerProviderStateMixin {
  static const _chromeDuration = Duration(milliseconds: 480);
  static const _chromeReverseDuration = Duration(milliseconds: 320);

  bool _focusActive = false;
  bool _disableAnimations = false;
  double? _normalTopInset;
  late final AnimationController _chrome = AnimationController(
    vsync: this,
    duration: _chromeDuration,
    reverseDuration: _chromeReverseDuration,
  );
  late final Animation<Offset> _topOut =
      Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1.15)).animate(
        CurvedAnimation(
          parent: _chrome,
          curve: Curves.easeInCubic,
          reverseCurve: Curves.easeOutCubic,
        ),
      );
  late final Animation<Offset> _bottomOut =
      Tween<Offset>(begin: Offset.zero, end: const Offset(0, 1.25)).animate(
        CurvedAnimation(
          parent: _chrome,
          curve: Curves.easeInCubic,
          reverseCurve: Curves.easeOutCubic,
        ),
      );
  late final Animation<double> _chromeFade = Tween<double>(begin: 1, end: 0)
      .animate(
        CurvedAnimation(
          parent: _chrome,
          curve: const Interval(0, 0.72, curve: Curves.easeOut),
          reverseCurve: const Interval(0.28, 1, curve: Curves.easeIn),
        ),
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableAnimations = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void initState() {
    super.initState();
    // Phase 2A: the route subscribes to the application-owned controller so
    // the visible count/phrase/haptic state stays live without being rebuilt
    // by an ancestor. The controller is NOT disposed here — ownership stays
    // with TasbeehAppScope.
    widget.focusController.addListener(_onTasbeehChanged);
  }

  void _onTasbeehChanged() {
    if (mounted) setState(() {});
  }

  /// Live state from the subscribed authority (falls back to the injected
  /// snapshot only for callers that pass a detached legacy state).
  TasbeehState get _liveState =>
      widget.taskContext == null ? widget.focusController.state : widget.state;

  List<TasbeehPhrase> get _livePhrases => widget.focusController.phrases;

  bool get _liveHaptic => widget.taskContext == null
      ? widget.focusController.settings.hapticFeedbackEnabled
      : widget.hapticEnabled;

  @override
  void didUpdateWidget(covariant TasbeehHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusController != oldWidget.focusController) {
      oldWidget.focusController.removeListener(_onTasbeehChanged);
      widget.focusController.addListener(_onTasbeehChanged);
    }
  }

  @override
  void dispose() {
    widget.focusController.removeListener(_onTasbeehChanged);
    _chrome.dispose();
    super.dispose();
  }

  Future<void> _openFocusMode() async {
    if (_focusActive || _chrome.isAnimating) return;
    _normalTopInset = MediaQuery.paddingOf(context).top;
    setState(() => _focusActive = true);
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      _chrome.value = 1;
    } else {
      await _chrome.forward();
    }
  }

  Future<void> _exitFocusMode() async {
    if (!mounted || !_focusActive) return;
    if (_disableAnimations) {
      _chrome.value = 0;
    } else {
      await _chrome.reverse();
    }
    if (mounted) setState(() => _focusActive = false);
  }

  @override
  Widget build(BuildContext context) {
    final isTaskMode = widget.taskContext != null;
    final target = isTaskMode ? widget.taskContext!.targetCount : null;
    final topInset = _normalTopInset ?? MediaQuery.paddingOf(context).top;

    final topChrome = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TasbeehHeader(
          isTaskMode: isTaskMode,
          onBack: widget.onBack,
          onOpenStatistics: widget.onOpenStatistics,
          onOpenFocusMode: _openFocusMode,
          hapticEnabled: _liveHaptic,
          onHapticChanged: widget.onHapticChanged,
        ),
        if (isTaskMode) ...[
          const SizedBox(height: 8),
          _LinkedTaskProgress(
            phrase: widget.taskContext!.phraseText,
            progress:
                widget.taskProgress ?? widget.taskContext!.initialProgress,
            target: widget.taskContext!.targetCount,
          ),
        ],
      ],
    );

    final bottomChrome = Padding(
      padding: const EdgeInsets.only(bottom: 102, top: 4),
      child: isTaskMode
          ? Row(
              children: [
                if (widget.onDecrement != null) ...[
                  Expanded(
                    child: _TasbeehTextAction(
                      title: 'تراجع',
                      icon: const Icon(Icons.undo_rounded, size: 20),
                      onTap: widget.onDecrement!,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: _TasbeehTextAction(
                    title: 'جلسة جديدة',
                    icon: const RafiqiSvgIcon(RafiqiIcons.reset, size: 20),
                    onTap: widget.onResetSession,
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _TasbeehActionCard(
                  title: 'تسجيل من سبحة خارجية',
                  description: 'أضف عددًا سجلته خارج التطبيق',
                  icon: const RafiqiSvgIcon(RafiqiIcons.edit, size: 24),
                  onTap: widget.onOpenManualLog,
                ),
                const SizedBox(height: 10),
                _TasbeehActionCard(
                  title: 'السبحة العائمة',
                  description: 'استخدم عدادًا عائمًا فوق التطبيقات',
                  icon: const RafiqiSvgIcon(RafiqiIcons.tasbeeh, size: 24),
                  onTap: widget.onOpenSettings,
                ),
              ],
            ),
    );

    return TasbeehFocusBehavior(
      controller: widget.focusController,
      active: _focusActive,
      onExit: _exitFocusMode,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _chrome,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Column(
                    children: [
                      _CollapsingTasbeehChrome(
                        sectionKey: const ValueKey('tasbeeh-top-chrome'),
                        progress: _chrome,
                        position: _topOut,
                        opacity: _chromeFade,
                        child: topChrome,
                      ),
                      Expanded(
                        child: RepaintBoundary(
                          child: _CounterHero(
                            phrase: _liveState.selectedDhikrText,
                            count: _liveState.currentCount,
                            dailyTotal: _liveState.dailyTotal,
                            target: target,
                            isTaskMode: isTaskMode,
                            focusProgress: _chrome,
                            hintsOpacity: _chromeFade,
                            onTap: widget.onIncrement,
                            onResetSession: widget.onResetSession,
                            onOpenDhikrSelector: () =>
                                _showDhikrSelector(context),
                          ),
                        ),
                      ),
                      _CollapsingTasbeehChrome(
                        sectionKey: const ValueKey('tasbeeh-bottom-chrome'),
                        progress: _chrome,
                        position: _bottomOut,
                        opacity: _chromeFade,
                        child: bottomChrome,
                      ),
                    ],
                  ),
                ),
              ),
              builder: (context, child) {
                final t = Curves.easeInOutCubic.transform(_chrome.value);
                return Padding(
                  padding: EdgeInsets.only(top: topInset * (1 - t)),
                  child: child,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDhikrSelector(BuildContext context) async {
    final selected = await showModalBottomSheet<TasbeehPhrase>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colors = sheetContext.appColors;
        return Container(
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border.withValues(alpha: .6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'اختر الذكر للتسبيح',
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final phrase in _livePhrases)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: phrase.id == _liveState.selectedDhikrId
                                ? colors.primaryContainer.withValues(alpha: .5)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            minTileHeight: 48,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text(
                              phrase.text,
                              style: TextStyle(
                                fontFamily: AppFonts.display,
                                fontSize: 17,
                                fontWeight:
                                    phrase.id == _liveState.selectedDhikrId
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: phrase.id == _liveState.selectedDhikrId
                                    ? colors.primary
                                    : colors.textPrimary,
                              ),
                            ),
                            trailing: phrase.id == _liveState.selectedDhikrId
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    color: colors.primary,
                                  )
                                : null,
                            onTap: () => Navigator.pop(sheetContext, phrase),
                          ),
                        ),
                      const SizedBox(height: 4),
                      ListTile(
                        minTileHeight: 48,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        leading: Icon(
                          Icons.add_circle_outline_rounded,
                          color: colors.primary,
                        ),
                        title: Text(
                          'إضافة ذكر مخصص',
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          await _showCustomPhraseDialog(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null) widget.onSelectDhikr(selected);
  }

  Future<void> _showCustomPhraseDialog(BuildContext context) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة ذكر مخصص'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            labelText: 'نص الذكر',
            hintText: 'مثال: أستغفر الله وأتوب إليه',
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text != null && text.isNotEmpty) await widget.onAddCustomPhrase(text);
  }
}

class _CollapsingTasbeehChrome extends StatelessWidget {
  const _CollapsingTasbeehChrome({
    required this.sectionKey,
    required this.progress,
    required this.position,
    required this.opacity,
    required this.child,
  });

  final Key sectionKey;
  final Animation<double> progress;
  final Animation<Offset> position;
  final Animation<double> opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      child: child,
      builder: (context, child) {
        final t = Curves.easeInOutCubic.transform(
          progress.value.clamp(0.0, 1.0),
        );
        return ClipRect(
          child: Align(
            key: sectionKey,
            heightFactor: 1 - t,
            child: SlideTransition(
              position: position,
              child: FadeTransition(
                opacity: opacity,
                child: IgnorePointer(
                  ignoring: progress.value > .02,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TasbeehHeader extends StatelessWidget {
  const _TasbeehHeader({
    required this.isTaskMode,
    required this.onBack,
    required this.onOpenStatistics,
    required this.onOpenFocusMode,
    required this.hapticEnabled,
    required this.onHapticChanged,
  });

  final bool isTaskMode;
  final VoidCallback? onBack;
  final VoidCallback onOpenStatistics;
  final VoidCallback onOpenFocusMode;
  final bool hapticEnabled;
  final ValueChanged<bool> onHapticChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 92),
              child: Text(
                isTaskMode ? 'ورد التسبيح' : 'التسبيح',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  color: colors.textPrimary,
                  fontSize: isTaskMode ? 24 : 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Row(
            children: [
              if (isTaskMode)
                IconButton(
                  onPressed: onBack ?? () => Navigator.maybePop(context),
                  tooltip: 'رجوع',
                  icon: const Icon(Icons.arrow_forward_rounded),
                  color: colors.textPrimary,
                )
              else
                _FocusModeChip(onTap: onOpenFocusMode),
              const Spacer(),
              _HeaderIconButton(
                tooltip: 'الاهتزاز',
                selected: hapticEnabled,
                onTap: () => onHapticChanged(!hapticEnabled),
                semanticToggled: hapticEnabled,
                child: RafiqiSvgIcon(
                  RafiqiIcons.vibration,
                  size: 20,
                  color: hapticEnabled ? colors.primary : colors.textSecondary,
                ),
              ),
              if (!isTaskMode) ...[
                const SizedBox(width: 6),
                _HeaderIconButton(
                  tooltip: 'الإحصائيات',
                  onTap: onOpenStatistics,
                  child: Icon(
                    Icons.bar_chart_rounded,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _FocusModeChip extends StatelessWidget {
  const _FocusModeChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: 'وضع التركيز',
      child: Material(
        color: colors.primaryContainer.withValues(alpha: dark ? .72 : .95),
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'وضع التركيز',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.spa_rounded,
                      size: 16,
                      color: colors.onPrimary,
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.onTap,
    required this.child,
    this.selected = false,
    this.semanticToggled,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;
  final bool selected;
  final bool? semanticToggled;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      toggled: semanticToggled,
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: colors.surfaceElevated.withValues(alpha: selected ? .92 : .7),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? colors.primary.withValues(alpha: .35)
                      : colors.border.withValues(alpha: .7),
                ),
              ),
              child: IconTheme(
                data: IconThemeData(
                  color: selected ? colors.primary : colors.textSecondary,
                  size: 20,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TasbeehTextAction extends StatelessWidget {
  const _TasbeehTextAction({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = colors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconTheme(
                  data: IconThemeData(color: color, size: 20),
                  child: icon,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TasbeehActionCard extends StatelessWidget {
  const _TasbeehActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = colors.surfaceElevated.withValues(
      alpha: dark ? .72 : .92,
    );

    return Semantics(
      button: true,
      label: '$title، $description',
      child: Material(
        color: background,
        elevation: dark ? 0 : 1,
        shadowColor: colors.primary.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border.withValues(alpha: .55)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(
                      alpha: dark ? .38 : .62,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconTheme(
                    data: IconThemeData(color: colors.primary, size: 24),
                    child: icon,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkedTaskProgress extends StatelessWidget {
  const _LinkedTaskProgress({
    required this.phrase,
    required this.progress,
    required this.target,
  });
  final String phrase;
  final int progress;
  final int target;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final capped = progress.clamp(0, target).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              phrase,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            'هدف الورد  ${ArabicNumerals.integer(capped)} / ${ArabicNumerals.integer(target)}',
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
