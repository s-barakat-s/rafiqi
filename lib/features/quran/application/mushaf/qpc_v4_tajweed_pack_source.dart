import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/models/quran_core_models.dart';
import 'package:tasbeh/features/quran/domain/mushaf/qpc_v4_tajweed_pack.dart';

abstract interface class QpcV4TajweedPackSource {
  Future<QpcV4TajweedManifest> loadManifest();
  Future<QpcPreparedPage> loadPage(int pageNumber);
}

/// RESEARCH ONLY — QPC content provenance remains unapproved for production.
final class DevQpcV4TajweedPackSource implements QpcV4TajweedPackSource {
  DevQpcV4TajweedPackSource({
    AssetBundle? assetBundle,
    Directory? projectRoot,
  }) : _bundle = assetBundle ?? rootBundle,
       _projectRoot = projectRoot ?? Directory.current;

  static const _assetRoot = 'quran_research/qpc_v4_tajweed_pack';
  static const _surahCatalogAsset =
      'assets/data/quran/qpc_v4_surah_metadata.json';
  static const _maximumCachedGeometries = 8;

  final AssetBundle _bundle;
  final Directory _projectRoot;
  QpcV4TajweedManifest? _manifest;
  Future<QpcV4TajweedManifest>? _manifestLoad;
  Future<Map<int, QuranSurah>>? _surahs;
  final LinkedHashMap<int, QpcPageGeometry> _geometryCache = LinkedHashMap();
  final Map<int, Future<QpcPageGeometry>> _geometryLoads = {};

  bool get _usesAndroidAssets => Platform.isAndroid;

  @override
  Future<QpcV4TajweedManifest> loadManifest() {
    _requireResearchDebug();
    final cached = _manifest;
    if (cached != null) return Future.value(cached);
    final loading = _manifestLoad;
    if (loading != null) return loading;
    late final Future<QpcV4TajweedManifest> pending;
    pending = _readManifest()
        .then((manifest) {
          _manifest = manifest;
          return manifest;
        })
        .whenComplete(() {
          if (identical(_manifestLoad, pending)) _manifestLoad = null;
        });
    _manifestLoad = pending;
    return pending;
  }

  Future<QpcV4TajweedManifest> _readManifest() async {
    final decoded = jsonDecode(utf8.decode(await _loadPack('manifest.json')));
    final manifest = QpcV4TajweedManifest.fromJson(
      _stringMap(decoded, 'QPC manifest'),
    )..validateResearchPack();
    return manifest;
  }

  @override
  Future<QpcPreparedPage> loadPage(int pageNumber) async {
    final runtimeManifest = await loadManifest();
    if (pageNumber < 1 || pageNumber > runtimeManifest.pageCount) {
      throw RangeError.range(
        pageNumber,
        1,
        runtimeManifest.pageCount,
        'pageNumber',
      );
    }
    final name = pageNumber.toString().padLeft(3, '0');
    final values = await Future.wait<Object>([
      _loadPack('pages/$name.png'),
      _loadGeometry(pageNumber, runtimeManifest),
      _loadSurahs(),
    ]);
    final geometry = values[1] as QpcPageGeometry;
    final surahs = values[2] as Map<int, QuranSurah>;
    final primary = surahs[geometry.firstAyah.surahNumber];
    if (primary == null) {
      throw FormatException(
        'QPC page $pageNumber references unknown Surah '
        '${geometry.firstAyah.surahNumber}',
      );
    }
    final image = await _decodePageImage(
      values[0] as Uint8List,
      geometry.imageWidth,
      geometry.imageHeight,
      pageNumber,
    );
    return QpcPreparedPage(
      image: image,
      geometry: geometry,
      primarySurah: primary,
      juzNumber: _juzFor(geometry.firstAyah),
      surahs: surahs,
    );
  }

  Future<QpcPageGeometry> _loadGeometry(
    int pageNumber,
    QpcV4TajweedManifest manifest,
  ) {
    final cached = _geometryCache.remove(pageNumber);
    if (cached != null) {
      _geometryCache[pageNumber] = cached;
      return Future.value(cached);
    }
    final loading = _geometryLoads[pageNumber];
    if (loading != null) return loading;

    late final Future<QpcPageGeometry> pending;
    pending = _readGeometry(pageNumber, manifest)
        .then((geometry) {
          _geometryCache[pageNumber] = geometry;
          while (_geometryCache.length > _maximumCachedGeometries) {
            _geometryCache.remove(_geometryCache.keys.first);
          }
          return geometry;
        })
        .whenComplete(() {
          if (identical(_geometryLoads[pageNumber], pending)) {
            _geometryLoads.remove(pageNumber);
          }
        });
    _geometryLoads[pageNumber] = pending;
    return pending;
  }

