import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar_audio/application/audio_playback_adapter.dart';
import 'package:tasbeh/features/adhkar_audio/application/dhikr_audio_controller.dart';
import 'package:tasbeh/features/adhkar_audio/application/dhikr_audio_download_controller.dart';
import 'package:tasbeh/features/adhkar_audio/data/dhikr_audio_file_store.dart';
import 'package:tasbeh/features/adhkar_audio/data/dhikr_audio_manifest_repository.dart';
import 'package:tasbeh/features/adhkar_audio/data/dhikr_audio_repository.dart';
import 'package:tasbeh/features/adhkar_audio/domain/dhikr_audio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late DhikrAudioFileStore files;
  late DhikrAudioManifestRepository manifests;
  late ReciterCollectionAudio collection;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    root = await Directory.systemTemp.createTemp('rafiqi_audio_test_');
    files = DhikrAudioFileStore(rootProvider: () async => root);
    collection = const ReciterCollectionAudio(
      collectionId: 'morning',
      sources: [
        IndividualDhikrAudio(
          dhikrId: 'd1',
          remoteUrl: 'https://example.invalid/d1.mp3',
        ),
        IndividualDhikrAudio(
          dhikrId: 'd2',
          remoteUrl: 'https://example.invalid/d2.mp3',
        ),
      ],
    );
    manifests = DhikrAudioManifestRepository(
      manifests: [
        DhikrReciterManifest(
          reciter: const DhikrReciter(
            id: 'full',
            nameAr: 'قارئ كامل',
            coverage: ReciterCoverage.full,
          ),
          collections: {'morning': collection},
        ),
        const DhikrReciterManifest(
          reciter: DhikrReciter(
            id: 'partial',
            nameAr: 'قارئ جزئي',
            coverage: ReciterCoverage.partial,
          ),
          collections: {},
        ),
      ],
    );
    for (final source in collection.sources) {
      final file = await files.fileFor(
        reciterId: 'full',
        collectionId: 'morning',
        source: source,
      );
      await file.create(recursive: true);
      await file.writeAsBytes([1]);
    }
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('fresh install has no downloaded audio', () async {
    final empty = await Directory.systemTemp.createTemp('rafiqi_empty_');
    addTearDown(() => empty.delete(recursive: true));
    final emptyStore = DhikrAudioFileStore(rootProvider: () async => empty);
    expect(
      await emptyStore.isCollectionDownloaded(
        reciterId: 'full',
        collection: collection,
      ),
      isFalse,
    );
  });

  test('downloaded state requires every real local file', () async {
    expect(
      await files.isCollectionDownloaded(
        reciterId: 'full',
        collection: collection,
      ),
      isTrue,
    );
    await (await files.fileFor(
      reciterId: 'full',
      collectionId: 'morning',
      source: collection.sources.last,
    )).delete();
    expect(
      await files.isCollectionDownloaded(
        reciterId: 'full',
        collection: collection,
      ),
      isFalse,
    );
  });

  test('manual single playback ignores canonical repeatCount', () async {
    final harness = await _harness(manifests, files);
    await harness.controller.playOne(
      collectionId: 'morning',
      item: _item('d1', repeats: 3),
    );
    await _waitFor(() => harness.player.playedIds.isNotEmpty);
    expect(harness.player.playedIds, ['d1']);
    harness.player.completeCurrent(const Duration(milliseconds: 5));
    await _waitFor(
      () => harness.controller.status == DhikrPlaybackStatus.stopped,
    );
    expect(harness.player.playedIds, ['d1']);
    expect(harness.controller.status, DhikrPlaybackStatus.stopped);
  });

  test('repeatAfterMe alternates audio then silence', () async {
    final harness = await _harness(manifests, files);
    await harness.controller.playAll(
      collectionId: 'morning',
      items: [_item('d1'), _item('d2')],
      playbackMode: DhikrPlaybackMode.repeatAfterMe,
    );
    await _waitFor(() => harness.player.playedIds.isNotEmpty);
    harness.player.completeCurrent(const Duration(milliseconds: 20));
    await _waitFor(
      () => harness.controller.phase == DhikrPlaybackPhase.repeatSilence,
    );
    expect(harness.controller.phase, DhikrPlaybackPhase.repeatSilence);
    expect(harness.player.playedIds.length, 1);
    await Future<void>.delayed(const Duration(milliseconds: 25));
    await _waitFor(() => harness.player.playedIds.length == 2);
    expect(harness.player.playedIds, ['d1', 'd2']);
  });

  test('repeat silence duration equals logical clip duration', () async {
    final clipCollection = ReciterCollectionAudio(
      collectionId: 'morning',
      sources: [
        DhikrAudioClip(
          dhikrId: 'd1',
          collectionAudio: const CollectionAudio(
            id: 'chapter',
            remoteUrl: 'https://example.invalid/chapter.mp3',
          ),
          start: const Duration(seconds: 2),
          end: const Duration(seconds: 2, milliseconds: 30),
        ),
      ],
    );
    final clipManifests = DhikrAudioManifestRepository(
      manifests: [
        DhikrReciterManifest(
          reciter: manifests.reciters.first,
          collections: {'morning': clipCollection},
        ),
      ],
    );
    final file = await files.fileFor(
      reciterId: 'full',
      collectionId: 'morning',
      source: clipCollection.sources.single,
    );
    await file.create(recursive: true);
    await file.writeAsBytes([1]);
    final harness = await _harness(clipManifests, files);
    await harness.controller.playOne(
      collectionId: 'morning',
      item: _item('d1', repeats: 2),
      playbackMode: DhikrPlaybackMode.repeatAfterMe,
    );
    await _waitFor(() => harness.player.playedIds.isNotEmpty);
    harness.player.completeCurrent(const Duration(seconds: 99));
    await _waitFor(
      () => harness.controller.phase == DhikrPlaybackPhase.repeatSilence,
    );
    expect(harness.controller.duration, const Duration(milliseconds: 30));
    await Future<void>.delayed(const Duration(milliseconds: 15));
    expect(harness.player.playedIds.length, 1);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await _waitFor(
      () => harness.controller.status == DhikrPlaybackStatus.stopped,
    );
    expect(harness.player.playedIds.length, 1);
  });

  test('stop during repeat silence cancels progression', () async {
    final harness = await _harness(manifests, files);
    await harness.controller.playOne(
      collectionId: 'morning',
      item: _item('d1', repeats: 2),
      playbackMode: DhikrPlaybackMode.repeatAfterMe,
    );
    await _waitFor(() => harness.player.playedIds.isNotEmpty);
    harness.player.completeCurrent(const Duration(milliseconds: 20));
    await _waitFor(
      () => harness.controller.phase == DhikrPlaybackPhase.repeatSilence,
    );
    await harness.controller.stop();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(harness.player.playedIds, ['d1']);
    expect(harness.controller.status, DhikrPlaybackStatus.stopped);
  });

  test('skipping during repeat silence starts the next dhikr', () async {
    final harness = await _harness(manifests, files);
    await harness.controller.playAll(
      collectionId: 'morning',
      items: [_item('d1'), _item('d2')],
      playbackMode: DhikrPlaybackMode.repeatAfterMe,
    );
    await _waitFor(() => harness.player.playedIds.isNotEmpty);
    harness.player.completeCurrent(const Duration(milliseconds: 40));
    await _waitFor(
      () => harness.controller.phase == DhikrPlaybackPhase.repeatSilence,
    );
    await harness.controller.skip();
    await _waitFor(() => harness.player.playedIds.length == 2);
    expect(harness.player.playedIds, ['d1', 'd2']);
    expect(harness.controller.currentDhikrId, 'd2');
  });

  test('changing reciter stops stale playback', () async {
    final harness = await _harness(manifests, files);
    await harness.controller.playOne(
      collectionId: 'morning',
      item: _item('d1'),
    );
    await _waitFor(() => harness.player.playedIds.isNotEmpty);
    await harness.controller.selectReciter('partial');
    expect(harness.controller.status, DhikrPlaybackStatus.stopped);
    expect(harness.controller.currentDhikrId, isNull);
  });

  test('partial reciter coverage is handled safely', () async {
    final repository = DhikrAudioRepository(manifests: manifests, files: files);
    expect(
      await repository.resolve(
        reciterId: 'partial',
        collectionId: 'morning',
        dhikrId: 'd1',
      ),
      isNull,
    );
  });

  test('collection clip resolves the correct start and end range', () async {
    final clip = DhikrAudioClip(
      dhikrId: 'd1',
      collectionAudio: CollectionAudio(
        id: 'chapter',
        remoteUrl: 'https://example.invalid/chapter.mp3',
      ),
      start: Duration(seconds: 4),
      end: Duration(seconds: 11),
    );
    final clipCollection = ReciterCollectionAudio(
      collectionId: 'morning',
      sources: [clip],
    );
    final clipManifests = DhikrAudioManifestRepository(
      manifests: [
        DhikrReciterManifest(
          reciter: manifests.reciters.first,
          collections: {'morning': clipCollection},
        ),
      ],
    );
    final clipFile = await files.fileFor(
      reciterId: 'full',
      collectionId: 'morning',
      source: clip,
    );
    await clipFile.create(recursive: true);
    await clipFile.writeAsBytes([1]);
    final resolved = await DhikrAudioRepository(
      manifests: clipManifests,
      files: files,
    ).resolve(reciterId: 'full', collectionId: 'morning', dhikrId: 'd1');
    expect(resolved?.clipStart, const Duration(seconds: 4));
    expect(resolved?.clipEnd, const Duration(seconds: 11));
  });

  test('downloaded continuous pack uses the generic play-all path', () async {
    const recording = CollectionAudio(
      id: 'generic_evening_pack',
      remoteUrl: 'https://example.invalid/generic_evening.m4a',
    );
    final genericCollection = ReciterCollectionAudio(
      collectionId: 'evening',
      playAllStrategy: DhikrPlayAllStrategy.continuousRecording,
      continuousSource: recording,
      playbackSequence: [
        DhikrAudioSegment(
          step: 1,
          mappingKey: 'first',
          sourceRepetition: 1,
          source: DhikrAudioClip(
            dhikrId: 'x',
            collectionAudio: recording,
            start: Duration.zero,
            end: const Duration(milliseconds: 10),
          ),
        ),
        DhikrAudioSegment(
          step: 2,
          mappingKey: 'second',
          sourceRepetition: 1,
          source: DhikrAudioClip(
            dhikrId: 'y',
            collectionAudio: recording,
            start: const Duration(milliseconds: 10),
            end: const Duration(milliseconds: 20),
          ),
        ),
      ],
      logicalCardOrder: const ['x', 'y'],
    );
    final genericManifests = DhikrAudioManifestRepository(
      manifests: [
        DhikrReciterManifest(
          reciter: const DhikrReciter(
            id: 'generic_reciter',
            nameAr: 'Generic',
            coverage: ReciterCoverage.partial,
          ),
          collections: {'evening': genericCollection},
        ),
      ],
    );
    final recordingFile = await files.fileFor(
      reciterId: 'generic_reciter',
      collectionId: 'evening',
      source: recording,
    );
    await recordingFile.create(recursive: true);
    await recordingFile.writeAsBytes([1]);
    final harness = await _harness(genericManifests, files);

    expect(
      await harness.controller.playAll(
        collectionId: 'evening',
        items: [_item('x'), _item('y')],
      ),
      isTrue,
    );
    await _waitFor(() => harness.player.playedSources.length == 1);
    expect(
      harness.player.playedSources.single.sourceType,
      DhikrAudioSourceType.collectionRecording,
    );
    expect(harness.player.playedSources.single.file?.path, recordingFile.path);

    harness.player.emitPosition(const Duration(milliseconds: 11));
    await _waitFor(() => harness.controller.currentDhikrId == 'y');
    expect(harness.player.playedSources, hasLength(1));
    expect(harness.controller.sessionCardOrder, ['x', 'y']);
  });

  test(
    'recorded-only segments are not expanded to canonical repeats',
    () async {
      const recording = CollectionAudio(
        id: 'unsafe_repeat_pack',
        remoteUrl: 'https://example.invalid/unsafe.m4a',
      );
      final collection = ReciterCollectionAudio(
        collectionId: 'morning',
        playAllStrategy: DhikrPlayAllStrategy.continuousRecording,
        continuousSource: recording,
        playbackSequence: [
          DhikrAudioSegment(
            step: 1,
            mappingKey: 'explanatory_segment',
            sourceRepetition: 1,
            repeatPolicy: DhikrSegmentRepeatPolicy.recordedOnly,
            source: DhikrAudioClip(
              dhikrId: 'd1',
              collectionAudio: recording,
              start: Duration.zero,
              end: const Duration(milliseconds: 2),
            ),
          ),
        ],
      );
      final repeatManifests = DhikrAudioManifestRepository(
        manifests: [
          DhikrReciterManifest(
            reciter: manifests.reciters.first,
            collections: {'morning': collection},
          ),
        ],
      );
      final file = await files.fileFor(
        reciterId: 'full',
        collectionId: 'morning',
        source: recording,
      );
      await file.create(recursive: true);
      await file.writeAsBytes([1]);
      final harness = await _harness(repeatManifests, files);

      await harness.controller.playAll(
        collectionId: 'morning',
        items: [_item('d1', repeats: 100)],
        playbackMode: DhikrPlaybackMode.repeatAfterMe,
      );
      await _waitFor(() => harness.player.playedSources.length == 1);
      harness.player.completeCurrent(const Duration(milliseconds: 2));
      await _waitFor(
        () => harness.controller.status == DhikrPlaybackStatus.stopped,
      );
      expect(harness.player.playedSources, hasLength(1));
    },
  );

  test('explicit clean-segment reuse can honor canonical repeats', () async {
    const recording = CollectionAudio(
      id: 'reusable_repeat_pack',
      remoteUrl: 'https://example.invalid/reusable.m4a',
    );
    final collection = ReciterCollectionAudio(
      collectionId: 'morning',
      playAllStrategy: DhikrPlayAllStrategy.continuousRecording,
      continuousSource: recording,
      playbackSequence: [
        DhikrAudioSegment(
          step: 1,
          mappingKey: 'clean_segment',
          sourceRepetition: 1,
          repeatPolicy: DhikrSegmentRepeatPolicy.reuseForCanonicalCount,
          source: DhikrAudioClip(
            dhikrId: 'd1',
            collectionAudio: recording,
            start: Duration.zero,
            end: const Duration(milliseconds: 2),
          ),
        ),
      ],
    );
    final repeatManifests = DhikrAudioManifestRepository(
      manifests: [
        DhikrReciterManifest(
          reciter: manifests.reciters.first,
          collections: {'morning': collection},
        ),
      ],
    );
    final file = await files.fileFor(
      reciterId: 'full',
      collectionId: 'morning',
      source: recording,
    );
    await file.create(recursive: true);
    await file.writeAsBytes([1]);
    final harness = await _harness(repeatManifests, files);

    await harness.controller.playAll(
      collectionId: 'morning',
      items: [_item('d1', repeats: 3)],
      playbackMode: DhikrPlaybackMode.repeatAfterMe,
    );
    for (var repeat = 1; repeat <= 3; repeat++) {
      await _waitFor(() => harness.player.playedSources.length == repeat);
      harness.player.completeCurrent(const Duration(milliseconds: 2));
    }
    await _waitFor(
      () => harness.controller.status == DhikrPlaybackStatus.stopped,
    );
    expect(harness.player.playedSources, hasLength(3));
  });

  test('currentDhikrId updates as play-all advances', () async {
    final harness = await _harness(manifests, files);
    await harness.controller.playAll(
      collectionId: 'morning',
      items: [_item('d1'), _item('d2')],
    );
    await _waitFor(() => harness.controller.currentDhikrId == 'd1');
    expect(harness.controller.currentDhikrId, 'd1');
    harness.player.completeCurrent(const Duration(milliseconds: 2));
    await _waitFor(() => harness.controller.currentDhikrId == 'd2');
    expect(harness.controller.currentDhikrId, 'd2');
  });

  test('deleting downloaded collection updates state', () async {
    final downloads = DhikrAudioDownloadController(
      manifests: manifests,
      files: files,
      backend: _FakeDownloadBackend(),
    );
    await downloads.refresh('full', 'morning');
    expect(
      downloads.snapshot('full', 'morning').status,
      AudioDownloadStatus.downloaded,
    );
    await downloads.delete('full', 'morning');
    expect(
      downloads.snapshot('full', 'morning').status,
      AudioDownloadStatus.notDownloaded,
    );
  });
}

