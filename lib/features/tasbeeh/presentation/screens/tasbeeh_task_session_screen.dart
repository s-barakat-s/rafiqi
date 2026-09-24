import 'package:flutter/material.dart';
import 'package:tasbeh/features/daily_wird/data/repositories/daily_wird_repository.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_controller.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_phrase.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_task_context.dart';
import 'package:tasbeh/features/tasbeeh/presentation/screens/tasbeeh_home_screen.dart';
import 'package:tasbeh/features/tasbeeh/presentation/screens/tasbeeh_statistics_screen.dart';

class TasbeehTaskSessionScreen extends StatefulWidget {
  const TasbeehTaskSessionScreen({required this.taskContext, super.key});

  final TasbeehTaskContext taskContext;

  @override
  State<TasbeehTaskSessionScreen> createState() =>
      _TasbeehTaskSessionScreenState();
}

class _TasbeehTaskSessionScreenState extends State<TasbeehTaskSessionScreen> {
  final _store = DailyWirdRepository.instance;
  final _tasbeeh = TasbeehController();
  bool _ready = false;

  int get _progress {
    final item = _store.todayRecord.items
        .where((item) => item.id == widget.taskContext.taskId)
        .firstOrNull;
    return item?.progress ?? widget.taskContext.initialProgress;
  }

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChanged);
    _tasbeeh.addListener(_onChanged);
    _initialize();
  }

  Future<void> _initialize() async {
    await _tasbeeh.initialize();
    await _tasbeeh.selectDhikr(
      TasbeehPhrase(
        id: widget.taskContext.phraseId,
        text: widget.taskContext.phraseText,
        isBuiltIn: TasbeehPhrase.defaultPhrases.any(
          (phrase) => phrase.id == widget.taskContext.phraseId,
        ),
      ),
    );
    if (mounted) setState(() => _ready = true);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _increment() async {
    final completedTask = await _tasbeeh.increment();
    if (!mounted || !completedTask) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('أحسنت، أكملت المهمة'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  void dispose() {
    _store.removeListener(_onChanged);
    _tasbeeh.removeListener(_onChanged);
    _tasbeeh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return TasbeehHomeScreen(
      state: _tasbeeh.state,
      taskContext: widget.taskContext,
      taskProgress: _progress,
      onIncrement: _increment,
      onResetSession: _tasbeeh.resetSession,
      onDecrement: _tasbeeh.decrement,
      onOpenSettings: () {},
      phrases: _tasbeeh.phrases,
      onSelectDhikr: _tasbeeh.selectDhikr,
      onAddCustomPhrase: (text) async {
        await _tasbeeh.addCustomPhrase(text);
      },
      onOpenStatistics: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const TasbeehStatisticsScreen()),
        );
      },
      onOpenManualLog: () {},
      focusController: _tasbeeh,
      hapticEnabled: _tasbeeh.settings.hapticFeedbackEnabled,
      onHapticChanged: (enabled) async {
        await _tasbeeh.replaceSettings(
          _tasbeeh.settings.copyWith(hapticFeedbackEnabled: enabled),
        );
      },
      onBack: () => Navigator.pop(context),
    );
  }
}
