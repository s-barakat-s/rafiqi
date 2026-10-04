import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:tasbeh/features/adhkar_audio/domain/dhikr_audio.dart';

abstract interface class AudioPlaybackAdapter {
  Stream<Duration> get positionStream;
  Future<Duration?> play(ResolvedDhikrAudio source);
  Future<void> seek(Duration position);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> dispose();
}

class JustAudioPlaybackAdapter implements AudioPlaybackAdapter {
  JustAudioPlaybackAdapter({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  Completer<Duration?>? _completion;
  StreamSubscription<ProcessingState>? _stateSubscription;

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Future<Duration?> play(ResolvedDhikrAudio source) async {
    await stop();
    final baseSource = source.bundledAssetPath != null
        ? AudioSource.asset(source.bundledAssetPath!)
        : AudioSource.uri(source.file!.uri);
    final audioSource = source.sourceType == DhikrAudioSourceType.collectionClip
        ? ClippingAudioSource(
            child: baseSource,
            start: source.clipStart,
            end: source.clipEnd,
          )
        : baseSource;
    final loadedDuration = await _player.setAudioSource(audioSource);
    final completion = Completer<Duration?>();
    _completion = completion;
    _stateSubscription = _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && !completion.isCompleted) {
        completion.complete(source.clipDuration ?? loadedDuration);
        _stateSubscription?.cancel();
        _stateSubscription = null;
      }
    });
    unawaited(_player.play());
    return completion.future;
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> resume() => _player.play();

  @override
  Future<void> stop() async {
    if (!(_completion?.isCompleted ?? true)) _completion!.complete(null);
    _completion = null;
    await _stateSubscription?.cancel();
    _stateSubscription = null;
    await _player.stop();
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}
