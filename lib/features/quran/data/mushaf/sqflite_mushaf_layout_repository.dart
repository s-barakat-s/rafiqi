import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_models.dart';
import 'package:tasbeh/features/quran/domain/mushaf/resource_provenance.dart';
import 'package:tasbeh/features/quran/domain/repositories/mushaf_layout_repository.dart';

final class SqfliteMushafLayoutRepository implements MushafLayoutRepository {
  SqfliteMushafLayoutRepository(this._database);
  final Database _database;
  MushafEdition? _edition;

  @override
  Future<MushafEdition> getEdition() async {
    final cached = _edition;
    if (cached != null) return cached;
    final rows = await _database.query('layout_metadata', limit: 1);
    if (rows.length != 1) throw StateError('Mushaf layout metadata is missing');
    final row = rows.single;
    final id = MushafEditionId(row['mushaf_id']! as String);
    final riwayah = RiwayahId(row['riwayah_id']! as String);
    final coreVersions =
        (jsonDecode(row['quran_core_versions']! as String) as List<dynamic>)
            .cast<String>()
            .toSet();
    final provenance = QuranResourceProvenance(
      resourceId: row['resource_id']! as String,
      resourceType: QuranResourceType.values.byName(
        row['resource_type']! as String,
      ),
      provider: row['provider']! as String,
      sourceReference: row['source_reference']! as String,
      version: row['resource_version']! as String,
      acquiredAt: DateTime.parse(row['acquired_at']! as String),
      sourceChecksum: row['source_checksum']! as String,
      licenseReference: row['license_reference']! as String,
      commercialUseStatus: CommercialUseStatus.values.byName(
        row['commercial_use_status']! as String,
      ),
      redistributionStatus: RedistributionStatus.values.byName(
        row['redistribution_status']! as String,
      ),
      attribution: row['attribution']! as String,
      productionApprovalStatus: ProductionApprovalStatus.values.byName(
        row['production_approval_status']! as String,
      ),
      compatibility: ResourceCompatibility(
        riwayahIds: {riwayah.value},
        mushafEditionIds: {id.value},
        quranCoreVersions: coreVersions,
      ),
    );
    return _edition = MushafEdition(
      id: id,
      displayName: row['display_name']! as String,
      internalName: row['internal_name']! as String,
      riwayahId: riwayah,
      editionVersion: row['edition_version']! as String,
      pageCount: row['page_count']! as int,
      nominalLinesPerPage: row['nominal_lines_per_page']! as int,
      renderStrategy: MushafRenderStrategy.values.byName(
        row['render_strategy']! as String,
      ),
      layoutResourceId: row['layout_resource_id']! as String,
      scriptResourceId: row['script_resource_id']! as String,
      fontResourceId: row['font_resource_id'] as String?,
      provenance: provenance,
    );
  }

  Future<bool> _matches(MushafPageKey key) async =>
      key.mushafId == (await getEdition()).id;

  @override
  Future<MushafPage?> getPage(MushafPageKey key) async {
    if (!await _matches(key)) return null;
    final rows = await _database.query(
      'pages',
      where: 'page_number = ?',
      whereArgs: [key.pageNumber],
      limit: 1,
    );
    return rows.isEmpty ? null : MushafPage(key);
  }

  @override
  Future<List<MushafLine>> getPageLines(MushafPageKey key) async {
    if (!await _matches(key)) return const [];
    return (await _database.query(
      'lines',
      where: 'page_number = ?',
      whereArgs: [key.pageNumber],
      orderBy: 'line_number ASC',
    )).map((row) => _line(key, row)).toList(growable: false);
  }

  @override
  Future<MushafLine?> getLine(MushafPageKey key, int lineNumber) async {
    if (lineNumber < 1 || !await _matches(key)) return null;
    final rows = await _database.query(
      'lines',
      where: 'page_number = ? AND line_number = ?',
      whereArgs: [key.pageNumber, lineNumber],
      limit: 1,
    );
    return rows.isEmpty ? null : _line(key, rows.single);
  }

  @override
  Future<List<MushafWordPlacement>> getWordPlacements(MushafPageKey key) async {
    if (!await _matches(key)) return const [];
    return (await _database.query(
      'word_placements',
      where: 'page_number = ?',
      whereArgs: [key.pageNumber],
      orderBy: 'line_number ASC, position_in_line ASC',
    )).map((row) => _placement(key, row)).toList(growable: false);
  }

  @override
  Future<List<MushafWordPlacement>> locateAyah(AyahKey key) async {
    final edition = await getEdition();
    return (await _database.query(
          'word_placements',
          where: 'surah_number = ? AND ayah_number = ?',
          whereArgs: [key.surahNumber, key.ayahNumber],
          orderBy: 'page_number ASC, line_number ASC, position_in_line ASC',
        ))
        .map(
          (row) => _placement(
            MushafPageKey(edition.id, row['page_number']! as int),
            row,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<MushafWordPlacement?> locateWord(WordKey key) async {
    final rows = await _database.query(
      'word_placements',
      where: 'surah_number = ? AND ayah_number = ? AND word_number = ?',
      whereArgs: [key.surahNumber, key.ayahNumber, key.wordNumber],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final edition = await getEdition();
    return _placement(
      MushafPageKey(edition.id, rows.single['page_number']! as int),
      rows.single,
    );
  }

  @override
  Future<MushafPageKey?> getPageForAyah(AyahKey key) async =>
      (await locateAyah(key)).firstOrNull?.pageKey;

  @override
  Future<MushafPageKey?> getPageForWord(WordKey key) async =>
      (await locateWord(key))?.pageKey;

  static MushafLine _line(MushafPageKey pageKey, Map<String, Object?> row) {
    WordKey? word(String prefix) {
      final surah = row['${prefix}_surah'] as int?;
      if (surah == null) return null;
      return WordKey(
        surah,
        row['${prefix}_ayah']! as int,
        row['${prefix}_word']! as int,
      );
    }

    final alignment = row['alignment'] as String?;
    return MushafLine(
      pageKey: pageKey,
      lineNumber: row['line_number']! as int,
      lineType: MushafLineType.values.byName(row['line_type']! as String),
      alignment: alignment == null
          ? null
          : MushafLineAlignment.values.byName(alignment),
      firstWordKey: word('first'),
      lastWordKey: word('last'),
    );
  }

  static MushafWordPlacement _placement(
    MushafPageKey pageKey,
    Map<String, Object?> row,
  ) {
    final wordKey = WordKey(
      row['surah_number']! as int,
      row['ayah_number']! as int,
      row['word_number']! as int,
    );
    final provider = row['provider'] as String?;
    return MushafWordPlacement(
      pageKey: pageKey,
      lineNumber: row['line_number']! as int,
      wordKey: wordKey,
      ayahKey: wordKey.ayahKey,
      positionInLine: row['position_in_line']! as int,
      glyphCode: row['glyph_code'] as String?,
      providerMapping: provider == null
          ? null
          : WordProviderMapping(
              wordKey: wordKey,
              provider: provider,
              providerWordId: row['provider_word_id']! as String,
              resourceVersion: row['provider_resource_version']! as String,
            ),
    );
  }
}
