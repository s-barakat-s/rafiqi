import 'package:flutter/material.dart';
import 'package:tasbeh/core/assets/rafiqi_icons.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/core/time/hijri_date.dart';
import 'package:tasbeh/core/time/local_day.dart';
import 'package:tasbeh/features/calendar/presentation/screens/hijri_calendar_screen.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_progress_repository.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar_progress.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_local_repository.dart';
import 'package:tasbeh/features/daily_wird/data/repositories/daily_wird_repository.dart';
import 'package:tasbeh/features/daily_wird/domain/entities/daily_wird.dart';
import 'package:tasbeh/features/home/data/repositories/daily_dhikr_repository.dart';
import 'package:tasbeh/features/home/domain/adhkar_time_period.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_phrase.dart';
import 'package:tasbeh/features/tasbeeh/data/repositories/tasbeeh_repository.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_task_context.dart';
import 'package:tasbeh/features/tasbeeh/presentation/screens/tasbeeh_task_session_screen.dart';
import 'package:tasbeh/shared/widgets/app_glass_surface.dart';
import 'package:tasbeh/shared/widgets/rafiqi_svg_icon.dart';

part '../../daily_wird/presentation/widgets/add_daily_task_sheet.dart';
part 'widgets/daily_wird_section.dart';
part 'widgets/dhikr_of_the_day.dart';
part 'widgets/home_hero.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.onOpenTasbeeh,
    required this.onOpenAdhkar,
    this.onOpenJourney,
    super.key,
  });
  final VoidCallback onOpenTasbeeh;
  final Future<void> Function(String categoryId) onOpenAdhkar;
  final VoidCallback? onOpenJourney;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _store = DailyWirdRepository.instance;
  final _progressRepository = AdhkarProgressRepository.instance;
  final _dailyDhikrRepository = DailyDhikrRepository.instance;
  Map<String, AdhkarProgressSummary> _adhkarProgress = const {};
  late DateTime _today;
  late HijriDate _hijriToday;

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
    _progressRepository.addListener(_onProgressChanged);
    _loadHomeState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _store.removeListener(_onStoreChanged);
    _progressRepository.removeListener(_onProgressChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshDate();
      _loadHomeState();
    }
  }

  void _refreshDate() {
    _today = LocalDay.date(DateTime.now());
    _hijriToday = HijriDate.fromGregorian(_today);
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  void _onProgressChanged() => _loadAdhkarProgress();

  Future<void> _loadHomeState() async {
    await Future.wait([
      _store.initialize(),
      _dailyDhikrRepository.initialize(),
    ]);
    await _loadAdhkarProgress();
  }

  Future<void> _loadAdhkarProgress() async {
    if (!_store.initialized) await _store.initialize();
    final categories = await AdhkarLocalRepository.loadCategories();
    final requiredCategories = categories.where(
      (category) => category.id == 'morning' || category.id == 'evening',
    );
    final summaries = await Future.wait(
      requiredCategories.map(_progressRepository.loadSummary),
    );
    final byCategory = {
      for (final summary in summaries) summary.categoryId: summary,
    };
    if (!mounted) return;
    setState(() {
      _adhkarProgress = byCategory;
    });
  }

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
                ? 'هل أتممت هذه المهمة خارج رفيقي؟'
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
          content: const Text('قريبًا في رفيقي'),
          action: SnackBarAction(label: 'حسنًا', onPressed: () {}),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final currentPeriod = AdhkarTimePeriod.now();
    final completedCount = _completedIds.length.clamp(0, _tasks.length);
    final overallProgress = _tasks.isEmpty ? 0.0 : completedCount / _tasks.length;
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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
        children: [
          _HomeHeader(
            hijriDate: _hijriToday.formatFull(),
            gregorianDate: HijriDate.formatGregorianFull(_today),
            streak: _store.currentStreak,
            onDateTap: _openHijriCalendar,
          ),
          const SizedBox(height: 18),
          _MorningHero(
            categoryId: currentPeriod.categoryId,
            complete: _completedIds.contains(currentPeriod.dailyTaskId),
            progress: _adhkarProgress[currentPeriod.categoryId],
            onOpen: _openHeroAdhkar,
          ),
          const SizedBox(height: 18),
          _QuickActions(
            onOpenAdhkar: () => widget.onOpenAdhkar(currentPeriod.categoryId),
            onOpenTasbeeh: widget.onOpenTasbeeh,
            onOpenJourney: widget.onOpenJourney ?? () {},
            onComingSoon: _showComingSoon,
          ),
          const SizedBox(height: 18),
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
          const SizedBox(height: 18),
          const _DhikrOfTheDay(),
          const SizedBox(height: 18),
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
