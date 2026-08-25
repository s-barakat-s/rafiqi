import 'package:flutter/material.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/core/time/local_day.dart';
import 'package:tasbeh/features/daily_wird/data/repositories/daily_wird_repository.dart';
import 'package:tasbeh/features/daily_wird/domain/entities/daily_wird.dart';

part '../widgets/journey_hero.dart';
part '../widgets/journey_summaries.dart';
part '../widgets/milestones_and_day_details.dart';
part '../widgets/monthly_calendar.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen>
    with WidgetsBindingObserver {
  final _store = DailyWirdRepository.instance;

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
    final now = LocalDay.date(DateTime.now());
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
              fontFamily: AppFonts.display,
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
    if (date.isAfter(LocalDay.date(DateTime.now()))) return;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => _DayDetails(date: date, store: _store),
    );
  }
}
