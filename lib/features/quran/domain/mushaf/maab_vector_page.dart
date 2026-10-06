import 'package:meta/meta.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_models.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_rendering.dart';

enum MaabVectorPathRole { text, diacritic, dots, waqf, ayahMarker, decoration }

@immutable
final class MaabVectorPath {
  const MaabVectorPath({
    required this.data,
    required this.role,
    this.transform,
    this.lineNumber,
    this.wordKey,
    this.ayahKey,
  });

  final String data;
  final MaabVectorPathRole role;
  final String? transform;
  final int? lineNumber;
  final WordKey? wordKey;
  final AyahKey? ayahKey;

  Map<String, Object?> toJson() => {
    'd': data,
    'r': role.name,
    if (transform != null) 't': transform,
    if (lineNumber != null) 'l': lineNumber,
    if (wordKey != null) 'w': wordKey!.serialize(),
    if (ayahKey != null) 'a': ayahKey!.serialize(),
  };

  factory MaabVectorPath.fromJson(Map<String, dynamic> json) => MaabVectorPath(
    data: json['d'] as String,
    role: MaabVectorPathRole.values.byName(json['r'] as String),
    transform: json['t'] as String?,
    lineNumber: json['l'] as int?,
    wordKey: json['w'] == null ? null : WordKey.parse(json['w'] as String),
    ayahKey: json['a'] == null ? null : AyahKey.parse(json['a'] as String),
  );
}

@immutable
final class MaabVectorWord {
  const MaabVectorWord({
    required this.key,
    required this.lineNumber,
    required this.pathIndexes,
    required this.region,
    required this.sourceElementId,
  });

  final WordKey key;
  final int lineNumber;
  final List<int> pathIndexes;
  final MushafNormalizedRect region;
  final String sourceElementId;

  Map<String, Object?> toJson() => {
    'k': key.serialize(),
    'l': lineNumber,
    'p': pathIndexes,
    'b': [region.left, region.top, region.right, region.bottom],
    's': sourceElementId,
  };

  factory MaabVectorWord.fromJson(Map<String, dynamic> json) {
    final bounds = (json['b'] as List<dynamic>).cast<num>();
    return MaabVectorWord(
      key: WordKey.parse(json['k'] as String),
      lineNumber: json['l'] as int,
      pathIndexes: List.unmodifiable((json['p'] as List<dynamic>).cast<int>()),
      region: MushafNormalizedRect(
        left: bounds[0].toDouble(),
        top: bounds[1].toDouble(),
        right: bounds[2].toDouble(),
        bottom: bounds[3].toDouble(),
      ),
      sourceElementId: json['s'] as String,
    );
  }
}

@immutable
final class MaabVectorAyahRun {
  const MaabVectorAyahRun({
    required this.ayahKey,
    required this.lineNumber,
    required this.pathIndexes,
    required this.region,
  });

  final AyahKey ayahKey;
  final int lineNumber;
  final List<int> pathIndexes;
  final MushafNormalizedRect region;

  Map<String, Object?> toJson() => {
    'a': ayahKey.serialize(),
    'l': lineNumber,
    'p': pathIndexes,
    'b': [region.left, region.top, region.right, region.bottom],
  };

  factory MaabVectorAyahRun.fromJson(Map<String, dynamic> json) {
    final bounds = (json['b'] as List<dynamic>).cast<num>();
    return MaabVectorAyahRun(
      ayahKey: AyahKey.parse(json['a'] as String),
      lineNumber: json['l'] as int,
      pathIndexes: List.unmodifiable((json['p'] as List<dynamic>).cast<int>()),
      region: MushafNormalizedRect(
        left: bounds[0].toDouble(),
        top: bounds[1].toDouble(),
        right: bounds[2].toDouble(),
        bottom: bounds[3].toDouble(),
      ),
    );
  }
}

