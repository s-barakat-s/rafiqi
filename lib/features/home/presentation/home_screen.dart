import 'package:flutter/material.dart';
import 'package:tasbeh/app/formatters/arabic_numerals.dart';
import 'package:tasbeh/app/theme/app_theme.dart';
import 'package:tasbeh/app/widgets/calligraphy_title.dart';
import 'package:tasbeh/features/adhkar/data/adhkar_progress_repository.dart';
import 'package:tasbeh/features/adhkar/domain/adhkar_data.dart';
import 'package:tasbeh/features/home/data/daily_journey_store.dart';
import 'package:tasbeh/features/home/domain/adhkar_time_period.dart';

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
  final _store = DailyJourneyStore.instance;
  final _progressRepository = AdhkarProgressRepository.instance;
  Map<String, AdhkarProgressSummary> _adhkarProgress = const {};

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
    if (state == AppLifecycleState.resumed) _loadHomeState();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  void _onProgressChanged() => _loadAdhkarProgress();

  Future<void> _loadHomeState() async {
    await _store.initialize();
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
    await _store.synchronizeAdhkarCompletion(
      morningCompletedInReader:
          byCategory['morning']?.isCompleted ?? false,
      eveningCompletedInReader:
          byCategory['evening']?.isCompleted ?? false,
    );
    if (!mounted) return;
    setState(() {
      _adhkarProgress = byCategory;
    });
  }

  bool _completedInReader(DailyTask task) {
    final categoryId = switch (task.id) {
      'morning_adhkar' => 'morning',
      'evening_adhkar' => 'evening',
      _ => null,
    };
    return categoryId != null &&
        (_adhkarProgress[categoryId]?.isCompleted ?? false);
  }

  Future<void> _openHeroAdhkar(String categoryId) async {
    await widget.onOpenAdhkar(categoryId);
    if (mounted) setState(() {});
  }

  Future<void> _toggleTask(DailyTask task) async {
    if (_completedInReader(task)) return;
    if (task.isBase && _completedIds.contains(task.id)) return;
    if (_completedIds.contains(task.id)) {
      await _store.setCompleted(task.id, false);
      return;
    }
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
    await _store.setCompleted(task.id, true, source: 'manual');
  }

  Future<void> _showAddTaskSheet() async {
    final task = await showModalBottomSheet<DailyTask>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AddTaskSheet(),
    );
    if (task == null || !mounted) return;
    await _store.addTask(task);
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '١٧ صفر ١٤٤٨ هـ',
                      style: text.bodyMedium?.copyWith(
                        color: colors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'السبت، ٢٢ أغسطس',
                      style: text.labelLarge?.copyWith(
                        color: colors.secondaryText,
                      ),
                    ),
                  ],
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

class _MorningHero extends StatelessWidget {
  const _MorningHero({
    required this.categoryId,
    required this.complete,
    required this.progress,
    required this.onOpen,
  });

