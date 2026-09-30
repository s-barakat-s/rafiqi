import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/app/bootstrap.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/core/theme/rafiqi_palette.dart';
import 'package:tasbeh/features/settings/data/repositories/app_preferences_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('restores the persisted palette before the first app frame', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'app_dark_theme': true,
      'app_color_palette': RafiqiPalette.ocean.name,
    });

    Widget? launchedApp;
    await bootstrapMainApp(runApplication: (app) => launchedApp = app);

    final restored = AppPreferencesRepository.instance.value;
    expect(restored.palette, RafiqiPalette.ocean);
    expect(restored.themeMode, ThemeMode.dark);
    expect(launchedApp, isNotNull);

    await tester.pumpWidget(launchedApp!);

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final firstFrameColors = materialApp.darkTheme!.extension<AppColors>()!;
    final persistedColors = rafiqiPaletteColors(
      palette: RafiqiPalette.ocean,
      brightness: Brightness.dark,
    );
    final defaultColors = rafiqiPaletteColors(
      palette: RafiqiPalette.rafiqi,
      brightness: Brightness.dark,
    );

    expect(materialApp.themeMode, ThemeMode.dark);
    expect(firstFrameColors.background, persistedColors.background);
    expect(firstFrameColors.primary, persistedColors.primary);
    expect(firstFrameColors.background, isNot(defaultColors.background));

    // Drain the startup intro's bounded display/fade timers.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 240));
    await tester.pump(const Duration(milliseconds: 320));
  });
}
