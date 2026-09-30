import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar_audio/application/audio_playback_adapter.dart';
import 'package:tasbeh/features/adhkar_audio/data/dhikr_audio_manifest_repository.dart';
import 'package:tasbeh/features/adhkar_audio/data/dhikr_audio_preferences_repository.dart';
import 'package:tasbeh/features/adhkar_audio/data/dhikr_audio_repository.dart';
import 'package:tasbeh/features/adhkar_audio/domain/dhikr_audio.dart';

class DhikrAudioController extends ChangeNotifier {
  DhikrAudioController({
    required this.repository,
    required this.manifests,
    required this.player,
    this.preferences = const DhikrAudioPreferencesRepository(),
  });

  final DhikrAudioRepository repository;
  final DhikrAudioManifestRepository manifests;
  final AudioPlaybackAdapter player;
  final DhikrAudioPreferencesRepository preferences;

  String? selectedReciterId;
  String? selectedCollectionId;
  String? currentDhikrId;
  int currentRepeatNumber = 0;
  int totalRepeatCount = 0;
  DhikrPlaybackMode mode = DhikrPlaybackMode.listen;
  DhikrPlaybackStatus status = DhikrPlaybackStatus.stopped;
  DhikrPlaybackPhase phase = DhikrPlaybackPhase.listening;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  int _generation = 0;
  int _currentIndex = -1;
  List<_QueuedAudio> _queue = const [];
  _PausableDelay? _silence;
  StreamSubscription<Duration>? _positionSubscription;

  Future<void> initialize() async {
    selectedReciterId =
        await preferences.selectedReciterId() ??
        manifests.reciters.firstOrNull?.id;
    mode = await preferences.playbackMode();
    _positionSubscription ??= player.positionStream.listen((value) {
      position = value;
      notifyListeners();
    });
    notifyListeners();
  }

  bool get isActive => status != DhikrPlaybackStatus.stopped;
  bool isCurrent(String dhikrId) => isActive && currentDhikrId == dhikrId;

  List<String> get sessionCardOrder {
    if (!isActive ||
        selectedCollectionId == null ||
        selectedReciterId == null) {
      return const [];
    }
    return manifests
            .collectionFor(selectedReciterId!, selectedCollectionId!)
            ?.logicalCardOrder ??
        const [];
  }

  Future<void> selectReciter(String reciterId) async {
    if (selectedReciterId == reciterId) return;
    await stop();
    selectedReciterId = reciterId;
    await preferences.setSelectedReciterId(reciterId);
    notifyListeners();
  }

  Future<void> selectMode(DhikrPlaybackMode value) async {
    mode = value;
    await preferences.setPlaybackMode(value);
    notifyListeners();
  }

  Future<bool> playOne({
    required String collectionId,
    required DhikrItem item,
    DhikrPlaybackMode? playbackMode,
  }) => _start(
    collectionId: collectionId,
    items: [item],
    playbackMode: playbackMode,
  );

  Future<bool> playAll({
    required String collectionId,
    required List<DhikrItem> items,
    DhikrPlaybackMode? playbackMode,
  }) => _start(
    collectionId: collectionId,
    items: items.where((item) => !item.isPrelude).toList(growable: false),
    playbackMode: playbackMode,
  );

  Future<bool> _start({
    required String collectionId,
    required List<DhikrItem> items,
    DhikrPlaybackMode? playbackMode,
  }) async {
    final reciterId = selectedReciterId;
    if (reciterId == null || items.isEmpty) return false;
    final collection = manifests.collectionFor(reciterId, collectionId);
    if (collection == null) return false;
    final itemsById = {for (final item in items) item.id: item};
    final isWholeCollection = items.length > 1;
    final queue = collection.playbackSequence.isNotEmpty
        ? [
            for (final segment in collection.playbackSequence)
              if ((segment.source.dhikrId == null && isWholeCollection) ||
                  itemsById.containsKey(segment.source.dhikrId))
                _QueuedAudio(
                  item: itemsById[segment.source.dhikrId],
                  source: segment.source,
                  repeatCount: 1,
                  sourceRepetition: segment.sourceRepetition,
                ),
          ]
        : [
            for (final item in items)
              _QueuedAudio(item: item, repeatCount: item.repeatCount),
          ];
    if (!queue.any((entry) => entry.item != null)) return false;
    var hasPlayableItem = false;
    for (final entry in queue.where((entry) => entry.item != null)) {
      final resolved = entry.source == null
          ? await repository.resolve(
              reciterId: reciterId,
              collectionId: collectionId,
              dhikrId: entry.item!.id,
            )
          : await repository.resolveSource(
              reciterId: reciterId,
              collectionId: collectionId,
              source: entry.source!,
            );
      if (resolved != null) {
        hasPlayableItem = true;
        break;
      }
    }
    if (!hasPlayableItem) return false;
    await stop();
    if (playbackMode != null) await selectMode(playbackMode);
    _queue = queue;
    selectedCollectionId = collectionId;
    _currentIndex = 0;
    final token = ++_generation;
    unawaited(_runQueue(token));
    return true;
  }

