import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_state.dart';

class TasbeehCounterLogic {
  const TasbeehCounterLogic._();

  static TasbeehState increment(TasbeehState state) {
    final targetCount = state.targetCount;

    if (targetCount == null || targetCount <= 0) {
      return state.copyWith(
        currentCount: state.currentCount + 1,
        totalCount: state.totalCount + 1,
      );
    }

    final nextCurrent =
        state.currentCount >= targetCount ? 1 : state.currentCount + 1;

    return state.copyWith(
      currentCount: nextCurrent,
      totalCount: state.totalCount + 1,
    );
  }

  static TasbeehState resetSession(TasbeehState state) {
    return state.copyWith(currentCount: 0);
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
