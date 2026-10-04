import 'dart:async';
import 'dart:convert';
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
import 'package:tasbeh/features/adhkar_audio/data/mishary_morning_manifest_parser.dart';
import 'package:tasbeh/features/adhkar_audio/domain/dhikr_audio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DhikrReciterManifest mishary;
  late ReciterCollectionAudio morning;
  late List<Map<String, dynamic>> rawSegments;

  setUpAll(() async {
    final manifestJson = await File(
      'assets/data/adhkar/manifests/mishary_morning.json',
    ).readAsString();
    final canonicalJson = await File(
      'assets/data/adhkar/normalized/morning.json',
    ).readAsString();
    rawSegments =
        ((jsonDecode(manifestJson) as Map<String, dynamic>)['segments']
                as List<dynamic>)
            .cast<Map<String, dynamic>>();
    mishary = const MisharyMorningManifestParser().parse(
      manifestJson: manifestJson,
      canonicalMorningJson: canonicalJson,
    );
    morning = mishary.collection('morning')!;
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Mishary Morning manifest parses with the bundled source', () {
    expect(mishary.reciter.id, 'mishary_alafasy');
    expect(mishary.collections.keys, ['morning']);
    expect(morning.playbackSequence, hasLength(56));
    expect(morning.playAllStrategy, DhikrPlayAllStrategy.continuousRecording);
    expect(morning.isBundledDevelopment, isTrue);
  });

  test('mapping keys resolve to the current canonical morning IDs', () {
    final mappedIds = morning.playbackSequence
        .map((segment) => segment.source.dhikrId)
        .whereType<String>()
        .toSet();
    expect(mappedIds, _expectedMappedIds.toSet());
    expect(mappedIds, hasLength(24));
  });

  test('runtime identity uses explicit manifest dhikrId values unchanged', () {
    for (var index = 0; index < rawSegments.length; index++) {
      expect(
        morning.playbackSequence[index].source.dhikrId,
        rawSegments[index]['dhikrId'],
      );
    }
  });

  test('the two split canonical adhkar remain independently mapped', () {
    final byKey = <String, String?>{
      for (final segment in morning.playbackSequence)
        segment.mappingKey: segment.source.dhikrId,
    };
    expect(byKey['asbahna_wa_asbahal_mulk'], 'seen-ar-morning-007');
    expect(byKey['rabbi_asaluka_khayra_hadha_alyawm'], 'seen-ar-morning-008');
  });

  test('reciter-specific card order is unique and follows the manifest', () {
    expect(morning.logicalCardOrder, _expectedMappedIds);
    expect(morning.logicalCardOrder.toSet(), hasLength(24));
  });

  test('every raw boundary reaches runtime clips unchanged', () async {
    final harness = await _harness(mishary);
    addTearDown(harness.dispose);
    final queued = morning.playbackSequence
        .map((segment) => segment.source)
        .whereType<DhikrAudioClip>()
        .toList(growable: false);
    expect(queued, hasLength(rawSegments.length));

    for (var index = 0; index < rawSegments.length; index++) {
      final raw = rawSegments[index];
      final runtimeClip = queued[index];
      final resolved = await harness.controller.repository.resolveSource(
        reciterId: 'mishary_alafasy',
        collectionId: 'morning',
        source: runtimeClip,
      );
      final rawStart = raw['startMs'] as int;
      final rawEnd = raw['endMs'] as int;

      expect(
        runtimeClip.start.inMilliseconds,
        rawStart,
        reason: 'Queued start changed for manifest step ${raw['step']}',
      );
      expect(
        runtimeClip.end.inMilliseconds,
        rawEnd,
        reason: 'Queued end changed for manifest step ${raw['step']}',
      );
      expect(
        resolved?.clipStart?.inMilliseconds,
        rawStart,
        reason: 'Resolved start changed for manifest step ${raw['step']}',
      );
      expect(
        resolved?.clipEnd?.inMilliseconds,
        rawEnd,
        reason: 'Resolved end changed for manifest step ${raw['step']}',
      );

      if (index < 12) {
        // Deliberate diagnostic output for investigating playback boundaries.
        // ignore: avoid_print
        print(
          'boundary step=${raw['step']} key=${raw['mappingKey']} '
          'raw=$rawStart..$rawEnd '
          'runtime=${runtimeClip.start.inMilliseconds}..'
          '${runtimeClip.end.inMilliseconds}',
        );
      }
    }
  });

  test(
    'play all opens the recording once and derives cards from position',
    () async {
      final harness = await _harness(mishary);
      addTearDown(harness.dispose);
      final items = _expectedMappedIds.map(_item).toList();

      expect(
        await harness.controller.playAll(collectionId: 'morning', items: items),
        isTrue,
      );
      await _waitFor(() => harness.player.playedIds.length == 1);
      expect(harness.player.playedIds, [isNull]);
      expect(
        harness.player.playedSources.single.sourceType,
        DhikrAudioSourceType.collectionRecording,
      );
      expect(harness.player.playedSources.single.clipStart, isNull);

      var notifications = 0;
      harness.controller.addListener(() => notifications++);
      harness.player.emitPosition(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(harness.controller.currentDhikrId, isNull);
      expect(notifications, 0);

      harness.player.emitPosition(const Duration(milliseconds: 10288));
      await _waitFor(
        () => harness.controller.currentDhikrId == 'seen-ar-morning-002',
      );
      expect(notifications, 1);

      harness.player.emitPosition(const Duration(milliseconds: 20000));
      await Future<void>.delayed(Duration.zero);
      expect(notifications, 1, reason: 'Same-segment ticks must stay silent');

      harness.player.emitPosition(const Duration(milliseconds: 81007));
      await _waitFor(
        () => harness.controller.currentDhikrId == 'seen-ar-morning-004',
      );
      expect(notifications, 2);
      expect(harness.player.playedIds, hasLength(1));

      harness.player.emitPosition(const Duration(milliseconds: 101274));
      await _waitFor(
        () => harness.controller.currentDhikrId == 'seen-ar-morning-005',
      );
      harness.player.emitPosition(const Duration(milliseconds: 132623));
      await _waitFor(
        () => harness.controller.currentDhikrId == 'seen-ar-morning-006',
      );
      harness.player.emitPosition(const Duration(milliseconds: 178900));
      await _waitFor(
        () => harness.controller.currentDhikrId == 'seen-ar-morning-004',
      );
      expect(harness.player.playedIds, hasLength(1));

      await harness.controller.skip();
      expect(harness.player.seeks, [const Duration(milliseconds: 197559)]);
      await _waitFor(
        () => harness.controller.currentDhikrId == 'seen-ar-morning-005',
      );
      expect(harness.player.playedIds, hasLength(1));
    },
  );

  test('single dhikr plays only source repetition one', () async {
    final harness = await _harness(mishary);
    addTearDown(harness.dispose);

    expect(
      await harness.controller.playOne(
        collectionId: 'morning',
        item: _item('seen-ar-morning-004', repeats: 3),
      ),
      isTrue,
    );
    await _waitFor(() => harness.player.playedSources.length == 1);

    final source = harness.player.playedSources.single;
    expect(source.dhikrId, 'seen-ar-morning-004');
    expect(source.sourceType, DhikrAudioSourceType.collectionClip);
    expect(source.clipStart, const Duration(milliseconds: 81007));
    expect(source.clipEnd, const Duration(milliseconds: 101274));

    harness.player.completeCurrent();
    await _waitFor(
      () => harness.controller.status == DhikrPlaybackStatus.stopped,
    );
    expect(harness.player.playedSources, hasLength(1));
  });

  test(
    'repeat after me remains segment-based and separate from listen',
    () async {
      final harness = await _harness(mishary);
      addTearDown(harness.dispose);

      expect(
        await harness.controller.playAll(
          collectionId: 'morning',
          items: _expectedMappedIds.map(_item).toList(),
          playbackMode: DhikrPlaybackMode.repeatAfterMe,
        ),
        isTrue,
      );
      await _waitFor(() => harness.player.playedSources.isNotEmpty);
      expect(
        harness.player.playedSources.first.sourceType,
        DhikrAudioSourceType.collectionClip,
      );
      expect(harness.player.playedSources.first.clipStart, Duration.zero);
    },
  );

  test('manifest repeat policies protect and explicitly allow reuse', () {
    final byKey = {
      for (final segment in morning.playbackSequence)
        segment.mappingKey: segment.repeatPolicy,
    };
    expect(
      byKey['allahumma_afini_fi_badani'],
      DhikrSegmentRepeatPolicy.reuseForCanonicalCount,
    );
    expect(
      byKey['subhanallahi_wa_bihamdihi_100'],
      DhikrSegmentRepeatPolicy.recordedOnly,
    );
    expect(
      byKey['la_ilaha_illa_allah_100'],
      DhikrSegmentRepeatPolicy.recordedOnly,
    );
  });

  test('stopping restores default reader order state', () async {
    final harness = await _harness(mishary);
    addTearDown(harness.dispose);
    expect(
      await harness.controller.playAll(
        collectionId: 'morning',
        items: _expectedMappedIds.map(_item).toList(),
      ),
      isTrue,
    );
    await _waitFor(() => harness.controller.isActive);
    expect(harness.controller.sessionCardOrder, _expectedMappedIds);
    await harness.controller.stop();
    expect(harness.controller.sessionCardOrder, isEmpty);
  });

  test(
    'bundled development audio is available without download state',
    () async {
      final root = await Directory.systemTemp.createTemp('mishary_audio_test_');
      addTearDown(() => root.delete(recursive: true));
      final backend = _CountingDownloadBackend();
      final downloads = DhikrAudioDownloadController(
        manifests: DhikrAudioManifestRepository(manifests: [mishary]),
        files: DhikrAudioFileStore(rootProvider: () async => root),
        backend: backend,
      );
      await downloads.refresh('mishary_alafasy', 'morning');
      final snapshot = downloads.snapshot('mishary_alafasy', 'morning');
      expect(snapshot.isAvailable, isTrue);
      expect(snapshot.isBundledDevelopment, isTrue);
      expect(snapshot.status, AudioDownloadStatus.notDownloaded);
      await downloads.download('mishary_alafasy', 'morning');
      expect(backend.enqueueCount, 0);
    },
  );

  test('only non-card narration remains without a canonical ID', () {
    expect(morning.unresolvedSegments.map((segment) => segment.mappingKey), [
      'intro',
      'closing_and_istighfar',
    ]);
  });

  test('bundled manifest introduces no fake remote URLs', () {
    expect(morning.uniqueAssets, hasLength(1));
    expect(morning.uniqueAssets.single.remoteUrl, isNull);
    expect(
      morning.uniqueAssets.single.bundledAssetPath,
      'assets/audio/adhkar/mishary_alafasy/morning.m4a',
    );
  });

  test('generic controller contains no current-fixture identifiers', () async {
    final source = await File(
      'lib/features/adhkar_audio/application/dhikr_audio_controller.dart',
    ).readAsString();
    expect(source, isNot(contains('mishary_alafasy')));
    expect(source, isNot(contains("'morning'")));
    expect(source, isNot(contains('assets/audio/')));
    expect(source, isNot(contains('assets/data/adhkar/manifests/')));
  });
}

