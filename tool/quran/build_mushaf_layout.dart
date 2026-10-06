import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tasbeh/features/quran/data/mushaf/mushaf_layout_dataset.dart';
import 'package:tasbeh/features/quran/data/mushaf/mushaf_layout_schema.dart';
import 'package:tasbeh/features/quran/data/mushaf/mushaf_layout_store.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_models.dart';
import 'package:tasbeh/features/quran/domain/mushaf/resource_provenance.dart';

const mushafLayoutIngestionToolVersion = 'maab-mushaf-layout-ingestion/1';

Future<MushafLayoutBuildResult> buildMushafLayout({
  required File sourceFile,
  required File outputDatabase,
  required File outputManifest,
  bool allowSyntheticTestFixture = false,
}) async {
  final bytes = await sourceFile.readAsBytes();
  final sourceChecksum = sha256.convert(bytes).toString();
  final root = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  final synthetic = root['dataset_kind'] == 'syntheticTest';
  if (synthetic && !allowSyntheticTestFixture) {
    throw StateError(
      'Synthetic fixtures require --allow-synthetic-test-fixture',
    );
  }
  if (root['ingestion_tool_version'] != mushafLayoutIngestionToolVersion) {
    throw StateError('Source requests a different ingestion tool version');
  }
  final parsed = _parse(root, sourceChecksum);
  MushafLayoutValidator.validate(
    parsed.dataset,
    validAyahKeys: parsed.validAyahKeys,
    validWordKeys: parsed.validWordKeys,
    forProduction: !synthetic,
  );

  sqfliteFfiInit();
  await outputDatabase.parent.create(recursive: true);
  await outputManifest.parent.create(recursive: true);
  final staging = File('${outputDatabase.path}.staging');
  if (await staging.exists()) await staging.delete();
  final database = await databaseFactoryFfi.openDatabase(
    staging.path,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  try {
    await database.execute('PRAGMA foreign_keys = ON');
    await database.execute('PRAGMA journal_mode = DELETE');
    for (final statement in MushafLayoutSchema.statements) {
      await database.execute(statement);
    }
    await database.transaction((txn) async {
      final edition = parsed.dataset.edition;
      final provenance = edition.provenance;
      await txn.insert('layout_metadata', {
        'id': 1,
        'mushaf_id': edition.id.value,
        'display_name': edition.displayName,
        'internal_name': edition.internalName,
        'riwayah_id': edition.riwayahId.value,
        'edition_version': edition.editionVersion,
        'page_count': edition.pageCount,
        'nominal_lines_per_page': edition.nominalLinesPerPage,
        'render_strategy': edition.renderStrategy.name,
        'layout_resource_id': edition.layoutResourceId,
        'script_resource_id': edition.scriptResourceId,
        'font_resource_id': edition.fontResourceId,
        'schema_version': MushafLayoutSchema.version,
        'resource_id': provenance.resourceId,
        'resource_type': provenance.resourceType.name,
        'provider': provenance.provider,
        'source_reference': provenance.sourceReference,
        'resource_version': provenance.version,
        'acquired_at': provenance.acquiredAt.toUtc().toIso8601String(),
        'source_checksum': provenance.sourceChecksum,
        'license_reference': provenance.licenseReference,
        'commercial_use_status': provenance.commercialUseStatus.name,
        'redistribution_status': provenance.redistributionStatus.name,
        'attribution': provenance.attribution,
        'production_approval_status': provenance.productionApprovalStatus.name,
        'quran_core_versions': jsonEncode(
          provenance.compatibility.quranCoreVersions.toList()..sort(),
        ),
      });
      for (final page in parsed.dataset.pages) {
        await txn.insert('pages', {'page_number': page.key.pageNumber});
      }
      for (final line in parsed.dataset.lines) {
        await txn.insert('lines', {
          'page_number': line.pageKey.pageNumber,
          'line_number': line.lineNumber,
          'line_type': line.lineType.name,
          'alignment': line.alignment?.name,
          'first_surah': line.firstWordKey?.surahNumber,
          'first_ayah': line.firstWordKey?.ayahNumber,
          'first_word': line.firstWordKey?.wordNumber,
          'last_surah': line.lastWordKey?.surahNumber,
          'last_ayah': line.lastWordKey?.ayahNumber,
          'last_word': line.lastWordKey?.wordNumber,
        });
      }
      for (final placement in parsed.dataset.placements) {
        await txn.insert('word_placements', {
          'page_number': placement.pageKey.pageNumber,
          'line_number': placement.lineNumber,
          'position_in_line': placement.positionInLine,
          'surah_number': placement.wordKey.surahNumber,
          'ayah_number': placement.wordKey.ayahNumber,
          'word_number': placement.wordKey.wordNumber,
          'glyph_code': placement.glyphCode,
          'provider': placement.providerMapping?.provider,
          'provider_word_id': placement.providerMapping?.providerWordId,
          'provider_resource_version':
              placement.providerMapping?.resourceVersion,
        });
      }
      for (final mapping in parsed.dataset.providerMappings) {
        await txn.insert('word_provider_mappings', {
          'provider': mapping.provider,
          'resource_version': mapping.resourceVersion,
          'provider_word_id': mapping.providerWordId,
          'surah_number': mapping.wordKey.surahNumber,
          'ayah_number': mapping.wordKey.ayahNumber,
          'word_number': mapping.wordKey.wordNumber,
        });
      }
    });
    await MushafLayoutDatabaseVerifier.verify(database);
  } finally {
    await database.close();
  }

  final databaseChecksum = await staging
      .openRead()
      .transform(sha256)
      .first
      .then((digest) => digest.toString());
  if (await outputDatabase.exists()) await outputDatabase.delete();
  await staging.rename(outputDatabase.path);
  final manifest = {
    'artifact': outputDatabase.uri.pathSegments.last,
    'database_sha256': databaseChecksum,
    'source_sha256': sourceChecksum,
    'schema_version': MushafLayoutSchema.version,
    'ingestion_tool_version': mushafLayoutIngestionToolVersion,
    'mushaf_id': parsed.dataset.edition.id.value,
    'edition_version': parsed.dataset.edition.editionVersion,
    'riwayah_id': parsed.dataset.edition.riwayahId.value,
    'production_approval_status':
        parsed.dataset.edition.provenance.productionApprovalStatus.name,
  };
  final manifestStaging = File('${outputManifest.path}.staging');
  await manifestStaging.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
    flush: true,
  );
  if (await outputManifest.exists()) await outputManifest.delete();
  await manifestStaging.rename(outputManifest.path);
  return MushafLayoutBuildResult(sourceChecksum, databaseChecksum);
}

