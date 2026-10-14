import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/models/quran_core_models.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_models.dart';

final qpcV4TajweedEditionId = MushafEditionId('qpc-v4-tajweed-research');

@immutable
final class QpcV4TajweedManifest {
  const QpcV4TajweedManifest({
    required this.packId,
    required this.researchOnly,
    required this.productionApproved,
    required this.pageCount,
    required this.canonicalWidth,
    required this.canonicalHeight,
    required this.layout,
    required this.renderFingerprint,
    required this.schemaVersion,
  });

  factory QpcV4TajweedManifest.fromJson(Map<String, Object?> json) {
    return QpcV4TajweedManifest(
      packId: json['pack_id']! as String,
      researchOnly: json['research_only']! as bool,
      productionApproved: json['production_approved']! as bool,
      pageCount: json['page_count']! as int,
      canonicalWidth:
          ((json['canonical_width'] ?? json['source_canvas_width'])! as num)
              .toDouble(),
      canonicalHeight:
          ((json['canonical_height'] ?? json['source_canvas_height'])! as num)
              .toDouble(),
      layout: json['layout'] as String?,
      renderFingerprint: json['render_fingerprint']! as String,
      schemaVersion: json['schema_version']! as int,
    );
  }

  final String packId;
  final bool researchOnly;
  final bool productionApproved;
  final int pageCount;
  final double canonicalWidth;
  final double canonicalHeight;
  final String? layout;
  final String renderFingerprint;
  final int schemaVersion;
  bool get isPhoneNativeLayout => layout == 'phone-native';

  void validateResearchPack() {
    final stable =
        packId == 'maab.qpc_v4_tajweed.research.v1' &&
        canonicalWidth == 1200 &&
        canonicalHeight == 1800 &&
        renderFingerprint ==
            'qpc-v4-tajweed-transparent-content-no-heading-frame-v4-indexed-png256';
    final phoneNative =
        packId == 'maab.qpc_v4_tajweed.research.v1' &&
        isPhoneNativeLayout &&
        canonicalWidth == 1074 &&
        canonicalHeight == 1944 &&
        renderFingerprint ==
            'qpc-v4-tajweed-phone-native-1074x1944-generated-specials-v8-indexed-png256';
    if ((!stable && !phoneNative) ||
        !researchOnly ||
        productionApproved ||
        pageCount != 604 ||
        schemaVersion != 2) {
      throw const FormatException('Research QPC V4 pack identity mismatch');
    }
  }
}

@immutable
final class QpcCanonicalRect {
  const QpcCanonicalRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory QpcCanonicalRect.fromJson(
    Map<String, Object?> json, {
    Offset origin = Offset.zero,
  }) => QpcCanonicalRect(
    x: (json['x']! as num).toDouble() + origin.dx,
    y: (json['y']! as num).toDouble() + origin.dy,
    width: (json['width']! as num).toDouble(),
    height: (json['height']! as num).toDouble(),
  );

  final double x;
  final double y;
  final double width;
  final double height;
  Rect get rect => Rect.fromLTWH(x, y, width, height);
}

@immutable
final class QpcWordRegion {
  const QpcWordRegion({required this.key, required this.bounds});

  factory QpcWordRegion.fromJson(
    Map<String, Object?> json, {
    Offset origin = Offset.zero,
  }) => QpcWordRegion(
    key: WordKey.parse(json['word_key']! as String),
    bounds: QpcCanonicalRect.fromJson(json, origin: origin),
  );

  final WordKey key;
  final QpcCanonicalRect bounds;
}

@immutable
final class QpcAyahMarkerRegion {
  const QpcAyahMarkerRegion({required this.key, required this.bounds});

  factory QpcAyahMarkerRegion.fromJson(
    Map<String, Object?> json, {
    Offset origin = Offset.zero,
  }) {
    if (json['type'] != 'ayah_marker') {
      throw const FormatException('QPC non-word region is not an ayah marker');
    }
    return QpcAyahMarkerRegion(
      key: AyahKey.parse(json['ayah_key']! as String),
      bounds: QpcCanonicalRect.fromJson(json, origin: origin),
    );
  }

  final AyahKey key;
  final QpcCanonicalRect bounds;
}

@immutable
final class QpcAyahRegion {
  const QpcAyahRegion({required this.key, required this.lineBounds});

  factory QpcAyahRegion.fromJson(
    Map<String, Object?> json, {
    Offset origin = Offset.zero,
  }) => QpcAyahRegion(
    key: AyahKey.parse(json['ayah_key']! as String),
    lineBounds: _objectList(json['line_regions'], 'line_regions')
        .map(
          (value) => QpcCanonicalRect.fromJson(
            _stringMap(value, 'line'),
            origin: origin,
          ),
        )
        .toList(growable: false),
  );

  final AyahKey key;
  final List<QpcCanonicalRect> lineBounds;
}

@immutable
final class QpcVisualOnlyRegion {
  const QpcVisualOnlyRegion({
    required this.type,
    required this.bounds,
    this.surahNumber,
  });

  factory QpcVisualOnlyRegion.fromJson(
    Map<String, Object?> json, {
    Offset origin = Offset.zero,
  }) => QpcVisualOnlyRegion(
    type: json['type']! as String,
    bounds: QpcCanonicalRect.fromJson(json, origin: origin),
    surahNumber: json['surah'] as int?,
  );

  final String type;
  final QpcCanonicalRect bounds;
  final int? surahNumber;
  bool get isSurahHeading => type == 'surah_heading';
}

