import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeh/features/quran/application/mushaf/default_mushaf_engine.dart';
import 'package:tasbeh/features/quran/application/mushaf/mushaf_page_index_mapper.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_models.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_rendering.dart';
import 'package:tasbeh/features/quran/domain/mushaf/resource_provenance.dart';
import 'package:tasbeh/features/quran/domain/repositories/mushaf_layout_repository.dart';

void main() {
  group('DefaultMushafEngine page preparation', () {
    test(
      'loads deterministic lines and words with semantic identity',
      () async {
        final fixture = _Fixture.approved();
        final engine = fixture.engine();
        final key = fixture.page(1);

        final prepared = await engine.preparePage(key);

        expect(prepared.key, key);
        expect(prepared.lines.map((line) => line.line.lineNumber), [1, 2]);
        expect(prepared.words.map((word) => word.wordKey), [
          WordKey(1, 1, 1),
          WordKey(1, 1, 2),
        ]);
        expect(prepared.word(WordKey(1, 1, 2))?.ayahKey, const AyahKey(1, 1));
        expect(fixture.renderer.prepareCounts[key], 1);
      },
    );

    test('rejects missing, out-of-range, and mismatched pages', () async {
      final fixture = _Fixture.approved();
      final engine = fixture.engine();
      await expectLater(
        engine.preparePage(fixture.page(6)),
        throwsA(isA<MushafPagePreparationException>()),
      );
      await expectLater(
        engine.preparePage(
          MushafPageKey(MushafEditionId('another-edition'), 1),
        ),
        throwsA(isA<MushafPagePreparationException>()),
      );
      fixture.repository.missingPages.add(3);
      await expectLater(
        engine.preparePage(fixture.page(3)),
        throwsA(isA<MushafPagePreparationException>()),
      );
    });

    test('deduplicates concurrent preparation', () async {
      final fixture = _Fixture.approved();
      fixture.renderer.delay = const Duration(milliseconds: 10);
      final engine = fixture.engine();
      final key = fixture.page(2);

      final pages = await Future.wait([
        engine.preparePage(key),
        engine.preparePage(key),
        engine.preparePage(key),
      ]);

      expect(pages.every((page) => identical(page, pages.first)), isTrue);
      expect(fixture.renderer.prepareCounts[key], 1);
    });

    test(
      'prefetches current plus or minus one with bounded eviction',
      () async {
        final fixture = _Fixture.approved();
        final engine = fixture.engine();

        await engine.prepareWindow(fixture.page(3));
        expect(engine.cachedPageCount, 3);
        expect(engine.cachedPageKeys, {
          fixture.page(2),
          fixture.page(3),
          fixture.page(4),
        });
        await engine.preparePage(fixture.page(5));
        expect(engine.cachedPageCount, 3);
        expect(engine.cachedPageKeys, isNot(contains(fixture.page(2))));
        await engine.preparePage(fixture.page(3));
        expect(fixture.renderer.prepareCounts[fixture.page(3)], 1);
      },
    );

    test('projects Ayah and Word to pages', () async {
      final fixture = _Fixture.approved();
      final engine = fixture.engine();
      expect(await engine.pageForAyah(const AyahKey(1, 2)), fixture.page(2));
      expect(await engine.pageForWord(WordKey(1, 4, 1)), fixture.page(4));
      expect(await engine.pageForWord(WordKey(1, 99, 1)), isNull);
    });
  });

  group('semantic regions', () {
    test('supports hit testing and multiple regions per Ayah', () async {
      final fixture = _Fixture.approved();
      final prepared = await fixture.engine().preparePage(fixture.page(2));

      expect(prepared.regionsForAyah(const AyahKey(1, 2)), hasLength(2));
      final hit = prepared.hitTest(MushafNormalizedPoint(0.1, 0.3));
      expect(hit?.wordKey, WordKey(1, 2, 1));
      expect(hit?.ayahKey, const AyahKey(1, 2));
      expect(prepared.hitTest(MushafNormalizedPoint(0.95, 0.95)), isNull);
    });

    test('refuses renderer output with missing semantic words', () async {
      final fixture = _Fixture.approved();
      fixture.renderer.omitLastWord = true;
      await expectLater(
        fixture.engine().preparePage(fixture.page(1)),
        throwsA(
          isA<MushafPagePreparationException>().having(
            (error) => error.message,
            'message',
            contains('word set'),
          ),
        ),
      );
    });
  });

  group('renderer activation and provenance', () {
    test('research-only resources are rejected by production engine', () async {
      final fixture = _Fixture.research();
      await expectLater(
        fixture.engine(forProduction: true).initialize(),
        throwsA(isA<MushafRendererActivationException>()),
      );
    });

    test('approved compatible resources activate production engine', () async {
      final fixture = _Fixture.approved();
      final edition = await fixture.engine().initialize();
      expect(edition.id, fixture.edition.id);
      expect(fixture.renderer.initializeCount, 1);
    });

    test('missing renderer resource fails without fallback', () async {
      final fixture = _Fixture.approved();
      fixture.renderer.resourceList.removeWhere(
        (resource) => resource.resourceId == 'synthetic-font',
      );
      await expectLater(
        fixture.engine().initialize(),
        throwsA(
          isA<MushafRendererActivationException>().having(
            (error) => error.issues.join(' '),
            'issues',
            contains('synthetic-font is missing'),
          ),
        ),
      );
      expect(fixture.renderer.initializeCount, 0);
    });

    test(
      'wrong strategy fails instead of silently changing renderer',
      () async {
        final fixture = _Fixture.approved(
          rendererStrategy: MushafRenderStrategy.pageAsset,
        );
        await expectLater(
          fixture.engine().initialize(),
          throwsA(isA<MushafRendererActivationException>()),
        );
      },
    );
  });

  group('RTL page mapping', () {
    test('maps page numbers and PageView indexes in one reversible place', () {
      final editionId = MushafEditionId('edition');
      final mapper = MushafPageIndexMapper(
        editionId: editionId,
        pageCount: 604,
      );
      expect(mapper.viewIndexFor(MushafPageKey(editionId, 1)), 603);
      expect(mapper.viewIndexFor(MushafPageKey(editionId, 604)), 0);
      expect(mapper.pageKeyForViewIndex(602).pageNumber, 2);
      expect(mapper.nextPage(MushafPageKey(editionId, 1))?.pageNumber, 2);
      expect(mapper.previousPage(MushafPageKey(editionId, 2))?.pageNumber, 1);
      expect(mapper.previousPage(MushafPageKey(editionId, 1)), isNull);
      expect(mapper.nextPage(MushafPageKey(editionId, 604)), isNull);
    });
  });
}

