import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeh/features/home/domain/adhkar_time_period.dart';

void main() {
  test('morning and evening use one shared noon boundary', () {
    expect(
      AdhkarTimePeriod.at(DateTime(2026, 9, 29, 11, 59)),
      AdhkarTimePeriod.morning,
    );
    expect(
      AdhkarTimePeriod.at(DateTime(2026, 9, 29, 12)),
      AdhkarTimePeriod.evening,
    );
  });

  test('next boundary advances through noon and midnight', () {
    expect(
      AdhkarTimePeriod.nextBoundaryAfter(DateTime(2026, 9, 29, 8)),
      DateTime(2026, 9, 29, 12),
    );
    final midnight = AdhkarTimePeriod.nextBoundaryAfter(
      DateTime(2026, 9, 29, 23, 59),
    );
    expect(midnight, DateTime(2026, 9, 30));
    expect(AdhkarTimePeriod.at(midnight), AdhkarTimePeriod.morning);
  });
}
