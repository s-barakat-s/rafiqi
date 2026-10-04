import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/core/theme/rafiqi_palette.dart';
import 'package:tasbeh/features/home/data/home_prayer_mock_data.dart';
import 'package:tasbeh/features/home/presentation/models/prayer_header_data.dart';
import 'package:tasbeh/features/home/presentation/widgets/prayer_header/prayer_header_section.dart';
import 'package:tasbeh/features/home/presentation/widgets/prayer_header/weekday_assets.dart';

void main() {
  test('weekday mapping uses all supplied PNG artwork and Wednesday mock', () {
    expect(WeekdayAssets.paths.length, 7);
    expect(
      WeekdayAssets.pathFor(AppWeekday.wednesday),
      'assets/image/home/days/الاربعاء.png',
    );
    expect(HomePrayerMockData.header.weekday, AppWeekday.wednesday);
    expect(
      WeekdayAssets.pathFor(AppWeekday.friday),
      'assets/image/home/days/الجمعة.png',
    );
  });

  testWidgets('all mapped weekday PNG assets load from the bundle', (
    tester,
  ) async {
    for (final path in WeekdayAssets.paths.values) {
      expect((await rootBundle.load(path)).lengthInBytes, greaterThan(0));
    }
  });

  testWidgets('prayer header stays overflow-free at a small phone width', (
    tester,
  ) async {
    var settingsTaps = 0;
    var prayerTimesTaps = 0;
    var qiblaTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildRafiqiTheme(
          palette: RafiqiPalette.rafiqi,
          brightness: Brightness.light,
        ),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: PrayerHeaderSection(
                    data: HomePrayerMockData.header,
                    onSettingsTap: () => settingsTaps++,
                    onPrayerTimesTap: () => prayerTimesTaps++,
                    onQiblaTap: () => qiblaTaps++,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final layoutException = tester.takeException();
    if (layoutException != null) {
      fail(layoutException.toString());
    }
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    final weekdayImage = tester.widget<Image>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName.endsWith('الاربعاء.png'),
      ),
    );
    expect(weekdayImage.fit, BoxFit.contain);
    expect(weekdayImage.color, isNull);
    expect(find.text('العصر'), findsNWidgets(2));
    expect(find.text('03:31'), findsOneWidget);
    expect(find.bySemanticsLabel('الآن، العصر، 3:31 PM'), findsOneWidget);

    await tester.tap(find.byTooltip('الإعدادات'));
    await tester.tap(find.text('المزيد من مواقيت الصلاة'));
    await tester.tap(find.text('تحديد اتجاه القبلة'));

    expect(settingsTaps, 1);
    expect(prayerTimesTaps, 1);
    expect(qiblaTaps, 1);
  });
}
