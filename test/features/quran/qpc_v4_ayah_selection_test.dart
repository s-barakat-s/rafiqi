import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/core/theme/rafiqi_palette.dart';
import 'package:tasbeh/features/quran/application/mushaf/qpc_v4_tajweed_pack_source.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/models/quran_core_models.dart';
import 'package:tasbeh/features/quran/domain/mushaf/qpc_v4_tajweed_pack.dart';
import 'package:tasbeh/features/quran/presentation/qpc_v4_tajweed_reader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'geometry hit testing prioritizes words, then markers, in pack order',
    () {
      final geometry = _geometry(1);

      expect(geometry.ayahAt(const Offset(120, 520)), const AyahKey(1, 1));
      expect(geometry.ayahAt(const Offset(420, 520)), const AyahKey(1, 2));
      expect(geometry.ayahAt(const Offset(700, 1200)), isNull);

      final overlap = QpcPageGeometry(
        pageNumber: 1,
        imageWidth: 1074,
        imageHeight: 1944,
        canonicalWidth: 1074,
        canonicalHeight: 1944,
        cropOrigin: Offset.zero,
        phoneNativeLayout: true,
        wordRegions: [
          _word(WordKey(1, 3, 1), const Rect.fromLTWH(0, 0, 50, 50)),
          _word(WordKey(1, 4, 1), const Rect.fromLTWH(0, 0, 50, 50)),
        ],
        ayahMarkerRegions: const [
          QpcAyahMarkerRegion(
            key: AyahKey(1, 5),
            bounds: QpcCanonicalRect(x: 0, y: 0, width: 50, height: 50),
          ),
        ],
        ayahRegions: const [],
        visualOnlyRegions: const [],
      );
      expect(overlap.ayahAt(const Offset(10, 10)), const AyahKey(1, 3));
    },
  );

  test('non-uniform inverse transform preserves canonical hit coordinates', () {
    final transform = QpcPageTransform.fit(
      sourceRect: const Rect.fromLTWH(10, 20, 100, 200),
      viewportRect: const Rect.fromLTWH(40, 80, 300, 240),
      nonUniform: true,
    );
    const canonical = Offset(37, 141);

    expect(transform.scaleX, 3);
    expect(transform.scaleY, 1.2);
    expect(transform.toCanonical(transform.toScreen(canonical)), canonical);
  });

  testWidgets(
    'word, marker, replacement, empty tap, multiline highlight, and resize',
    (tester) async {
      final source = _FakePackSource();
      await _pumpReader(tester, source);
      final initialLoads = Map<int, int>.of(source.loadCounts);

      await _tapCanonical(tester, const Offset(120, 520));
      var painter = _visibleHighlight(tester);
      expect(painter.selected, const AyahKey(1, 1));
      expect(painter.highlightRects, hasLength(2));

      await _tapCanonical(tester, const Offset(420, 520));
      painter = _visibleHighlight(tester);
      expect(painter.selected, const AyahKey(1, 2));

      await _tapCanonical(tester, const Offset(120, 820));
      painter = _visibleHighlight(tester);
      expect(painter.selected, const AyahKey(1, 3));

      await _tapCanonical(tester, const Offset(700, 1200));
      expect(_visibleHighlight(tester).selected, isNull);
      expect(source.loadCounts, initialLoads);

      await _tapCanonical(tester, const Offset(120, 520));
      final portraitRects = _visibleHighlight(tester).highlightRects;
      await tester.binding.setSurfaceSize(const Size(800, 400));
      await tester.pumpAndSettle();
      final landscapeRects = _visibleHighlight(tester).highlightRects;
      expect(landscapeRects, hasLength(2));
      expect(landscapeRects, isNot(portraitRects));
      final expected = QpcPageTransform.fit(
        sourceRect: _displaySourceRect,
        viewportRect: const Rect.fromLTWH(0, 0, 800, 400),
        nonUniform: true,
      ).rectToScreen(const Rect.fromLTWH(75, 475, 510, 100));
      expect(landscapeRects.first, expected);
      expect(source.loadCounts, initialLoads);
    },
  );

  testWidgets(
    'changing page clears selection without reloading retained pages',
    (tester) async {
      final source = _FakePackSource();
      await _pumpReader(tester, source);
      await _tapCanonical(tester, const Offset(120, 520));
      expect(_visibleHighlight(tester).selected, const AyahKey(1, 1));
      final pageOneLoads = source.loadCounts[1];
      final pageTwoLoads = source.loadCounts[2];

      await tester.fling(find.byType(PageView), const Offset(350, 0), 1200);
      await tester.pumpAndSettle();

      expect(
        tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((paint) => paint.painter)
            .whereType<AyahHighlightPainter>()
            .every((painter) => painter.selected == null),
        isTrue,
      );
      expect(source.loadCounts[1], pageOneLoads);
      expect(source.loadCounts[2], pageTwoLoads);
    },
  );
}

