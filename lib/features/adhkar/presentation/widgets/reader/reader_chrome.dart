part of '../../screens/wird_reader_screen.dart';

class _CompletionState extends StatelessWidget {
  const _CompletionState({
    required this.total,
    required this.onRestart,
    super.key,
  });
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
                fontFamily: AppFonts.display,
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
                  icon: const RafiqiSvgIcon(RafiqiIcons.add, size: 20),
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

/// Compact image-backed reader header the hub hero morphs into.
///
/// Rendered inside a Hero (same tag as the hub hero) so the flight animates
/// between the large hero and this bar without the artwork ever disappearing.
class _MorphingReaderHeader extends StatelessWidget {
  const _MorphingReaderHeader({
    required this.category,
    required this.onBackPressed,
    required this.mode,
    required this.onModeSelected,
    required this.canUndo,
    required this.onUndo,
    required this.hapticEnabled,
    required this.onToggleHaptic,
    required this.progress,
    required this.readingProgress,
    this.morph,
  });

  final AdhkarCategory category;
  final Animation<double>? morph;
  final VoidCallback onBackPressed;
  final WirdReaderMode mode;
  final ValueChanged<WirdReaderMode> onModeSelected;
  final bool canUndo;
  final VoidCallback onUndo;
  final bool hapticEnabled;
  final VoidCallback onToggleHaptic;
  final double progress;
  final ValueNotifier<double> readingProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final isMorning = category.kind != AdhkarCategoryKind.evening;
    final foreground = colors.imageForeground;
    final backgroundAsset = colors.heroAsset(
      isMorning: isMorning,
      brightness: theme.brightness,
    );
    final topInset = MediaQuery.paddingOf(context).top;
    final content = Material(
      color: Colors.transparent,
      child: Container(
        height: topInset + 76,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: AppThemeArtwork(
                asset: backgroundAsset,
                alignment: colors.usesExplicitControlRoles
                    ? Alignment.centerLeft
                    : Alignment.center,
              ),
            ),
            Positioned.fill(
              child: ColoredBox(
                color: colors.imageScrim.withValues(alpha: .26),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(8, topInset, 8, 0),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: _ImageHeaderAction(
                            label: 'رجوع',
                            onPressed: onBackPressed,
                            active: true,
                            icon: Icon(
                              Icons.arrow_forward_rounded,
                              color: colors.imageActionForeground,
                              size: 21,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 120),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                category.title,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppFonts.display,
                                  color: foreground,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: _ReaderHeaderControls(
                            morph: morph,
                            mode: mode,
                            onModeSelected: onModeSelected,
                            canUndo: canUndo,
                            onUndo: onUndo,
                            hapticEnabled: hapticEnabled,
                            onToggleHaptic: onToggleHaptic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ReaderHeaderProgress(
                    mode: mode,
                    progress: progress,
                    readingProgress: readingProgress,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    final animation = morph;
    if (animation == null) return content;
    return Hero(
      tag: WirdReaderScreen.heroTagFor(category.id),
      flightShuttleBuilder: WirdReaderScreen.heroFlightShuttle,
      child: content,
    );
  }
}

class _ReaderHeaderControls extends StatelessWidget {
  const _ReaderHeaderControls({
    required this.morph,
    required this.mode,
    required this.onModeSelected,
    required this.canUndo,
    required this.onUndo,
    required this.hapticEnabled,
    required this.onToggleHaptic,
  });

  final Animation<double>? morph;
  final WirdReaderMode mode;
  final ValueChanged<WirdReaderMode> onModeSelected;
  final bool canUndo;
  final VoidCallback onUndo;
  final bool hapticEnabled;
  final VoidCallback onToggleHaptic;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ReaderModeButton(selected: mode, onSelected: onModeSelected),
        _ImageHeaderAction(
          label: 'تراجع خطوة',
          onPressed: mode != WirdReaderMode.reading && canUndo ? onUndo : null,
          icon: RafiqiSvgIcon(
            RafiqiIcons.reset,
            size: 19,
            color: mode != WirdReaderMode.reading && canUndo
                ? colors.imageForeground
                : colors.imageForeground.withValues(alpha: .38),
          ),
        ),
        _ImageHeaderAction(
          label: hapticEnabled ? 'إيقاف الاهتزاز' : 'تشغيل الاهتزاز',
          onPressed: onToggleHaptic,
          active: hapticEnabled,
          icon: RafiqiSvgIcon(
            RafiqiIcons.vibration,
            size: 19,
            color: hapticEnabled
                ? colors.imageActionForeground
                : colors.imageForeground,
          ),
        ),
      ],
    );
    final animation = morph;
    if (animation == null) return controls;
    return AnimatedBuilder(
      animation: animation,
      child: controls,
      builder: (context, child) {
        final opacity = const Interval(
          .70,
          1,
          curve: Curves.easeOutCubic,
        ).transform(animation.value.clamp(0.0, 1.0));
        return IgnorePointer(
          ignoring: animation.status != AnimationStatus.completed,
          child: Opacity(opacity: opacity, child: child),
        );
      },
    );
  }
}

class _ImageHeaderAction extends StatelessWidget {
  const _ImageHeaderAction({
    required this.label,
    required this.onPressed,
    required this.icon,
    this.active = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox.square(
      dimension: 40,
      child: IconButton(
        onPressed: onPressed,
        tooltip: label,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: active
              ? colors.imageActionBackground.withValues(alpha: .88)
              : Colors.transparent,
          disabledForegroundColor: colors.imageForeground.withValues(
            alpha: .38,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: icon,
      ),
    );
  }
}

class _ReaderHeaderProgress extends StatelessWidget {
  const _ReaderHeaderProgress({
    required this.mode,
    required this.progress,
    required this.readingProgress,
  });

  final WirdReaderMode mode;
  final double progress;
  final ValueNotifier<double> readingProgress;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: readingProgress,
      builder: (context, readingValue, _) {
        final colors = context.appColors;
        final value = mode == WirdReaderMode.reading ? readingValue : progress;
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 3,
            backgroundColor: colors.imageForeground.withValues(alpha: .24),
            color: colors.progress,
          ),
        );
      },
    );
  }
}
