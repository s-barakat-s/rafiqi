import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tasbeh/features/quran/data/quran_core_dataset.dart';
import 'package:tasbeh/features/quran/data/quran_core_schema.dart';
import 'package:tasbeh/features/quran/data/quran_core_store.dart';
import 'package:tasbeh/features/quran/domain/models/quran_core_models.dart';

const quranCoreIngestionToolVersion = 'maab-quran-core-ingestion/1';

Future<QuranCoreBuildResult> buildQuranCore({
  required File sourceFile,
  required File outputDatabase,
  required File outputManifest,
  bool allowSyntheticTestFixture = false,
  DatabaseFactory? factory,
}) async {
  final sourceBytes = await sourceFile.readAsBytes();
  final sourceChecksum = sha256.convert(sourceBytes).toString();
  final sourceText = utf8.decode(sourceBytes, allowMalformed: false);
  final dataset = QuranCoreDataset.fromSourceJson(
    sourceText,
    sourceChecksum: sourceChecksum,
  );
  if (dataset.metadata.ingestionToolVersion != quranCoreIngestionToolVersion) {
    throw StateError('Source requests a different ingestion tool version');
  }
  if (dataset.metadata.datasetKind == QuranDatasetKind.syntheticTest &&
      !allowSyntheticTestFixture) {
    throw StateError(
      'Synthetic fixtures require --allow-synthetic-test-fixture',
    );
  }
  QuranCoreDatasetValidator.validate(dataset);

  sqfliteFfiInit();
  final dbFactory = factory ?? databaseFactoryFfi;
  await outputDatabase.parent.create(recursive: true);
  await outputManifest.parent.create(recursive: true);
  final staging = File('${outputDatabase.path}.staging');
  if (await staging.exists()) await staging.delete();

  final db = await dbFactory.openDatabase(
    staging.path,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  try {
    await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('PRAGMA journal_mode = DELETE');
    for (final statement in QuranCoreSchema.statements) {
      await db.execute(statement);
    }
    await db.transaction((txn) async {
      final metadata = dataset.metadata;
      await txn.insert('quran_metadata', {
        'id': 1,
        'source_provider': metadata.sourceProvider,
        'source_resource_name': metadata.sourceResourceName,
        'source_reference': metadata.sourceReference,
        'source_version': metadata.sourceVersion,
        'source_acquired_at': metadata.sourceAcquiredAt.toIso8601String(),
        'source_checksum': metadata.sourceChecksum,
        'schema_version': metadata.schemaVersion,
        'ingestion_tool_version': metadata.ingestionToolVersion,
        'license_or_usage_reference': metadata.licenseOrUsageReference,
        'attribution_notes': metadata.attributionNotes,
        'expected_surah_count': metadata.expectedSurahCount,
        'expected_ayah_count': metadata.expectedAyahCount,
        'dataset_kind': metadata.datasetKind.name,
      });
      for (final surah in dataset.surahs) {
        await txn.insert('surahs', {
          'number': surah.number,
          'name_arabic': surah.nameArabic,
          'ayah_count': surah.ayahCount,
        });
      }
      for (final ayah in dataset.ayahs) {
        await txn.insert('ayahs', {
          'surah_number': ayah.key.surahNumber,
          'ayah_number': ayah.key.ayahNumber,
          'global_index': ayah.globalIndex,
          'text_uthmani': ayah.textUthmani,
          'text_search': ayah.textSearch,
        });
      }
      Future<void> boundaries(String table, Iterable<dynamic> values) async {
        for (final boundary in values) {
          await txn.insert(table, {
            'number': boundary.number as int,
            'surah_number': boundary.startsAt.surahNumber as int,
            'ayah_number': boundary.startsAt.ayahNumber as int,
          });
        }
      }

      await boundaries('juz_boundaries', dataset.juz);
      await boundaries('hizb_boundaries', dataset.hizb);
      await boundaries('rub_el_hizb_boundaries', dataset.rubElHizb);
      for (var index = 0; index < dataset.sajdah.length; index++) {
        final marker = dataset.sajdah[index];
        await txn.insert('sajdah_markers', {
          'id': index + 1,
          'surah_number': marker.key.surahNumber,
          'ayah_number': marker.key.ayahNumber,
          'kind': marker.kind,
        });
      }
    });
    await QuranCoreDatabaseVerifier.verify(db);
  } finally {
    await db.close();
  }

  final databaseChecksum = await staging
      .openRead()
      .transform(sha256)
      .first
      .then((value) => value.toString());
  if (await outputDatabase.exists()) await outputDatabase.delete();
  await staging.rename(outputDatabase.path);
  final manifestData = <String, Object?>{
    'artifact': p.basename(outputDatabase.path),
    'database_sha256': databaseChecksum,
    'schema_version': QuranCoreSchema.version,
    'source_sha256': sourceChecksum,
    'source_provider': dataset.metadata.sourceProvider,
    'source_resource_name': dataset.metadata.sourceResourceName,
    'source_reference': dataset.metadata.sourceReference,
    'source_version': dataset.metadata.sourceVersion,
    'source_acquired_at': dataset.metadata.sourceAcquiredAt.toIso8601String(),
    'license_or_usage_reference': dataset.metadata.licenseOrUsageReference,
    'attribution_notes': dataset.metadata.attributionNotes,
    'ingestion_tool_version': quranCoreIngestionToolVersion,
    'dataset_kind': dataset.metadata.datasetKind.name,
  };
  final manifestStaging = File('${outputManifest.path}.staging');
  await manifestStaging.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(manifestData)}\n',
    flush: true,
  );
  if (await outputManifest.exists()) await outputManifest.delete();
  await manifestStaging.rename(outputManifest.path);
  return QuranCoreBuildResult(
    databaseChecksum: databaseChecksum,
    sourceChecksum: sourceChecksum,
  );
}

final class QuranCoreBuildResult {
  const QuranCoreBuildResult({
    required this.databaseChecksum,
    required this.sourceChecksum,
  });
  final String databaseChecksum;
  final String sourceChecksum;
}

Future<void> main(List<String> arguments) async {
  if (arguments.length < 3) {
    stderr.writeln(
      'Usage: dart run tool/quran/build_quran_core.dart <source.json> <quran_core.db> <manifest.json> [--allow-synthetic-test-fixture]',
    );
    exitCode = 64;
    return;
  }
  await buildQuranCore(
    sourceFile: File(arguments[0]),
    outputDatabase: File(arguments[1]),
    outputManifest: File(arguments[2]),
    allowSyntheticTestFixture: arguments
        .skip(3)
        .contains('--allow-synthetic-test-fixture'),
  );
}
