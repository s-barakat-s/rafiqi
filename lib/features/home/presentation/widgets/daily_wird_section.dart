part of '../home_screen.dart';

class _DailyWirdCard extends StatelessWidget {
  const _DailyWirdCard({
    required this.tasks,
    required this.completedIds,
    required this.progress,
    required this.readyForStreak,
    required this.progressFor,
    required this.tasbeehProgressFor,
    required this.onTapTask,
    required this.onToggleCheckbox,
    required this.onAdd,
  });

  final List<DailyTask> tasks;
  final Set<String> completedIds;
  final double progress;
  final bool readyForStreak;
  final AdhkarProgressSummary? Function(DailyTask task) progressFor;
  final int? Function(DailyTask task) tasbeehProgressFor;
  final Future<void> Function(DailyTask task) onTapTask;
  final Future<void> Function(DailyTask task) onToggleCheckbox;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final isEmpty = tasks.isEmpty;

    return AppGlassSurface(
      borderRadius: BorderRadius.circular(26),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: title (+ optional count pill) on the right, add on the left.
          Row(
            children: [
              Text(
                'وردك اليوم',
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              if (!isEmpty) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceSoft.withValues(alpha: .85),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: colors.outline.withValues(alpha: .5),
                    ),
                  ),
                  child: Text(
                    '${ArabicNumerals.integer(tasks.length)} مهام',
                    style: text.labelSmall?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Semantics(
                button: true,
                label: 'إضافة عمل يومي',
                child: Material(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: onAdd,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 38,
                      height: 38,
                      child: Icon(
                        Icons.add_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isEmpty)
            _DailyWirdEmpty(onAdd: onAdd)
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    constraints.maxWidth < 330 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.2;
                final progressRing = _DailyWirdProgressRing(progress: progress);
                final taskList = Column(
                  children: [
                    for (final task in tasks)
                      _DailyTaskRow(
                        task: task,
                        complete: completedIds.contains(task.id),
                        adhkarProgress: progressFor(task),
                        tasbeehProgress: tasbeehProgressFor(task),
                        onTap: () => onTapTask(task),
                        onToggle: () => onToggleCheckbox(task),
                      ),
                  ],
                );
                if (compact) {
                  return Column(
                    children: [
                      Center(child: progressRing),
                      const SizedBox(height: 16),
                      taskList,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    progressRing,
                    const SizedBox(width: 18),
                    Expanded(child: taskList),
                  ],
                );
              },
            ),
            if (readyForStreak)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 16,
                      color: colors.success,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'أتممت ورد اليوم، بارك الله في مداومتك',
                        style: text.labelMedium?.copyWith(
                          color: colors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Prominent circular completion indicator for وردك اليوم (72dp).
class _DailyWirdProgressRing extends StatelessWidget {
  const _DailyWirdProgressRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final percent = (progress * 100).round();
    return Semantics(
      label: 'اكتمال الورد اليومي',
      value: '${ArabicNumerals.integer(percent)}٪',
      excludeSemantics: true,
      child: SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
              backgroundColor: colors.progressTrack.withValues(alpha: .8),
              color: colors.progress,
            ),
            Center(
              child: Text(
                '${ArabicNumerals.integer(percent)}٪',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Calm empty state inside the same outer card.
class _DailyWirdEmpty extends StatelessWidget {
  const _DailyWirdEmpty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ابدأ بخطوة صغيرة',
            style: text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'أضف أول أذكار أو عمل يومي وابدأ مداومتك',
            style: text.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton.tonal(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer ?? colors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                visualDensity: VisualDensity.compact,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text('أضف وردك الأول'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.color});
  final String title;
  final Color? color;
  @override
  Widget build(BuildContext context) => Text(
        title,
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 25,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      );
}

class _DailyTaskRow extends StatelessWidget {
  const _DailyTaskRow({
    required this.task,
    required this.complete,
    required this.adhkarProgress,
    required this.tasbeehProgress,
    required this.onTap,
    required this.onToggle,
  });

  final DailyTask task;
  final bool complete;
  final AdhkarProgressSummary? adhkarProgress;
  final int? tasbeehProgress;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  static const _collectionIcons = {
    'morning': RafiqiIcons.morningAdhkar,
    'evening': RafiqiIcons.eveningAdhkar,
    'sleep': RafiqiIcons.sleepAdhkar,
    'after_prayer': RafiqiIcons.afterPrayerAdhkar,
  };

  String _iconForTask() {
    if (task.taskType == DailyTask.adhkarCollectionTaskType) {
      return _collectionIcons[task.collectionId] ?? RafiqiIcons.adhkar;
    }
    if (task.taskType == DailyTask.tasbeehTargetTaskType) {
      return RafiqiIcons.tasbeeh;
    }
    return '';
  }

  String _detailText() {
    if (task.taskType == DailyTask.tasbeehTargetTaskType) {
      final target = task.tasbeehTargetCount ?? task.goal ?? 33;
      final current = (tasbeehProgress ?? 0).clamp(0, target).toInt();
      return '${ArabicNumerals.integer(current)} / ${ArabicNumerals.integer(target)}';
    }
    if (complete) return 'تم الإنجاز';
    if (task.taskType == DailyTask.adhkarCollectionTaskType) {
      if (adhkarProgress?.hasProgress ?? false) {
        return '${ArabicNumerals.integer(adhkarProgress!.completedSteps)} من ${ArabicNumerals.integer(adhkarProgress!.totalSteps)}';
      }
      return task.type;
    }
    if (task.goal != null) {
      return '${task.type} · الهدف ${ArabicNumerals.integer(task.goal!)}';
    }
    return task.type;
  }

  /// 0..1 for partially completed tasbeeh tasks; null otherwise.
  double? _partialProgress() {
    if (complete) return null;
    if (task.taskType == DailyTask.tasbeehTargetTaskType) {
      final target = task.tasbeehTargetCount ?? task.goal ?? 33;
      if (target <= 0) return null;
      final current = (tasbeehProgress ?? 0).clamp(0, target).toInt();
      return current / target;
    }
    final progress = adhkarProgress;
    if (progress != null && progress.totalSteps > 0) {
      return progress.completedSteps / progress.totalSteps;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final taskIcon = _iconForTask();
    final detail = _detailText();
    final partialProgress = _partialProgress();
    final isActionable =
        task.taskType == DailyTask.adhkarCollectionTaskType ||
        task.taskType == DailyTask.tasbeehTargetTaskType;

    // More opaque than the outer glass card so rows read as their own
    // rectangles in Light Mode too. No BackdropFilter here — fill only.
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.surfaceElevated.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? .92 : .96,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: complete
                ? colors.success.withValues(alpha: .35)
                : colors.outline.withValues(alpha: .7),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: complete ? 'إلغاء الإنجاز' : 'تسجيل منجز',
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: InkResponse(
                      onTap: onToggle,
                      radius: 24,
                      child: Icon(
                        complete
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 24,
                        color: complete ? colors.success : colors.outlineStrong,
                      ),
                    ),
                  ),
                ),
                if (taskIcon.isNotEmpty) ...[
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.counterSurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: RafiqiSvgIcon(
                      taskIcon,
                      size: 19,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: complete
                              ? colors.textSecondary
                              : colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.labelSmall?.copyWith(
                                color: complete
                                    ? colors.success
                                    : colors.textSecondary,
                              ),
                            ),
                          ),
                          if (partialProgress != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: partialProgress,
                                  minHeight: 3,
                                  backgroundColor:
                                      colors.outline.withValues(alpha: .5),
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (isActionable && !complete) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 13,
                    color: colors.outlineStrong,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JourneyStrip extends StatelessWidget {
  const _JourneyStrip({required this.streak, required this.weekCompleted, required this.onTap});
  final int streak;
  final int weekCompleted;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppGlassSurface(
      borderRadius: BorderRadius.circular(24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Container(width: 48, height: 48, alignment: Alignment.center, decoration: BoxDecoration(color: colors.counterSurface, borderRadius: BorderRadius.circular(16)), child: RafiqiSvgIcon(RafiqiIcons.journey, color: colors.primary)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('رحلتك هذا الأسبوع', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(children: List.generate(7, (index) { final active = index < weekCompleted; return Padding(padding: const EdgeInsetsDirectional.only(end: 6), child: Icon(active ? Icons.circle : Icons.circle_outlined, size: 13, color: active ? colors.progress : colors.outlineStrong)); })),
              ])),
              Text('${ArabicNumerals.integer(streak)} يوم', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colors.primary, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
            ]),
          ),
        ),
      ),
    );
  }
}
