import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tasbeh/features/quran/data/mushaf/mushaf_layout_dataset.dart';
import 'package:tasbeh/features/quran/data/mushaf/mushaf_layout_store.dart';
import 'package:tasbeh/features/quran/data/mushaf/sqflite_mushaf_layout_repository.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_models.dart';
import 'package:tasbeh/features/quran/domain/mushaf/resource_provenance.dart';

import '../../../tool/quran/benchmark/renderer_bakeoff.dart';
import '../../../tool/quran/build_mushaf_layout.dart';

void main() {
  group('layout validation', () {
    test('accepts ordered provider-neutral synthetic layout', () {
      final fixture = _fixture();
      expect(
        () => MushafLayoutValidator.validate(
          fixture.dataset,
          validAyahKeys: fixture.ayahs,
          validWordKeys: fixture.words,
          forProduction: false,
        ),
        returnsNormally,
      );
    });

    test(
      'rejects duplicate placements, unknown keys, and mismatched edition',
      () {
        final fixture = _fixture();
        final placement = fixture.dataset.placements.first;
        final invalid = MushafLayoutDataset(
          edition: fixture.dataset.edition,
          pages: fixture.dataset.pages,
          lines: fixture.dataset.lines,
          placements: [
            placement,
            MushafWordPlacement(
              pageKey: MushafPageKey(MushafEditionId('other-edition'), 1),
              lineNumber: 1,
              wordKey: WordKey(1, 99, 1),
              ayahKey: const AyahKey(1, 99),
              positionInLine: 1,
            ),
          ],
        );
        expect(
          () => MushafLayoutValidator.validate(
            invalid,
            validAyahKeys: fixture.ayahs,
            validWordKeys: fixture.words,
            forProduction: false,
          ),
          throwsA(
            isA<MushafLayoutValidationException>().having(
              (error) => error.issues.join(' '),
              'issues',
              allOf(
                contains('another edition'),
                contains('duplicate placement'),
                contains('unknown WordKey'),
                contains('unknown AyahKey'),
              ),
            ),
          ),
        );
      },
    );

    test('rejects non-contiguous page, line, and word ordering', () {
      final fixture = _fixture();
      final edition = fixture.dataset.edition;
      final page = MushafPageKey(edition.id, 1);
      final invalid = MushafLayoutDataset(
        edition: edition,
        pages: [MushafPage(MushafPageKey(edition.id, 2))],
        lines: [
          MushafLine(
            pageKey: page,
            lineNumber: 2,
            lineType: MushafLineType.quranText,
          ),
        ],
        placements: [
          MushafWordPlacement(
            pageKey: page,
            lineNumber: 2,
            wordKey: WordKey(1, 1, 1),
            ayahKey: const AyahKey(1, 1),
            positionInLine: 2,
          ),
        ],
      );
      expect(
        () => MushafLayoutValidator.validate(
          invalid,
          validAyahKeys: fixture.ayahs,
          validWordKeys: fixture.words,
          forProduction: false,
        ),
        throwsA(
          isA<MushafLayoutValidationException>().having(
            (error) => error.issues.join(' '),
            'issues',
            allOf(
              contains('exceeds edition page count'),
              contains('line numbering'),
              contains('word ordering'),
            ),
          ),
        ),
      );
    });

    test('provider ID cannot replace WordKey or map to two words', () {
      final fixture = _fixture();
      final duplicateProviderId = WordProviderMapping(
        wordKey: WordKey(1, 1, 2),
        provider: 'synthetic-provider',
        providerWordId: 'external-1',
        resourceVersion: '1',
      );
      final invalid = MushafLayoutDataset(
        edition: fixture.dataset.edition,
        pages: fixture.dataset.pages,
        lines: fixture.dataset.lines,
        placements: fixture.dataset.placements,
        providerMappings: [
          ...fixture.dataset.providerMappings,
          duplicateProviderId,
        ],
      );
      expect(
        () => MushafLayoutValidator.validate(
          invalid,
          validAyahKeys: fixture.ayahs,
          validWordKeys: fixture.words,
          forProduction: false,
        ),
        throwsA(
          isA<MushafLayoutValidationException>().having(
            (error) => error.issues.join(' '),
            'issues',
            contains('provider ID maps to more than one WordKey'),
          ),
        ),
      );
    });
  });

  group('layout ingestion and repository', () {
    late Directory temporary;
    late Database database;
    late SqfliteMushafLayoutRepository repository;

    setUpAll(() async {
      sqfliteFfiInit();
      temporary = await Directory.systemTemp.createTemp('maab_mushaf_layout_');
      final databaseFile = File('${temporary.path}/mushaf.db');
      await buildMushafLayout(
        sourceFile: File(
          'test/features/quran/fixtures/synthetic_mushaf_layout.json',
        ),
        outputDatabase: databaseFile,
        outputManifest: File('${temporary.path}/manifest.json'),
        allowSyntheticTestFixture: true,
      );
      database = await databaseFactoryFfi.openDatabase(
        databaseFile.path,
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
      );
      repository = SqfliteMushafLayoutRepository(database);
    });

    tearDownAll(() async {
      await database.close();
      await temporary.delete(recursive: true);
    });

    test('reads pages, lines, and words deterministically', () async {
      final edition = await repository.getEdition();
      final page = MushafPageKey(edition.id, 1);
      expect((await repository.getPage(page))?.key, page);
      expect(
        (await repository.getPageLines(page)).map((line) => line.lineNumber),
        [1, 2],
      );
      expect(
        (await repository.getWordPlacements(page)).map((word) => word.wordKey),
        [WordKey(1, 1, 1), WordKey(1, 1, 2)],
      );
    });

    test('locates Ayah and Word and rejects mismatched edition', () async {
      expect((await repository.locateAyah(const AyahKey(1, 1))).length, 2);
      expect(
        (await repository.locateWord(WordKey(1, 2, 1)))?.pageKey.pageNumber,
        2,
      );
      expect(
        (await repository.getPageForAyah(const AyahKey(1, 2)))?.pageNumber,
        2,
      );
      expect(await repository.getPageForWord(WordKey(1, 99, 1)), isNull);
      expect(
        await repository.getPage(
          MushafPageKey(MushafEditionId('other-edition'), 1),
        ),
        isNull,
      );
    });

    test('runtime storage is read-only and manifest has checksums', () async {
      expect(() => database.rawDelete('DELETE FROM pages'), throwsA(anything));
      final manifest =
          jsonDecode(
                await File('${temporary.path}/manifest.json').readAsString(),
              )
              as Map<String, dynamic>;
      expect(manifest['source_sha256'], matches(RegExp(r'^[a-f0-9]{64}$')));
      expect(manifest['database_sha256'], matches(RegExp(r'^[a-f0-9]{64}$')));
    });

    test('identical input produces byte-identical databases', () async {
      final second = await buildMushafLayout(
        sourceFile: File(
          'test/features/quran/fixtures/synthetic_mushaf_layout.json',
        ),
        outputDatabase: File('${temporary.path}/mushaf-second.db'),
        outputManifest: File('${temporary.path}/manifest-second.json'),
        allowSyntheticTestFixture: true,
      );
      final firstManifest =
          jsonDecode(
                await File('${temporary.path}/manifest.json').readAsString(),
              )
              as Map<String, dynamic>;
      expect(second.sourceChecksum, firstManifest['source_sha256']);
      expect(second.databaseChecksum, firstManifest['database_sha256']);
    });

    test('store memoizes one read-only repository', () async {
      final store = MushafLayoutStore(databaseFactory: databaseFactoryFfi);
      final first = await store.initialize(database.path);
      final second = await store.initialize(database.path);
      expect(identical(first, second), isTrue);
      await store.close();
    });
  });

  test('bake-off refuses a renderer decision without measured evidence', () {
    final source = File(
      'tool/quran/benchmark/renderer_bakeoff_pending.json',
    ).readAsStringSync();
    final result = evaluateRendererBakeoff(source);
    expect(result.candidates.map((candidate) => candidate.id).toSet(), {
      'semanticVector',
      'digitalKhatt',
      'qcfV2',
      'pageAsset',
    });
    expect(result.decisionPending, isTrue);
    final map = jsonDecode(source) as Map<String, dynamic>;
    map['selected_renderer'] = 'qcfV2';
    expect(() => evaluateRendererBakeoff(jsonEncode(map)), throwsStateError);
  });
}

