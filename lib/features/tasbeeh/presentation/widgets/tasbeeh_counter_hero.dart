part of '../screens/tasbeeh_home_screen.dart';

class _CounterHero extends StatelessWidget {
  const _CounterHero({
    required this.phrase,
    required this.count,
    required this.dailyTotal,
    required this.target,
    required this.isTaskMode,
    required this.focusProgress,
    required this.hintsOpacity,
    required this.onTap,
    required this.onResetSession,
    required this.onOpenDhikrSelector,
  });

  final String phrase;
  final int count;
  final int dailyTotal;
  final int? target;
  final bool isTaskMode;

  /// 0.0 = normal Tasbeeh
  /// 1.0 = final Focus Mode composition
  final Animation<double> focusProgress;

  /// Controls the secondary UI that disappears while entering focus.
  final Animation<double> hintsOpacity;

  final VoidCallback onTap;
  final VoidCallback onResetSession;
  final VoidCallback onOpenDhikrSelector;

  double _lerp(double begin, double end, double t) {
    return begin + ((end - begin) * t);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: 'زيادة عداد التسبيح',
      value: ArabicNumerals.integer(count),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('tasbeeh-counter-tap-area'),
          onTap: onTap,
          splashColor: colors.primary.withValues(alpha: dark ? .12 : .08),
          highlightColor: colors.primary.withValues(alpha: dark ? .06 : .04),
          child: SizedBox.expand(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AnimatedBuilder(
                animation: focusProgress,
                builder: (context, _) {
                  final rawProgress = focusProgress.value.clamp(0.0, 1.0);

                  final t = Curves.easeInOutCubic.transform(rawProgress);

                  // --------------------------------------------------
                  // Continuous normal -> focus interpolation
                  // --------------------------------------------------

                  final phraseFontSize = _lerp(isTaskMode ? 34 : 36,
                      (MediaQuery.sizeOf(context).width * .18).clamp(54.0, 84.0).toDouble(), t);

                  final countFontSize = _lerp(118,
                      (MediaQuery.sizeOf(context).width * .40).clamp(118.0, 180.0).toDouble(), t);

                  final phraseToCountSpacing = _lerp(18, 0, t);

                  return Align(
                    alignment: Alignment(0, _lerp(-.2, 0, t)),
                    child: Transform.translate(
                        offset: Offset(0, _lerp(0, -10, t)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // -------------------------------
                            // CURRENT DHIKR
                            // -------------------------------
                            if (isTaskMode)
                              Text(
                                phrase,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppFonts.display,
                                  color: colors.textPrimary,
                                  fontSize: phraseFontSize,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              )
                            else
                              _InlineDhikrSelector(
                                phrase: phrase,
                                focusProgress: t,
                                fontSize: phraseFontSize,
                                onTap: onOpenDhikrSelector,
                              ),

                            SizedBox(height: phraseToCountSpacing),

                            // -------------------------------
                            // MAIN COUNTER
                            // -------------------------------
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                ArabicNumerals.integer(count),
                                maxLines: 1,
                                style: TextStyle(
                                  fontFamily: AppFonts.ui,
                                  color: Color.lerp(
                                    colors.textPrimary,
                                    colors.primary,
                                    t * .22,
                                  ),
                                  fontSize: countFontSize,
                                  fontWeight: FontWeight.w400,
                                  height: .92,
                                  letterSpacing: _lerp(-1, -2, t),
                                ),
                              ),
                            ),

                            // -------------------------------
                            // NORMAL-MODE SECONDARY CONTENT
                            // -------------------------------
                            ClipRect(
                              child: Align(
                                heightFactor: 1 - t,
                                child: FadeTransition(
                              opacity: hintsOpacity,
                              child: IgnorePointer(
                                ignoring: rawProgress > .05,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (target != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'هدف الورد  '
                                        '${ArabicNumerals.integer(count.clamp(0, target!).toInt())} / '
                                        '${ArabicNumerals.integer(target!)}',
                                        style: TextStyle(
                                          color: colors.primary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 18),

                                    _TodayTotalLabel(total: dailyTotal),

                                    if (!isTaskMode) ...[
                                      const SizedBox(height: 8),
                                      Center(
                                        child: _TasbeehTextAction(
                                          title: 'تصفير العداد',
                                          icon: const RafiqiSvgIcon(
                                            RafiqiIcons.reset,
                                            size: 20,
                                          ),
                                          onTap: onResetSession,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineDhikrSelector extends StatelessWidget {
  const _InlineDhikrSelector({
    required this.phrase,
    required this.focusProgress,
    required this.fontSize,
    required this.onTap,
  });

  final String phrase;

  /// Already curved/interpolated value from 0 -> 1.
  final double focusProgress;

  final double fontSize;
  final VoidCallback onTap;

  double _lerp(double begin, double end, double t) {
    return begin + ((end - begin) * t);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final progress = focusProgress.clamp(0.0, 1.0);
    final selectorEnabled = progress == 0;

    return Semantics(
      button: selectorEnabled,
      label: 'اختيار الذكر',
      value: phrase,
      child: GestureDetector(
        onTap: selectorEnabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _lerp(18, 2, progress),
            vertical: _lerp(8, 2, progress),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                phrase,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  color: colors.textPrimary,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  height: 1.16,
                ),
              ),

              SizedBox(height: _lerp(2, 0, progress)),

              Align(
                heightFactor: 1 - progress,
                child: Opacity(
                opacity: (1 - progress).clamp(0.0, 1.0),
                child: ExcludeSemantics(
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colors.textPrimary.withValues(alpha: .72),
                    size: _lerp(26, 20, progress),
                  ),
                ),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayTotalLabel extends StatelessWidget {
  const _TodayTotalLabel({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final label = 'إجمالي تسبيحات اليوم: ${ArabicNumerals.integer(total)}';

    return Semantics(
      label: label,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 6),
          ExcludeSemantics(
            child: Icon(
              Icons.bar_chart_rounded,
              size: 16,
              color: colors.textSecondary.withValues(alpha: .9),
            ),
          ),
        ],
      ),
    );
  }
}
