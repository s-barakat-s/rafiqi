part of '../home_screen.dart';

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontFamily: AppFonts.display,
      fontSize: 25,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _DailyTaskRow extends StatelessWidget {
  const _DailyTaskRow({
    required this.task,
    required this.complete,
    required this.progress,
    required this.onTap,
  });
  final DailyTask task;
  final bool complete;
  final AdhkarProgressSummary? progress;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: complete
                        ? colors.selected
                        : colors.primary.withValues(alpha: .1),
                    border: Border.all(
                      color: complete ? colors.progress : colors.outline,
                    ),
                  ),
                  child: Icon(
                    complete ? Icons.check_rounded : Icons.circle_outlined,
                    size: 19,
                    color: complete ? colors.textPrimary : colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: complete
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        !complete && (progress?.hasProgress ?? false)
                            ? '${ArabicNumerals.integer(progress!.completedSteps)} من ${ArabicNumerals.integer(progress!.totalSteps)}'
                            : task.goal == null
                            ? task.type
                            : '${task.type} · الهدف ${ArabicNumerals.integer(task.goal!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (task.isBase)
                  Icon(
                    Icons.auto_stories_outlined,
                    size: 19,
                    color: colors.secondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
