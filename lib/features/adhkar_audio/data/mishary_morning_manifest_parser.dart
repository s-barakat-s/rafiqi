import 'dart:convert';

import 'package:tasbeh/features/adhkar_audio/domain/dhikr_audio.dart';

class MisharyMorningManifestParser {
  const MisharyMorningManifestParser();

  DhikrReciterManifest parse({
    required String manifestJson,
    required String canonicalMorningJson,
  }) {
    final manifest = jsonDecode(manifestJson) as Map<String, dynamic>;
    final canonical = (jsonDecode(canonicalMorningJson) as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final canonicalIds = canonical
        .map((entry) => entry['id'] as String)
        .toSet();
    final reciter = manifest['reciter'] as Map<String, dynamic>;
    final collection = manifest['collection'] as Map<String, dynamic>;
    final audio = manifest['audio'] as Map<String, dynamic>;
    final sharedAudio = CollectionAudio.bundledDevelopment(
      id: '${reciter['id']}_${collection['id']}',
      bundledAssetPath: audio['assetPath'] as String,
    );
    final rawSegments = (manifest['segments'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final sequence = <DhikrAudioSegment>[];
    final logicalCardOrder = <String>[];
    final unresolved = <UnresolvedDhikrAudioSegment>[];

    for (final segment in rawSegments) {
      final step = segment['step'] as int;
      final mappingKey = segment['mappingKey'] as String;
      final dhikrId = segment['dhikrId'] as String?;
      if (dhikrId == null) {
        unresolved.add(
          UnresolvedDhikrAudioSegment(
            step: step,
            mappingKey: mappingKey,
            reason: 'Non-card narration',
          ),
        );
      } else if (!canonicalIds.contains(dhikrId)) {
        throw FormatException(
          'Unknown canonical dhikrId "$dhikrId" at manifest step $step',
        );
      } else if (!logicalCardOrder.contains(dhikrId)) {
        logicalCardOrder.add(dhikrId);
      }

      sequence.add(
        DhikrAudioSegment(
          step: step,
          mappingKey: mappingKey,
          sourceRepetition: segment['sourceRepetition'] as int?,
          source: DhikrAudioClip(
            dhikrId: dhikrId,
            collectionAudio: sharedAudio,
            start: Duration(milliseconds: segment['startMs'] as int),
            end: Duration(milliseconds: segment['endMs'] as int),
          ),
        ),
      );
    }

    return DhikrReciterManifest(
      reciter: DhikrReciter(
        id: reciter['id'] as String,
        nameAr: reciter['nameAr'] as String,
        coverage: ReciterCoverage.partial,
      ),
      collections: {
        collection['id'] as String: ReciterCollectionAudio(
          collectionId: collection['id'] as String,
          playbackSequence: List.unmodifiable(sequence),
          logicalCardOrder: List.unmodifiable(logicalCardOrder),
          unresolvedSegments: List.unmodifiable(unresolved),
        ),
      },
    );
  }
}
