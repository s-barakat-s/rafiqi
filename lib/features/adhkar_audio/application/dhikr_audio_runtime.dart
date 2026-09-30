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

  late final DhikrAudioManifestRepository manifests;
  late final DhikrAudioFileStore files;
  late final DhikrAudioRepository repository;
  late final DhikrAudioController playback;
  late final DhikrAudioDownloadController downloads;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    manifests = await DhikrAudioManifestRepository.load();
    files = DhikrAudioFileStore();
    repository = DhikrAudioRepository(manifests: manifests, files: files);
    playback = DhikrAudioController(
      repository: repository,
      manifests: manifests,
      player: JustAudioPlaybackAdapter(),
    );
    final downloadBackend = BackgroundAudioDownloadBackend();
    downloads = DhikrAudioDownloadController(
      manifests: manifests,
      files: files,
      backend: downloadBackend,
    );
    await Future.wait([playback.initialize(), downloadBackend.initialize()]);
    await AudioService.init(
      builder: () => _DhikrAudioHandler(playback),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.mahmoudelnahrawy.tasbeh.adhkar',
        androidNotificationChannelName: 'تشغيل الأذكار',
        androidNotificationOngoing: false,
      ),
    );
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
                  : 'رفيقي — الأذكار',
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
