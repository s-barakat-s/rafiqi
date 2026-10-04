import 'package:tasbeh/features/adhkar_audio/data/dhikr_audio_file_store.dart';
import 'package:tasbeh/features/adhkar_audio/data/dhikr_audio_manifest_repository.dart';
import 'package:tasbeh/features/adhkar_audio/domain/dhikr_audio.dart';

class DhikrAudioRepository {
  const DhikrAudioRepository({required this.manifests, required this.files});

  final DhikrAudioManifestRepository manifests;
  final DhikrAudioFileStore files;

  Future<ResolvedDhikrAudio?> resolve({
    required String reciterId,
    required String collectionId,
    required String dhikrId,
  }) async {
    final source = manifests
        .collectionFor(reciterId, collectionId)
        ?.sourceFor(dhikrId);
    if (source == null) return null;
    return resolveSource(
      reciterId: reciterId,
      collectionId: collectionId,
      source: source,
    );
  }

  Future<ResolvedDhikrAudio?> resolveSource({
    required String reciterId,
    required String collectionId,
    required DhikrAudioSource source,
  }) async {
    if (source.locationType == DhikrAudioLocationType.bundledDevelopmentAsset) {
      return ResolvedDhikrAudio(
        dhikrId: source.dhikrId,
        bundledAssetPath: source.bundledAssetPath,
        sourceType: source.type,
        clipStart: source is DhikrAudioClip ? source.start : null,
        clipEnd: source is DhikrAudioClip ? source.end : null,
      );
    }
    final file = await files.fileFor(
      reciterId: reciterId,
      collectionId: collectionId,
      source: source,
    );
    if (!await files.exists(
      reciterId: reciterId,
      collectionId: collectionId,
      source: source,
    )) {
      return null;
    }
    return switch (source) {
      IndividualDhikrAudio() => ResolvedDhikrAudio(
        dhikrId: source.dhikrId,
        file: file,
        sourceType: source.type,
      ),
      CollectionAudio() => ResolvedDhikrAudio(
        dhikrId: null,
        file: file,
        sourceType: source.type,
      ),
      DhikrAudioClip() => ResolvedDhikrAudio(
        dhikrId: source.dhikrId,
        file: file,
        sourceType: source.type,
        clipStart: source.start,
        clipEnd: source.end,
      ),
    };
  }
}
