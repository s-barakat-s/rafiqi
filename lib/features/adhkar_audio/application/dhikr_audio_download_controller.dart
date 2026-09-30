import 'dart:async';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:tasbeh/features/adhkar_audio/data/dhikr_audio_file_store.dart';
import 'package:tasbeh/features/adhkar_audio/data/dhikr_audio_manifest_repository.dart';
import 'package:tasbeh/features/adhkar_audio/domain/dhikr_audio.dart';

abstract interface class AudioDownloadBackend {
  Future<bool> enqueue({
    required String taskId,
    required String remoteUrl,
    required String directory,
    required String filename,
    required void Function(double progress) onProgress,
    required void Function(bool success) onFinished,
  });

  Future<void> cancel(String taskId);
}

class BackgroundAudioDownloadBackend implements AudioDownloadBackend {
  final Map<String, DownloadTask> _tasks = {};

  Future<void> initialize() => FileDownloader().start(autoCleanDatabase: true);

  @override
  Future<bool> enqueue({
    required String taskId,
    required String remoteUrl,
    required String directory,
    required String filename,
    required void Function(double progress) onProgress,
    required void Function(bool success) onFinished,
  }) async {
    final task = DownloadTask(
      taskId: taskId,
      url: remoteUrl,
      filename: filename,
      directory: directory,
      baseDirectory: BaseDirectory.applicationSupport,
      group: 'rafiqi_adhkar_audio',
      updates: Updates.statusAndProgress,
      retries: 2,
      allowPause: true,
      displayName: 'Rafiqi adhkar audio',
    );
    _tasks[taskId] = task;
    unawaited(
      FileDownloader()
          .download(task, onProgress: (value) => onProgress(value.clamp(0, 1)))
          .then((update) {
            _tasks.remove(taskId);
            onFinished(update.status == TaskStatus.complete);
          }),
    );
    return true;
  }

  @override
  Future<void> cancel(String taskId) async {
    await FileDownloader().cancelTaskWithId(taskId);
    _tasks.remove(taskId);
  }
}

class DhikrAudioDownloadController extends ChangeNotifier {
  DhikrAudioDownloadController({
    required this.manifests,
    required this.files,
    required this.backend,
  });

  final DhikrAudioManifestRepository manifests;
  final DhikrAudioFileStore files;
  final AudioDownloadBackend backend;
  final Map<String, AudioDownloadSnapshot> _snapshots = {};
  final Map<String, Set<String>> _activeTasks = {};
  final Map<String, Map<String, double>> _assetProgress = {};

  String _key(String reciterId, String collectionId) =>
      '$reciterId::$collectionId';

  AudioDownloadSnapshot snapshot(String reciterId, String collectionId) {
    final collection = manifests.collectionFor(reciterId, collectionId);
    return _snapshots[_key(reciterId, collectionId)] ??
        AudioDownloadSnapshot(
          isAvailable: collection?.hasMappedAudio ?? false,
          isBundledDevelopment: collection?.isBundledDevelopment ?? false,
        );
  }

  Future<void> refresh(String reciterId, String collectionId) async {
    final collection = manifests.collectionFor(reciterId, collectionId);
    final key = _key(reciterId, collectionId);
    final available = collection?.hasMappedAudio ?? false;
    final bundledDevelopment = collection?.isBundledDevelopment ?? false;
    final downloaded =
        available &&
        !bundledDevelopment &&
        await files.isCollectionDownloaded(
          reciterId: reciterId,
          collection: collection!,
        );
    _snapshots[key] = AudioDownloadSnapshot(
      status: downloaded
          ? AudioDownloadStatus.downloaded
          : AudioDownloadStatus.notDownloaded,
      progress: downloaded ? 1 : 0,
      isAvailable: available,
      isBundledDevelopment: bundledDevelopment,
    );
    notifyListeners();
  }

  Future<void> download(String reciterId, String collectionId) async {
    final collection = manifests.collectionFor(reciterId, collectionId);
    if (collection == null || !collection.hasMappedAudio) {
      await refresh(reciterId, collectionId);
      return;
    }
    if (collection.isBundledDevelopment) {
      await refresh(reciterId, collectionId);
      return;
    }
    final key = _key(reciterId, collectionId);
    _snapshots[key] = const AudioDownloadSnapshot(
      status: AudioDownloadStatus.queued,
    );
    notifyListeners();

    final assets = collection.uniqueAssets;
    _assetProgress[key] = {for (final source in assets) source.assetId: 0};
    _activeTasks[key] = <String>{};
    var completed = 0;
    var failed = false;
    for (final source in assets) {
      final target = await files.fileFor(
        reciterId: reciterId,
        collectionId: collectionId,
        source: source,
      );
      if (await target.exists()) {
        completed++;
        _assetProgress[key]![source.assetId] = 1;
        continue;
      }
      final taskId = 'adhkar_${reciterId}_${collectionId}_${source.assetId}'
          .replaceAll(RegExp('[^a-zA-Z0-9_-]'), '_');
      _activeTasks[key]!.add(taskId);
      final accepted = await backend.enqueue(
        taskId: taskId,
        remoteUrl: source.remoteUrl!,
        directory: 'adhkar_audio/$reciterId/$collectionId',
        filename: target.uri.pathSegments.last,
        onProgress: (progress) {
          _assetProgress[key]?[source.assetId] = progress;
          _publishProgress(key);
        },
        onFinished: (success) async {
          _activeTasks[key]?.remove(taskId);
          if (success && await target.exists()) {
            completed++;
            _assetProgress[key]?[source.assetId] = 1;
          } else {
            failed = true;
          }
          if (_activeTasks[key]?.isEmpty ?? true) {
            final allPresent = await files.isCollectionDownloaded(
              reciterId: reciterId,
              collection: collection,
            );
            _snapshots[key] = AudioDownloadSnapshot(
              status: allPresent
                  ? AudioDownloadStatus.downloaded
                  : AudioDownloadStatus.failed,
              progress: allPresent ? 1 : completed / assets.length,
            );
            if (failed && !allPresent) {
              _snapshots[key] = AudioDownloadSnapshot(
                status: AudioDownloadStatus.failed,
                progress: completed / assets.length,
              );
            }
            notifyListeners();
          }
        },
      );
      if (!accepted) {
        failed = true;
        _activeTasks[key]!.remove(taskId);
      }
    }
    if (_activeTasks[key]!.isEmpty) await refresh(reciterId, collectionId);
  }

  void _publishProgress(String key) {
    final values = _assetProgress[key]?.values;
    final progress = values == null || values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a + b) / values.length;
    _snapshots[key] = AudioDownloadSnapshot(
      status: AudioDownloadStatus.downloading,
      progress: progress,
    );
    notifyListeners();
  }

  Future<void> retry(String reciterId, String collectionId) =>
      download(reciterId, collectionId);

  Future<void> cancel(String reciterId, String collectionId) async {
    final key = _key(reciterId, collectionId);
    for (final taskId in [...?_activeTasks[key]]) {
      await backend.cancel(taskId);
    }
    _activeTasks.remove(key);
    await refresh(reciterId, collectionId);
  }

  Future<void> delete(String reciterId, String collectionId) async {
    await cancel(reciterId, collectionId);
    await files.deleteCollection(
      reciterId: reciterId,
      collectionId: collectionId,
    );
    await refresh(reciterId, collectionId);
  }
}