const _expectedMappedIds = <String>[
  'seen-ar-morning-002',
  'seen-ar-morning-004',
  'seen-ar-morning-005',
  'seen-ar-morning-006',
  'seen-ar-morning-007',
  'seen-ar-morning-008',
  'seen-ar-morning-009',
  'seen-ar-morning-011',
  'seen-ar-morning-012',
  'seen-ar-morning-014',
  'seen-ar-morning-016',
  'seen-ar-morning-017',
  'seen-ar-morning-018',
  'seen-ar-morning-019',
  'seen-ar-morning-020',
  'seen-ar-morning-021',
  'seen-ar-morning-031',
  'seen-ar-morning-034',
  'seen-ar-morning-022',
  'seen-ar-morning-032',
  'seen-ar-morning-023',
  'seen-ar-morning-025',
  'seen-ar-morning-027',
  'seen-ar-morning-029',
];

DhikrItem _item(String id, {int repeats = 1}) => DhikrItem(
  id: id,
  order: 1,
  category: 'morning',
  text: id,
  repeatCount: repeats,
  entryType: DhikrEntryType.single,
);

Future<_Harness> _harness(DhikrReciterManifest manifest) async {
  final root = await Directory.systemTemp.createTemp('mishary_controller_');
  final repository = DhikrAudioManifestRepository(manifests: [manifest]);
  final player = _FakePlayer();
  final controller = DhikrAudioController(
    repository: DhikrAudioRepository(
      manifests: repository,
      files: DhikrAudioFileStore(rootProvider: () async => root),
    ),
    manifests: repository,
    player: player,
  );
  await controller.initialize();
  return _Harness(controller, player, root);
}

Future<void> _waitFor(bool Function() predicate) async {
  for (var attempt = 0; attempt < 200 && !predicate(); attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(predicate(), isTrue, reason: 'Timed out waiting for audio state');
}

class _Harness {
  const _Harness(this.controller, this.player, this.root);

  final DhikrAudioController controller;
  final _FakePlayer player;
  final Directory root;

  Future<void> dispose() async {
    controller.dispose();
    if (await root.exists()) await root.delete(recursive: true);
  }
}

class _FakePlayer implements AudioPlaybackAdapter {
  final StreamController<Duration> _positions =
      StreamController<Duration>.broadcast();
  final List<String?> playedIds = [];
  final List<ResolvedDhikrAudio> playedSources = [];
  final List<Duration> seeks = [];
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

  void completeCurrent() => _current!.complete(const Duration(milliseconds: 1));

  @override
  Future<void> seek(Duration position) async {
    seeks.add(position);
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

class _CountingDownloadBackend implements AudioDownloadBackend {
  int enqueueCount = 0;

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
  }) async {
    enqueueCount++;
    return true;
  }
}
