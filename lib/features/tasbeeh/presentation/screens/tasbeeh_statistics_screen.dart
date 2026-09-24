import 'package:flutter/material.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/core/time/local_day.dart';
import 'package:tasbeh/features/daily_wird/data/repositories/daily_wird_repository.dart';
import 'package:tasbeh/features/tasbeeh/data/repositories/tasbeeh_repository.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_daily_record.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/manual_tasbeeh_entry.dart';

enum _StatsPeriod { today, week, lastSevenDays, month }

class TasbeehStatisticsScreen extends StatefulWidget {
  const TasbeehStatisticsScreen({super.key});

  @override
  State<TasbeehStatisticsScreen> createState() =>
      _TasbeehStatisticsScreenState();
}

class _TasbeehStatisticsScreenState extends State<TasbeehStatisticsScreen> {
  final _repository = TasbeehRepository();
  final _dailyWird = DailyWirdRepository.instance;
  _StatsPeriod _period = _StatsPeriod.today;
  List<TasbeehDailyRecord> _records = const [];
  List<ManualTasbeehEntry> _manualEntries = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _dailyWird.initialize();
    final results = await Future.wait<Object>([
      _repository.loadDailyRecords(),
      _repository.loadManualEntries(),
    ]);
    if (!mounted) return;
    setState(() {
      _records = results[0] as List<TasbeehDailyRecord>;
      _manualEntries = results[1] as List<ManualTasbeehEntry>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ranges = _rangesFor(_period);
    final current = _summary(ranges.$1, ranges.$2);
    final previous = _summary(ranges.$3, ranges.$4);
    final difference = current.total - previous.total;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('إحصائيات التسبيح')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _periodChip(_StatsPeriod.today, 'اليوم'),
                      _periodChip(_StatsPeriod.week, 'هذا الأسبوع'),
                      _periodChip(_StatsPeriod.lastSevenDays, 'آخر ٧ أيام'),
                      _periodChip(_StatsPeriod.month, 'هذا الشهر'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colors.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('إجمالي التسبيح', style: TextStyle(color: colors.textSecondary)),
                        const SizedBox(height: 8),
                        Text(
                          '${ArabicNumerals.integer(current.total)} مرة',
                          style: TextStyle(
                            fontFamily: AppFonts.display,
                            color: colors.textPrimary,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _comparisonText(
                            current: current.total,
                            previous: previous.total,
                            difference: difference,
                          ),
                          style: TextStyle(color: colors.textSecondary, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (current.items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Text(
                        'لا يوجد تسبيح مسجل في هذه الفترة',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    )
                  else
                    ...current.items.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.text,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              ArabicNumerals.integer(item.count),
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _periodChip(_StatsPeriod period, String label) => ChoiceChip(
    label: Text(label),
    selected: _period == period,
    onSelected: (_) => setState(() => _period = period),
  );

  (DateTime, DateTime, DateTime, DateTime) _rangesFor(_StatsPeriod period) {
    final today = LocalDay.date(DateTime.now());
    switch (period) {
      case _StatsPeriod.today:
        final previous = today.subtract(const Duration(days: 1));
        return (today, today, previous, previous);
      case _StatsPeriod.week:
        final start = today.subtract(Duration(days: today.weekday - 1));
        final previousStart = start.subtract(const Duration(days: 7));
        final elapsed = today.difference(start).inDays;
        return (
          start,
          today,
          previousStart,
          previousStart.add(Duration(days: elapsed)),
        );
      case _StatsPeriod.lastSevenDays:
        final start = today.subtract(const Duration(days: 6));
        return (
          start,
          today,
          start.subtract(const Duration(days: 7)),
          start.subtract(const Duration(days: 1)),
        );
      case _StatsPeriod.month:
        final start = DateTime(today.year, today.month);
        final previousStart = DateTime(today.year, today.month - 1);
        final previousMonthEnd = start.subtract(const Duration(days: 1));
        final candidateEnd = previousStart.add(
          Duration(days: today.difference(start).inDays),
        );
        return (
          start,
          today,
          previousStart,
          candidateEnd.isAfter(previousMonthEnd) ? previousMonthEnd : candidateEnd,
        );
    }
  }

  _StatsSummary _summary(DateTime start, DateTime end) {
    final counts = <String, int>{};
    final texts = <String, String>{};
    for (final record in _records) {
      final day = LocalDay.parse(record.dayKey);
      if (day.isBefore(start) || day.isAfter(end)) continue;
      final key = '${record.dhikrId}\u0000${record.dhikrTextSnapshot}';
      counts[key] = (counts[key] ?? 0) + record.inAppCount;
      texts[key] = record.dhikrTextSnapshot;
    }
    for (final entry in _manualEntries) {
      final day = LocalDay.parse(entry.dayKey);
      if (day.isBefore(start) || day.isAfter(end)) continue;
      final key = '${entry.dhikrId}\u0000${entry.dhikrTextSnapshot}';
      counts[key] = (counts[key] ?? 0) + entry.count;
      texts[key] = entry.dhikrTextSnapshot;
    }
    for (final record in _dailyWird.history.values) {
      final day = LocalDay.parse(record.dateKey);
      if (day.isBefore(start) || day.isAfter(end)) continue;
      for (final item in record.items) {
        final id = item.tasbeehPhraseId;
        if (id == null || item.externalContribution <= 0) continue;
        final text = item.tasbeehPhraseText ?? item.title;
        final key = '$id\u0000$text';
        counts[key] = (counts[key] ?? 0) + item.externalContribution;
        texts[key] = text;
      }
    }
    final items = counts.entries
        .map((entry) => _StatsItem(texts[entry.key] ?? entry.key, entry.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return _StatsSummary(items.fold(0, (sum, item) => sum + item.count), items);
  }

  String _comparisonText({
    required int current,
    required int previous,
    required int difference,
  }) {
    if (current == 0 && previous == 0) return 'لا يوجد تغير عن الفترة السابقة';
    if (difference == 0) return 'مماثل للفترة السابقة';
    final direction = difference > 0 ? 'أكثر' : 'أقل';
    final absolute = difference.abs();
    if (previous == 0) {
      return '$direction من الفترة السابقة بـ ${ArabicNumerals.integer(absolute)}';
    }
    final percentage = (difference / previous) * 100;
    final sign = percentage > 0 ? '+' : '−';
    final absolutePercentage = percentage.abs();
    final rawPercentage = absolutePercentage == absolutePercentage.roundToDouble()
        ? absolutePercentage.round().toString()
        : absolutePercentage.toStringAsFixed(1).replaceAll('.', '٫');
    final formattedPercentage = ArabicNumerals.digits(rawPercentage);
    return '$direction من الفترة السابقة بـ ${ArabicNumerals.integer(absolute)}  $sign$formattedPercentage٪';
  }
}

class _StatsItem {
  const _StatsItem(this.text, this.count);
  final String text;
  final int count;
}

class _StatsSummary {
  const _StatsSummary(this.total, this.items);
  final int total;
  final List<_StatsItem> items;
}
