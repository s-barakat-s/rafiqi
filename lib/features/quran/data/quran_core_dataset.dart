import 'dart:convert';

import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/models/quran_core_models.dart';

final class QuranCoreDataset {
  const QuranCoreDataset({
    required this.metadata,
    required this.surahs,
    required this.ayahs,
    this.juz = const [],
    this.hizb = const [],
    this.rubElHizb = const [],
    this.sajdah = const [],
  });

  factory QuranCoreDataset.fromSourceJson(
    String source, {
    required String sourceChecksum,
  }) {
    final root = jsonDecode(source);
    if (root is! Map<String, Object?>) {
      throw const FormatException('Quran source root must be an object');
    }
    final metadata = _map(root, 'metadata');
    final kindName = _string(metadata, 'dataset_kind');
    final kind = QuranDatasetKind.values
        .where((e) => e.name == kindName)
        .firstOrNull;
    if (kind == null) throw FormatException('Unknown dataset_kind: $kindName');
    final acquiredAt = DateTime.tryParse(
      _string(metadata, 'source_acquired_at'),
    );
    if (acquiredAt == null) {
      throw const FormatException('Invalid source_acquired_at');
    }

    AyahKey key(Map<String, Object?> row) =>
        AyahKey(_integer(row, 'surah_number'), _integer(row, 'ayah_number'));
    List<T> rows<T>(String name, T Function(Map<String, Object?>) parse) =>
        _list(
          root,
          name,
        ).map((e) => parse(_asMap(e, name))).toList(growable: false);

    return QuranCoreDataset(
      metadata: QuranCoreMetadata(
        sourceProvider: _string(metadata, 'source_provider'),
        sourceResourceName: _string(metadata, 'source_resource_name'),
        sourceReference: _string(metadata, 'source_reference'),
        sourceVersion: _string(metadata, 'source_version'),
        sourceAcquiredAt: acquiredAt.toUtc(),
        sourceChecksum: sourceChecksum,
        schemaVersion: _integer(metadata, 'schema_version'),
        ingestionToolVersion: _string(metadata, 'ingestion_tool_version'),
        licenseOrUsageReference: _string(
          metadata,
          'license_or_usage_reference',
        ),
        attributionNotes: _string(metadata, 'attribution_notes'),
        expectedSurahCount: _integer(metadata, 'expected_surah_count'),
        expectedAyahCount: _integer(metadata, 'expected_ayah_count'),
        datasetKind: kind,
      ),
      surahs: rows(
        'surahs',
        (row) => QuranSurah(
          number: _integer(row, 'number'),
          nameArabic: _string(row, 'name_arabic'),
          ayahCount: _integer(row, 'ayah_count'),
        ),
      ),
      ayahs: rows(
        'ayahs',
        (row) => QuranAyah(
          key: key(row),
          globalIndex: _integer(row, 'global_index'),
          textUthmani: _string(row, 'text_uthmani'),
          textSearch: row['text_search'] as String?,
        ),
      ),
      juz: rows(
        'juz_boundaries',
        (row) => QuranJuz(_integer(row, 'number'), key(row)),
      ),
      hizb: rows(
        'hizb_boundaries',
        (row) => QuranHizb(_integer(row, 'number'), key(row)),
      ),
      rubElHizb: rows(
        'rub_el_hizb_boundaries',
        (row) => QuranRubElHizb(_integer(row, 'number'), key(row)),
      ),
      sajdah: rows(
        'sajdah_markers',
        (row) => QuranSajdah(key: key(row), kind: _string(row, 'kind')),
      ),
    );
  }

  final QuranCoreMetadata metadata;
  final List<QuranSurah> surahs;
  final List<QuranAyah> ayahs;
  final List<QuranJuz> juz;
  final List<QuranHizb> hizb;
  final List<QuranRubElHizb> rubElHizb;
  final List<QuranSajdah> sajdah;

  static Map<String, Object?> _map(Map<String, Object?> map, String key) =>
      _asMap(map[key], key);
  static Map<String, Object?> _asMap(Object? value, String key) {
    if (value is Map<String, Object?>) return value;
    throw FormatException('$key must contain objects');
  }

  static List<Object?> _list(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is List<Object?>) return value;
    throw FormatException('$key must be a list');
  }

  static String _string(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is String) return value;
    throw FormatException('$key must be a string');
  }

  static int _integer(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is int) return value;
    throw FormatException('$key must be an integer');
  }
}

