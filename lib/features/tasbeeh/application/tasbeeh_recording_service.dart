import 'package:tasbeh/features/daily_wird/data/repositories/daily_wird_repository.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_counter_logic.dart';
import 'package:tasbeh/features/tasbeeh/data/repositories/tasbeeh_repository.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_state.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_daily_record.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/manual_tasbeeh_entry.dart';

class TasbeehIncrementResult {
  const TasbeehIncrementResult({
    required this.state,
    required this.completedTask,
  });

  final TasbeehState state;
  final bool completedTask;
}

/// Coordinates compact Tasbeeh activity storage with Daily Wird progress.
class TasbeehRecordingService {
  TasbeehRecordingService({
    TasbeehRepository? repository,
    DailyWirdRepository? dailyWird,
  }) : _repository = repository ?? TasbeehRepository(),
       _dailyWird = dailyWird ?? DailyWirdRepository.instance;

  final TasbeehRepository _repository;
  final DailyWirdRepository _dailyWird;

  TasbeehState nextState(TasbeehState state) =>
      TasbeehCounterLogic.increment(state);

  Future<TasbeehIncrementResult> recordIncrement(
    TasbeehState next, {
    required TasbeehActivitySource source,
  }) async {
    await _repository.save(next);
    final daily = await _repository.recordIncrement(
      dhikrId: next.selectedDhikrId,
      dhikrText: next.selectedDhikrText,
      source: source,
    );
    // Reload before projecting so a concurrently running overlay cannot
    // overwrite a manual completion/uncheck made by the main app isolate.
    await _dailyWird.initialize();
    final eligibleTotal = daily.inAppCount + await _repository.manualCountForDay(
      daily.dayKey,
      next.selectedDhikrId,
    );
    final completedTask = await _dailyWird.syncTasbeehProgress(
      dhikrId: next.selectedDhikrId,
      currentEligibleTotal: eligibleTotal,
    );
    return TasbeehIncrementResult(
      state: next,
      completedTask: completedTask,
    );
  }

  Future<({ManualTasbeehEntry entry, bool completedTask})> addPhysicalManual({
    required String dhikrId,
    required String dhikrText,
    required int count,
  }) async {
    final entry = await _repository.addManualEntry(
      dhikrId: dhikrId,
      dhikrText: dhikrText,
      count: count,
    );
    final completed = await _reconcile(entry.dayKey, entry.dhikrId);
    return (entry: entry, completedTask: completed);
  }

  Future<bool> updatePhysicalManual(ManualTasbeehEntry updated) async {
    final entries = await _repository.loadManualEntries();
    final previous = entries.where((entry) => entry.id == updated.id).firstOrNull;
    if (previous == null) return false;
    await _repository.updateManualEntry(updated);
    var completed = await _reconcile(previous.dayKey, previous.dhikrId);
    if (previous.dhikrId != updated.dhikrId) {
      completed = await _reconcile(updated.dayKey, updated.dhikrId) || completed;
    }
    return completed;
  }

  Future<void> deletePhysicalManual(ManualTasbeehEntry entry) async {
    await _repository.deleteManualEntry(entry.id);
    await _reconcile(entry.dayKey, entry.dhikrId);
  }

  Future<bool> _reconcile(String dayKey, String dhikrId) async {
    await _dailyWird.initialize();
    final eligibleTotal = await _repository.eligibleCountForDay(dayKey, dhikrId);
    return _dailyWird.syncTasbeehProgress(
      dhikrId: dhikrId,
      currentEligibleTotal: eligibleTotal,
      day: DateTime.parse(dayKey),
    );
  }
}