({MushafLayoutDataset dataset, Set<AyahKey> ayahs, Set<WordKey> words})
_fixture() {
  final editionId = MushafEditionId('synthetic-edition');
  final provenance = QuranResourceProvenance(
    resourceId: 'synthetic-layout',
    resourceType: QuranResourceType.mushafLayout,
    provider: 'Maab tests',
    sourceReference: 'synthetic',
    version: '1',
    acquiredAt: DateTime.utc(2026, 10, 6),
    sourceChecksum:
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    licenseReference: 'synthetic only',
    commercialUseStatus: CommercialUseStatus.unknown,
    redistributionStatus: RedistributionStatus.unknown,
    attribution: 'No Quran content',
    productionApprovalStatus: ProductionApprovalStatus.researchOnly,
    compatibility: const ResourceCompatibility(
      riwayahIds: {'hafs-an-asim'},
      mushafEditionIds: {'synthetic-edition'},
    ),
  );
  final edition = MushafEdition(
    id: editionId,
    displayName: 'Synthetic',
    internalName: 'synthetic',
    riwayahId: RiwayahId.hafsAnAsim,
    editionVersion: '1',
    pageCount: 1,
    nominalLinesPerPage: 1,
    renderStrategy: MushafRenderStrategy.qcfGlyphs,
    layoutResourceId: 'synthetic-layout',
    scriptResourceId: 'synthetic-script',
    provenance: provenance,
  );
  final pageKey = MushafPageKey(editionId, 1);
  final first = WordKey(1, 1, 1);
  final second = WordKey(1, 1, 2);
  final mapping = WordProviderMapping(
    wordKey: first,
    provider: 'synthetic-provider',
    providerWordId: 'external-1',
    resourceVersion: '1',
  );
  return (
    dataset: MushafLayoutDataset(
      edition: edition,
      pages: [MushafPage(pageKey)],
      lines: [
        MushafLine(
          pageKey: pageKey,
          lineNumber: 1,
          lineType: MushafLineType.quranText,
          firstWordKey: first,
          lastWordKey: second,
        ),
      ],
      placements: [
        MushafWordPlacement(
          pageKey: pageKey,
          lineNumber: 1,
          wordKey: first,
          ayahKey: first.ayahKey,
          positionInLine: 1,
        ),
        MushafWordPlacement(
          pageKey: pageKey,
          lineNumber: 1,
          wordKey: second,
          ayahKey: second.ayahKey,
          positionInLine: 2,
        ),
      ],
      providerMappings: [mapping],
    ),
    ayahs: {const AyahKey(1, 1)},
    words: {first, second},
  );
}
