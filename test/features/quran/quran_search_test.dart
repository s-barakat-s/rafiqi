import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tasbeh/features/quran/application/search/arabic_search_normalizer.dart';
import 'package:tasbeh/features/quran/data/sqflite_quran_search_repository.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/search/quran_search.dart';

import '../../../tool/quran/build_quran_core.dart';

void main() {
  late Directory temporary;
  late Database database;
  late SqfliteQuranSearchRepository search;

  setUpAll(() async {
    sqfliteFfiInit();
    temporary = await Directory.systemTemp.createTemp('maab_quran_search_');
    final databaseFile = File('${temporary.path}/quran.db');
    await buildQuranCore(
      sourceFile: File(
        'test/features/quran/fixtures/synthetic_quran_core.json',
      ),
      outputDatabase: databaseFile,
      outputManifest: File('${temporary.path}/manifest.json'),
      allowSyntheticTestFixture: true,
    );
    database = await databaseFactoryFfi.openDatabase(
      databaseFile.path,
      options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
    );
    search = SqfliteQuranSearchRepository(database);
  });

  tearDownAll(() async {
    await database.close();
    await temporary.delete(recursive: true);
  });

  test('normalizes Arabic deterministically without changing source text', () {
    const display = 'نَصٌّ تَجْرِيبِيٌّ مُصْطَنَعٌ';
    expect(
      ArabicSearchNormalizer.normalize('  نَـصٌّ،   تَجْرِيبِيٌّ!  '),
      'نص تجريبي',
    );
    expect(display, 'نَصٌّ تَجْرِيبِيٌّ مُصْطَنَعٌ');
    expect(ArabicSearchNormalizer.normalize('أ إ آ ٱ'), 'ا ا ا ا');
  });

  test('returns exact match with semantic and Surah metadata', () async {
    final results = await search.search('synthetic token a');
    expect(results, hasLength(1));
    expect(results.single.ayahKey, const AyahKey(1, 1));
    expect(results.single.surahNameArabic, 'SYNTHETIC-SURAH-A');
    expect(results.single.matchKind, QuranSearchMatchKind.exact);
    expect(results.single.displayText, 'SYNTHETIC TOKEN A');
  });

  test('matches normalized Arabic while preserving display text', () async {
    final results = await search.search('نص تجريبي مصطنع');
    expect(results.single.ayahKey, const AyahKey(2, 1));
    expect(results.single.displayText, 'نَصٌّ تَجْرِيبِيٌّ مُصْطَنَعٌ');
  });

  test('orders broad results deterministically by canonical order', () async {
    final first = await search.search('synthetic token');
    final second = await search.search('SYNTHETIC   TOKEN');
    expect(first.map((result) => result.ayahKey), const [
      AyahKey(1, 1),
      AyahKey(1, 2),
    ]);
    expect(
      second.map((result) => result.ayahKey),
      first.map((result) => result.ayahKey),
    );
  });

  test('returns no results and rejects invalid queries', () async {
    expect(await search.search('nothing-matches'), isEmpty);
    expect(
      () => search.search('... !!!'),
      throwsA(isA<QuranSearchQueryException>()),
    );
    expect(() => search.search('test', limit: 0), throwsArgumentError);
  });
}
