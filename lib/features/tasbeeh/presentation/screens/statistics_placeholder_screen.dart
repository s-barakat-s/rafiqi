import 'package:flutter/material.dart';
import 'package:tasbeh/app/formatters/arabic_numerals.dart';
import 'package:tasbeh/app/theme/app_theme.dart';
import 'package:tasbeh/features/home/data/daily_journey_store.dart';

class StatisticsPlaceholderScreen extends StatefulWidget {
  const StatisticsPlaceholderScreen({super.key});

  @override
  State<StatisticsPlaceholderScreen> createState() =>
      _StatisticsPlaceholderScreenState();
}

class _StatisticsPlaceholderScreenState
    extends State<StatisticsPlaceholderScreen> with WidgetsBindingObserver {
  final _store = DailyJourneyStore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _store.addListener(_refresh);
    _store.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _store.initialize();
  }

  @override
  Widget build(BuildContext context) {
    if (!_store.initialized) {
      return const Center(child: CircularProgressIndicator());
    }
    final colors = context.appColors;
    final now = calendarDate(DateTime.now());
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekCompleted = _store.completedBetween(
      weekStart,
      weekStart.add(const Duration(days: 6)),
    );
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 30),
        children: [
          const Text(
            'رحلتي',
            style: TextStyle(
              fontFamily: 'ArefRuqaa',
              fontSize: 36,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'استمر ولو بالقليل، فالثبات يصنع الأثر',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: colors.secondaryText),
          ),
          const SizedBox(height: 24),
          _JourneyHero(
            current: _store.currentStreak,
            longest: _store.longestStreak,
            weekCompleted: weekCompleted,
          ),
          const SizedBox(height: 30),
          _SectionHeader(title: 'اتساق الشهر', trailing: _monthName(now.month)),
          const SizedBox(height: 14),
          _MonthlyCalendar(
            store: _store,
            month: now,
            onDayTap: _showDayDetails,
          ),
          const SizedBox(height: 30),
          const _SectionHeader(title: 'هذا الأسبوع'),
          const SizedBox(height: 14),
          _WeekConsistency(store: _store, start: weekStart),
          const SizedBox(height: 10),
          Text(
            '${ArabicNumerals.integer(weekCompleted)} من ${ArabicNumerals.integer(7)} أيام مكتملة',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.secondaryText),
          ),
          const SizedBox(height: 30),
          const _SectionHeader(title: 'ملخص الشهر'),
          const SizedBox(height: 14),
          _MonthlySummary(store: _store, month: now),
          const SizedBox(height: 30),
          const _SectionHeader(title: 'محطات'),
          const SizedBox(height: 14),
          _Milestones(store: _store),
        ],
      ),
    );
  }

  void _showDayDetails(DateTime date) {
    if (date.isAfter(calendarDate(DateTime.now()))) return;
    final record = _store.recordFor(date);
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => _DayDetails(date: date, record: record),
    );
  }
}

class _JourneyHero extends StatelessWidget {
  const _JourneyHero({
    required this.current,
    required this.longest,
    required this.weekCompleted,
  });
  final int current;
  final int longest;
  final int weekCompleted;
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 25),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outline.withValues(alpha: .7)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_fire_department_outlined,
            color: colors.secondary,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            ArabicNumerals.integer(current),
            style: const TextStyle(
              color: AppPalette.dustGrey,
              fontSize: 52,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'يومًا متواصلًا',
            style: TextStyle(
              fontFamily: 'ArefRuqaa',
              color: AppPalette.dustGrey,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: colors.outline.withValues(alpha: .55)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _HeroDetail(
                label: 'أطول سلسلة',
                value: '${ArabicNumerals.integer(longest)} يومًا',
              ),
              Container(
                width: 1,
                height: 34,
                color: colors.outline.withValues(alpha: .55),
              ),
              _HeroDetail(
                label: 'هذا الأسبوع',
                value: '${ArabicNumerals.integer(weekCompleted)} من ${ArabicNumerals.integer(7)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroDetail extends StatelessWidget {
  const _HeroDetail({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: AppPalette.dustGrey,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        style: const TextStyle(color: Color(0xFFCDC5B8), fontSize: 12),
      ),
    ],
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final String? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'ArefRuqaa',
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      if (trailing != null)
        Text(
          trailing!,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: context.appColors.secondary),
        ),
    ],
  );
}

class _MonthlyCalendar extends StatelessWidget {
  const _MonthlyCalendar({
    required this.store,
    required this.month,
    required this.onDayTap,
  });
  final DailyJourneyStore store;
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
    final today = calendarDate(DateTime.now());
    final isToday = date == today;
    final future = date.isAfter(today);
    final completed = record?.completed ?? false;
    final background = completed
        ? colors.emerald
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
              : null,
        ),
        child: Text(
          ArabicNumerals.integer(date.day),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: completed
                ? AppPalette.dustGrey
                : (future ? colors.secondaryText.withValues(alpha: .42) : null),
            fontWeight: isToday || completed
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _WeekConsistency extends StatelessWidget {
  const _WeekConsistency({required this.store, required this.start});
  final DailyJourneyStore store;
  final DateTime start;
  @override
  Widget build(BuildContext context) {
    const labels = ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];
    final colors = context.appColors;
    return Row(
      children: List.generate(7, (index) {
        final date = start.add(Duration(days: index));
        final completed = store.recordFor(date)?.completed ?? false;
        final today = date == calendarDate(DateTime.now());
        final future = date.isAfter(calendarDate(DateTime.now()));
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
                      : future
                      ? Colors.transparent
                      : colors.divider.withValues(alpha: .18),
                  border: today ? Border.all(color: colors.progress) : null,
                ),
                child: completed
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppPalette.dustGrey,
                        size: 17,
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
  final DailyJourneyStore store;
  final DateTime month;
  @override
  Widget build(BuildContext context) {
    final now = calendarDate(DateTime.now());
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

class _Milestones extends StatelessWidget {
  const _Milestones({required this.store});
  final DailyJourneyStore store;
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

class _DayDetails extends StatelessWidget {
  const _DayDetails({required this.date, required this.record});
  final DateTime date;
  final DailyHistoryRecord? record;
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
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
          Text(
            '${ArabicNumerals.integer(date.day)} ${_monthName(date.month)}',
            style: const TextStyle(
              fontFamily: 'ArefRuqaa',
              fontSize: 27,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (record == null)
            Text(
              'لا توجد لقطة محفوظة لهذا اليوم.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.secondaryText),
            )
          else
            ...record!.items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  item.completed
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: item.completed
                      ? colors.progress
                      : colors.textSecondary,
                ),
                title: Text(item.title),
                subtitle: Text(
                  item.completed
                      ? item.completionSource == 'manual'
                            ? 'مكتمل · تم تسجيله يدويًا'
                            : 'مكتمل'
                      : 'لم يكتمل',
                ),
              ),
            ),
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