  Future<QpcPageGeometry> _readGeometry(
    int pageNumber,
    QpcV4TajweedManifest manifest,
  ) async {
    final name = pageNumber.toString().padLeft(3, '0');
    final geometryName = _usesAndroidAssets
        ? 'geometry/$name.json_gz'
        : 'geometry/$name.json.gz';
    final compressed = await _loadPack(geometryName);
    final decoded = await compute(
      _decodeCompressedGeometryJson,
      compressed,
      debugLabel: 'qpc-geometry-$pageNumber',
    );
    final geometry = QpcPageGeometry.fromJson(decoded, manifest);
    if (geometry.pageNumber != pageNumber || geometry.wordRegions.isEmpty) {
      throw FormatException('QPC page identity mismatch for $pageNumber');
    }
    return geometry;
  }


  Future<ui.Image> _decodePageImage(
    Uint8List bytes,
    double expectedWidth,
    double expectedHeight,
    int pageNumber,
  ) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      final image = frame.image;
      if (image.width != expectedWidth || image.height != expectedHeight) {
        image.dispose();
        throw FormatException(
          'QPC page $pageNumber dimensions differ from its manifest',
        );
      }
      return image;
    } finally {
      codec.dispose();
    }
  }

  Future<Map<int, QuranSurah>> _loadSurahs() =>
      _surahs ??= _readSurahCatalog();

  Future<Map<int, QuranSurah>> _readSurahCatalog() async {
    final decoded = jsonDecode(await _bundle.loadString(_surahCatalogAsset));
    final catalog = _stringMap(decoded, 'QPC Surah catalog');
    final names = catalog['names_arabic'];
    final counts = catalog['ayah_counts'];
    if (names is! List<Object?> ||
        counts is! List<Object?> ||
        names.length != 114 ||
        counts.length != 114) {
      throw const FormatException('QPC Surah catalog must contain 114 rows');
    }
    final result = <int, QuranSurah>{};
    for (var index = 0; index < 114; index++) {
      final surah = QuranSurah(
        number: index + 1,
        nameArabic: names[index]! as String,
        ayahCount: counts[index]! as int,
      );
      result[surah.number] = surah;
    }
    if (result.length != 114) {
      throw const FormatException('QPC Surah catalog identities are invalid');
    }
    return Map.unmodifiable(result);
  }

  Future<Uint8List> _loadPack(String relativePath) async {
    _requireResearchDebug();
    if (_usesAndroidAssets) {
      final data = await _bundle.load('$_assetRoot/$relativePath');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    }
    final file = File(
      p.join(
        _projectRoot.path,
        'quran_resources',
        'qpc_v4_tajweed_pack',
        relativePath,
      ),
    );
    if (!await file.exists()) {
      throw StateError('Research QPC resource is missing: ${file.path}');
    }
    return file.readAsBytes();
  }

  void _requireResearchDebug() {
    if (!kDebugMode) {
      throw StateError('Research-only QPC runtime is disabled outside debug');
    }
  }
}

int _juzFor(AyahKey ayah) {
  var juz = 1;
  for (var index = 0; index < _juzStarts.length; index++) {
    if (ayah.compareTo(_juzStarts[index]) < 0) break;
    juz = index + 1;
  }
  return juz;
}

const _juzStarts = <AyahKey>[
  AyahKey(1, 1),
  AyahKey(2, 142),
  AyahKey(2, 253),
  AyahKey(3, 93),
  AyahKey(4, 24),
  AyahKey(4, 148),
  AyahKey(5, 82),
  AyahKey(6, 111),
  AyahKey(7, 88),
  AyahKey(8, 41),
  AyahKey(9, 93),
  AyahKey(11, 6),
  AyahKey(12, 53),
  AyahKey(15, 1),
  AyahKey(17, 1),
  AyahKey(18, 75),
  AyahKey(21, 1),
  AyahKey(23, 1),
  AyahKey(25, 21),
  AyahKey(27, 56),
  AyahKey(29, 46),
  AyahKey(33, 31),
  AyahKey(36, 28),
  AyahKey(39, 32),
  AyahKey(41, 47),
  AyahKey(46, 1),
  AyahKey(51, 31),
  AyahKey(58, 1),
  AyahKey(67, 1),
  AyahKey(78, 1),
];

Map<String, Object?> _decodeCompressedGeometryJson(Uint8List compressed) {
  final decoded = jsonDecode(utf8.decode(gzip.decode(compressed)));
  return _stringMap(decoded, 'QPC page geometry');
}

Map<String, Object?> _stringMap(Object? value, String label) {
  if (value is! Map<Object?, Object?>) {
    throw FormatException('$label must be an object');
  }
  return value.map((key, entry) => MapEntry(key! as String, entry));
}
