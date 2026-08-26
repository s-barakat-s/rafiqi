import 'package:flutter/material.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/core/time/hijri_date.dart';
import 'package:tasbeh/core/time/local_day.dart';
import 'package:tasbeh/features/calendar/presentation/screens/hijri_calendar_screen.dart';
import 'package:tasbeh/shared/widgets/calligraphy_title.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_progress_repository.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar_progress.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_local_repository.dart';
import 'package:tasbeh/features/daily_wird/data/repositories/daily_wird_repository.dart';
import 'package:tasbeh/features/daily_wird/domain/entities/daily_wird.dart';
import 'package:tasbeh/features/home/data/repositories/daily_dhikr_repository.dart';
import 'package:tasbeh/features/home/domain/adhkar_time_period.dart';

part '../../daily_wird/presentation/widgets/add_daily_task_sheet.dart';
part 'widgets/daily_wird_section.dart';
part 'widgets/dhikr_of_the_day.dart';
part 'widgets/home_hero.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.onOpenTasbeeh,
    required this.onOpenAdhkar,
    super.key,
  });
  final VoidCallback onOpenTasbeeh;
  final Future<void> Function(String categoryId) onOpenAdhkar;

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

  Future<void> _toggleTask(DailyTask task) async {
    if (_completedIds.contains(task.id)) {
      await _store.setCompleted(task.id, false);
      return;
    }
    if (task.isBase) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('هل أتممت هذا الورد خارج التطبيق؟'),
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
    final category = await showModalBottomSheet<AdhkarCategory>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ReadyTaskPickerSheet(categories: categories),
    );
    if (category == null || !mounted) return;
    if (_store.hasLinkedCollection(category.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا الورد مضاف بالفعل إلى وردك اليومي')),
      );
      return;
    }
    await _store.addTask(
      DailyTask(
        id: 'linked_adhkar_${category.id}',
        title: category.title,
        type: 'ذكر',
        taskType: DailyTask.adhkarCollectionTaskType,
        collectionId: category.id,
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final currentPeriod = AdhkarTimePeriod.now();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _openHijriCalendar,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hijriToday.formatFull(),
                          style: text.bodyMedium?.copyWith(
                            color: colors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          HijriDate.formatGregorianDayMonth(_today),
                          style: text.labelLarge?.copyWith(
                            color: colors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colors.outline.withValues(alpha: .8),
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_outlined,
                      size: 18,
                      color: colors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${ArabicNumerals.integer(_store.currentStreak)} يومًا',
                      style: text.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Transform.translate(
              offset: const Offset(30, 0),
              child: SizedBox(
                width: 260,
                child: Column(
                  children: [
                    const CalligraphyTitle(
                      asset: 'assets/calligraphy/salam_alaykum.png',
                      semanticLabel: 'السلام عليكم',
                      height: 76,
                      alignment: Alignment.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'جعل الله يومك عامرًا بذكره',
                      textAlign: TextAlign.center,
                      style: text.titleMedium?.copyWith(
                        color: colors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _MorningHero(
            categoryId: currentPeriod.categoryId,
            complete: _completedIds.contains(currentPeriod.dailyTaskId),
            progress: _adhkarProgress[currentPeriod.categoryId],
            onOpen: _openHeroAdhkar,
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              const Expanded(child: _SectionTitle('وردك اليوم')),
              IconButton.filledTonal(
                onPressed: _showAddTaskSheet,
                tooltip: 'إضافة عمل يومي',
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          Text(
            _readyForStreak
                ? 'أتممت أعمال اليوم، بارك الله في مداومتك'
                : 'تُحتسب جاهزية يومك بإتمام كل الأعمال أدناه',
            style: text.bodySmall?.copyWith(
              color: _readyForStreak ? colors.progress : colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ..._tasks.map(
            (task) => _DailyTaskRow(
              task: task,
              complete: _completedIds.contains(task.id),
              progress: _taskProgress(task),
              onTap: () => _toggleTask(task),
            ),
          ),
          const SizedBox(height: 28),
          const _SectionTitle('ذكر اليوم'),
          const SizedBox(height: 14),
          const _DhikrOfTheDay(),
        ],
      ),
    );
  }

  AdhkarProgressSummary? _taskProgress(DailyTask task) {
    return switch (task.id) {
      'morning_adhkar' => _adhkarProgress['morning'],
      'evening_adhkar' => _adhkarProgress['evening'],
      _ => null,
    };
  }
}
