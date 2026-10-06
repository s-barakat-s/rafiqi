part of '../home_screen.dart';

/// Image-led Hero for the Adhkar collection relevant right now
/// (أذكار الصباح / أذكار المساء).
class _MorningHero extends StatelessWidget {
  const _MorningHero({
    required this.categoryId,
    required this.complete,
    required this.progress,
    required this.onOpen,
  });

  final String categoryId;
  final bool complete;
  final AdhkarProgressSummary? progress;
  final Future<void> Function(String categoryId) onOpen;

  static const _thmanyahGeneralFeatures = <FontFeature>[
    FontFeature('ss01', 1),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final isMorning = categoryId == 'morning';
    final isRafiqi = colors.isRafiqi;
    final isRafiqiDark = isRafiqi && theme.brightness == Brightness.dark;
    final foreground = isRafiqi
        ? isRafiqiDark
              ? AppPalette.rafiqiDarkHeroForeground
              : AppPalette.rafiqiLightHeroForeground
        : colors.imageForeground;
    final mutedForeground = isRafiqi
        ? isRafiqiDark
              ? AppPalette.rafiqiDarkHeroForegroundMuted
              : AppPalette.rafiqiLightHeroForegroundMuted
        : colors.imageForegroundMuted;
    final actionBackground = isRafiqi
        ? isRafiqiDark
              ? AppPalette.rafiqiDarkHeroActionBackground
              : AppPalette.rafiqiLightHeroActionBackground
        : colors.imageActionBackground;
    final actionForeground = isRafiqi
        ? isRafiqiDark
              ? AppPalette.rafiqiDarkHeroActionForeground
              : AppPalette.rafiqiLightHeroActionForeground
        : colors.imageActionForeground;
    final reminderBackground = isRafiqi
        ? actionBackground
        : foreground.withValues(alpha: .14);
    final reminderForeground = isRafiqi ? actionForeground : foreground;
    final reminderBorder = isRafiqi
        ? actionForeground.withValues(alpha: .22)
        : foreground.withValues(alpha: .28);
    final backgroundAsset = colors.heroAsset(
      isMorning: isMorning,
      brightness: theme.brightness,
    );
    final title = isMorning ? 'أذكار الصباح' : 'أذكار المساء';
    final subtitle = isMorning
        ? 'ابدأ يومك بذكر الله وطمأنينة'
        : 'اختم يومك بذكر الله وسكينة';
    final completedSteps = progress?.completedSteps ?? 0;
    final totalSteps = progress?.totalSteps ?? 0;
    final hasProgress = (progress?.hasProgress ?? false) && !complete;
    final ctaLabel = complete
        ? 'أعد قراءة الورد'
        : hasProgress
        ? 'أكمل وردك'
        : 'ابدأ الورد';

    return Container(
      // Fixed height: the hero lives in a ListView (unbounded height), so a
      // Spacer inside needs a bounded parent to lay out against.
      height: 192,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(28)),
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
          if (!colors.isRafiqi)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [
                      colors.imageScrim.withValues(
                        alpha: colors.heroScrimOpacity(
                          isMorning: isMorning,
                          brightness: theme.brightness,
                        ),
                      ),
                      colors.imageScrim.withValues(alpha: 0),
                    ],
                    stops: const [0, .62],
                  ),
                ),
              ),
            ),
          Padding(
            // +2 horizontal so the CTA's ink/rounding never nudges the
            // column past the clip edge; removes the 1px overflow.
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact "حان الآن وقته" badge.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: reminderBackground,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: reminderBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RafiqiSvgIcon(
                        RafiqiIcons.notification,
                        size: 14,
                        color: reminderForeground,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'حان الآن وقته',
                        style: text.labelSmall?.copyWith(
                          fontFamily: AppFonts.thmanyahSans,
                          fontFeatures: _thmanyahGeneralFeatures,
                          color: reminderForeground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.thmanyahSans,
                    fontFeatures: _thmanyahGeneralFeatures,
                    color: foreground,
                    fontSize: 32,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(
                    fontFamily: AppFonts.thmanyahSans,
                    fontFeatures: _thmanyahGeneralFeatures,
                    color: mutedForeground,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    FilledButton(
                      onPressed: () => onOpen(categoryId),
                      style: FilledButton.styleFrom(
                        backgroundColor: actionBackground,
                        foregroundColor: actionForeground,
                        minimumSize: const Size(0, 42),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ctaLabel,
                            style: const TextStyle(
                              fontFamily: AppFonts.thmanyahSans,
                              fontFeatures: _thmanyahGeneralFeatures,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 7),
                          const Icon(Icons.arrow_back_rounded, size: 17),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (hasProgress) ...[
                      Text(
                        '${ArabicNumerals.integer(completedSteps)} من ${ArabicNumerals.integer(totalSteps)}',
                        style: text.labelMedium?.copyWith(
                          fontFamily: AppFonts.thmanyahSans,
                          fontFeatures: _thmanyahGeneralFeatures,
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (hasProgress)
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: totalSteps == 0
                                ? 0
                                : completedSteps / totalSteps,
                            minHeight: 4,
                            backgroundColor: foreground.withValues(alpha: .22),
                            color: foreground,
                          ),
                        ),
                      )
                    else if (complete)
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 26,
                        color: foreground,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
