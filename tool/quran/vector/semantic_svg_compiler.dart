import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/mushaf/maab_vector_page.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_models.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_rendering.dart';
import 'package:vector_graphics_compiler/vector_graphics_compiler.dart'
    show parseSvgPathData;
import 'package:xml/xml.dart';

const semanticSvgCompilerVersion = 'maab-semantic-svg-compiler/1';
const semanticSvgEditionId = 'madinah-kfgqpc-1441h-hafs';

final class SemanticSvgFormatException implements Exception {
  const SemanticSvgFormatException(this.message);
  final String message;
  @override
  String toString() => 'Semantic SVG rejected: $message';
}

final class SemanticSvgCompileResult {
  const SemanticSvgCompileResult({
    required this.page,
    required this.sourceBytes,
    required this.compiledJsonBytes,
    required this.compiledGzipBytes,
    required this.parseTime,
  });

  final MaabVectorPage page;
  final int sourceBytes;
  final int compiledJsonBytes;
  final int compiledGzipBytes;
  final Duration parseTime;
}

SemanticSvgCompileResult compileSemanticSvg({
  required List<int> sourceBytes,
  required MushafEditionId editionId,
  required int expectedPageNumber,
  required String sourceVersion,
  String? expectedSourceChecksum,
}) {
  final stopwatch = Stopwatch()..start();
  final checksum = sha256.convert(sourceBytes).toString();
  if (editionId.value != semanticSvgEditionId) {
    throw SemanticSvgFormatException(
      'resource edition is $semanticSvgEditionId, not ${editionId.value}',
    );
  }
  if (expectedSourceChecksum != null && checksum != expectedSourceChecksum) {
    throw const SemanticSvgFormatException('source checksum mismatch');
  }
  final source = utf8.decode(sourceBytes, allowMalformed: false);
  final document = XmlDocument.parse(source);
  final root = document.rootElement;
  if (root.name.local != 'svg') {
    throw const SemanticSvgFormatException('root is not svg');
  }
  if (root.getAttribute('data-md-version') != sourceVersion) {
    throw SemanticSvgFormatException(
      'source version does not match $sourceVersion',
    );
  }
  final rootId = root.getAttribute('id');
  final expectedRootId =
      'Mushaf_Page_${expectedPageNumber.toString().padLeft(3, '0')}';
  if (rootId != expectedRootId) {
    throw SemanticSvgFormatException(
      'root page ID is $rootId, expected $expectedRootId',
    );
  }
  final viewBox = _numbers(root.getAttribute('viewBox'), expected: 4);
  if (viewBox[0] != 0 ||
      viewBox[1] != 0 ||
      viewBox[2] <= 0 ||
      viewBox[3] <= 0) {
    throw const SemanticSvgFormatException('unsupported or invalid viewBox');
  }
  if (root.getAttribute('preserveAspectRatio') != 'xMidYMid meet') {
    throw const SemanticSvgFormatException(
      'page must use uniform contain scaling',
    );
  }
  final pageGroups = root.descendants
      .whereType<XmlElement>()
      .where((element) => element.getAttribute('id') == 'md-page')
      .toList();
  if (pageGroups.length != 1 ||
      int.tryParse(pageGroups.single.getAttribute('data-page-number') ?? '') !=
          expectedPageNumber) {
    throw const SemanticSvgFormatException('page wrapper identity mismatch');
  }

  final lineElements = root.descendants
      .whereType<XmlElement>()
      .where((element) => _lineId.hasMatch(element.getAttribute('id') ?? ''))
      .toList(growable: false);
  final lineNumbers = lineElements.map(_requiredLineNumber).toList();
  if (lineNumbers.length != 15 || lineNumbers.toSet().length != 15) {
    throw SemanticSvgFormatException(
      'expected 15 unique lines, found ${lineNumbers.length}',
    );
  }
  for (var index = 0; index < 15; index++) {
    if (lineNumbers[index] != index + 1) {
      throw const SemanticSvgFormatException('line order is not 1 through 15');
    }
  }

  final pathElements = root.descendants
      .whereType<XmlElement>()
      .where((element) => element.name.local == 'path')
      .toList(growable: false);
  final pathIndexes = <XmlElement, int>{};
  final paths = <MaabVectorPath>[];
  for (final element in pathElements) {
    final index = paths.length;
    pathIndexes[element] = index;
    final context = _context(element);
    final data = element.getAttribute('d');
    if (data == null || data.trim().isEmpty) {
      throw const SemanticSvgFormatException('path is missing geometry');
    }
    paths.add(
      MaabVectorPath(
        data: data,
        role: _role(element, context.ayahMarker),
        transform: _combinedTransform(element),
        lineNumber: context.lineNumber,
        wordKey: context.wordKey,
        ayahKey: context.ayahKey,
      ),
    );
  }

  final words = <MaabVectorWord>[];
  final seenWords = <WordKey>{};
  final wordElements = root.descendants.whereType<XmlElement>().where(
    (element) => _wordId.hasMatch(element.getAttribute('id') ?? ''),
  );
  for (final element in wordElements) {
    final key = _wordKey(element);
    if (!seenWords.add(key)) {
      throw SemanticSvgFormatException('duplicate source WordKey $key');
    }
    final line = _requiredLineNumber(element);
    final indexes = element.descendants
        .whereType<XmlElement>()
        .where((child) => child.name.local == 'path')
        .map((child) => pathIndexes[child]!)
        .toList(growable: false);
    if (indexes.isEmpty) {
      throw SemanticSvgFormatException('word $key has no paths');
    }
    words.add(
      MaabVectorWord(
        key: key,
        lineNumber: line,
        pathIndexes: List.unmodifiable(indexes),
        region: _regionFor(indexes, paths, viewBox[2], viewBox[3]),
        sourceElementId: element.getAttribute('id')!,
      ),
    );
  }

  final ayahRuns = <MaabVectorAyahRun>[];
  final groupedWords = <(AyahKey, int), List<MaabVectorWord>>{};
  for (final word in words) {
    groupedWords
        .putIfAbsent((word.key.ayahKey, word.lineNumber), () => [])
        .add(word);
  }
  final markerPaths = <(AyahKey, int), List<int>>{};
  for (var index = 0; index < paths.length; index++) {
    final path = paths[index];
    if (path.role == MaabVectorPathRole.ayahMarker &&
        path.ayahKey != null &&
        path.lineNumber != null) {
      markerPaths
          .putIfAbsent((path.ayahKey!, path.lineNumber!), () => [])
          .add(index);
    }
  }
  for (final entry in groupedWords.entries) {
    final indexes = <int>[
      for (final word in entry.value) ...word.pathIndexes,
      ...?markerPaths[entry.key],
    ];
    ayahRuns.add(
      MaabVectorAyahRun(
        ayahKey: entry.key.$1,
        lineNumber: entry.key.$2,
        pathIndexes: List.unmodifiable(indexes),
        region: _regionFor(indexes, paths, viewBox[2], viewBox[3]),
      ),
    );
  }

  final page = MaabVectorPage(
    schemaVersion: MaabVectorPage.currentSchemaVersion,
    sourceVersion: sourceVersion,
    sourceChecksum: checksum,
    pageKey: MushafPageKey(editionId, expectedPageNumber),
    viewportWidth: viewBox[2],
    viewportHeight: viewBox[3],
    lineNumbers: List.unmodifiable(lineNumbers),
    paths: List.unmodifiable(paths),
    words: List.unmodifiable(words),
    ayahRuns: List.unmodifiable(ayahRuns),
  );
  final jsonBytes = utf8.encode(jsonEncode(page.toJson()));
  final gzipBytes = gzip.encode(jsonBytes);
  stopwatch.stop();
  return SemanticSvgCompileResult(
    page: page,
    sourceBytes: sourceBytes.length,
    compiledJsonBytes: jsonBytes.length,
    compiledGzipBytes: gzipBytes.length,
    parseTime: stopwatch.elapsed,
  );
}

