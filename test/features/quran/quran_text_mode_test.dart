import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/core/theme/rafiqi_palette.dart';
import 'package:tasbeh/features/quran/application/text/quran_text_mode_controller.dart';
import 'package:tasbeh/features/quran/data/sqflite_quran_repository.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/models/quran_core_models.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_models.dart';
import 'package:tasbeh/features/quran/domain/navigation/quran_navigation.dart';
import 'package:tasbeh/features/quran/domain/repositories/quran_repository.dart';
import 'package:tasbeh/features/quran/presentation/quran_reader_screen.dart';

import '../../../tool/quran/build_quran_core.dart';

void main() {
  late Directory temporary;
  late Database database;
  late SqfliteQuranRepository repository;

  setUpAll(() async {
    sqfliteFfiInit();
    temporary = await Directory.systemTemp.createTemp('maab_quran_text_');
    final file = File('${temporary.path}/core.db');
    await buildQuranCore(
      sourceFile: File(
        'test/features/quran/fixtures/synthetic_quran_core.json',
      ),
      outputDatabase: file,
      outputManifest: File('${temporary.path}/manifest.json'),
      allowSyntheticTestFixture: true,
    );
    database = await databaseFactoryFfi.openDatabase(
      file.path,
      options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
    );
    repository = SqfliteQuranRepository(database);
  });

  tearDownAll(() async {
    await database.close();
    await temporary.delete(recursive: true);
  });

  test('loads canonical display text in deterministic Ayah order', () async {
    final controller = QuranTextModeController(repository);
    await controller.loadSurah(1);
    expect(controller.ayahs.map((ayah) => ayah.key), const [
      AyahKey(1, 1),
      AyahKey(1, 2),
    ]);
    expect(controller.ayahs.last.textUthmani, 'SYNTHETIC TOKEN B');
    expect(controller.surah?.number, 1);
    controller.dispose();
  });

  test('preserves semantic scroll target and selection identity', () async {
    final controller = QuranTextModeController(repository);
    await controller.loadSurah(1, target: const AyahKey(1, 2));
    expect(controller.scrollTarget, const AyahKey(1, 2));
    expect(controller.scrollTargetIndex, 1);
    expect(controller.selectedAyah, const AyahKey(1, 2));
    controller.selectAyah(const AyahKey(1, 1));
    expect(controller.selectedAyah, const AyahKey(1, 1));
    controller.dispose();
  });

  test('enforces Surah boundaries and rejects missing targets', () async {
    final controller = QuranTextModeController(repository);
    await expectLater(
      controller.loadSurah(1, target: const AyahKey(2, 1)),
      throwsArgumentError,
    );
    await expectLater(
      controller.loadSurah(1, target: const AyahKey(1, 99)),
      throwsStateError,
    );
    controller.dispose();
  });

  testWidgets('Text Mode opens on the requested semantic Ayah', (tester) async {
    final target = QuranNavigationTarget(
      ayahKey: const AyahKey(1, 2),
      pageKey: MushafPageKey(MushafEditionId('synthetic-edition'), 2),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildRafiqiTheme(
          palette: RafiqiPalette.rafiqi,
          brightness: Brightness.light,
        ),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: QuranReaderScreen(
            repository: const _TextFixtureRepository(),
            target: target,
            initialMode: QuranReadingMode.text,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SYNTHETIC TOKEN B'), findsOneWidget);
    expect(find.text('النص'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final class _TextFixtureRepository implements QuranRepository {
  const _TextFixtureRepository();

  static const _surah = QuranSurah(
    number: 1,
    nameArabic: 'SYNTHETIC-SURAH-A',
    ayahCount: 2,
  );
  static const _ayahs = [
    QuranAyah(
      key: AyahKey(1, 1),
      globalIndex: 1,
      textUthmani: 'SYNTHETIC TOKEN A',
    ),
    QuranAyah(
      key: AyahKey(1, 2),
      globalIndex: 2,
      textUthmani: 'SYNTHETIC TOKEN B',
    ),
  ];

  @override
  Future<bool> containsAyah(AyahKey key) async =>
      _ayahs.any((a) => a.key == key);
  @override
  Future<QuranAyah?> getAyah(AyahKey key) async =>
      _ayahs.where((ayah) => ayah.key == key).firstOrNull;
  @override
  Future<List<QuranAyah>> getAyahRange(AyahKey start, AyahKey end) async =>
      _ayahs
          .where(
            (ayah) =>
                ayah.key.compareTo(start) >= 0 && ayah.key.compareTo(end) <= 0,
          )
          .toList();
  @override
  Future<QuranHizb?> getHizb(int number) async => null;
  @override
  Future<List<QuranHizb>> getHizbs() async => const [];
  @override
  Future<QuranJuz?> getJuz(int number) async => null;
  @override
  Future<List<QuranJuz>> getJuzs() async => const [];
  @override
  Future<QuranCoreMetadata> getMetadata() => throw UnimplementedError();
  @override
  Future<QuranRubElHizb?> getRubElHizb(int number) async => null;
  @override
  Future<List<QuranRubElHizb>> getRubElHizbs() async => const [];
  @override
  Future<List<QuranSajdah>> getSajdahMarkers() async => const [];
  @override
  Future<QuranSurah?> getSurah(int surahNumber) async =>
      surahNumber == 1 ? _surah : null;
  @override
  Future<List<QuranAyah>> getSurahAyahs(int surahNumber) async =>
      surahNumber == 1 ? _ayahs : const [];
  @override
  Future<List<QuranSurah>> getSurahs() async => const [_surah];
  @override
  Future<int?> resolveGlobalAyahIndex(AyahKey key) async =>
      (await getAyah(key))?.globalIndex;
}