  final String categoryId;
  final bool complete;
  final AdhkarProgressSummary? progress;
  final Future<void> Function(String categoryId) onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final backgroundAsset = isDark
        ? 'assets/image/ChatGPT Image Aug 22, 2026, 09_26_58 PM.png'
        : 'assets/image/ChatGPT Image Aug 22, 2026, 09_16_46 PM.png';
    final periodTitle = categoryId == 'morning'
        ? 'أذكار الصباح'
        : 'أذكار المساء';
    final title = complete ? 'أتممت $periodTitle' : periodTitle;
    final subtitle = complete
        ? 'تقبّل الله منك وبارك في ذكرك'
        : categoryId == 'morning'
        ? 'بداية مطمئنة ليومك'
        : 'سكينة المساء وخاتمة هادئة ليومك';
    final completedSteps = progress?.completedSteps ?? 0;
    final totalSteps = progress?.totalSteps ?? 0;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outline.withValues(alpha: .7)),
        image: DecorationImage(
          image: AssetImage(backgroundAsset),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            isDark
                ? colors.background.withValues(alpha: .42)
                : AppPalette.hunterGreen.withValues(alpha: .28),
            BlendMode.srcOver,
          ),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'ArefRuqaa',
                  color: AppPalette.dustGrey,
                  fontSize: 29,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: text.bodyLarge?.copyWith(color: AppPalette.dustGrey),
              ),
              if (complete) ...[
                const SizedBox(height: 24),
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppPalette.dustGrey,
                  size: 34,
                ),
              ] else ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: totalSteps == 0
                              ? 0
                              : completedSteps / totalSteps,
                          minHeight: 7,
                          backgroundColor: AppPalette.dustGrey.withValues(
                            alpha: .2,
                          ),
                          color: colors.progress,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${ArabicNumerals.integer(completedSteps)} من ${ArabicNumerals.integer(totalSteps)}',
                      style: text.labelLarge?.copyWith(
                        color: AppPalette.dustGrey,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => onOpen(categoryId),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        progress?.hasProgress ?? false
                            ? 'متابعة الورد'
                            : 'ابدأ الورد',
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_back_rounded, size: 19),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontFamily: 'ArefRuqaa',
      fontSize: 25,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _DailyTaskRow extends StatelessWidget {
  const _DailyTaskRow({
    required this.task,
    required this.complete,
    required this.progress,
    required this.onTap,
  });
  final DailyTask task;
  final bool complete;
  final AdhkarProgressSummary? progress;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: complete
                        ? colors.selected
                        : colors.primary.withValues(alpha: .1),
                    border: Border.all(
                      color: complete ? colors.progress : colors.outline,
                    ),
                  ),
                  child: Icon(
                    complete ? Icons.check_rounded : Icons.circle_outlined,
                    size: 19,
                    color: complete ? colors.textPrimary : colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: complete
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        !complete && (progress?.hasProgress ?? false)
                            ? '${ArabicNumerals.integer(progress!.completedSteps)} من ${ArabicNumerals.integer(progress!.totalSteps)}'
                            : task.goal == null
                            ? task.type
                            : '${task.type} · الهدف ${ArabicNumerals.integer(task.goal!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (task.isBase)
                  Icon(
                    Icons.auto_stories_outlined,
                    size: 19,
                    color: colors.secondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet();
  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleController = TextEditingController();
  final _goalController = TextEditingController();
  String _type = 'ذكر';
  @override
  void dispose() {
    _titleController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    Navigator.pop(
      context,
      DailyTask(
        id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        type: _type,
        goal: int.tryParse(_goalController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
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
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'إضافة عمل يومي',
              style: TextStyle(
                fontFamily: 'ArefRuqaa',
                fontSize: 27,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.selected.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.spa_outlined, color: colors.secondary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'أحب الأعمال إلى الله أدومها وإن قل. اختر أعمالًا يسهل عليك المداومة عليها، ولا تكثر على نفسك حتى لا تنقطع.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'اسم العمل',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'النوع',
                border: OutlineInputBorder(),
              ),
              items:
                  const [
                        'ذكر',
                        'قرآن',
                        'صلاة على النبي',
                        'استغفار',
                        'دعاء',
                        'عمل مخصص',
                      ]
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _goalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'الهدف العددي (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('حفظ العمل'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DhikrOfTheDay extends StatelessWidget {
  const _DhikrOfTheDay();
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withValues(alpha: .65)),
      ),
      child: Column(
        children: [
          const Text(
            'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 23,
              height: 1.75,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'متفق عليه',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.secondaryText),
                ),
              ),
              IconButton(
                onPressed: () {},
                tooltip: 'استماع',
                icon: const Icon(Icons.volume_up_outlined),
              ),
              IconButton(
                onPressed: () {},
                tooltip: 'مشاركة',
                icon: const Icon(Icons.ios_share_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
