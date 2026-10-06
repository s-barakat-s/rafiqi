import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_models.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_rendering.dart';

import '../../../tool/quran/benchmark/resource_measurement.dart';
import '../../../tool/quran/vector/semantic_svg_compiler.dart';

void main() {
  group('semantic vector compiler', () {
    test('maps visible paths to WordKey and AyahKey from SVG semantics', () {
      final result = _compile(_syntheticSvg);

      expect(result.page.words.map((word) => word.key), [
        WordKey(1, 1, 1),
        WordKey(1, 1, 2),
        WordKey(1, 1, 3),
        WordKey(1, 2, 1),
      ]);
      final firstPath =
          result.page.paths[result.page.words.first.pathIndexes.first];
      expect(firstPath.wordKey, WordKey(1, 1, 1));
      expect(firstPath.ayahKey, const AyahKey(1, 1));
      expect(result.page.runsForAyah(const AyahKey(1, 1)), hasLength(2));
      expect(
        result.page.hitTest(MushafNormalizedPoint(0.15, 0.15)),
        WordKey(1, 1, 1),
      );
    });

    test('round trip preserves geometry, order, semantics, and checksum', () {
      final result = _compile(_syntheticSvg);
      final decoded = decodeCompiledVector(
        gzip.encode(utf8.encode(jsonEncode(result.page.toJson()))),
      );

      expect(jsonEncode(decoded.toJson()), jsonEncode(result.page.toJson()));
      expect(
        decoded.sourceChecksum,
        sha256.convert(utf8.encode(_syntheticSvg)).toString(),
      );
    });

    test('uniform contain scaling preserves aspect and line composition', () {
      final page = _compile(_syntheticSvg).page;
      final narrow = page.contain(320, 1000);
      final phone = page.contain(430, 900);
      final tablet = page.contain(1024, 1366);

      for (final size in [narrow, phone, tablet]) {
        expect(size.width / size.height, closeTo(page.aspectRatio, 1e-12));
      }
      expect(page.lineNumbers, List<int>.generate(15, (index) => index + 1));
      expect(page.words.map((word) => word.lineNumber), [1, 1, 2, 2]);
    });

    test('rejects malformed semantic identity', () {
      expect(
        () => _compile(
          _syntheticSvg.replaceFirst('data-word-index-in-ayah="1"', ''),
        ),
        throwsA(isA<SemanticSvgFormatException>()),
      );
    });

    test('rejects edition mismatch', () {
      expect(
        () => compileSemanticSvg(
          sourceBytes: utf8.encode(_syntheticSvg),
          editionId: MushafEditionId('another-edition'),
          expectedPageNumber: 1,
          sourceVersion: '1.01',
        ),
        throwsA(isA<SemanticSvgFormatException>()),
      );
    });

    test('rejects checksum mismatch', () {
      expect(
        () => compileSemanticSvg(
          sourceBytes: utf8.encode(_syntheticSvg),
          editionId: MushafEditionId(semanticSvgEditionId),
          expectedPageNumber: 1,
          sourceVersion: '1.01',
          expectedSourceChecksum: List.filled(64, '0').join(),
        ),
        throwsA(isA<SemanticSvgFormatException>()),
      );
    });
  });

  test('corpus measurement is deterministic', () {
    final first = measureSizes([5, 1, 9, 3]);
    final second = measureSizes([9, 3, 1, 5]);
    expect(first.toJson(), second.toJson());
    expect(first.toJson(), {
      'file_count': 4,
      'raw_bytes': 18,
      'min_bytes': 1,
      'median_bytes': 4.0,
      'p95_bytes': 9,
      'max_bytes': 9,
    });
  });
}

SemanticSvgCompileResult _compile(String source) => compileSemanticSvg(
  sourceBytes: utf8.encode(source),
  editionId: MushafEditionId(semanticSvgEditionId),
  expectedPageNumber: 1,
  sourceVersion: '1.01',
);

const _syntheticSvg = '''
<?xml version="1.0" encoding="UTF-8"?>
<svg id="Mushaf_Page_001" xmlns="http://www.w3.org/2000/svg"
  preserveAspectRatio="xMidYMid meet" viewBox="0 0 100 200"
  data-md-version="1.01">
  <title>Synthetic non-Quran vector fixture</title>
  <desc>Arbitrary rectangles used only to validate structure.</desc>
  <g id="md-page" data-page-number="001">
    <g id="md-page-inner" data-rect="0,0,100,200">
      <g id="md-line-01" data-line-number="01" data-type="text">
        <g id="md-word-001" data-surah="001" data-aya="001"
          data-line-number="01" data-word-index-in-ayah="1">
          <path id="p1" data-type="text" d="M10,20 l10,0 l0,10 l-10,0 z"/>
        </g>
        <g id="md-word-002" data-surah="001" data-aya="001"
          data-line-number="01" data-word-index-in-ayah="2">
          <path id="p2" data-type="diacritic" data-diacritic="dot"
            d="M30,20 l10,0 l0,10 l-10,0 z"/>
        </g>
      </g>
      <g id="md-line-02" data-line-number="02" data-type="text">
        <g id="md-word-003" data-surah="001" data-aya="001"
          data-line-number="02" data-word-index-in-ayah="3">
          <path id="p3" data-type="waqf" data-waqf="synthetic"
            d="M10,40 l10,0 l0,10 l-10,0 z"/>
        </g>
        <g id="md-aya-mark-004" data-surah="001" data-aya="001"
          data-line-number="02" data-type="aya-mark">
          <path id="p4" d="M25,40 l5,0 l0,5 l-5,0 z"/>
        </g>
        <g id="md-word-005" data-surah="001" data-aya="002"
          data-line-number="02" data-word-index-in-ayah="1">
          <path id="p5" data-type="text" d="M40,40 l10,0 l0,10 l-10,0 z"/>
        </g>
      </g>
      <g id="md-line-03" data-line-number="03" data-type="empty"/>
      <g id="md-line-04" data-line-number="04" data-type="empty"/>
      <g id="md-line-05" data-line-number="05" data-type="empty"/>
      <g id="md-line-06" data-line-number="06" data-type="empty"/>
      <g id="md-line-07" data-line-number="07" data-type="empty"/>
      <g id="md-line-08" data-line-number="08" data-type="empty"/>
      <g id="md-line-09" data-line-number="09" data-type="empty"/>
      <g id="md-line-10" data-line-number="10" data-type="empty"/>
      <g id="md-line-11" data-line-number="11" data-type="empty"/>
      <g id="md-line-12" data-line-number="12" data-type="empty"/>
      <g id="md-line-13" data-line-number="13" data-type="empty"/>
      <g id="md-line-14" data-line-number="14" data-type="empty"/>
      <g id="md-line-15" data-line-number="15" data-type="empty"/>
    </g>
  </g>
</svg>
''';
