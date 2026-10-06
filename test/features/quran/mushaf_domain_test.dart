import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_models.dart';
import 'package:tasbeh/features/quran/domain/mushaf/resource_provenance.dart';

void main() {
  test(
    'WordKey validates, parses, serializes, compares, and has value equality',
    () {
      final key = WordKey(2, 255, 5);
      expect(WordKey.parse('2:255:5'), key);
      expect(key.serialize(), '2:255:5');
      expect(WordKey(2, 255, 4).compareTo(key), lessThan(0));
      expect({key, WordKey(2, 255, 5)}, hasLength(1));
      expect(() => WordKey(0, 1, 1), throwsArgumentError);
      expect(() => WordKey.parse('2:255'), throwsFormatException);
    },
  );

  test('Riwayah and edition are stable, separate, and validated', () {
    final provenance = _provenance(riwayahIds: {'hafs-an-asim'});
    final edition = MushafEdition(
      id: MushafEditionId('synthetic-edition'),
      displayName: 'Synthetic edition',
      internalName: 'synthetic-edition',
      riwayahId: RiwayahId.hafsAnAsim,
      editionVersion: '1',
      pageCount: 2,
      nominalLinesPerPage: 2,
      renderStrategy: MushafRenderStrategy.qcfGlyphs,
      layoutResourceId: 'layout-test',
      scriptResourceId: 'script-test',
      provenance: provenance,
    );
    expect(edition.id.value, 'synthetic-edition');
    expect(edition.riwayahId, RiwayahId('hafs-an-asim'));
    expect(
      () => MushafEdition(
        id: MushafEditionId('bad-edition'),
        displayName: 'Bad',
        internalName: 'bad',
        riwayahId: RiwayahId('warsh-an-nafi'),
        editionVersion: '1',
        pageCount: 1,
        nominalLinesPerPage: 1,
        renderStrategy: MushafRenderStrategy.pageAsset,
        layoutResourceId: 'layout',
        scriptResourceId: 'script',
        provenance: provenance,
      ),
      throwsArgumentError,
    );
  });

  test('MushafPageKey identity includes edition and validates page', () {
    final first = MushafPageKey(MushafEditionId('edition-a'), 1);
    final otherEdition = MushafPageKey(MushafEditionId('edition-b'), 1);
    expect(MushafPageKey.parse('edition-a:1'), first);
    expect(first, isNot(otherEdition));
    expect(first.serialize(), 'edition-a:1');
    expect(
      () => MushafPageKey(MushafEditionId('edition-a'), 0),
      throwsArgumentError,
    );
    expect(() => MushafPageKey.parse('edition-a'), throwsFormatException);
  });

  test('production provenance requires explicit approval and rights', () {
    final research = _provenance(riwayahIds: {'hafs-an-asim'});
    expect(research.researchEligible, isTrue);
    expect(research.productionEligible, isFalse);
    expect(research.validate(forProduction: true), isNotEmpty);
  });
}

QuranResourceProvenance _provenance({required Set<String> riwayahIds}) =>
    QuranResourceProvenance(
      resourceId: 'synthetic-resource',
      resourceType: QuranResourceType.mushafLayout,
      provider: 'Maab tests',
      sourceReference: 'synthetic',
      version: '1',
      acquiredAt: DateTime.utc(2026, 10, 6),
      sourceChecksum:
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      licenseReference: 'synthetic test only',
      commercialUseStatus: CommercialUseStatus.unknown,
      redistributionStatus: RedistributionStatus.unknown,
      attribution: 'No Quran content',
      productionApprovalStatus: ProductionApprovalStatus.researchOnly,
      compatibility: ResourceCompatibility(riwayahIds: riwayahIds),
    );
