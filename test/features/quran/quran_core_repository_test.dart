import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tasbeh/features/quran/data/quran_core_store.dart';
import 'package:tasbeh/features/quran/data/sqflite_quran_repository.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';

import '../../../tool/quran/build_quran_core.dart';

void main() {
  late Directory temporary;
  late File databaseFile;
  late Database database;
  late SqfliteQuranRepository repository;

  setUpAll(() async {
    sqfliteFfiInit();
    temporary = await Directory.systemTemp.createTemp('maab_quran_core_test_');
    databaseFile = File('${temporary.path}/quran_core.db');
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
    repository = SqfliteQuranRepository(database);
  });

  tearDownAll(() async {
    await database.close();
    await temporary.delete(recursive: true);
  });

  test('reads Surah and Ayah data in canonical order', () async {
    expect((await repository.getSurahs()).map((e) => e.number), [1, 2]);
    expect((await repository.getSurah(1))?.ayahCount, 2);
    expect(await repository.getSurah(114), isNull);
    expect((await repository.getSurahAyahs(1)).map((e) => e.key), const [
      AyahKey(1, 1),
      AyahKey(1, 2),
    ]);
    expect(await repository.getSurahAyahs(114), isEmpty);
  });

  test('gets Ayat and inclusive cross-Surah ranges by semantic keys', () async {
    expect(
      (await repository.getAyah(const AyahKey(1, 2)))?.textUthmani,
      'SYNTHETIC TOKEN B',
    );
    expect(await repository.getAyah(const AyahKey(1, 99)), isNull);
    expect(
      (await repository.getAyahRange(
        const AyahKey(1, 2),
        const AyahKey(2, 1),
      )).map((e) => e.key),
      const [AyahKey(1, 2), AyahKey(2, 1)],
    );
    expect(
      () => repository.getAyahRange(const AyahKey(2, 1), const AyahKey(1, 1)),
      throwsArgumentError,
    );
  });

  test('reads structural metadata and provenance', () async {
    expect((await repository.getJuz(1))?.startsAt, const AyahKey(1, 1));
    expect((await repository.getHizb(1))?.startsAt, const AyahKey(1, 1));
    expect((await repository.getRubElHizb(1))?.startsAt, const AyahKey(1, 1));
    expect(
      (await repository.getSajdahMarkers()).single.key,
      const AyahKey(2, 1),
    );
    expect((await repository.getMetadata()).sourceProvider, 'Maab test suite');
  });

  test('runtime database is physically read-only', () async {
    expect(
      () => database.rawInsert("INSERT INTO surahs VALUES (3, 'NO', 1)"),
      throwsA(anything),
    );
  });

  test('store initializes once and repeated reads do not reinstall', () async {
    final installer = _CountingInstaller(databaseFile);
    final store = QuranCoreStore(
      installer: installer,
      databaseFactory: databaseFactoryFfi,
    );
    const artifact = QuranCoreArtifact(
      assetPath: 'unused',
      sha256Checksum:
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      contentVersion: 'test',
    );
    final first = await store.initialize(artifact);
    final second = await store.initialize(artifact);
    expect(identical(first, second), isTrue);
    expect(installer.calls, 1);
    await store.close();
  });

  test(
    'builder records checksums and is deterministic for identical input',
    () async {
      final secondDatabase = File('${temporary.path}/quran_core_second.db');
      final secondManifest = File('${temporary.path}/manifest_second.json');
      final second = await buildQuranCore(
        sourceFile: File(
          'test/features/quran/fixtures/synthetic_quran_core.json',
        ),
        outputDatabase: secondDatabase,
        outputManifest: secondManifest,
        allowSyntheticTestFixture: true,
      );
      final firstManifest =
          jsonDecode(
                await File('${temporary.path}/manifest.json').readAsString(),
              )
              as Map<String, dynamic>;
      final nextManifest =
          jsonDecode(await secondManifest.readAsString())
              as Map<String, dynamic>;
      expect(second.databaseChecksum, firstManifest['database_sha256']);
      expect(nextManifest['database_sha256'], firstManifest['database_sha256']);
      expect(nextManifest['source_sha256'], firstManifest['source_sha256']);
    },
  );

  test('builder refuses synthetic input without explicit opt-in', () async {
    expect(
      () => buildQuranCore(
        sourceFile: File(
          'test/features/quran/fixtures/synthetic_quran_core.json',
        ),
        outputDatabase: File('${temporary.path}/refused.db'),
        outputManifest: File('${temporary.path}/refused.json'),
      ),
      throwsStateError,
    );
  });

  test(
    'builder requires explicit research opt-in and records unavailable acquisition',
    () async {
      final sourceMap =
          jsonDecode(
                await File(
                  'test/features/quran/fixtures/synthetic_quran_core.json',
                ).readAsString(),
              )
              as Map<String, dynamic>;
      final metadata = sourceMap['metadata'] as Map<String, dynamic>;
      metadata['dataset_kind'] = 'research';
      metadata['source_acquired_at'] = 'unavailable';
      final source = File('${temporary.path}/research_source.json');
      await source.writeAsString(jsonEncode(sourceMap));
      final researchDatabase = File('${temporary.path}/research.db');
      final researchManifest = File('${temporary.path}/research_manifest.json');

      expect(
        () => buildQuranCore(
          sourceFile: source,
          outputDatabase: researchDatabase,
          outputManifest: researchManifest,
        ),
        throwsStateError,
      );
      await buildQuranCore(
        sourceFile: source,
        outputDatabase: researchDatabase,
        outputManifest: researchManifest,
        allowResearchDataset: true,
      );
      final manifest =
          jsonDecode(await researchManifest.readAsString())
              as Map<String, dynamic>;
      expect(manifest['dataset_kind'], 'research');
      expect(manifest['source_acquired_at'], 'unavailable');

      final researchDb = await databaseFactoryFfi.openDatabase(
        researchDatabase.path,
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
      );
      final researchMetadata = await SqfliteQuranRepository(
        researchDb,
      ).getMetadata();
      expect(researchMetadata.datasetKind.name, 'research');
      expect(researchMetadata.sourceAcquiredAt, isNull);
      await researchDb.close();
    },
  );
}

final class _CountingInstaller implements QuranCoreInstaller {
  _CountingInstaller(this.file);
  final File file;
  int calls = 0;

  @override
  Future<File> install(QuranCoreArtifact artifact) async {
    calls++;
    return file;
  }
}