@immutable
final class QpcPageGeometry {
  const QpcPageGeometry({
    required this.pageNumber,
    required this.imageWidth,
    required this.imageHeight,
    required this.canonicalWidth,
    required this.canonicalHeight,
    required this.cropOrigin,
    required this.phoneNativeLayout,
    required this.wordRegions,
    this.ayahMarkerRegions = const [],
    required this.ayahRegions,
    required this.visualOnlyRegions,
  });

  factory QpcPageGeometry.fromJson(
    Map<String, Object?> json,
    QpcV4TajweedManifest manifest,
  ) {
    final viewport = _stringMap(json['viewport'], 'viewport');
    final width = (viewport['width']! as num).toDouble();
    final height = (viewport['height']! as num).toDouble();
    final sourceCanvas = json['source_canvas'] == null
        ? null
        : _stringMap(json['source_canvas'], 'source_canvas');
    final canonicalWidth = sourceCanvas == null
        ? manifest.canonicalWidth
        : (sourceCanvas['width']! as num).toDouble();
    final canonicalHeight = sourceCanvas == null
        ? manifest.canonicalHeight
        : (sourceCanvas['height']! as num).toDouble();
    final crop = json['crop_origin'] == null
        ? null
        : _stringMap(json['crop_origin'], 'crop_origin');
    final cropOrigin = crop == null
        ? Offset.zero
        : Offset(
            (crop['x']! as num).toDouble(),
            (crop['y']! as num).toDouble(),
          );
    if (json['schema_version'] != manifest.schemaVersion ||
        json['render_fingerprint'] != manifest.renderFingerprint ||
        canonicalWidth != manifest.canonicalWidth ||
        canonicalHeight != manifest.canonicalHeight ||
        cropOrigin.dx < 0 ||
        cropOrigin.dy < 0 ||
        cropOrigin.dx + width > canonicalWidth + .5 ||
        cropOrigin.dy + height > canonicalHeight + .5) {
      throw const FormatException('QPC page geometry identity mismatch');
    }
    return QpcPageGeometry(
      pageNumber: json['page']! as int,
      imageWidth: width,
      imageHeight: height,
      canonicalWidth: canonicalWidth,
      canonicalHeight: canonicalHeight,
      cropOrigin: cropOrigin,
      phoneNativeLayout: json['layout'] == 'phone-native',
      wordRegions: _objectList(json['word_regions'], 'word_regions')
          .map(
            (value) => QpcWordRegion.fromJson(
              _stringMap(value, 'word'),
              origin: cropOrigin,
            ),
          )
          .toList(growable: false),
      ayahMarkerRegions:
          _objectList(json['non_word_regions'], 'non_word_regions')
              .map(
                (value) => QpcAyahMarkerRegion.fromJson(
                  _stringMap(value, 'non-word region'),
                  origin: cropOrigin,
                ),
              )
              .toList(growable: false),
      ayahRegions: _objectList(json['ayah_regions'], 'ayah_regions')
          .map(
            (value) => QpcAyahRegion.fromJson(
              _stringMap(value, 'ayah'),
              origin: cropOrigin,
            ),
          )
          .toList(growable: false),
      visualOnlyRegions:
          _objectList(json['visual_only_regions'], 'visual_only_regions')
              .map(
                (value) => QpcVisualOnlyRegion.fromJson(
                  _stringMap(value, 'visual-only region'),
                  origin: cropOrigin,
                ),
              )
              .toList(growable: false),
    );
  }

  final int pageNumber;
  final double imageWidth;
  final double imageHeight;
  final double canonicalWidth;
  final double canonicalHeight;
  final Offset cropOrigin;
  final bool phoneNativeLayout;
  final List<QpcWordRegion> wordRegions;
  final List<QpcAyahMarkerRegion> ayahMarkerRegions;
  final List<QpcAyahRegion> ayahRegions;
  final List<QpcVisualOnlyRegion> visualOnlyRegions;
  Rect get canonicalRect =>
      Rect.fromLTWH(0, 0, canonicalWidth, canonicalHeight);
  Rect get imageRect =>
      Rect.fromLTWH(cropOrigin.dx, cropOrigin.dy, imageWidth, imageHeight);

  /// Word geometry takes priority over marker geometry. Within each list the
  /// first matching region wins, preserving the pack's authored order.
  AyahKey? ayahAt(Offset canonicalPoint) {
    for (final word in wordRegions) {
      if (word.bounds.rect.contains(canonicalPoint)) return word.key.ayahKey;
    }
    for (final marker in ayahMarkerRegions) {
      if (marker.bounds.rect.contains(canonicalPoint)) return marker.key;
    }
    return null;
  }

  AyahKey get firstAyah => wordRegions.first.key.ayahKey;
  List<QpcVisualOnlyRegion> get surahHeadings => visualOnlyRegions
      .where((region) => region.isSurahHeading)
      .toList(growable: false);
}

@immutable
final class QpcPreparedPage {
  const QpcPreparedPage({
    required this.image,
    required this.geometry,
    required this.primarySurah,
    required this.juzNumber,
    required this.surahs,
  });

  final ui.Image image;
  final QpcPageGeometry geometry;
  final QuranSurah primarySurah;
  final int juzNumber;
  final Map<int, QuranSurah> surahs;
}

Map<String, Object?> _stringMap(Object? value, String label) {
  if (value is! Map<Object?, Object?>) {
    throw FormatException('$label must be an object');
  }
  return value.map((key, entry) => MapEntry(key! as String, entry));
}

List<Object?> _objectList(Object? value, String label) {
  if (value is! List<Object?>) throw FormatException('$label must be a list');
  return value;
}