final class MushafLayoutBuildResult {
  const MushafLayoutBuildResult(this.sourceChecksum, this.databaseChecksum);
  final String sourceChecksum;
  final String databaseChecksum;
}

final class _ParsedLayout {
  const _ParsedLayout(this.dataset, this.validAyahKeys, this.validWordKeys);
  final MushafLayoutDataset dataset;
  final Set<AyahKey> validAyahKeys;
  final Set<WordKey> validWordKeys;
}

_ParsedLayout _parse(Map<String, dynamic> root, String sourceChecksum) {
  Map<String, dynamic> map(String name) => root[name] as Map<String, dynamic>;
  List<dynamic> list(String name) => root[name] as List<dynamic>;
  final editionMap = map('edition');
  final provenanceMap = map('provenance');
  final compatibilityMap =
      provenanceMap['compatibility'] as Map<String, dynamic>;
  final editionId = MushafEditionId(editionMap['id'] as String);
  final riwayahId = RiwayahId(editionMap['riwayah_id'] as String);
  final provenance = QuranResourceProvenance(
    resourceId: provenanceMap['resource_id'] as String,
    resourceType: QuranResourceType.values.byName(
      provenanceMap['resource_type'] as String,
    ),
    provider: provenanceMap['provider'] as String,
    sourceReference: provenanceMap['source_reference'] as String,
    version: provenanceMap['version'] as String,
    acquiredAt: DateTime.parse(provenanceMap['acquired_at'] as String),
    sourceChecksum: sourceChecksum,
    licenseReference: provenanceMap['license_reference'] as String,
    commercialUseStatus: CommercialUseStatus.values.byName(
      provenanceMap['commercial_use_status'] as String,
    ),
    redistributionStatus: RedistributionStatus.values.byName(
      provenanceMap['redistribution_status'] as String,
    ),
    attribution: provenanceMap['attribution'] as String,
    productionApprovalStatus: ProductionApprovalStatus.values.byName(
      provenanceMap['production_approval_status'] as String,
    ),
    compatibility: ResourceCompatibility(
      riwayahIds: (compatibilityMap['riwayah_ids'] as List<dynamic>)
          .cast<String>()
          .toSet(),
      mushafEditionIds:
          (compatibilityMap['mushaf_edition_ids'] as List<dynamic>)
              .cast<String>()
              .toSet(),
      quranCoreVersions:
          (compatibilityMap['quran_core_versions'] as List<dynamic>)
              .cast<String>()
              .toSet(),
    ),
  );
  final edition = MushafEdition(
    id: editionId,
    displayName: editionMap['display_name'] as String,
    internalName: editionMap['internal_name'] as String,
    riwayahId: riwayahId,
    editionVersion: editionMap['edition_version'] as String,
    pageCount: editionMap['page_count'] as int,
    nominalLinesPerPage: editionMap['nominal_lines_per_page'] as int,
    renderStrategy: MushafRenderStrategy.values.byName(
      editionMap['render_strategy'] as String,
    ),
    layoutResourceId: editionMap['layout_resource_id'] as String,
    scriptResourceId: editionMap['script_resource_id'] as String,
    fontResourceId: editionMap['font_resource_id'] as String?,
    provenance: provenance,
  );
  WordKey word(Object? value) => WordKey.parse(value! as String);
  final pages = list(
    'pages',
  ).map((value) => MushafPage(MushafPageKey(editionId, value as int))).toList();
  final lines = list('lines').map((value) {
    final row = value as Map<String, dynamic>;
    return MushafLine(
      pageKey: MushafPageKey(editionId, row['page_number'] as int),
      lineNumber: row['line_number'] as int,
      lineType: MushafLineType.values.byName(row['line_type'] as String),
      alignment: row['alignment'] == null
          ? null
          : MushafLineAlignment.values.byName(row['alignment'] as String),
      firstWordKey: row['first_word_key'] == null
          ? null
          : word(row['first_word_key']),
      lastWordKey: row['last_word_key'] == null
          ? null
          : word(row['last_word_key']),
    );
  }).toList();
  WordProviderMapping? mapping(Map<String, dynamic> row, WordKey key) =>
      row['provider'] == null
      ? null
      : WordProviderMapping(
          wordKey: key,
          provider: row['provider'] as String,
          providerWordId: row['provider_word_id'] as String,
          resourceVersion: row['provider_resource_version'] as String,
        );
  final placements = list('placements').map((value) {
    final row = value as Map<String, dynamic>;
    final key = word(row['word_key']);
    return MushafWordPlacement(
      pageKey: MushafPageKey(editionId, row['page_number'] as int),
      lineNumber: row['line_number'] as int,
      wordKey: key,
      ayahKey: key.ayahKey,
      positionInLine: row['position_in_line'] as int,
      glyphCode: row['glyph_code'] as String?,
      providerMapping: mapping(row, key),
    );
  }).toList();
  final mappings = list('provider_mappings').map((value) {
    final row = value as Map<String, dynamic>;
    return WordProviderMapping(
      wordKey: word(row['word_key']),
      provider: row['provider'] as String,
      providerWordId: row['provider_word_id'] as String,
      resourceVersion: row['resource_version'] as String,
    );
  }).toList();
  final validWords = list('validated_word_keys').map(word).toSet();
  return _ParsedLayout(
    MushafLayoutDataset(
      edition: edition,
      pages: pages,
      lines: lines,
      placements: placements,
      providerMappings: mappings,
    ),
    validWords.map((key) => key.ayahKey).toSet(),
    validWords,
  );
}

Future<void> main(List<String> arguments) async {
  if (arguments.length < 3) {
    stderr.writeln(
      'Usage: dart run tool/quran/build_mushaf_layout.dart <source.json> <mushaf.db> <manifest.json> [--allow-synthetic-test-fixture]',
    );
    exitCode = 64;
    return;
  }
  await buildMushafLayout(
    sourceFile: File(arguments[0]),
    outputDatabase: File(arguments[1]),
    outputManifest: File(arguments[2]),
    allowSyntheticTestFixture: arguments
        .skip(3)
        .contains('--allow-synthetic-test-fixture'),
  );
}
