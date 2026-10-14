import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:tasbeh/features/adhkar_audio/application/audio_playback_adapter.dart';
import 'package:tasbeh/features/adhkar_audio/application/dhikr_audio_controller.dart';
import 'package:tasbeh/features/adhkar_audio/application/dhikr_audio_download_controller.dart';
import 'package:tasbeh/features/adhkar_audio/data/dhikr_audio_file_store.dart';
import 'package:tasbeh/features/adhkar_audio/data/dhikr_audio_manifest_repository.dart';
import 'package:tasbeh/features/adhkar_audio/data/dhikr_audio_repository.dart';
import 'package:tasbeh/features/adhkar_audio/domain/dhikr_audio.dart';

class DhikrAudioRuntime {
  DhikrAudioRuntime._();

  static final instance = DhikrAudioRuntime._();
  Future<void>? _initialization;
  bool _isInitialized = false;

  late final DhikrAudioManifestRepository manifests;
  late final DhikrAudioFileStore files;
  late final DhikrAudioRepository repository;
  late final DhikrAudioController playback;
  late final DhikrAudioDownloadController downloads;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() {
    if (_isInitialized) return Future<void>.value();
    final pending = _initialization;
    if (pending != null) return pending;

    late final Future<void> initialization;
    initialization = _initialize().then(
      (_) {
        _isInitialized = true;
      },
      onError: (Object error, StackTrace stackTrace) {
        if (identical(_initialization, initialization)) {
          _initialization = null;
        }
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
    _initialization = initialization;
    return initialization;
  }

  Future<void> _initialize() async {
    final initializedManifests = await DhikrAudioManifestRepository.load();
    final initializedFiles = DhikrAudioFileStore();
    final initializedRepository = DhikrAudioRepository(
      manifests: initializedManifests,
      files: initializedFiles,
    );
    final initializedPlayback = DhikrAudioController(
      repository: initializedRepository,
      manifests: initializedManifests,
      player: JustAudioPlaybackAdapter(),
    );
    final downloadBackend = BackgroundAudioDownloadBackend();
    final initializedDownloads = DhikrAudioDownloadController(
      manifests: initializedManifests,
      files: initializedFiles,
      backend: downloadBackend,
    );
    try {
      await Future.wait([
        initializedPlayback.initialize(),
        downloadBackend.initialize(),
      ]);
      await AudioService.init(
        builder: () => _DhikrAudioHandler(initializedPlayback),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.mahmoudelnahrawy.tasbeh.adhkar',
          androidNotificationChannelName: 'تشغيل الأذكار',
          androidNotificationOngoing: false,
        ),
      );
    } catch (_) {
      initializedPlayback.dispose();
      rethrow;
    }
    manifests = initializedManifests;
    files = initializedFiles;
    repository = initializedRepository;
    playback = initializedPlayback;
    downloads = initializedDownloads;
  }
}

class _DhikrAudioHandler extends BaseAudioHandler {
  _DhikrAudioHandler(this.controller) {
    controller.addListener(_publish);
    _publish();
  }

  final DhikrAudioController controller;

  void _publish() {
    final active = controller.isActive;
    final playing = controller.status == DhikrPlaybackStatus.playing;
    playbackState.add(
      PlaybackState(
        controls: [
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: active
            ? AudioProcessingState.ready
            : AudioProcessingState.idle,
        playing: playing,
        updatePosition: controller.position,
      ),
    );
    final dhikrId = controller.currentDhikrId;
    mediaItem.add(
      dhikrId == null
          ? null
          : MediaItem(
              id: dhikrId,
              title:
                  'ذكر ${controller.currentRepeatNumber} من '
                  '${controller.totalRepeatCount}',
              album: controller.phase == DhikrPlaybackPhase.repeatSilence
                  ? 'حان وقت الترديد'
                  : 'maab — الأذكار',
              duration: controller.duration,
            ),
    );
  }

  @override
  Future<void> play() => controller.resume();

  @override
  Future<void> pause() => controller.pause();

  @override
  Future<void> stop() => controller.stop();

  @override
  Future<void> skipToNext() => controller.skip();
}