const _manifest = QpcV4TajweedManifest(
  packId: 'maab.qpc_v4_tajweed.research.v1',
  researchOnly: true,
  productionApproved: false,
  pageCount: 604,
  canonicalWidth: 1074,
  canonicalHeight: 1944,
  layout: 'phone-native',
  renderFingerprint:
      'qpc-v4-tajweed-phone-native-1074x1944-generated-specials-v8-indexed-png256',
  schemaVersion: 2,
);

const _displaySourceRect = Rect.fromLTRB(0, 72, 1074, 1944);

Future<void> _pumpReader(WidgetTester tester, _FakePackSource source) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(const Size(400, 800));
  await tester.pumpWidget(
    MaterialApp(
      theme: buildRafiqiTheme(
        palette: RafiqiPalette.rafiqi,
        brightness: Brightness.light,
      ),
      home: QpcV4TajweedReader(
        source: source,
        manifest: _manifest,
        initialPageNumber: 1,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapCanonical(WidgetTester tester, Offset canonical) async {
  final transform = QpcPageTransform.fit(
    sourceRect: _displaySourceRect,
    viewportRect: const Rect.fromLTWH(0, 0, 400, 800),
    nonUniform: true,
  );
  await tester.tapAt(transform.toScreen(canonical));
  await tester.pump();
}

AyahHighlightPainter _visibleHighlight(WidgetTester tester) {
  final painters = tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((paint) => paint.painter)
      .whereType<AyahHighlightPainter>()
      .where((painter) => painter.transform.destinationRect.width > 0)
      .toList();
  return painters.firstWhere(
    (painter) => painter.selected != null,
    orElse: () => painters.first,
  );
}

QpcWordRegion _word(WordKey key, Rect rect) => QpcWordRegion(
  key: key,
  bounds: QpcCanonicalRect(
    x: rect.left,
    y: rect.top,
    width: rect.width,
    height: rect.height,
  ),
);

QpcPageGeometry _geometry(int pageNumber) => QpcPageGeometry(
  pageNumber: pageNumber,
  imageWidth: 1074,
  imageHeight: 1800,
  canonicalWidth: 1074,
  canonicalHeight: 1944,
  cropOrigin: const Offset(0, 100),
  phoneNativeLayout: true,
  wordRegions: [
    _word(WordKey(1, 1, 1), const Rect.fromLTWH(100, 500, 100, 60)),
    _word(WordKey(1, 3, 1), const Rect.fromLTWH(100, 800, 100, 60)),
  ],
  ayahMarkerRegions: const [
    QpcAyahMarkerRegion(
      key: AyahKey(1, 2),
      bounds: QpcCanonicalRect(x: 400, y: 500, width: 100, height: 60),
    ),
  ],
  ayahRegions: const [
    QpcAyahRegion(
      key: AyahKey(1, 1),
      lineBounds: [
        QpcCanonicalRect(x: 80, y: 480, width: 500, height: 90),
        QpcCanonicalRect(x: 80, y: 580, width: 500, height: 90),
      ],
    ),
    QpcAyahRegion(
      key: AyahKey(1, 2),
      lineBounds: [QpcCanonicalRect(x: 380, y: 480, width: 140, height: 90)],
    ),
    QpcAyahRegion(
      key: AyahKey(1, 3),
      lineBounds: [QpcCanonicalRect(x: 80, y: 780, width: 500, height: 90)],
    ),
  ],
  visualOnlyRegions: const [],
);

final class _FakePackSource implements QpcV4TajweedPackSource {
  final Map<int, int> loadCounts = {};

  @override
  Future<QpcV4TajweedManifest> loadManifest() async => _manifest;

  @override
  Future<QpcPreparedPage> loadPage(int pageNumber) async {
    loadCounts.update(pageNumber, (count) => count + 1, ifAbsent: () => 1);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 10, 10),
      Paint()..color = Colors.transparent,
    );
    final image = await recorder.endRecording().toImage(10, 10);
    const surah = QuranSurah(number: 1, nameArabic: 'الفاتحة', ayahCount: 7);
    return QpcPreparedPage(
      image: image,
      geometry: _geometry(pageNumber),
      primarySurah: surah,
      juzNumber: 1,
      surahs: const {1: surah},
    );
  }
}
