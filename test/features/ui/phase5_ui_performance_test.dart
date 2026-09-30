import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/app/widgets/rafiqi_startup_intro.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/presentation/screens/wird_reader_screen.dart';
import 'package:tasbeh/shared/widgets/app_decorative_background.dart';
import 'package:tasbeh/shared/widgets/app_theme_artwork.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Reader owns the same decorative background for every entry', (
    tester,
  ) async {
    Future<void> pumpReader({Animation<double>? morph}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: WirdReaderScreen(
            category: _category,
            vibrationEnabled: false,
            soundEnabled: false,
            morphTransition: morph == null
                ? null
                : MorphTransitionSpec(controller: morph),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AppDecorativeBackground), findsOneWidget);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        Colors.transparent,
      );
    }

    await pumpReader();
    final morph = AnimationController(vsync: tester, value: 1);
    addTearDown(morph.dispose);
    await pumpReader(morph: morph);
  });

  testWidgets('theme artwork keeps the selected asset and sizes its decode', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            height: 100,
            child: AppThemeArtwork(asset: _lightHero),
          ),
        ),
      ),
    );

    final firstImage = tester.widget<Image>(find.byType(Image));
    final firstProvider = firstImage.image as ResizeImage;
    expect(firstProvider.width, 448);
    expect(
      (firstProvider.imageProvider as AssetImage).assetName,
      _lightHero,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            height: 100,
            child: AppThemeArtwork(asset: _darkHero),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.byType(Image), findsNWidgets(2));
    await tester.pump(AppThemeArtwork.transitionDuration);
    expect(find.byType(Image), findsOneWidget);
    final finalProvider = tester.widget<Image>(find.byType(Image)).image;
    expect((finalProvider as ResizeImage).imageProvider, isA<AssetImage>());
    expect(
      (finalProvider.imageProvider as AssetImage).assetName,
      _darkHero,
    );
  });

  test('destination artwork is selected when color interpolation starts', () {
    final light = AppTheme.light().extension<AppColors>()!;
    final dark = AppTheme.dark().extension<AppColors>()!;

    expect(light.lerp(dark, 0).morningHeroAsset, light.morningHeroAsset);
    expect(light.lerp(dark, .01).morningHeroAsset, dark.morningHeroAsset);
  });

  testWidgets('startup intro still fades away after its shorter hold', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const RafiqiStartupIntro(
          child: ColoredBox(
            key: ValueKey('startup-content'),
            color: Colors.white,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Exit = splash frame ready + 240ms hold + 320ms fade, with a 1500ms
    // decode fallback. Pump long enough to cover the fallback path so the
    // test is deterministic regardless of when the frame decodes.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('startup-content')), findsOneWidget);
    expect(find.byType(AppThemeArtwork), findsNothing);
  });
}

const _lightHero = 'assets/image/home/rafiqi/morning_light.webp';
const _darkHero = 'assets/image/home/rafiqi/morning_dark.webp';

const _category = AdhkarCategory(
  id: 'phase-5-reader',
  title: 'اختبار القارئ',
  subtitle: '',
  kind: AdhkarCategoryKind.morning,
  items: [
    DhikrItem(
      id: 'phase-5-item',
      order: 1,
      category: 'phase-5-reader',
      text: 'سبحان الله',
      repeatCount: 1,
      entryType: DhikrEntryType.single,
    ),
  ],
);
