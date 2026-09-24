import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_state.dart';

class TasbeehCounterLogic {
  const TasbeehCounterLogic._();

  static TasbeehState increment(TasbeehState state) {
    state = state.forCurrentDay();
    final targetCount = state.targetCount;
    final sessions = Map<String, int>.from(state.sessionCounts);

    if (targetCount == null || targetCount <= 0) {
      final nextCurrent = state.currentCount + 1;
      sessions[state.selectedDhikrId] = nextCurrent;
      return state.copyWith(
        currentCount: nextCurrent,
        totalCount: state.totalCount + 1,
        dailyTotal: state.dailyTotal + 1,
        sessionCounts: sessions,
      );
    }

    final nextCurrent = state.currentCount >= targetCount
        ? 1
        : state.currentCount + 1;
    sessions[state.selectedDhikrId] = nextCurrent;

    return state.copyWith(
      currentCount: nextCurrent,
      totalCount: state.totalCount + 1,
      dailyTotal: state.dailyTotal + 1,
      sessionCounts: sessions,
    );
  }

  static TasbeehState resetSession(TasbeehState state) {
    final sessions = Map<String, int>.from(state.sessionCounts)
      ..[state.selectedDhikrId] = 0;
    return state.copyWith(currentCount: 0, sessionCounts: sessions);
  }

  static TasbeehState decrement(TasbeehState state) {
    state = state.forCurrentDay();
    if (state.currentCount <= 0) return state;
    final nextCurrent = state.currentCount - 1;
    final sessions = Map<String, int>.from(state.sessionCounts);
    sessions[state.selectedDhikrId] = nextCurrent;
    return state.copyWith(
      currentCount: nextCurrent,
      totalCount: state.totalCount > 0 ? state.totalCount - 1 : 0,
      dailyTotal: state.dailyTotal > 0 ? state.dailyTotal - 1 : 0,
      sessionCounts: sessions,
    );
  }

  static TasbeehState selectDhikr(
    TasbeehState state, {
    required String id,
    required String text,
  }) {
    return state.copyWith(
      selectedDhikrId: id,
      selectedDhikrText: text,
      currentCount: state.sessionCounts[id] ?? 0,
    );
  }

  static TasbeehState changeTarget(TasbeehState state, String targetMode) {
    final updated = state.copyWith(targetMode: targetMode);
    final targetCount = updated.targetCount;

    if (targetCount != null && updated.currentCount > targetCount) {
      return updated.copyWith(currentCount: 0);
    }

    return updated;
  }
}
