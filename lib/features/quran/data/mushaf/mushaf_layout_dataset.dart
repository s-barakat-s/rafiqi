import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_models.dart';

final class MushafLayoutDataset {
  const MushafLayoutDataset({
    required this.edition,
    required this.pages,
    required this.lines,
    required this.placements,
    this.providerMappings = const [],
  });

  final MushafEdition edition;
  final List<MushafPage> pages;
  final List<MushafLine> lines;
  final List<MushafWordPlacement> placements;
  final List<WordProviderMapping> providerMappings;
}

final class MushafLayoutValidationException implements Exception {
  const MushafLayoutValidationException(this.issues);
  final List<String> issues;
  @override
  String toString() => 'Mushaf layout validation failed:\n${issues.join('\n')}';
}

abstract final class MushafLayoutValidator {
  static void validate(
    MushafLayoutDataset dataset, {
    required Set<AyahKey> validAyahKeys,
    required Set<WordKey> validWordKeys,
    required bool forProduction,
  }) {
    final issues = <String>[];
    issues.addAll(
      dataset.edition.provenance.validate(forProduction: forProduction),
    );
    final editionId = dataset.edition.id;
    final provenance = dataset.edition.provenance;
    if (dataset.edition.layoutResourceId != provenance.resourceId) {
      issues.add('layout resource ID does not match provenance resource ID');
    }
    if (!provenance.compatibility.mushafEditionIds.contains(editionId.value)) {
      issues.add('provenance is incompatible with edition $editionId');
    }
    final pageNumbers = <int>{};
    for (final page in dataset.pages) {
      if (page.key.mushafId != editionId) {
        issues.add('page ${page.key} uses another edition');
      }
      if (page.key.pageNumber > dataset.edition.pageCount) {
        issues.add('page ${page.key.pageNumber} exceeds edition page count');
      }
      if (!pageNumbers.add(page.key.pageNumber)) {
        issues.add('duplicate page ${page.key.pageNumber}');
      }
    }
    if (pageNumbers.length != dataset.edition.pageCount) {
      issues.add('page count does not match edition');
    }
    for (var page = 1; page <= dataset.edition.pageCount; page++) {
      if (!pageNumbers.contains(page)) issues.add('missing page $page');
    }

    final lineKeys = <String>{};
    final linesByPage = <int, List<MushafLine>>{};
    for (final line in dataset.lines) {
      if (line.pageKey.mushafId != editionId) {
        issues.add('line uses another edition');
      }
      if (!pageNumbers.contains(line.pageKey.pageNumber)) {
        issues.add('line references missing page ${line.pageKey.pageNumber}');
      }
      final key = '${line.pageKey.pageNumber}:${line.lineNumber}';
      if (!lineKeys.add(key)) issues.add('duplicate line $key');
      for (final wordKey in [line.firstWordKey, line.lastWordKey]) {
        if (wordKey != null && !validWordKeys.contains(wordKey)) {
          issues.add('line $key references unknown WordKey $wordKey');
        }
      }
      linesByPage.putIfAbsent(line.pageKey.pageNumber, () => []).add(line);
    }
    for (final entry in linesByPage.entries) {
      final ordered = entry.value.map((e) => e.lineNumber).toList()..sort();
      for (var index = 0; index < ordered.length; index++) {
        if (ordered[index] != index + 1) {
          issues.add('page ${entry.key} line numbering is not contiguous');
        }
      }
    }

    final placementKeys = <String>{};
    final placedWords = <WordKey>{};
    final positionsByLine = <String, List<int>>{};
    for (final placement in dataset.placements) {
      if (placement.pageKey.mushafId != editionId) {
        issues.add('placement uses another edition');
      }
      final lineKey = '${placement.pageKey.pageNumber}:${placement.lineNumber}';
      if (!lineKeys.contains(lineKey)) {
        issues.add('placement references missing line $lineKey');
      }
      final key = '$lineKey:${placement.positionInLine}';
      if (!placementKeys.add(key)) issues.add('duplicate placement $key');
      if (!placedWords.add(placement.wordKey)) {
        issues.add('duplicate WordKey placement ${placement.wordKey}');
      }
      if (!validWordKeys.contains(placement.wordKey)) {
        issues.add('unknown WordKey ${placement.wordKey}');
      }
      if (!validAyahKeys.contains(placement.ayahKey)) {
        issues.add('unknown AyahKey ${placement.ayahKey}');
      }
      positionsByLine
          .putIfAbsent(lineKey, () => [])
          .add(placement.positionInLine);
    }
    for (final entry in positionsByLine.entries) {
      final ordered = entry.value..sort();
      for (var index = 0; index < ordered.length; index++) {
        if (ordered[index] != index + 1) {
          issues.add('line ${entry.key} word ordering is not contiguous');
        }
      }
    }

    final providerKeys = <String>{};
    final providerIds = <String>{};
    for (final mapping in dataset.providerMappings) {
      if (!validWordKeys.contains(mapping.wordKey)) {
        issues.add('mapping references unknown WordKey ${mapping.wordKey}');
      }
      final key =
          '${mapping.provider}:${mapping.resourceVersion}:${mapping.wordKey}';
      if (!providerKeys.add(key)) {
        issues.add('duplicate provider mapping for ${mapping.wordKey}');
      }
      final providerId =
          '${mapping.provider}:${mapping.resourceVersion}:${mapping.providerWordId}';
      if (!providerIds.add(providerId)) {
        issues.add('provider ID maps to more than one WordKey: $providerId');
      }
    }
    if (issues.isNotEmpty) {
      throw MushafLayoutValidationException(List.unmodifiable(issues));
    }
  }
}
