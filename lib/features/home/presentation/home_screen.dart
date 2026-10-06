import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tasbeh/core/assets/rafiqi_icons.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/core/time/local_day.dart';
import 'package:tasbeh/features/calendar/presentation/screens/hijri_calendar_screen.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_progress_repository.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_collection_overrides_repository.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar_progress.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_local_repository.dart';
import 'package:tasbeh/features/daily_wird/data/repositories/daily_wird_repository.dart';
import 'package:tasbeh/features/daily_wird/domain/entities/daily_wird.dart';
import 'package:tasbeh/features/home/data/repositories/daily_dhikr_repository.dart';
import 'package:tasbeh/features/home/data/home_prayer_mock_data.dart';
import 'package:tasbeh/features/home/domain/adhkar_time_period.dart';
import 'dart:async';

import 'package:tasbeh/features/home/domain/quran_reading.dart';
import 'package:tasbeh/features/home/presentation/widgets/prayer_header/prayer_header_section.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_phrase.dart';
import 'package:tasbeh/features/tasbeeh/data/repositories/tasbeeh_repository.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_task_context.dart';
import 'package:tasbeh/features/tasbeeh/presentation/screens/tasbeeh_task_session_screen.dart';
import 'package:tasbeh/shared/widgets/app_glass_surface.dart';
import 'package:tasbeh/shared/widgets/app_theme_artwork.dart';
import 'package:tasbeh/shared/widgets/rafiqi_svg_icon.dart';

