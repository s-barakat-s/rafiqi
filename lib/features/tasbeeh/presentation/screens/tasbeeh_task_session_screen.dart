import 'package:flutter/material.dart';
import 'package:tasbeh/features/daily_wird/data/repositories/daily_wird_repository.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_app_scope.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_phrase.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_task_context.dart';
import 'package:tasbeh/features/tasbeeh/presentation/screens/tasbeeh_home_screen.dart';
import 'package:tasbeh/features/tasbeeh/presentation/screens/tasbeeh_statistics_screen.dart';

/// A linked Daily Wird task session.
///
/// Phase 2A: this route no longer creates its own [TasbeehController].
/// It observes the application-scoped authority via a session adapter
/// ([TasbeehSessionScope]), so ordinary Tasbeeh and task sessions can never
/// save conflicting snapshots, and opening/closing the task neither replaces
/// nor removes the main-app named port.
class TasbeehTaskSessionScreen extends StatefulWidget {
  const TasbeehTaskSessionScreen({required this.taskContext, super.key});

  final TasbeehTaskContext taskContext;

  @override
  State<TasbeehTaskSessionScreen> createState() =>
      _TasbeehTaskSessionScreenState();
}

class _TasbeehTaskSessionScreenState extends State<TasbeehTaskSessionScreen> {
  final _store = DailyWirdRepository.instance;
  /// Session-local adapter over the shared authority; disposed with the
  /// route. The underlying controller is NOT disposed here.
  late final TasbeehSessionScope _scope =
      TasbeehSessionScope.inheritAppScope();
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
    _scope.addListener(_onChanged);
    _initialize();
  }

  Future<void> _initialize() async {
    // Idempotent: no port re-registration, no stale full reload.
    await TasbeehAppScope.ensureInitialized();
    await _scope.selectDhikr(
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
    final completedTask = await _scope.increment();
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
    _scope.removeListener(_onChanged);
    // Only the adapter is disposed; the shared authority (and its port)
    // remains alive for the rest of the app.
    _scope.dispose();
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
      state: _scope.state,
      taskContext: widget.taskContext,
      taskProgress: _progress,
      onIncrement: _increment,
      onResetSession: _scope.resetSession,
      onDecrement: _scope.decrement,
      onOpenSettings: () {},
      phrases: _scope.phrases,
      onSelectDhikr: _scope.selectDhikr,
      onAddCustomPhrase: (text) async {
        await _scope.addCustomPhrase(text);
      },
      onOpenStatistics: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const TasbeehStatisticsScreen()),
        );
      },
      onOpenManualLog: () {},
      focusController: _scope.controller,
      hapticEnabled: _scope.controller.settings.hapticFeedbackEnabled,
      onHapticChanged: (enabled) async {
        await _scope.controller.replaceSettings(
          _scope.controller.settings.copyWith(hapticFeedbackEnabled: enabled),
        );
      },
      onBack: () => Navigator.pop(context),
    );
  }
}