@immutable
final class MaabVectorPage {
  MaabVectorPage({
    required this.schemaVersion,
    required this.sourceVersion,
    required this.sourceChecksum,
    required this.pageKey,
    required this.viewportWidth,
    required this.viewportHeight,
    required this.lineNumbers,
    required this.paths,
    required this.words,
    required this.ayahRuns,
  }) {
    if (schemaVersion != currentSchemaVersion) {
      throw ArgumentError.value(schemaVersion, 'schemaVersion');
    }
    if (sourceVersion.trim().isEmpty || sourceChecksum.trim().isEmpty) {
      throw ArgumentError('Vector source version and checksum are required');
    }
    if (viewportWidth <= 0 || viewportHeight <= 0) {
      throw ArgumentError('Vector viewport must be positive');
    }
    if (lineNumbers.toSet().length != lineNumbers.length ||
        lineNumbers.any((line) => line < 1)) {
      throw ArgumentError('Vector line identities must be unique and positive');
    }
    for (final word in words) {
      if (!lineNumbers.contains(word.lineNumber) ||
          word.pathIndexes.isEmpty ||
          word.pathIndexes.any((index) => index < 0 || index >= paths.length)) {
        throw ArgumentError('Vector word references invalid geometry');
      }
      if (word.pathIndexes.any((index) => paths[index].wordKey != word.key)) {
        throw ArgumentError('Vector word geometry has a different WordKey');
      }
    }
  }

  static const currentSchemaVersion = 1;

  final int schemaVersion;
  final String sourceVersion;
  final String sourceChecksum;
  final MushafPageKey pageKey;
  final double viewportWidth;
  final double viewportHeight;
  final List<int> lineNumbers;
  final List<MaabVectorPath> paths;
  final List<MaabVectorWord> words;
  final List<MaabVectorAyahRun> ayahRuns;

  double get aspectRatio => viewportWidth / viewportHeight;

  ({double width, double height}) contain(double maxWidth, double maxHeight) {
    if (maxWidth <= 0 || maxHeight <= 0) {
      throw ArgumentError('Viewport constraints must be positive');
    }
    final scale = (maxWidth / viewportWidth) < (maxHeight / viewportHeight)
        ? maxWidth / viewportWidth
        : maxHeight / viewportHeight;
    return (width: viewportWidth * scale, height: viewportHeight * scale);
  }

  WordKey? hitTest(MushafNormalizedPoint point) {
    for (final word in words.reversed) {
      if (word.region.contains(point)) return word.key;
    }
    return null;
  }

  List<MaabVectorAyahRun> runsForAyah(AyahKey key) =>
      List.unmodifiable(ayahRuns.where((run) => run.ayahKey == key));

  Map<String, Object?> toJson() => {
    'schema': schemaVersion,
    'source_version': sourceVersion,
    'source_sha256': sourceChecksum,
    'page': pageKey.serialize(),
    'view': [viewportWidth, viewportHeight],
    'lines': lineNumbers,
    'paths': paths.map((path) => path.toJson()).toList(growable: false),
    'words': words.map((word) => word.toJson()).toList(growable: false),
    'ayah_runs': ayahRuns.map((run) => run.toJson()).toList(growable: false),
  };

  factory MaabVectorPage.fromJson(Map<String, dynamic> json) {
    final viewport = (json['view'] as List<dynamic>).cast<num>();
    return MaabVectorPage(
      schemaVersion: json['schema'] as int,
      sourceVersion: json['source_version'] as String,
      sourceChecksum: json['source_sha256'] as String,
      pageKey: MushafPageKey.parse(json['page'] as String),
      viewportWidth: viewport[0].toDouble(),
      viewportHeight: viewport[1].toDouble(),
      lineNumbers: List.unmodifiable(
        (json['lines'] as List<dynamic>).cast<int>(),
      ),
      paths: List.unmodifiable(
        (json['paths'] as List<dynamic>).map(
          (value) => MaabVectorPath.fromJson(value as Map<String, dynamic>),
        ),
      ),
      words: List.unmodifiable(
        (json['words'] as List<dynamic>).map(
          (value) => MaabVectorWord.fromJson(value as Map<String, dynamic>),
        ),
      ),
      ayahRuns: List.unmodifiable(
        (json['ayah_runs'] as List<dynamic>).map(
          (value) => MaabVectorAyahRun.fromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }
}
