part of '../home_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final isMorning = categoryId == 'morning';
    final foreground = colors.imageForeground;
    final mutedForeground = colors.imageForegroundMuted;
    final backgroundAsset = colors.heroAsset(
      isMorning: isMorning,
      brightness: theme.brightness,
    );
    final title = complete
        ? categoryId == 'morning'
              ? 'قرأت أذكار الصباح'
              : 'قرأت أذكار المساء'
        : categoryId == 'morning'
        ? 'أذكار الصباح'
        : 'أذكار المساء';
    final subtitle = complete
        ? 'تقبّل الله منك وبارك في ذكرك'
        : categoryId == 'morning'
        ? 'بداية مطمئنة ليومك'
        : 'سكينة المساء وخاتمة هادئة ليومك';
    final completedSteps = progress?.completedSteps ?? 0;
    final totalSteps = progress?.totalSteps ?? 0;
    return Container(
      constraints: const BoxConstraints(minHeight: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        image: DecorationImage(
          image: AssetImage(backgroundAsset),
          fit: BoxFit.cover,
          alignment: colors.usesExplicitControlRoles ? Alignment.centerLeft : Alignment.center,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    colors.imageScrim.withValues(alpha: 0),
                    colors.imageScrim.withValues(alpha: .12),
                    colors.imageScrim.withValues(alpha: colors.heroScrimOpacity(
                      isMorning: isMorning,
                      brightness: theme.brightness,
                    )),
                  ],
                  stops: const [0, .48, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(children: [
                RafiqiSvgIcon(
                  RafiqiIcons.notification,
                  size: 20,
                  color: foreground,
                ),
                const SizedBox(width: 7),
                Text('حان الآن وقت', style: text.labelLarge?.copyWith(color: mutedForeground)),
              ]),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  color: foreground,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: text.bodyLarge?.copyWith(color: mutedForeground),
              ),
              if (complete) ...[
                const SizedBox(height: 24),
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 34,
                  color: foreground,
                ),
              ] else ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: totalSteps == 0
                              ? 0
                              : completedSteps / totalSteps,
                          minHeight: 7,
                          backgroundColor: foreground.withValues(alpha: .2),
                          color: foreground,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${ArabicNumerals.integer(completedSteps)} من ${ArabicNumerals.integer(totalSteps)}',
                      style: text.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => onOpen(categoryId),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.imageActionBackground,
                    foregroundColor: colors.imageActionForeground,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        progress?.hasProgress ?? false
                            ? 'متابعة الورد'
                            : 'ابدأ الورد',
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_back_rounded, size: 19),
                    ],
                  ),
                ),
              ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
