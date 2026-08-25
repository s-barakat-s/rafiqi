part of '../screens/journey_screen.dart';

class _Milestones extends StatelessWidget {
  const _Milestones({required this.store});
  final DailyWirdRepository store;
  @override
  Widget build(BuildContext context) {
    final total = store.history.values
        .where((record) => record.completed)
        .length;
    final longest = store.longestStreak;
    final milestones = [
      ('بداية الطريق', 'أول يوم مكتمل', total >= 1),
      ('أسبوع من المداومة', '٧ أيام متواصلة', longest >= 7),
      ('شهر من الاستمرار', '٣٠ يومًا متواصلًا', longest >= 30),
      ('مائة يوم من المداومة', '١٠٠ يوم متواصل', longest >= 100),
    ];
    return Column(
      children: milestones
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.$3
                          ? context.appColors.selected.withValues(alpha: .25)
                          : context.appColors.divider.withValues(alpha: .16),
                    ),
                    child: Icon(
                      item.$3
                          ? Icons.check_rounded
                          : Icons.lock_outline_rounded,
                      size: 17,
                      color: item.$3
                          ? context.appColors.secondary
                          : context.appColors.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          item.$2,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: context.appColors.secondaryText,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DayDetails extends StatefulWidget {
  const _DayDetails({required this.date, required this.store});

  final DateTime date;
  final DailyWirdRepository store;

  @override
  State<_DayDetails> createState() => _DayDetailsState();
}

class _DayDetailsState extends State<_DayDetails> {
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final record = widget.store.recordFor(widget.date);
    final today = LocalDay.date(DateTime.now());
    final isPast = widget.date.isBefore(today);
    final remainingGrace = widget.store.remainingGraceDaysInMonth(widget.date);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${ArabicNumerals.integer(widget.date.day)} ${_monthName(widget.date.month)}',
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (record?.completed ?? false)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.emerald.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.emerald.withValues(alpha: .5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: colors.emerald,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'مكتمل',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.emerald,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              else if (record?.graceUsed ?? false)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondary.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.secondary.withValues(alpha: .5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: colors.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'يوم سماح',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (record == null)
            Text(
              'لا توجد لقطة محفوظة لهذا اليوم.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.secondaryText),
            )
          else ...[
            ...record.items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                onTap: () => widget.store.setCompleted(
                  item.id,
                  !item.completed,
                  day: widget.date,
                  source: 'manual',
                ),
                leading: Icon(
                  item.completed
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: item.completed
                      ? colors.progress
                      : colors.textSecondary,
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    decoration: item.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle: Text(
                  item.completed
                      ? (item.completionSource == 'reader'
                            ? 'مكتمل · عبر القارئ'
                            : 'مكتمل · تسجيل يدوي')
                      : 'اضغط لتسجيل الإتمام',
                ),
              ),
            ),
            if (isPast && !(record.completed)) ...[
              const SizedBox(height: 16),
              Divider(color: colors.divider.withValues(alpha: .5)),
              const SizedBox(height: 8),
              if (record.graceUsed) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'هذا اليوم محمي بيوم سماح',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colors.secondary,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'يحافظ على استمراريتك دون اعتبار هذا اليوم مكتملًا.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.secondaryText),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          widget.store.setGraceUsed(widget.date, false),
                      child: const Text('إلغاء السماح'),
                    ),
                  ],
                ),
              ] else if (remainingGrace > 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'يحافظ يوم السماح على استمراريتك دون اعتبار هذا اليوم مكتملًا.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.secondaryText),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'متبقٍ لك ${ArabicNumerals.integer(remainingGrace)} من ${ArabicNumerals.integer(DailyWirdRepository.maxMonthlyGraceDays)} أيام سماح هذا الشهر',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colors.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          widget.store.setGraceUsed(widget.date, true),
                      icon: const Icon(Icons.shield_outlined, size: 18),
                      label: const Text('استخدام يوم سماح'),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  'تم استهلاك رصيد أيام السماح لهذا الشهر (${ArabicNumerals.integer(DailyWirdRepository.maxMonthlyGraceDays)}/${ArabicNumerals.integer(DailyWirdRepository.maxMonthlyGraceDays)}).',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.secondaryText),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

String _monthName(int month) => const [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
][month - 1];