final class QuranCoreValidationException implements Exception {
  const QuranCoreValidationException(this.issues);
  final List<String> issues;
  @override
  String toString() => 'Quran Core validation failed:\n${issues.join('\n')}';
}

abstract final class QuranCoreDatasetValidator {
  static void validate(QuranCoreDataset dataset) {
    final issues = <String>[];
    final metadata = dataset.metadata;
    final requiredProvenance = <String, String>{
      'source_provider': metadata.sourceProvider,
      'source_resource_name': metadata.sourceResourceName,
      'source_reference': metadata.sourceReference,
      'source_version': metadata.sourceVersion,
      'license_or_usage_reference': metadata.licenseOrUsageReference,
      'attribution_notes': metadata.attributionNotes,
      'ingestion_tool_version': metadata.ingestionToolVersion,
    };
    for (final entry in requiredProvenance.entries) {
      if (entry.value.trim().isEmpty) issues.add('${entry.key} is required');
    }
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(metadata.sourceChecksum)) {
      issues.add('source_checksum must be a lowercase SHA-256');
    }
    if (metadata.schemaVersion < 1) {
      issues.add('schema_version must be positive');
    }
    if (metadata.datasetKind == QuranDatasetKind.production &&
        metadata.expectedSurahCount != 114) {
      issues.add('production Hafs data must declare 114 Surahs');
    }
    if (dataset.surahs.length != metadata.expectedSurahCount) {
      issues.add('Surah count does not match source convention');
    }
    if (dataset.ayahs.length != metadata.expectedAyahCount) {
      issues.add('Ayah count does not match source convention');
    }

    final surahNumbers = <int>{};
    for (final surah in dataset.surahs) {
      if (!surahNumbers.add(surah.number)) {
        issues.add('duplicate Surah ${surah.number}');
      }
      if (surah.nameArabic.trim().isEmpty) {
        issues.add('Surah ${surah.number} has no name');
      }
      if (surah.ayahCount < 1) {
        issues.add('Surah ${surah.number} has invalid Ayah count');
      }
    }
    for (var number = 1; number <= metadata.expectedSurahCount; number++) {
      if (!surahNumbers.contains(number)) issues.add('missing Surah $number');
    }

    final keys = <AyahKey>{};
    final globalIndexes = <int>{};
    final ayahsBySurah = <int, List<QuranAyah>>{};
    for (final ayah in dataset.ayahs) {
      if (!keys.add(ayah.key)) issues.add('duplicate Ayah ${ayah.key}');
      if (!globalIndexes.add(ayah.globalIndex)) {
        issues.add('duplicate global index ${ayah.globalIndex}');
      }
      if (ayah.textUthmani.trim().isEmpty) {
        issues.add('Ayah ${ayah.key} has empty canonical text');
      }
      ayahsBySurah.putIfAbsent(ayah.key.surahNumber, () => []).add(ayah);
    }
    for (var index = 1; index <= dataset.ayahs.length; index++) {
      if (!globalIndexes.contains(index)) {
        issues.add('missing global index $index');
      }
    }
    for (final surah in dataset.surahs) {
      final values = ayahsBySurah[surah.number] ?? const [];
      if (values.length != surah.ayahCount) {
        issues.add('Surah ${surah.number} Ayah count mismatch');
      }
      final numbers = values.map((e) => e.key.ayahNumber).toSet();
      for (var number = 1; number <= surah.ayahCount; number++) {
        if (!numbers.contains(number)) {
          issues.add('missing Ayah ${surah.number}:$number');
        }
      }
    }
    for (final boundary in [
      ...dataset.juz,
      ...dataset.hizb,
      ...dataset.rubElHizb,
    ]) {
      if (!keys.contains(boundary.startsAt)) {
        issues.add(
          'boundary ${boundary.number} references missing ${boundary.startsAt}',
        );
      }
    }
    for (final marker in dataset.sajdah) {
      if (!keys.contains(marker.key)) {
        issues.add('sajdah references missing ${marker.key}');
      }
      if (marker.kind.trim().isEmpty) {
        issues.add('sajdah ${marker.key} has no kind');
      }
    }
    if (issues.isNotEmpty) {
      throw QuranCoreValidationException(List.unmodifiable(issues));
    }
  }
}