MaabVectorPage decodeCompiledVector(List<int> gzipBytes) {
  final json = jsonDecode(utf8.decode(gzip.decode(gzipBytes)));
  return MaabVectorPage.fromJson(json as Map<String, dynamic>);
}

final _lineId = RegExp(r'^md-line-\d{2}$');
final _wordId = RegExp(r'^md-word-\d{3}$');

List<double> _numbers(String? value, {required int expected}) {
  final values = value
      ?.split(RegExp(r'[\s,]+'))
      .where((part) => part.isNotEmpty)
      .map(double.tryParse)
      .toList();
  if (values == null ||
      values.length != expected ||
      values.any((value) => value == null)) {
    throw SemanticSvgFormatException(
      'expected $expected numeric values in $value',
    );
  }
  return values.cast<double>();
}

int _requiredLineNumber(XmlElement element) {
  final value = int.tryParse(element.getAttribute('data-line-number') ?? '');
  if (value == null || value < 1 || value > 15) {
    throw SemanticSvgFormatException(
      'invalid line on ${element.getAttribute('id')}',
    );
  }
  return value;
}

WordKey _wordKey(XmlElement element) {
  final surah = int.tryParse(element.getAttribute('data-surah') ?? '');
  final ayah = int.tryParse(element.getAttribute('data-aya') ?? '');
  final word = int.tryParse(
    element.getAttribute('data-word-index-in-ayah') ?? '',
  );
  if (surah == null || ayah == null || word == null) {
    throw SemanticSvgFormatException(
      'word ${element.getAttribute('id')} has malformed semantic identity',
    );
  }
  return WordKey(surah, ayah, word);
}

