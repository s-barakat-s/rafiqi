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
    final isDark = theme.brightness == Brightness.dark;
    final backgroundAsset = isDark
        ? 'assets/image/ChatGPT Image Aug 22, 2026, 09_26_58 PM.png'
        : 'assets/image/ChatGPT Image Aug 22, 2026, 09_16_46 PM.png';
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outline.withValues(alpha: .7)),
        image: DecorationImage(
          image: AssetImage(backgroundAsset),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            isDark
                ? colors.background.withValues(alpha: .42)
                : AppPalette.hunterGreen.withValues(alpha: .28),
            BlendMode.srcOver,
          ),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  color: AppPalette.dustGrey,
                  fontSize: 29,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: text.bodyLarge?.copyWith(color: AppPalette.dustGrey),
              ),
              if (complete) ...[
                const SizedBox(height: 24),
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppPalette.dustGrey,
                  size: 34,
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
                          backgroundColor: AppPalette.dustGrey.withValues(
                            alpha: .2,
                          ),
                          color: colors.progress,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${ArabicNumerals.integer(completedSteps)} من ${ArabicNumerals.integer(totalSteps)}',
                      style: text.labelLarge?.copyWith(
                        color: AppPalette.dustGrey,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => onOpen(categoryId),
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
        ],
      ),
    );
  }
}
