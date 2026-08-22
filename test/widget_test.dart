import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/app/tasbeeh_app.dart';

void main() {
  testWidgets('Tasbeeh count increments and reset affects session only', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const TasbeehApp());
    await tester.pumpAndSettle();

    expect(find.text('تسبيح'), findsWidgets);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('اضغط للتسبيح'), findsOneWidget);

    await tester.drag(find.byType(Scrollable), const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tasbeeh-counter-tap-area')));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('tasbeeh.currentCount'), 1);
    expect(prefs.getInt('tasbeeh.totalCount'), 1);

    await tester.drag(find.byType(Scrollable), const Offset(0, -500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تصفير الجلسة'));
    await tester.pumpAndSettle();

    expect(prefs.getInt('tasbeeh.currentCount'), 0);
    expect(prefs.getInt('tasbeeh.totalCount'), 1);
  });
}
