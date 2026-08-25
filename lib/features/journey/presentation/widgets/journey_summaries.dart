part of '../screens/journey_screen.dart';

class _WeekConsistency extends StatelessWidget {
  const _WeekConsistency({required this.store, required this.start});
  final DailyWirdRepository store;
  final DateTime start;
  @override
  Widget build(BuildContext context) {
    const labels = ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];
    final colors = context.appColors;
    return Row(
      children: List.generate(7, (index) {
        final date = start.add(Duration(days: index));
        final record = store.recordFor(date);
        final completed = record?.completed ?? false;
        final isGrace = !completed && (record?.graceUsed ?? false);
        final today = date == LocalDay.date(DateTime.now());
        final future = date.isAfter(LocalDay.date(DateTime.now()));
        return Expanded(
          child: Column(
            children: [
              Text(
                labels[index],
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: colors.secondaryText),
              ),
              const SizedBox(height: 8),
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completed
                      ? colors.emerald
                      : isGrace
                      ? colors.secondary.withValues(alpha: .28)
                      : future
                      ? Colors.transparent
                      : colors.divider.withValues(alpha: .18),
                  border: today
                      ? Border.all(color: colors.progress)
                      : isGrace
                      ? Border.all(
                          color: colors.secondary.withValues(alpha: .7),
                        )
                      : null,
                ),
                child: completed
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppPalette.dustGrey,
                        size: 17,
                      )
                    : isGrace
                    ? Icon(
                        Icons.shield_outlined,
                        color: colors.secondary,
                        size: 15,
                      )
                    : Text(
                        ArabicNumerals.integer(date.day),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: future
                              ? colors.secondaryText.withValues(alpha: .42)
                              : null,
                        ),
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _MonthlySummary extends StatelessWidget {
  const _MonthlySummary({required this.store, required this.month});
  final DailyWirdRepository store;
  final DateTime month;
  @override
  Widget build(BuildContext context) {
    final now = LocalDay.date(DateTime.now());
    final first = DateTime(month.year, month.month);
    final last = DateTime(month.year, month.month + 1, 0);
    final end = month.year == now.year && month.month == now.month ? now : last;
    final completed = store.completedBetween(first, end);
    final elapsed = end.difference(first).inDays + 1;
    final percent = elapsed == 0 ? 0 : (completed * 100 / elapsed).round();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 17),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: context.appColors.divider),
          bottom: BorderSide(color: context.appColors.divider),
        ),
      ),
      child: Row(
        children: [
          _SummaryValue(
            label: 'أيام مكتملة',
            value: ArabicNumerals.integer(completed),
          ),
          _SummaryValue(
            label: 'نسبة الالتزام',
            value: ArabicNumerals.percent(percent),
          ),
          _SummaryValue(
            label: 'أطول سلسلة',
            value: ArabicNumerals.integer(store.longestStreak),
          ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: context.appColors.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: context.appColors.secondaryText,
          ),
        ),
      ],
    ),
  );
}
