import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeh/core/time/local_day.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_counter_logic.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_phrase.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_state.dart';

void main() {
  test('increment updates session, daily and lifetime counters together', () {
    final phrase = TasbeehPhrase.defaultPhrases.first;
    final state = TasbeehState(
      currentCount: 32,
      totalCount: 100,
      dailyTotal: 20,
      dailyDateKey: LocalDay.key(DateTime.now()),
      targetMode: TasbeehState.targetMode33,
      selectedDhikrId: phrase.id,
      selectedDhikrText: phrase.text,
      sessionCounts: {phrase.id: 32},
    );

    final next = TasbeehCounterLogic.increment(state);

    expect(next.currentCount, 33);
    expect(next.dailyTotal, 21);
    expect(next.totalCount, 101);
  });

  test('finite target wraps session without resetting totals', () {
    final phrase = TasbeehPhrase.defaultPhrases.first;
    final state = TasbeehState(
      currentCount: 33,
      totalCount: 100,
      dailyTotal: 20,
      dailyDateKey: LocalDay.key(DateTime.now()),
      targetMode: TasbeehState.targetMode33,
      selectedDhikrId: phrase.id,
      selectedDhikrText: phrase.text,
      sessionCounts: {phrase.id: 33},
    );

    final next = TasbeehCounterLogic.increment(state);

    expect(next.currentCount, 1);
    expect(next.dailyTotal, 21);
    expect(next.totalCount, 101);
  });
}
