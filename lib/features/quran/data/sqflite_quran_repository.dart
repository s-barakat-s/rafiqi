import 'package:sqflite/sqflite.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/models/quran_core_models.dart';
import 'package:tasbeh/features/quran/domain/repositories/quran_repository.dart';

final class SqfliteQuranRepository implements QuranRepository {
  const SqfliteQuranRepository(this._database);
  final Database _database;

  @override
  Future<QuranCoreMetadata> getMetadata() async {
    final rows = await _database.query('quran_metadata', limit: 1);
    if (rows.length != 1) throw StateError('Quran Core provenance is missing');
    final row = rows.single;
    return QuranCoreMetadata(
      sourceProvider: row['source_provider']! as String,
      sourceResourceName: row['source_resource_name']! as String,
      sourceReference: row['source_reference']! as String,
      sourceVersion: row['source_version']! as String,
      sourceAcquiredAt: DateTime.parse(row['source_acquired_at']! as String),
      sourceChecksum: row['source_checksum']! as String,
      schemaVersion: row['schema_version']! as int,
      ingestionToolVersion: row['ingestion_tool_version']! as String,
      licenseOrUsageReference: row['license_or_usage_reference']! as String,
      attributionNotes: row['attribution_notes']! as String,
      expectedSurahCount: row['expected_surah_count']! as int,
      expectedAyahCount: row['expected_ayah_count']! as int,
      datasetKind: QuranDatasetKind.values.byName(
        row['dataset_kind']! as String,
      ),
    );
  }

  @override
  Future<List<QuranSurah>> getSurahs() async => (await _database.query(
    'surahs',
    orderBy: 'number ASC',
  )).map(_surah).toList(growable: false);

  @override
  Future<QuranSurah?> getSurah(int surahNumber) async {
    if (surahNumber < 1 || surahNumber > 114) return null;
    final rows = await _database.query(
      'surahs',
      where: 'number = ?',
      whereArgs: [surahNumber],
      limit: 1,
    );
    return rows.isEmpty ? null : _surah(rows.single);
  }

  @override
  Future<QuranAyah?> getAyah(AyahKey key) async {
    final rows = await _database.query(
      'ayahs',
      where: 'surah_number = ? AND ayah_number = ?',
      whereArgs: [key.surahNumber, key.ayahNumber],
      limit: 1,
    );
    return rows.isEmpty ? null : _ayah(rows.single);
  }

  @override
  Future<bool> containsAyah(AyahKey key) async => await getAyah(key) != null;

  @override
  Future<List<QuranAyah>> getSurahAyahs(int surahNumber) async {
    if (surahNumber < 1 || surahNumber > 114) return const [];
    return (await _database.query(
      'ayahs',
      where: 'surah_number = ?',
      whereArgs: [surahNumber],
      orderBy: 'ayah_number ASC',
    )).map(_ayah).toList(growable: false);
  }

  @override
  Future<List<QuranAyah>> getAyahRange(AyahKey start, AyahKey end) async {
    final startIndex = await resolveGlobalAyahIndex(start);
    final endIndex = await resolveGlobalAyahIndex(end);
    if (startIndex == null || endIndex == null) return const [];
    if (startIndex > endIndex) {
      throw ArgumentError.value(end, 'end', 'must not precede start');
    }
    return (await _database.query(
      'ayahs',
      where: 'global_index BETWEEN ? AND ?',
      whereArgs: [startIndex, endIndex],
      orderBy: 'global_index ASC',
    )).map(_ayah).toList(growable: false);
  }

  @override
  Future<int?> resolveGlobalAyahIndex(AyahKey key) async {
    final rows = await _database.query(
      'ayahs',
      columns: ['global_index'],
      where: 'surah_number = ? AND ayah_number = ?',
      whereArgs: [key.surahNumber, key.ayahNumber],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single['global_index']! as int;
  }

  @override
  Future<QuranJuz?> getJuz(int number) =>
      _boundary('juz_boundaries', number, QuranJuz.new);
  @override
  Future<QuranHizb?> getHizb(int number) =>
      _boundary('hizb_boundaries', number, QuranHizb.new);
  @override
  Future<QuranRubElHizb?> getRubElHizb(int number) =>
      _boundary('rub_el_hizb_boundaries', number, QuranRubElHizb.new);

  Future<T?> _boundary<T extends QuranBoundary>(
    String table,
    int number,
    T Function(int, AyahKey) create,
  ) async {
    if (number < 1) return null;
    final rows = await _database.query(
      table,
      where: 'number = ?',
      whereArgs: [number],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    return create(
      number,
      AyahKey(row['surah_number']! as int, row['ayah_number']! as int),
    );
  }

  @override
  Future<List<QuranSajdah>> getSajdahMarkers() async =>
      (await _database.query('sajdah_markers', orderBy: 'id ASC'))
          .map(
            (row) => QuranSajdah(
              key: AyahKey(
                row['surah_number']! as int,
                row['ayah_number']! as int,
              ),
              kind: row['kind']! as String,
            ),
          )
          .toList(growable: false);

  static QuranSurah _surah(Map<String, Object?> row) => QuranSurah(
    number: row['number']! as int,
    nameArabic: row['name_arabic']! as String,
    ayahCount: row['ayah_count']! as int,
  );

  static QuranAyah _ayah(Map<String, Object?> row) => QuranAyah(
    key: AyahKey(row['surah_number']! as int, row['ayah_number']! as int),
    globalIndex: row['global_index']! as int,
    textUthmani: row['text_uthmani']! as String,
    textSearch: row['text_search'] as String?,
  );
}
