import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:tasbeh/features/adhkar_audio/domain/dhikr_audio.dart';

typedef AudioRootProvider = Future<Directory> Function();

class DhikrAudioFileStore {
  DhikrAudioFileStore({AudioRootProvider? rootProvider})
    : _rootProvider = rootProvider ?? _defaultRoot;

  final AudioRootProvider _rootProvider;

  static Future<Directory> _defaultRoot() async => Directory(
    '${(await getApplicationSupportDirectory()).path}/adhkar_audio',
  );

  Future<Directory> rootDirectory() => _rootProvider();

  Future<File> fileFor({
    required String reciterId,
    required String collectionId,
    required DhikrAudioSource source,
  }) async {
    final root = await rootDirectory();
    final extension = _safeExtension(source.remoteUrl!);
    return File(
      '${root.path}/${_safe(reciterId)}/${_safe(collectionId)}/'
      '${_safe(source.assetId)}$extension',
    );
  }

  Future<bool> exists({
    required String reciterId,
    required String collectionId,
    required DhikrAudioSource source,
  }) async {
    final file = await fileFor(
      reciterId: reciterId,
      collectionId: collectionId,
      source: source,
    );
    if (!await file.exists()) return false;
    final length = await file.length();
    if (length <= 0) return false;
    final expectedSize = source.expectedSizeBytes;
    return expectedSize == null || length == expectedSize;
  }

  Future<bool> isCollectionDownloaded({
    required String reciterId,
    required ReciterCollectionAudio collection,
  }) async {
    final assets = collection.uniqueAssets;
    if (assets.isEmpty) return false;
    if (assets.any(
      (source) =>
          source.locationType == DhikrAudioLocationType.bundledDevelopmentAsset,
    )) {
      return false;
    }
    for (final source in assets) {
      if (!await exists(
        reciterId: reciterId,
        collectionId: collection.collectionId,
        source: source,
      )) {
        return false;
      }
    }
    return true;
  }

  Future<void> deleteCollection({
    required String reciterId,
    required String collectionId,
  }) async {
    final root = await rootDirectory();
    final directory = Directory(
      '${root.path}/${_safe(reciterId)}/${_safe(collectionId)}',
    );
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  static String _safe(String value) =>
      value.replaceAll(RegExp('[^a-zA-Z0-9_-]'), '_');

  static String _safeExtension(String url) {
    final path = Uri.tryParse(url)?.path ?? '';
    final dot = path.lastIndexOf('.');
    if (dot < 0) return '.audio';
    final extension = path.substring(dot).toLowerCase();
    return RegExp(r'^\.[a-z0-9]{2,5}$').hasMatch(extension)
        ? extension
        : '.audio';
  }
}
