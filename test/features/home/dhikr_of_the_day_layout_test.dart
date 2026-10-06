import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/core/time/local_day.dart';
import 'package:tasbeh/features/home/data/repositories/daily_dhikr_repository.dart';
import 'package:tasbeh/features/home/presentation/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('daily dhikr content stays clear of the left artwork', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(480, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const cases = <(String, String)>[
      ('daily_dhikr_003', 'سبحان الله'),
      ('daily_dhikr_009', 'أستغفر الله وأتوب إليه'),
      ('daily_dhikr_004', 'رب اغفر لي وتب علي، إنك أنت التواب الرحيم'),
      (
        'daily_salawat_001',
        'اللهم صل على محمد وعلى آل محمد، كما صليت على آل إبراهيم، إنك حميد مجيد، اللهم بارك على محمد وعلى آل محمد، كما باركت على آل إبراهيم، إنك حميد مجيد.',
      ),
    ];

    for (final (id, text) in cases) {
      await DailyDhikrRepository.instance.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'daily_dhikr_day_key': LocalDay.key(LocalDay.date(DateTime.now())),
        'daily_dhikr_shuffled_ids': [id],
        'daily_dhikr_current_index': 0,
        'daily_dhikr_remaining_count': 93,
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: HomeScreen(
              onOpenTasbeeh: () {},
              onOpenAdhkar: (_) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(text), findsOneWidget);
      expect(tester.takeException(), isNull);

      final cardRect = tester.getRect(find.byKey(ValueKey(id)));
      final contentRect = tester.getRect(
        find.byKey(const ValueKey('daily-dhikr-content-region')),
      );
      expect(contentRect.left, greaterThanOrEqualTo(cardRect.left + 100));
      expect(contentRect.right, lessThanOrEqualTo(cardRect.right - 19));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });
}
