import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tasbeh/features/quran/application/navigation/quran_navigation_service.dart';
import 'package:tasbeh/features/quran/data/mushaf/sqflite_mushaf_layout_repository.dart';
import 'package:tasbeh/features/quran/data/sqflite_quran_repository.dart';
import 'package:tasbeh/features/quran/data/sqflite_quran_search_repository.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_models.dart';

import '../../../tool/quran/build_mushaf_layout.dart';
import '../../../tool/quran/build_quran_core.dart';

void main() {
  late Directory temporary;
  late Database coreDatabase;
  late Database layoutDatabase;
  late QuranNavigationService navigation;
  late SqfliteQuranSearchRepository search;
  late MushafEdition edition;

  setUpAll(() async {
    sqfliteFfiInit();
    temporary = await Directory.systemTemp.createTemp('maab_quran_navigation_');
    final coreFile = File('${temporary.path}/core.db');
    final layoutFile = File('${temporary.path}/layout.db');
    await buildQuranCore(
      sourceFile: File(
        'test/features/quran/fixtures/synthetic_quran_core.json',
      ),
      outputDatabase: coreFile,
      outputManifest: File('${temporary.path}/core.json'),
      allowSyntheticTestFixture: true,
    );
    await buildMushafLayout(
      sourceFile: File(
        'test/features/quran/fixtures/synthetic_mushaf_layout.json',
      ),
      outputDatabase: layoutFile,
      outputManifest: File('${temporary.path}/layout.json'),
      allowSyntheticTestFixture: true,
    );
    coreDatabase = await databaseFactoryFfi.openDatabase(
      coreFile.path,
      options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
    );
    layoutDatabase = await databaseFactoryFfi.openDatabase(
      layoutFile.path,
      options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
    );
    final core = SqfliteQuranRepository(coreDatabase);
    final layout = SqfliteMushafLayoutRepository(layoutDatabase);
    edition = await layout.getEdition();
    navigation = QuranNavigationService(
      quranRepository: core,
      layoutRepository: layout,
      edition: edition,
    );
    search = SqfliteQuranSearchRepository(coreDatabase);
  });

  tearDownAll(() async {
    await coreDatabase.close();
    await layoutDatabase.close();
    await temporary.delete(recursive: true);
  });

  test('lists Surah, Juz, Hizb, and Rub boundaries locally', () async {
    expect((await navigation.getSurahs()).map((item) => item.number), [1, 2]);
    expect((await navigation.getJuzs()).map((item) => item.number), [1]);
    expect((await navigation.getHizbs()).map((item) => item.number), [1]);
    expect((await navigation.getRubs()).map((item) => item.number), [1]);
  });

  test('resolves semantic starts before edition-aware pages', () async {
    for (final target in [
      await navigation.resolveSurahStart(1),
      await navigation.resolveJuzStart(1),
      await navigation.resolveHizbStart(1),
      await navigation.resolveRubStart(1),
    ]) {
      expect(target?.ayahKey, const AyahKey(1, 1));
      expect(target?.pageKey, MushafPageKey(edition.id, 1));
    }
    final ayah = await navigation.resolveAyah(const AyahKey(1, 2));
    expect(ayah?.ayahKey, const AyahKey(1, 2));
    expect(ayah?.pageKey, MushafPageKey(edition.id, 2));
  });

  test('resolves page to its first semantic Ayah', () async {
    final target = await navigation.resolvePage(MushafPageKey(edition.id, 2));
    expect(target?.ayahKey, const AyahKey(1, 2));
    expect(target?.pageKey.pageNumber, 2);
  });

  test(
    'rejects invalid numbers, absent mappings, and another edition',
    () async {
      expect(await navigation.resolveSurahStart(114), isNull);
      expect(await navigation.resolveJuzStart(99), isNull);
      expect(await navigation.resolveHizbStart(99), isNull);
      expect(await navigation.resolveRubStart(99), isNull);
      expect(await navigation.resolveAyah(const AyahKey(1, 99)), isNull);
      expect(
        await navigation.resolvePage(MushafPageKey(edition.id, 3)),
        isNull,
      );
      expect(
        await navigation.resolvePage(
          MushafPageKey(MushafEditionId('another-edition'), 1),
        ),
        isNull,
      );
    },
  );

  test(
    'search result resolves through AyahKey to selected edition page',
    () async {
      final result = (await search.search('synthetic token b')).single;
      final target = await navigation.resolveAyah(result.ayahKey);
      expect(result.ayahKey, const AyahKey(1, 2));
      expect(target?.pageKey, MushafPageKey(edition.id, 2));
    },
  );
}
