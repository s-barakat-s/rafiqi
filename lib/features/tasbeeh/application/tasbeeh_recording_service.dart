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
    this.revision = 0,
    this.duplicate = false,
  });

  final TasbeehState state;
  final bool completedTask;
  final int revision;
  final bool duplicate;
}

class TasbeehUndoResult {
  const TasbeehUndoResult({
    required this.state,
    required this.revision,
    required this.reversed,
  });

  final TasbeehState state;
  final int revision;
  final bool reversed;
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
    int? revision,
  }) async {
    await _repository.save(next, revision: revision);
    final daily = await _repository.recordIncrement(
      dhikrId: next.selectedDhikrId,
      dhikrText: next.selectedDhikrText,
      source: source,
    );
    // Refresh only today's indexed record. This preserves cross-engine
    // correctness without decoding/rebuilding the whole Journey history.
    await _dailyWird.refreshDayForTasbeeh();
    final eligibleTotal =
        daily.inAppCount +
        await _repository.manualCountForDay(daily.dayKey, next.selectedDhikrId);
    final completedTask = await _dailyWird.syncTasbeehProgress(
      dhikrId: next.selectedDhikrId,
      currentEligibleTotal: eligibleTotal,
    );
    return TasbeehIncrementResult(
      state: next,
      completedTask: completedTask,
      revision: revision ?? await _repository.loadRevision(),
    );
  }

  /// Applies one retriable increment operation at most once.
  ///
  /// The operation id is persisted only after state, activity and linked-task
  /// projection complete. This makes a repeated delivery after a lost reply a
  /// no-op. Full multi-engine transactional storage remains a Phase 3 concern.
  Future<TasbeehIncrementResult> recordIncrementOperation({
    required String operationId,
    required TasbeehActivitySource source,
  }) async {
    if (await _repository.hasProcessedOperation(operationId)) {
      return TasbeehIncrementResult(
        state: await _repository.load(),
        completedTask: false,
        revision: await _repository.loadRevision(),
        duplicate: true,
      );
    }

    final current = await _repository.load();
    final revision = await _repository.loadRevision() + 1;
    final result = await recordIncrement(
      nextState(current),
      source: source,
      revision: revision,
    );
    await _repository.markOperationProcessed(operationId);
    return result;
  }

  Future<TasbeehUndoResult> undoIncrement({
    required TasbeehActivitySource source,
  }) async {
    final current = await _repository.load();
    final currentRevision = await _repository.loadRevision();
    if (current.currentCount <= 0) {
      return TasbeehUndoResult(
        state: current,
        revision: currentRevision,
        reversed: false,
      );
    }

    final daily = await _repository.removeRecordedIncrement(
      dhikrId: current.selectedDhikrId,
      source: source,
    );
    if (daily == null) {
      return TasbeehUndoResult(
        state: current,
        revision: currentRevision,
        reversed: false,
      );
    }

    final next = TasbeehCounterLogic.decrement(current);
    final revision = currentRevision + 1;
    await _repository.save(next, revision: revision);
    await _dailyWird.refreshDayForTasbeeh();
    final eligibleTotal =
        daily.inAppCount +
        await _repository.manualCountForDay(
          daily.dayKey,
          current.selectedDhikrId,
        );
    await _dailyWird.syncTasbeehProgress(
      dhikrId: current.selectedDhikrId,
      currentEligibleTotal: eligibleTotal,
    );
    return TasbeehUndoResult(state: next, revision: revision, reversed: true);
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
    final previous = entries
        .where((entry) => entry.id == updated.id)
        .firstOrNull;
    if (previous == null) return false;
    await _repository.updateManualEntry(updated);
    var completed = await _reconcile(previous.dayKey, previous.dhikrId);
    if (previous.dhikrId != updated.dhikrId) {
      completed =
          await _reconcile(updated.dayKey, updated.dhikrId) || completed;
    }
    return completed;
  }

  Future<void> deletePhysicalManual(ManualTasbeehEntry entry) async {
    await _repository.deleteManualEntry(entry.id);
    await _reconcile(entry.dayKey, entry.dhikrId);
  }

  Future<bool> _reconcile(String dayKey, String dhikrId) async {
    await _dailyWird.initialize();
    final eligibleTotal = await _repository.eligibleCountForDay(
      dayKey,
      dhikrId,
    );
    return _dailyWird.syncTasbeehProgress(
      dhikrId: dhikrId,
      currentEligibleTotal: eligibleTotal,
      day: DateTime.parse(dayKey),
    );
  }
}