  Future<void> _runQueue(int token) async {
    while (token == _generation && _currentIndex < _queue.length) {
      final queued = _queue[_currentIndex];
      final item = queued.item;
      final resolved = queued.source == null
          ? await repository.resolve(
              reciterId: selectedReciterId!,
              collectionId: selectedCollectionId!,
              dhikrId: item!.id,
            )
          : await repository.resolveSource(
              reciterId: selectedReciterId!,
              collectionId: selectedCollectionId!,
              source: queued.source!,
            );
      if (token != _generation) return;
      if (resolved == null) {
        _currentIndex++;
        continue;
      }
      currentDhikrId = item?.id;
      totalRepeatCount = item == null
          ? 1
          : (item.repeatCount < 1 ? 1 : item.repeatCount);
      status = DhikrPlaybackStatus.playing;
      notifyListeners();
      for (var repeat = 1; repeat <= queued.repeatCount; repeat++) {
        if (token != _generation) return;
        currentRepeatNumber = queued.sourceRepetition ?? repeat;
        phase = DhikrPlaybackPhase.listening;
        position = Duration.zero;
        notifyListeners();
        final spokenDuration = await player.play(resolved);
        if (token != _generation || spokenDuration == null) return;
        duration = resolved.clipDuration ?? spokenDuration;
        if (mode == DhikrPlaybackMode.repeatAfterMe) {
          phase = DhikrPlaybackPhase.repeatSilence;
          position = Duration.zero;
          notifyListeners();
          final delay = _PausableDelay(duration);
          _silence = delay;
          final completed = await delay.future;
          if (!completed || token != _generation) return;
          _silence = null;
        }
      }
      _currentIndex++;
    }
    if (token == _generation) await stop();
  }

  Future<void> pause() async {
    if (status != DhikrPlaybackStatus.playing) return;
    if (phase == DhikrPlaybackPhase.repeatSilence) {
      _silence?.pause();
    } else {
      await player.pause();
    }
    status = DhikrPlaybackStatus.paused;
    notifyListeners();
  }

  Future<void> resume() async {
    if (status != DhikrPlaybackStatus.paused) return;
    if (phase == DhikrPlaybackPhase.repeatSilence) {
      _silence?.resume();
    } else {
      await player.resume();
    }
    status = DhikrPlaybackStatus.playing;
    notifyListeners();
  }

  Future<void> skip() async {
    if (!isActive) return;
    final nextIndex = _currentIndex + 1;
    _generation++;
    _silence?.cancel();
    _silence = null;
    await player.stop();
    if (nextIndex >= _queue.length) {
      _setStopped();
      return;
    }
    _currentIndex = nextIndex;
    final token = ++_generation;
    unawaited(_runQueue(token));
  }

  Future<void> stop() async {
    _generation++;
    _silence?.cancel();
    _silence = null;
    await player.stop();
    _setStopped();
  }

  void _setStopped() {
    status = DhikrPlaybackStatus.stopped;
    phase = DhikrPlaybackPhase.listening;
    currentDhikrId = null;
    currentRepeatNumber = 0;
    totalRepeatCount = 0;
    position = Duration.zero;
    duration = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _generation++;
    _silence?.cancel();
    _positionSubscription?.cancel();
    unawaited(player.dispose());
    super.dispose();
  }
}

class _QueuedAudio {
  const _QueuedAudio({
    required this.item,
    required this.repeatCount,
    this.source,
    this.sourceRepetition,
  });

  final DhikrItem? item;
  final DhikrAudioSource? source;
  final int repeatCount;
  final int? sourceRepetition;
}

class _PausableDelay {
  _PausableDelay(this._remaining) {
    _start();
  }

  Duration _remaining;
  final Completer<bool> _completer = Completer<bool>();
  Timer? _timer;
  Stopwatch? _stopwatch;

  Future<bool> get future => _completer.future;

  void _start() {
    if (_remaining <= Duration.zero) {
      if (!_completer.isCompleted) _completer.complete(true);
      return;
    }
    _stopwatch = Stopwatch()..start();
    _timer = Timer(_remaining, () {
      if (!_completer.isCompleted) _completer.complete(true);
    });
  }

  void pause() {
    if (_timer == null || _completer.isCompleted) return;
    _timer!.cancel();
    _timer = null;
    _stopwatch?.stop();
    _remaining -= _stopwatch?.elapsed ?? Duration.zero;
  }

  void resume() {
    if (_timer != null || _completer.isCompleted) return;
    _start();
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    if (!_completer.isCompleted) _completer.complete(false);
  }
}
