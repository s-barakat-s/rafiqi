part of '../home_screen.dart';

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.hijriDate, required this.gregorianDate, required this.streak, required this.onDateTap});
  final String hijriDate;
  final String gregorianDate;
  final int streak;
  final VoidCallback onDateTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: 82,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Image.asset(
              'assets/branding/rafeqe.png',
              color: colors.usesExplicitControlRoles || colors.isShafaq
                  ? colors.primary
                  : null,
              colorBlendMode: BlendMode.srcIn,
              width: 96,
              height: 48,
              fit: BoxFit.contain,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        size: 22, color: colors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      ArabicNumerals.integer(streak),
                      style: text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
                Text(
                  'أيام متتالية',
                  style: text.labelMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: onDateTap,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      hijriDate,
                      maxLines: 1,
                      style: text.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      gregorianDate,
                      maxLines: 1,
                      style: text.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onOpenAdhkar, required this.onOpenTasbeeh, required this.onOpenJourney, required this.onComingSoon});
  final VoidCallback onOpenAdhkar;
  final VoidCallback onOpenTasbeeh;
  final VoidCallback onOpenJourney;
  final VoidCallback onComingSoon;

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickAction('القرآن', RafiqiIcons.quran, onComingSoon),
      _QuickAction('الأذكار', RafiqiIcons.adhkar, onOpenAdhkar),
      _QuickAction('التسبيح', RafiqiIcons.tasbeeh, onOpenTasbeeh),
      _QuickAction('القبلة', RafiqiIcons.qibla, onComingSoon),
      _QuickAction('الأذان', RafiqiIcons.adhan, onComingSoon),
      _QuickAction('رحلتي', RafiqiIcons.journey, onOpenJourney),
    ];
    return AppGlassSurface(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: items
            .map(
              (item) => Expanded(child: _QuickActionButton(item: item)),
            )
            .toList(),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.onTap);
  final String label;
  final String icon;
  final VoidCallback onTap;
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.item});
  final _QuickAction item;
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: colors.counterSurface, borderRadius: BorderRadius.circular(14)), child: RafiqiSvgIcon(item.icon, size: 21, color: colors.primary)),
          const SizedBox(height: 6),
          Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
        ])),
      ),
    );
  }
}

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
    final visibleTasks = tasks;
    return AppGlassSurface(
      borderRadius: BorderRadius.circular(26),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: _SectionTitle('وردك اليوم')),
              IconButton(
                onPressed: onAdd,
                tooltip: 'إضافة عمل يومي',
                icon: const RafiqiSvgIcon(RafiqiIcons.add, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < 330 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.2;
              final progressIndicator = Semantics(
                label: 'اكتمال الورد اليومي',
                value:
                    '${ArabicNumerals.integer((progress * 100).round())}٪',
                excludeSemantics: true,
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 7,
                        strokeCap: StrokeCap.round,
                        backgroundColor: colors.outline.withValues(alpha: .45),
                      ),
                      Center(
                        child: Text(
                          '${ArabicNumerals.integer((progress * 100).round())}٪',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
              final taskList = Column(
                children: visibleTasks
                    .map(
                      (task) => _DailyTaskRow(
                        task: task,
                        complete: completedIds.contains(task.id),
                        adhkarProgress: progressFor(task),
                        tasbeehProgress: tasbeehProgressFor(task),
                        onTap: () => onTapTask(task),
                        onToggle: () => onToggleCheckbox(task),
                      ),
                    )
                    .toList(),
              );
              if (compact) {
                return Column(
                  children: [
                    progressIndicator,
                    const SizedBox(height: 16),
                    taskList,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  progressIndicator,
                  const SizedBox(width: 16),
                  Expanded(child: taskList),
                ],
              );
            },
          ),
          if (readyForStreak)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'أتممت ورد اليوم، بارك الله في مداومتك',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.success,
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

  String _iconForTask() {
    if (task.taskType == DailyTask.adhkarCollectionTaskType) {
      return switch (task.collectionId) {
        'morning' => RafiqiIcons.morningAdhkar,
        'evening' => RafiqiIcons.eveningAdhkar,
        'sleep' => RafiqiIcons.sleepAdhkar,
        'after_prayer' => RafiqiIcons.afterPrayerAdhkar,
        _ => RafiqiIcons.adhkar,
      };
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final taskIcon = _iconForTask();
    final detail = _detailText();
    final isActionable =
        task.taskType == DailyTask.adhkarCollectionTaskType ||
        task.taskType == DailyTask.tasbeehTargetTaskType;

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: AppTranslucentSurface(
        borderRadius: BorderRadius.circular(15),
        tintWithPrimaryInLight: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: complete ? 'إلغاء الإنجاز' : 'تسجيل منجز',
                  child: SizedBox(
                    width: 48,
                    height: 48,
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
                const SizedBox(width: 6),
                if (taskIcon.isNotEmpty) ...[
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.counterSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: RafiqiSvgIcon(
                      taskIcon,
                      size: 18,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: complete
                                  ? colors.textSecondary
                                  : colors.textPrimary,
                            ),
                      ),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: complete
                                  ? colors.success
                                  : colors.textSecondary,
                            ),
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