final class _Fixture {
  _Fixture._({
    required this.edition,
    required this.repository,
    required this.renderer,
  });

  factory _Fixture.approved({
    MushafRenderStrategy rendererStrategy = MushafRenderStrategy.qcfGlyphs,
  }) => _create(
    approval: ProductionApprovalStatus.approved,
    commercial: CommercialUseStatus.allowed,
    redistribution: RedistributionStatus.allowed,
    rendererStrategy: rendererStrategy,
  );

  factory _Fixture.research() => _create(
    approval: ProductionApprovalStatus.researchOnly,
    commercial: CommercialUseStatus.unknown,
    redistribution: RedistributionStatus.unknown,
    rendererStrategy: MushafRenderStrategy.qcfGlyphs,
  );

  static _Fixture _create({
    required ProductionApprovalStatus approval,
    required CommercialUseStatus commercial,
    required RedistributionStatus redistribution,
    required MushafRenderStrategy rendererStrategy,
  }) {
    final editionId = MushafEditionId('synthetic-engine-edition');
    QuranResourceProvenance provenance(
      String id,
      QuranResourceType type,
    ) => QuranResourceProvenance(
      resourceId: id,
      resourceType: type,
      provider: 'Maab tests',
      sourceReference: 'synthetic non-Quran test resource',
      version: '1',
      acquiredAt: DateTime.utc(2026, 10, 6),
      sourceChecksum:
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      licenseReference: 'internal synthetic tests only',
      commercialUseStatus: commercial,
      redistributionStatus: redistribution,
      attribution: 'Contains no Quran content',
      productionApprovalStatus: approval,
      compatibility: ResourceCompatibility(
        riwayahIds: const {'hafs-an-asim'},
        mushafEditionIds: {editionId.value},
        quranCoreVersions: const {'synthetic-core-1'},
      ),
    );
    final edition = MushafEdition(
      id: editionId,
      displayName: 'Synthetic engine edition',
      internalName: 'synthetic-engine-edition',
      riwayahId: RiwayahId.hafsAnAsim,
      editionVersion: '1',
      pageCount: 5,
      nominalLinesPerPage: 2,
      renderStrategy: MushafRenderStrategy.qcfGlyphs,
      layoutResourceId: 'synthetic-layout',
      scriptResourceId: 'synthetic-script',
      fontResourceId: 'synthetic-font',
      provenance: provenance(
        'synthetic-layout',
        QuranResourceType.mushafLayout,
      ),
    );
    final repository = _MemoryLayoutRepository(edition);
    final renderer = _SyntheticRenderer(
      strategy: rendererStrategy,
      resourceList: [
        provenance('synthetic-script', QuranResourceType.quranScript),
        provenance('synthetic-font', QuranResourceType.quranFont),
      ],
    );
    return _Fixture._(
      edition: edition,
      repository: repository,
      renderer: renderer,
    );
  }