part '../../daily_wird/presentation/widgets/add_daily_task_sheet.dart';
part 'widgets/daily_wird_section.dart';
part 'widgets/dhikr_of_the_day.dart';
part 'widgets/home_hero.dart';
part 'widgets/home_quran_section.dart';
part 'widgets/home_quick_access.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.onOpenTasbeeh,
    required this.onOpenAdhkar,
    this.onOpenJourney,
    this.onOpenTasbeehStatistics,
    this.onOpenMore,
    this.onOpenPrayerTimes,
    super.key,
  });
  final VoidCallback onOpenTasbeeh;
  final Future<void> Function(String categoryId) onOpenAdhkar;
  final VoidCallback? onOpenJourney;
  final VoidCallback? onOpenTasbeehStatistics;
  final VoidCallback? onOpenMore;
  final VoidCallback? onOpenPrayerTimes;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _store = DailyWirdRepository.instance;
  final _progressRepository = AdhkarProgressRepository.instance;
  final _dailyDhikrRepository = DailyDhikrRepository.instance;
  Map<String, AdhkarProgressSummary> _adhkarProgress = const {};
  late final ValueListenable<int> _morningProgressChanges;
  late final ValueListenable<int> _eveningProgressChanges;
  late final ValueListenable<int> _morningDefinitionChanges;
  late final ValueListenable<int> _eveningDefinitionChanges;
  Timer? _timeBoundaryTimer;
  late DateTime _today;

  List<DailyTask> get _tasks => _store.tasks;
  Set<String> get _completedIds => _store.initialized
      ? _store.todayRecord.items
            .where((item) => item.completed)
            .map((item) => item.id)
            .toSet()
      : <String>{};
  bool get _readyForStreak => _store.initialized && _store.readyForStreak;

  @override
  void initState() {
    super.initState();
    _refreshDate();
    WidgetsBinding.instance.addObserver(this);
    _store.addListener(_onStoreChanged);
    _morningProgressChanges = _progressRepository.changesFor('morning')
      ..addListener(_onMorningProgressChanged);
    _eveningProgressChanges = _progressRepository.changesFor('evening')
      ..addListener(_onEveningProgressChanged);
    _morningDefinitionChanges =
        AdhkarCollectionOverridesRepository.instance.changesFor('morning')
          ..addListener(_onMorningProgressChanged);
    _eveningDefinitionChanges =
        AdhkarCollectionOverridesRepository.instance.changesFor('evening')
          ..addListener(_onEveningProgressChanged);
    _scheduleTimeBoundary();
    _loadHomeState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _store.removeListener(_onStoreChanged);
    _morningProgressChanges.removeListener(_onMorningProgressChanged);
    _eveningProgressChanges.removeListener(_onEveningProgressChanged);
    _morningDefinitionChanges.removeListener(_onMorningProgressChanged);
    _eveningDefinitionChanges.removeListener(_onEveningProgressChanged);
    _timeBoundaryTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshDate();
      _scheduleTimeBoundary();
      _loadHomeState();
    }
  }

  void _refreshDate() {
    _today = LocalDay.date(DateTime.now());
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  void _onMorningProgressChanged() => _loadAdhkarProgressFor('morning');

  void _onEveningProgressChanged() => _loadAdhkarProgressFor('evening');

  void _scheduleTimeBoundary() {
    _timeBoundaryTimer?.cancel();
    final now = DateTime.now();
    final boundary = AdhkarTimePeriod.nextBoundaryAfter(now);
    _timeBoundaryTimer = Timer(
      boundary.difference(now) + const Duration(milliseconds: 10),
      _handleTimeBoundary,
    );
  }

  void _handleTimeBoundary() {
    if (!mounted) return;
    _refreshDate();
    setState(() {});
    _loadAdhkarProgress();
    _scheduleTimeBoundary();
  }

  Future<void> _loadHomeState() async {
    await Future.wait([
      _store.initialize(),
      _dailyDhikrRepository.initialize(),
    ]);
    await _loadAdhkarProgress();
  }

  Future<void> _loadAdhkarProgress() async {
    final summaries = await Future.wait([
      _loadSummaryFor('morning'),
      _loadSummaryFor('evening'),
    ]);
    final byCategory = {
      for (final summary in summaries.whereType<AdhkarProgressSummary>())
        summary.categoryId: summary,
    };
    if (!mounted || _mapsEqual(_adhkarProgress, byCategory)) return;
    setState(() {
      _adhkarProgress = byCategory;
    });
  }

  Future<void> _loadAdhkarProgressFor(String categoryId) async {
    final summary = await _loadSummaryFor(categoryId);
    if (!mounted || summary == null || _adhkarProgress[categoryId] == summary) {
      return;
    }
    setState(() {
      _adhkarProgress = {..._adhkarProgress, categoryId: summary};
    });
  }

  Future<AdhkarProgressSummary?> _loadSummaryFor(String categoryId) async {
    final category = await AdhkarLocalRepository.loadResolvedCategory(
      categoryId,
    );
    return category == null ? null : _progressRepository.loadSummary(category);
  }

  bool _mapsEqual(
    Map<String, AdhkarProgressSummary> left,
    Map<String, AdhkarProgressSummary> right,
  ) =>
      left.length == right.length &&
      left.entries.every((entry) => right[entry.key] == entry.value);

  Future<void> _openHeroAdhkar(String categoryId) async {
    await widget.onOpenAdhkar(categoryId);
    if (mounted) setState(() {});
  }

  Future<void> _openTasbeehTask(DailyTask task) async {
    final todayItem = _store.todayRecord.items
        .where((item) => item.id == task.id)
        .firstOrNull;
    final context = TasbeehTaskContext(
      taskId: task.id,
      phraseId: task.tasbeehPhraseId ?? 'subhan_allah',
      phraseText: task.tasbeehPhraseText ?? task.title,
      targetCount: task.tasbeehTargetCount ?? task.goal ?? 33,
      initialProgress: todayItem?.progress ?? 0,
    );
    await Navigator.of(this.context).push<void>(
      MaterialPageRoute(
        builder: (_) => TasbeehTaskSessionScreen(taskContext: context),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _onTaskTap(DailyTask task) async {
    if (task.taskType == DailyTask.adhkarCollectionTaskType &&
        task.collectionId != null) {
      await _openHeroAdhkar(task.collectionId!);
      return;
    }
    if (task.taskType == DailyTask.tasbeehTargetTaskType) {
      await _openTasbeehTask(task);
      return;
    }
    await _toggleTask(task);
  }

  Future<void> _toggleTask(DailyTask task) async {
    if (_completedIds.contains(task.id)) {
      await _store.setCompleted(task.id, false);
      return;
    }
    if (task.isBase || task.taskType == DailyTask.tasbeehTargetTaskType) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            task.taskType == DailyTask.tasbeehTargetTaskType
                ? 'هل أتممت هذه المهمة خارج maab؟'
                : 'هل أتممت هذا الورد خارج التطبيق؟',
          ),
          content: const Text(
            'إذا كنت قد أتممته خارج التطبيق، يمكنك تسجيله منجزًا لليوم.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('لا، سأكمله هنا'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('نعم، تم'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    await _store.setCompleted(task.id, true, source: 'manual');
  }

  Future<void> _showAddTaskSheet() async {
    final choice = await showModalBottomSheet<_DailyTaskAddChoice>(
      context: context,
      useSafeArea: true,
      builder: (_) => const _AddTaskChoiceSheet(),
    );
    if (choice == null || !mounted) return;
    if (choice == _DailyTaskAddChoice.readyMade) {
      await _showReadyTaskPicker();
      return;
    }
    final task = await showModalBottomSheet<DailyTask>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AddTaskSheet(),
    );
    if (task == null || !mounted) return;
    await _store.addTask(task);
  }

  Future<void> _showReadyTaskPicker() async {
    final categories = await AdhkarLocalRepository.loadCategories();
    if (!mounted) return;
    final task = await showModalBottomSheet<DailyTask>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ReadyTaskPickerSheet(categories: categories),
    );
    if (task == null || !mounted) return;
    if (task.taskType == DailyTask.adhkarCollectionTaskType &&
        task.collectionId != null &&
        _store.hasLinkedCollection(task.collectionId!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا الورد مضاف بالفعل إلى وردك اليومي')),
      );
      return;
    }
    if (task.taskType == DailyTask.tasbeehTargetTaskType &&
        task.tasbeehPhraseId != null &&
        task.tasbeehTargetCount != null &&
        _store.hasLinkedTasbeehTask(
          task.tasbeehPhraseId!,
          task.tasbeehTargetCount!,
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا العمل مضاف بالفعل إلى وردك اليومي')),
      );
      return;
    }
    await _store.addTask(task);
  }

  Future<void> _openHijriCalendar() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const HijriCalendarScreen()),
    );
    if (mounted) {
      setState(() {
        _refreshDate();
      });
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text('قريبًا في maab'),
          action: SnackBarAction(label: 'حسنًا', onPressed: () {}),
        ),
      );
  }

  Future<void> _openQuranPosition(QuranReadingPosition position) async {
    // Placeholder until Quran navigation exists; keeps the UI isolated.
    _showComingSoon();
  }

  @override
  Widget build(BuildContext context) {
    final currentPeriod = AdhkarTimePeriod.now();
    final completedCount = _completedIds.length.clamp(0, _tasks.length);
    final overallProgress = _tasks.isEmpty
        ? 0.0
        : completedCount / _tasks.length;
    final weekStart = _today.subtract(Duration(days: _today.weekday - 1));
    final weekCompleted = _store.initialized
        ? _store.completedBetween(
            weekStart,
            weekStart.add(const Duration(days: 6)),
          )
        : 0;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          PrayerHeaderSection(
            data: HomePrayerMockData.header,
            onSettingsTap: widget.onOpenMore ?? _showComingSoon,
            onPrayerTimesTap: widget.onOpenPrayerTimes ?? _showComingSoon,
            onQiblaTap: _showComingSoon,
          ),
          const SizedBox(height: 18),
          _ContinueQuranCard(
            onContinue: _openQuranPosition,
            onStart: _showComingSoon,
          ),
          const SizedBox(height: 20),
          _MorningHero(
            categoryId: currentPeriod.categoryId,
            complete: _completedIds.contains(currentPeriod.dailyTaskId),
            progress: _adhkarProgress[currentPeriod.categoryId],
            onOpen: _openHeroAdhkar,
          ),
          const SizedBox(height: 20),
          _DailyWirdCard(
            tasks: _tasks,
            completedIds: _completedIds,
            progress: overallProgress,
            readyForStreak: _readyForStreak,
            progressFor: _taskProgress,
            tasbeehProgressFor: _taskTasbeehProgress,
            onTapTask: _onTaskTap,
            onToggleCheckbox: _toggleTask,
            onAdd: _showAddTaskSheet,
          ),
          const SizedBox(height: 20),
          const _DhikrOfTheDay(),
          const SizedBox(height: 16),
          _QuickAccessSection(
            onOpenTasbeeh: widget.onOpenTasbeeh,
            onOpenJourney: widget.onOpenJourney ?? () {},
            onOpenCalendar: _openHijriCalendar,
            onOpenStatistics: widget.onOpenTasbeehStatistics,
            onOpenSettings: widget.onOpenMore,
            onComingSoon: _showComingSoon,
          ),
          const SizedBox(height: 20),
          _JourneyStrip(
            streak: _store.currentStreak,
            weekCompleted: weekCompleted,
            onTap: widget.onOpenJourney ?? () {},
          ),
        ],
      ),
    );
  }

  AdhkarProgressSummary? _taskProgress(DailyTask task) {
    if (task.taskType == DailyTask.adhkarCollectionTaskType &&
        task.collectionId != null) {
      return _adhkarProgress[task.collectionId!];
    }
    return switch (task.id) {
      'morning_adhkar' => _adhkarProgress['morning'],
      'evening_adhkar' => _adhkarProgress['evening'],
      _ => null,
    };
  }

  int? _taskTasbeehProgress(DailyTask task) {
    if (task.taskType != DailyTask.tasbeehTargetTaskType) return null;
    final item = _store.todayRecord.items
        .where((entry) => entry.id == task.id)
        .firstOrNull;
    return item?.progress ?? 0;
  }
}
