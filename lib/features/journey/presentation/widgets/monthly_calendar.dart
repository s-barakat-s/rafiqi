part of '../screens/journey_screen.dart';

class _MonthlyCalendar extends StatelessWidget {
  const _MonthlyCalendar({
    required this.store,
    required this.month,
    required this.onDayTap,
  });
  final DailyWirdRepository store;
  final DateTime month;
  final ValueChanged<DateTime> onDayTap;
  @override
  Widget build(BuildContext context) {
    const weekdays = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
    final first = DateTime(month.year, month.month);
    final offset = (first.weekday + 1) % 7;
    final count = DateTime(month.year, month.month + 1, 0).day;
    return Column(
      children: [
        Row(
          children: weekdays
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: context.appColors.secondaryText,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 7,
            crossAxisSpacing: 5,
          ),
          itemCount: offset + count,
          itemBuilder: (context, index) {
            if (index < offset) return const SizedBox.shrink();
            final date = DateTime(month.year, month.month, index - offset + 1);
            return _CalendarDay(
              date: date,
              record: store.recordFor(date),
              onTap: () => onDayTap(date),
            );
          },
        ),
      ],
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.record,
    required this.onTap,
  });
  final DateTime date;
  final DailyHistoryRecord? record;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final today = LocalDay.date(DateTime.now());
    final isToday = date == today;
    final future = date.isAfter(today);
    final completed = record?.completed ?? false;
    final isGrace = !completed && (record?.graceUsed ?? false);
    final background = completed
        ? colors.emerald
        : isGrace
        ? colors.secondary.withValues(alpha: .28)
        : (future ? Colors.transparent : colors.divider.withValues(alpha: .18));
    return InkWell(
      onTap: future ? null : onTap,
      customBorder: const CircleBorder(),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: background,
          border: isToday
              ? Border.all(color: colors.progress, width: 1.5)
              : isGrace
              ? Border.all(
                  color: colors.secondary.withValues(alpha: .7),
                  width: 1,
                )
              : null,
        ),
        child: Text(
          ArabicNumerals.integer(date.day),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: completed
                ? AppPalette.dustGrey
                : isGrace
                ? colors.secondary
                : (future ? colors.secondaryText.withValues(alpha: .42) : null),
            fontWeight: isToday || completed || isGrace
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