({int? lineNumber, WordKey? wordKey, AyahKey? ayahKey, bool ayahMarker})
_context(XmlElement path) {
  int? line;
  WordKey? word;
  AyahKey? ayah;
  var marker = false;
  for (final element in <XmlElement>[
    path,
    ...path.ancestors.whereType<XmlElement>(),
  ]) {
    final id = element.getAttribute('id') ?? '';
    if (line == null && _lineId.hasMatch(id)) {
      line = _requiredLineNumber(element);
    }
    if (word == null && _wordId.hasMatch(id)) word = _wordKey(element);
    if (id.startsWith('md-aya-mark-')) {
      marker = true;
      final surah = int.tryParse(element.getAttribute('data-surah') ?? '');
      final number = int.tryParse(element.getAttribute('data-aya') ?? '');
      if (surah == null || number == null) {
        throw const SemanticSvgFormatException(
          'ayah marker identity is malformed',
        );
      }
      ayah = AyahKey(surah, number);
    }
  }
  return (
    lineNumber: line,
    wordKey: word,
    ayahKey: ayah ?? word?.ayahKey,
    ayahMarker: marker,
  );
}

MaabVectorPathRole _role(XmlElement path, bool ayahMarker) {
  if (ayahMarker) return MaabVectorPathRole.ayahMarker;
  return switch (path.getAttribute('data-type')) {
    'text' => MaabVectorPathRole.text,
    'diacritic' => MaabVectorPathRole.diacritic,
    'dots' => MaabVectorPathRole.dots,
    'waqf' => MaabVectorPathRole.waqf,
    _ => MaabVectorPathRole.decoration,
  };
}

String? _combinedTransform(XmlElement element) {
  final transforms = <String>[];
  for (final ancestor
      in element.ancestors.whereType<XmlElement>().toList().reversed) {
    final transform = ancestor.getAttribute('transform');
    if (transform != null && transform.trim().isNotEmpty) {
      transforms.add(transform.trim());
    }
  }
  final own = element.getAttribute('transform');
  if (own != null && own.trim().isNotEmpty) transforms.add(own.trim());
  return transforms.isEmpty ? null : transforms.join(' ');
}

MushafNormalizedRect _regionFor(
  List<int> indexes,
  List<MaabVectorPath> paths,
  double width,
  double height,
) {
  var left = double.infinity;
  var top = double.infinity;
  var right = double.negativeInfinity;
  var bottom = double.negativeInfinity;
  for (final index in indexes) {
    if (paths[index].transform != null) {
      throw const SemanticSvgFormatException(
        'transformed path bounds require an explicit transform normalizer',
      );
    }
    final bounds = parseSvgPathData(paths[index].data).bounds();
    if (bounds.left < left) left = bounds.left;
    if (bounds.top < top) top = bounds.top;
    if (bounds.right > right) right = bounds.right;
    if (bounds.bottom > bottom) bottom = bounds.bottom;
  }
  double normalized(double value, double extent) =>
      (value / extent).clamp(0, 1);
  final normalizedLeft = normalized(left, width);
  final normalizedTop = normalized(top, height);
  final normalizedRight = normalized(right, width);
  final normalizedBottom = normalized(bottom, height);
  if (normalizedLeft >= normalizedRight || normalizedTop >= normalizedBottom) {
    throw const SemanticSvgFormatException('path bounds have no visible area');
  }
  return MushafNormalizedRect(
    left: normalizedLeft,
    top: normalizedTop,
    right: normalizedRight,
    bottom: normalizedBottom,
  );
}

Future<void> main(List<String> arguments) async {
  if (arguments.length != 4) {
    stderr.writeln(
      'Usage: dart run tool/quran/vector/semantic_svg_compiler.dart '
      '<source.svg> <output.mvec.gz> <edition-id> <page-number>',
    );
    exitCode = 64;
    return;
  }
  final sourceFile = File(arguments[0]);
  final outputFile = File(arguments[1]);
  final result = compileSemanticSvg(
    sourceBytes: await sourceFile.readAsBytes(),
    editionId: MushafEditionId(arguments[2]),
    expectedPageNumber: int.parse(arguments[3]),
    sourceVersion: '1.01',
  );
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsBytes(
    gzip.encode(utf8.encode(jsonEncode(result.page.toJson()))),
    flush: true,
  );
  stdout.writeln(
    jsonEncode({
      'compiler': semanticSvgCompilerVersion,
      'page': result.page.pageKey.serialize(),
      'source_bytes': result.sourceBytes,
      'compiled_json_bytes': result.compiledJsonBytes,
      'compiled_gzip_bytes': result.compiledGzipBytes,
      'paths': result.page.paths.length,
      'words': result.page.words.length,
      'ayah_runs': result.page.ayahRuns.length,
      'parse_microseconds': result.parseTime.inMicroseconds,
    }),
  );
}
