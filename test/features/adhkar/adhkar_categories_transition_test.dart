import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/presentation/widgets/adhkar_category_grid.dart';

void main() {
  testWidgets('category container opens reader and reverses to its tile', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final category = AdhkarCategory(
      id: 'morning',
      kind: AdhkarCategoryKind.morning,
      title: 'أذكار الصباح',
      subtitle: 'بداية مطمئنة ليومك',
      items: const [
        DhikrItem(
          id: 'morning-test',
          order: 1,
          category: 'morning',
          text: 'ذكر تجريبي',
          repeatCount: 1,
          entryType: DhikrEntryType.single,
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: AdhkarCategoryGrid(
              categories: [category],
              vibrationEnabled: false,
              soundEnabled: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('أذكار الصباح'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('adhkar-category-morning')));
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);

    expect(find.byTooltip('رجوع'), findsOneWidget);
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('أذكار الصباح'), findsOneWidget);
  });
}
