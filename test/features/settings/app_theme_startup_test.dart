import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/app/bootstrap.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/core/theme/rafiqi_palette.dart';
import 'package:tasbeh/features/settings/data/repositories/app_preferences_repository.dart';
import 'package:tasbeh/features/settings/domain/app_preferences.dart';
import 'package:tasbeh/features/settings/presentation/screens/appearance_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fresh preferences default to Rafiqi Light', () {
    const preferences = AppPreferences();

    expect(preferences.palette, RafiqiPalette.rafiqi);
    expect(preferences.themeMode, ThemeMode.light);
  });

  test('all saved alternative palettes resolve to Rafiqi for V1', () {
    for (final palette in RafiqiPalette.values) {
      expect(RafiqiPalette.resolveForV1(palette.name), RafiqiPalette.rafiqi);
    }
    expect(RafiqiPalette.resolveForV1(null), RafiqiPalette.rafiqi);
  });

  test('Rafiqi Light and Dark keep semantic colors and valid artwork', () {
    final light = rafiqiPaletteColors(
      palette: RafiqiPalette.rafiqi,
      brightness: Brightness.light,
    );
    final dark = rafiqiPaletteColors(
      palette: RafiqiPalette.rafiqi,
      brightness: Brightness.dark,
    );

    expect(light.isRafiqi, isTrue);
    expect(dark.isRafiqi, isTrue);
    expect(light.background, AppPalette.rafiqiLightBackground);
    expect(dark.background, AppPalette.rafiqiDarkBackground);
    expect(
      light.heroAsset(isMorning: true, brightness: Brightness.light),
      'assets/image/home/Morning light.png',
    );
    expect(
      dark.heroAsset(isMorning: true, brightness: Brightness.dark),
      'assets/image/home/morning dark.png',
    );
    expect(
      light.dailyDhikrBackground(Brightness.light),
      'assets/image/zekr/rafiqi_zekr_light.png',
    );
    expect(
      dark.dailyDhikrBackground(Brightness.dark),
      'assets/image/zekr/rafiqi_zekr_light.png',
    );
  });

  testWidgets('falls back from a saved alternative before the first frame', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'app_dark_theme': true,
      'app_color_palette': RafiqiPalette.ocean.name,
    });

    Widget? launchedApp;
    await bootstrapMainApp(runApplication: (app) => launchedApp = app);

    final restored = AppPreferencesRepository.instance.value;
    expect(restored.palette, RafiqiPalette.rafiqi);
    expect(restored.themeMode, ThemeMode.dark);
    expect(launchedApp, isNotNull);

    await tester.pumpWidget(launchedApp!);

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final firstFrameColors = materialApp.darkTheme!.extension<AppColors>()!;
    final defaultColors = rafiqiPaletteColors(
      palette: RafiqiPalette.rafiqi,
      brightness: Brightness.dark,
    );

    expect(materialApp.themeMode, ThemeMode.dark);
    expect(firstFrameColors.background, defaultColors.background);
    expect(firstFrameColors.primary, defaultColors.primary);
    final storage = await SharedPreferences.getInstance();
    expect(storage.getString('app_color_palette'), RafiqiPalette.ocean.name);

    // Drain the startup intro's frame fallback, hold, and fade timers.
    await tester.pump(const Duration(milliseconds: 6500));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        home: const AppearanceScreen(),
      ),
    );
    await tester.pump();
    expect(find.text('ألوان مَآب'), findsNothing);
    expect(find.text('اختر الألوان التي تناسبك'), findsNothing);
    expect(find.byType(SwitchListTile), findsOneWidget);
  });
}
