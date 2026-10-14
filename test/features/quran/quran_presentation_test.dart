import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/core/theme/rafiqi_palette.dart';
import 'package:tasbeh/features/quran/presentation/quran_index_screen.dart';

void main() {
  testWidgets('production tab reports the honest local-data gate', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildRafiqiTheme(
          palette: RafiqiPalette.rafiqi,
          brightness: Brightness.light,
        ),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: QuranIndexScreen(),
        ),
      ),
    );

    expect(find.text('البنية المحلية جاهزة'), findsOneWidget);
    expect(
      find.textContaining('بيانات القرآن الإنتاجية المعتمدة'),
      findsOneWidget,
    );
    expect(find.textContaining('دون إنترنت'), findsOneWidget);
    expect(find.byType(QuranIndexScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(812, 375);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildRafiqiTheme(
          palette: RafiqiPalette.rafiqi,
          brightness: Brightness.dark,
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.8)),
          child: child!,
        ),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: QuranIndexScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('البنية المحلية جاهزة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
