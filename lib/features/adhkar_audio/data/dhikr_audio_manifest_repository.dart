import 'package:flutter/services.dart';
import 'package:tasbeh/features/adhkar_audio/data/mishary_morning_manifest_parser.dart';
import 'package:tasbeh/features/adhkar_audio/domain/dhikr_audio.dart';

/// Rafiqi-owned normalized catalog. Audio mappings deliberately remain empty
/// until verified source URLs (and clip timestamps where relevant) are supplied.
class DhikrAudioManifestRepository {
  const DhikrAudioManifestRepository({this.manifests = seedManifests});

  static Future<DhikrAudioManifestRepository> load({
    AssetBundle? bundle,
  }) async {
    final assets = bundle ?? rootBundle;
    final manifestJson = await assets.loadString(
      'assets/data/adhkar/manifests/mishary_morning.json',
    );
    final canonicalJson = await assets.loadString(
      'assets/data/adhkar/normalized/morning.json',
    );
    final mishary = const MisharyMorningManifestParser().parse(
      manifestJson: manifestJson,
      canonicalMorningJson: canonicalJson,
    );
    return DhikrAudioManifestRepository(manifests: [...seedManifests, mishary]);
  }

  final List<DhikrReciterManifest> manifests;

  static const seedManifests = <DhikrReciterManifest>[
    DhikrReciterManifest(
      reciter: DhikrReciter(
        id: 'hamad_al_duraihim',
        nameAr: 'حمد الدريهم',
        coverage: ReciterCoverage.full,
      ),
      collections: {
        'morning': ReciterCollectionAudio(collectionId: 'morning'),
        'evening': ReciterCollectionAudio(collectionId: 'evening'),
        'after_prayer': ReciterCollectionAudio(collectionId: 'after_prayer'),
        'sleep': ReciterCollectionAudio(collectionId: 'sleep'),
      },
    ),
    DhikrReciterManifest(
      reciter: DhikrReciter(
        id: 'sulaiman_al_shuwaihi',
        nameAr: 'سليمان بن محمد الشويحي',
        coverage: ReciterCoverage.full,
      ),
      collections: {
        'morning': ReciterCollectionAudio(collectionId: 'morning'),
        'evening': ReciterCollectionAudio(collectionId: 'evening'),
        'after_prayer': ReciterCollectionAudio(collectionId: 'after_prayer'),
        'sleep': ReciterCollectionAudio(collectionId: 'sleep'),
      },
    ),
    DhikrReciterManifest(
      reciter: DhikrReciter(
        id: 'fares_abbad',
        nameAr: 'فارس عباد',
        coverage: ReciterCoverage.partial,
      ),
      collections: {'morning': ReciterCollectionAudio(collectionId: 'morning')},
    ),
    DhikrReciterManifest(
      reciter: DhikrReciter(
        id: 'waleed_abu_ziyad',
        nameAr: 'وليد أبو زياد',
        coverage: ReciterCoverage.partial,
      ),
      collections: {'evening': ReciterCollectionAudio(collectionId: 'evening')},
    ),
  ];

  List<DhikrReciter> get reciters =>
      manifests.map((manifest) => manifest.reciter).toList(growable: false);

  DhikrReciterManifest? manifestFor(String reciterId) => manifests
      .where((manifest) => manifest.reciter.id == reciterId)
      .firstOrNull;

  ReciterCollectionAudio? collectionFor(
    String reciterId,
    String collectionId,
  ) => manifestFor(reciterId)?.collection(collectionId);

  bool hasDhikr(String reciterId, String collectionId, String dhikrId) =>
      collectionFor(reciterId, collectionId)?.sourceFor(dhikrId) != null;
}
