import 'dart:convert';
import 'dart:io';

import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_models.dart';
import 'package:tasbeh/features/quran/domain/mushaf/maab_vector_page.dart';
import 'package:vector_graphics_compiler/vector_graphics_compiler.dart'
    show encodeSvg;

import '../vector/semantic_svg_compiler.dart';
import 'resource_measurement.dart';

const _benchmarkPages = <int>[
  1,
  2,
  22,
  42,
  48,
  176,
  255,
  293,
  336,
  365,
  454,
  500,
  550,
  600,
  604,
];

Future<void> main(List<String> arguments) async {
  if (arguments.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/quran/benchmark/semantic_vector_corpus.dart '
      '<svg-directory> <compiled-directory> <report.json>',
    );
    exitCode = 64;
    return;
  }
  final sourceDirectory = Directory(arguments[0]);
  final outputDirectory = Directory(arguments[1]);
  final reportFile = File(arguments[2]);
  await outputDirectory.create(recursive: true);
  await reportFile.parent.create(recursive: true);

  final editionId = MushafEditionId(semanticSvgEditionId);
  final sourceSizes = <int>[];
  final compiledJsonSizes = <int>[];
  final compiledGzipSizes = <int>[];
  final compileMicros = <int>[];
  final decodeMicros = <int>[];
  final globalWords = <WordKey, int>{};
  var pathCount = 0;
  var wordCount = 0;
  var ayahRunCount = 0;
  var diacriticPathCount = 0;
  var waqfPathCount = 0;
  var ayahMarkerPathCount = 0;
  var decorationPathCount = 0;
  final pagesWithMultiLineAyah = <int>[];
  final pagesWithMultipleAyatOnLine = <int>[];
  final representative = <String, Object>{};

  for (var pageNumber = 1; pageNumber <= 604; pageNumber++) {
    final sourceFile = File(
      '${sourceDirectory.path}${Platform.pathSeparator}'
      '${pageNumber.toString().padLeft(3, '0')}.svg',
    );
    if (!await sourceFile.exists()) {
      throw StateError('Missing semantic SVG page $pageNumber');
    }
    final sourceBytes = await sourceFile.readAsBytes();
    final result = compileSemanticSvg(
      sourceBytes: sourceBytes,
      editionId: editionId,
      expectedPageNumber: pageNumber,
      sourceVersion: '1.01',
    );
    final encoded = gzip.encode(utf8.encode(jsonEncode(result.page.toJson())));
    final outputFile = File(
      '${outputDirectory.path}${Platform.pathSeparator}'
      '${pageNumber.toString().padLeft(3, '0')}.mvec.gz',
    );
    await outputFile.writeAsBytes(encoded, flush: true);

    final decodeWatch = Stopwatch()..start();
    final decoded = decodeCompiledVector(encoded);
    decodeWatch.stop();
    if (jsonEncode(decoded.toJson()) != jsonEncode(result.page.toJson())) {
      throw StateError('Compiled round trip changed page $pageNumber');
    }
    for (final word in result.page.words) {
      final previousPage = globalWords[word.key];
      if (previousPage != null) {
        throw StateError(
          'WordKey ${word.key} occurs on pages $previousPage and $pageNumber',
        );
      }
      globalWords[word.key] = pageNumber;
    }
    final linesByAyah = <AyahKey, Set<int>>{};
    final ayatByLine = <int, Set<AyahKey>>{};
    for (final run in result.page.ayahRuns) {
      linesByAyah.putIfAbsent(run.ayahKey, () => <int>{}).add(run.lineNumber);
      ayatByLine
          .putIfAbsent(run.lineNumber, () => <AyahKey>{})
          .add(run.ayahKey);
    }
    if (linesByAyah.values.any((lines) => lines.length > 1)) {
      pagesWithMultiLineAyah.add(pageNumber);
    }
    if (ayatByLine.values.any((ayat) => ayat.length > 1)) {
      pagesWithMultipleAyatOnLine.add(pageNumber);
    }

    sourceSizes.add(result.sourceBytes);
    compiledJsonSizes.add(result.compiledJsonBytes);
    compiledGzipSizes.add(result.compiledGzipBytes);
    compileMicros.add(result.parseTime.inMicroseconds);
    decodeMicros.add(decodeWatch.elapsedMicroseconds);
    pathCount += result.page.paths.length;
    wordCount += result.page.words.length;
    ayahRunCount += result.page.ayahRuns.length;
    for (final path in result.page.paths) {
      switch (path.role) {
        case MaabVectorPathRole.diacritic:
        case MaabVectorPathRole.dots:
          diacriticPathCount++;
        case MaabVectorPathRole.waqf:
          waqfPathCount++;
        case MaabVectorPathRole.ayahMarker:
          ayahMarkerPathCount++;
        case MaabVectorPathRole.decoration:
          decorationPathCount++;
        case MaabVectorPathRole.text:
          break;
      }
    }

    if (_benchmarkPages.contains(pageNumber)) {
      final rawRenderWatch = Stopwatch()..start();
      final vectorBytes = encodeSvg(
        xml: utf8.decode(sourceBytes),
        debugName: sourceFile.path,
        enableMaskingOptimizer: false,
        enableClippingOptimizer: false,
        enableOverdrawOptimizer: false,
      );
      rawRenderWatch.stop();
      representative['$pageNumber'] = {
        'source_bytes': sourceBytes.length,
        'semantic_compile_microseconds': result.parseTime.inMicroseconds,
        'compiled_decode_microseconds': decodeWatch.elapsedMicroseconds,
        'flutter_vector_compile_microseconds':
            rawRenderWatch.elapsedMicroseconds,
        'flutter_vec_bytes_without_semantics': vectorBytes.length,
      };
    }
    if (pageNumber % 50 == 0 || pageNumber == 604) {
      stdout.writeln('compiled $pageNumber/604');
    }
  }

  Map<String, Object> durationStats(List<int> values) {
    final measurement = measureSizes(values);
    return {
      'min_microseconds': measurement.minBytes,
      'median_microseconds': measurement.medianBytes,
      'p95_microseconds': measurement.p95Bytes,
      'max_microseconds': measurement.maxBytes,
    };
  }

  final report = <String, Object>{
    'compiler': semanticSvgCompilerVersion,
    'edition': editionId.value,
    'source_version': '1.01',
    'page_count': 604,
    'source': measureSizes(sourceSizes).toJson(),
    'compiled_json': measureSizes(compiledJsonSizes).toJson(),
    'compiled_gzip': measureSizes(compiledGzipSizes).toJson(),
    'semantic_compile_time': durationStats(compileMicros),
    'compiled_decode_time': durationStats(decodeMicros),
    'path_count': pathCount,
    'word_count': wordCount,
    'unique_word_key_count': globalWords.length,
    'ayah_run_count': ayahRunCount,
    'diacritic_or_dot_path_count': diacriticPathCount,
    'waqf_path_count': waqfPathCount,
    'ayah_marker_path_count': ayahMarkerPathCount,
    'decoration_path_count': decorationPathCount,
    'pages_with_multi_line_ayah': pagesWithMultiLineAyah,
    'pages_with_multiple_ayat_on_line': pagesWithMultipleAyatOnLine,
    'representative_pages': representative,
  };
  await reportFile.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(report)}\n',
    flush: true,
  );
  stdout.writeln(jsonEncode(report));
}
