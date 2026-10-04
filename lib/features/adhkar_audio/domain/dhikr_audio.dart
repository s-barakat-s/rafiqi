import 'dart:io';

enum ReciterCoverage { full, partial }

enum DhikrAudioSourceType {
  individualTrack,
  collectionRecording,
  collectionClip,
}

enum DhikrPlayAllStrategy { sequentialSources, continuousRecording }

enum DhikrSegmentRepeatPolicy { recordedOnly, reuseForCanonicalCount }

enum DhikrAudioLocationType { remoteDownload, bundledDevelopmentAsset }

enum DhikrPlaybackMode { listen, repeatAfterMe }

enum DhikrPlaybackStatus { stopped, playing, paused }

enum DhikrPlaybackPhase { listening, repeatSilence }

enum AudioDownloadStatus {
  notDownloaded,
  queued,
  downloading,
  downloaded,
  failed,
}

class DhikrReciter {
  const DhikrReciter({
    required this.id,
    required this.nameAr,
    required this.coverage,
  });

  final String id;
  final String nameAr;
  final ReciterCoverage coverage;
}

sealed class DhikrAudioSource {
  const DhikrAudioSource({required this.dhikrId});

  final String? dhikrId;
  DhikrAudioSourceType get type;
  String get assetId;
  DhikrAudioLocationType get locationType;
  String? get remoteUrl;
  String? get bundledAssetPath;
  int? get expectedSizeBytes;
}

class IndividualDhikrAudio extends DhikrAudioSource {
  const IndividualDhikrAudio({
    required String dhikrId,
    required this.remoteUrl,
    this.expectedSizeBytes,
  }) : super(dhikrId: dhikrId);

  @override
  final String remoteUrl;
  @override
  String? get bundledAssetPath => null;
  @override
  DhikrAudioLocationType get locationType =>
      DhikrAudioLocationType.remoteDownload;
  @override
  final int? expectedSizeBytes;
  @override
  DhikrAudioSourceType get type => DhikrAudioSourceType.individualTrack;
  @override
  String get assetId => dhikrId!;
}

class CollectionAudio extends DhikrAudioSource {
  const CollectionAudio({
    required this.id,
    required this.remoteUrl,
    this.expectedSizeBytes,
  }) : bundledAssetPath = null,
       super(dhikrId: null);

  const CollectionAudio.bundledDevelopment({
    required this.id,
    required this.bundledAssetPath,
  }) : remoteUrl = null,
       expectedSizeBytes = null,
       super(dhikrId: null);

  final String id;
  @override
  final String? remoteUrl;
  @override
  final String? bundledAssetPath;
  @override
  final int? expectedSizeBytes;

  @override
  String get assetId => id;
  @override
  DhikrAudioSourceType get type => DhikrAudioSourceType.collectionRecording;
  @override
  DhikrAudioLocationType get locationType => bundledAssetPath == null
      ? DhikrAudioLocationType.remoteDownload
      : DhikrAudioLocationType.bundledDevelopmentAsset;
}

class DhikrAudioClip extends DhikrAudioSource {
  const DhikrAudioClip({
    required super.dhikrId,
    required this.collectionAudio,
    required this.start,
    required this.end,
  }) : assert(end > start);

  final CollectionAudio collectionAudio;
  final Duration start;
  final Duration end;

  @override
  String get assetId => collectionAudio.id;
  @override
  String? get remoteUrl => collectionAudio.remoteUrl;
  @override
  String? get bundledAssetPath => collectionAudio.bundledAssetPath;
  @override
  DhikrAudioLocationType get locationType => collectionAudio.locationType;
  @override
  int? get expectedSizeBytes => collectionAudio.expectedSizeBytes;
  @override
  DhikrAudioSourceType get type => DhikrAudioSourceType.collectionClip;
}

class ReciterCollectionAudio {
  const ReciterCollectionAudio({
    required this.collectionId,
    this.playAllStrategy = DhikrPlayAllStrategy.sequentialSources,
    this.continuousSource,
    this.sources = const [],
    this.playbackSequence = const [],
    this.logicalCardOrder = const [],
    this.unresolvedSegments = const [],
  }) : assert(
         playAllStrategy != DhikrPlayAllStrategy.continuousRecording ||
             continuousSource != null,
       );

  final String collectionId;
  final DhikrPlayAllStrategy playAllStrategy;
  final CollectionAudio? continuousSource;
  final List<DhikrAudioSource> sources;
  final List<DhikrAudioSegment> playbackSequence;
  final List<String> logicalCardOrder;
  final List<UnresolvedDhikrAudioSegment> unresolvedSegments;

  Iterable<DhikrAudioSource> get allSources sync* {
    if (continuousSource != null) yield continuousSource!;
    yield* sources;
    for (final segment in playbackSequence) {
      yield segment.source;
    }
  }

  bool get hasMappedAudio => allSources.any((source) => source.dhikrId != null);
  bool get isBundledDevelopment => allSources.any(
    (source) =>
        source.locationType == DhikrAudioLocationType.bundledDevelopmentAsset,
  );
  DhikrAudioSource? sourceFor(String dhikrId) =>
      allSources.where((source) => source.dhikrId == dhikrId).firstOrNull;

  List<DhikrAudioSource> get uniqueAssets {
    final seen = <String>{};
    return [
      for (final source in allSources)
        if (seen.add(source.assetId)) source,
    ];
  }
}

class DhikrAudioSegment {
  const DhikrAudioSegment({
    required this.step,
    required this.mappingKey,
    required this.source,
    this.sourceRepetition,
    this.repeatPolicy = DhikrSegmentRepeatPolicy.recordedOnly,
  });

  final int step;
  final String mappingKey;
  final DhikrAudioSource source;
  final int? sourceRepetition;
  final DhikrSegmentRepeatPolicy repeatPolicy;
}

class UnresolvedDhikrAudioSegment {
  const UnresolvedDhikrAudioSegment({
    required this.step,
    required this.mappingKey,
    required this.reason,
  });

  final int step;
  final String mappingKey;
  final String reason;
}

class DhikrReciterManifest {
  const DhikrReciterManifest({
    required this.reciter,
    this.collections = const {},
  });

  final DhikrReciter reciter;
  final Map<String, ReciterCollectionAudio> collections;

  ReciterCollectionAudio? collection(String id) => collections[id];
}

class ResolvedDhikrAudio {
  const ResolvedDhikrAudio({
    required this.dhikrId,
    required this.sourceType,
    this.file,
    this.bundledAssetPath,
    this.clipStart,
    this.clipEnd,
  }) : assert(file != null || bundledAssetPath != null);

  final String? dhikrId;
  final File? file;
  final String? bundledAssetPath;
  final DhikrAudioSourceType sourceType;
  final Duration? clipStart;
  final Duration? clipEnd;

  Duration? get clipDuration =>
      clipStart == null || clipEnd == null ? null : clipEnd! - clipStart!;
}

class AudioDownloadSnapshot {
  const AudioDownloadSnapshot({
    this.status = AudioDownloadStatus.notDownloaded,
    this.progress = 0,
    this.isAvailable = true,
    this.isBundledDevelopment = false,
  });

  final AudioDownloadStatus status;
  final double progress;
  final bool isAvailable;
  final bool isBundledDevelopment;
}