  final MushafEdition edition;
  final _MemoryLayoutRepository repository;
  final _SyntheticRenderer renderer;

  MushafPageKey page(int number) => MushafPageKey(edition.id, number);

  DefaultMushafEngine engine({bool forProduction = true}) =>
      DefaultMushafEngine(
        layoutRepository: repository,
        renderer: renderer,
        forProduction: forProduction,
      );
}

final class _MemoryLayoutRepository implements MushafLayoutRepository {
  _MemoryLayoutRepository(this.edition);

  final MushafEdition edition;
  final Set<int> missingPages = {};

  MushafPageKey _page(int number) => MushafPageKey(edition.id, number);

  List<MushafWordPlacement> _placements(int page) {
    final ayah = AyahKey(1, page);
    return [
      MushafWordPlacement(
        pageKey: _page(page),
        lineNumber: 1,
        wordKey: WordKey.fromAyah(ayah, 1),
        ayahKey: ayah,
        positionInLine: 1,
        glyphCode: 'SYNTHETIC_${page}_1',
      ),
      MushafWordPlacement(
        pageKey: _page(page),
        lineNumber: 2,
        wordKey: WordKey.fromAyah(ayah, 2),
        ayahKey: ayah,
        positionInLine: 1,
        glyphCode: 'SYNTHETIC_${page}_2',
      ),
    ];
  }

  @override
  Future<MushafEdition> getEdition() async => edition;

  @override
  Future<MushafPage?> getPage(MushafPageKey key) async =>
      key.mushafId == edition.id &&
          key.pageNumber <= edition.pageCount &&
          !missingPages.contains(key.pageNumber)
      ? MushafPage(key)
      : null;

  @override
  Future<List<MushafLine>> getPageLines(MushafPageKey key) async => [
    MushafLine(
      pageKey: key,
      lineNumber: 1,
      lineType: MushafLineType.quranText,
      firstWordKey: WordKey(1, key.pageNumber, 1),
      lastWordKey: WordKey(1, key.pageNumber, 1),
    ),
    MushafLine(
      pageKey: key,
      lineNumber: 2,
      lineType: MushafLineType.quranText,
      firstWordKey: WordKey(1, key.pageNumber, 2),
      lastWordKey: WordKey(1, key.pageNumber, 2),
    ),
  ];

  @override
  Future<MushafLine?> getLine(MushafPageKey key, int lineNumber) async =>
      (await getPageLines(
        key,
      )).where((line) => line.lineNumber == lineNumber).firstOrNull;

  @override
  Future<List<MushafWordPlacement>> getWordPlacements(
    MushafPageKey key,
  ) async => _placements(key.pageNumber);

  @override
  Future<List<MushafWordPlacement>> locateAyah(AyahKey key) async =>
      key.surahNumber == 1 && key.ayahNumber <= edition.pageCount
      ? _placements(key.ayahNumber)
      : const [];

  @override
  Future<MushafWordPlacement?> locateWord(WordKey key) async =>
      (await locateAyah(
        key.ayahKey,
      )).where((placement) => placement.wordKey == key).firstOrNull;

  @override
  Future<MushafPageKey?> getPageForAyah(AyahKey key) async =>
      (await locateAyah(key)).firstOrNull?.pageKey;

  @override
  Future<MushafPageKey?> getPageForWord(WordKey key) async =>
      (await locateWord(key))?.pageKey;
}

final class _SyntheticRenderer implements MushafRendererAdapter {
  _SyntheticRenderer({required this.strategy, required this.resourceList});

  @override
  final MushafRenderStrategy strategy;
  final List<QuranResourceProvenance> resourceList;
  final Map<MushafPageKey, int> prepareCounts = {};
  int initializeCount = 0;
  bool omitLastWord = false;
  Duration delay = Duration.zero;

  @override
  List<QuranResourceProvenance> get resources => resourceList;

  @override
  Future<void> initialize(MushafEdition edition) async {
    initializeCount++;
  }

  @override
  Future<MushafRendererPage> preparePage(MushafRenderRequest request) async {
    prepareCounts.update(
      request.page.key,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    final source = omitLastWord
        ? request.placements.sublist(0, request.placements.length - 1)
        : request.placements;
    return MushafRendererPage(
      pageKey: request.page.key,
      words: source
          .map(
            (placement) => MushafRenderWord(
              wordKey: placement.wordKey,
              rendererToken: placement.glyphCode!,
              regions: [
                MushafNormalizedRect(
                  left: 0.05,
                  top: placement.lineNumber == 1 ? 0.2 : 0.5,
                  right: 0.45,
                  bottom: placement.lineNumber == 1 ? 0.4 : 0.7,
                ),
              ],
            ),
          )
          .toList(growable: false),
    );
  }
}