DhikrItem _item(String id, {int repeats = 1}) => DhikrItem(
  id: id,
  order: 1,
  category: 'morning',
  text: id,
  repeatCount: repeats,
  entryType: DhikrEntryType.single,
);

Future<_Harness> _harness(
  DhikrAudioManifestRepository manifests,
  DhikrAudioFileStore files,
) async {
  final player = _FakePlayer();
  final controller = DhikrAudioController(
    repository: DhikrAudioRepository(manifests: manifests, files: files),
    manifests: manifests,
    player: player,
  );
  await controller.initialize();
  return _Harness(controller, player);
}

Future<void> _waitFor(bool Function() predicate) async {
  for (var attempt = 0; attempt < 100 && !predicate(); attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(
    predicate(),
    isTrue,
    reason: 'Timed out waiting for async audio state',
  );
}

class _Harness {
  const _Harness(this.controller, this.player);
  final DhikrAudioController controller;
  final _FakePlayer player;
}

class _FakePlayer implements AudioPlaybackAdapter {
  final _positions = StreamController<Duration>.broadcast();
  final List<String?> playedIds = [];
  final List<ResolvedDhikrAudio> playedSources = [];
  Completer<Duration?>? _current;

  @override
  Stream<Duration> get positionStream => _positions.stream;

  @override
  Future<Duration?> play(ResolvedDhikrAudio source) {
    playedIds.add(source.dhikrId);
    playedSources.add(source);
    _current = Completer<Duration?>();
    return _current!.future;
  }

  void emitPosition(Duration position) => _positions.add(position);

  void completeCurrent(Duration duration) => _current!.complete(duration);

  @override
  Future<void> seek(Duration position) async {
    emitPosition(position);
  }

  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {
    if (!(_current?.isCompleted ?? true)) _current!.complete(null);
  }

  @override
  Future<void> dispose() => _positions.close();
}

class _FakeDownloadBackend implements AudioDownloadBackend {
  @override
  Future<void> cancel(String taskId) async {}

  @override
  Future<bool> enqueue({
    required String taskId,
    required String remoteUrl,
    required String directory,
    required String filename,
    required void Function(double progress) onProgress,
    required void Function(bool success) onFinished,
  }) async => true;
}
