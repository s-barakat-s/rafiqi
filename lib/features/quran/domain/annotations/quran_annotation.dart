import 'package:meta/meta.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';

const qpcV4ResearchAnnotationEditionId = 'qpc-v4-tajweed-research';

enum QuranAnnotationGranularity { ayah, word }

enum QuranHighlightColorId {
  yellow,
  green,
  pink,
  blue,
  purple;

  static QuranHighlightColorId? tryParse(Object? value) {
    if (value is! String) return null;
    for (final color in values) {
      if (color.name == value) return color;
    }
    return null;
  }
}

@immutable
final class QuranAnnotation {
  const QuranAnnotation({
    required this.id,
    required this.editionId,
    required this.granularity,
    required this.startIdentity,
    required this.endIdentity,
    required this.colorId,
    required this.createdAt,
    required this.lastModifiedAt,
    this.comment,
  });

  factory QuranAnnotation.fromJson(Map<String, Object?> json) {
    final granularity = QuranAnnotationGranularity.values.firstWhere(
      (value) => value.name == json['granularity'],
      orElse: () => throw const FormatException(
        'Unsupported Quran annotation granularity',
      ),
    );
    final colorId = QuranHighlightColorId.tryParse(json['color_id']);
    if (colorId == null) {
      throw const FormatException('Unsupported Quran annotation color');
    }
    final id = json['id'];
    final editionId = json['edition_id'];
    final startIdentity = json['start_identity'];
    final endIdentity = json['end_identity'];
    final comment = json['comment'];
    final createdAt = DateTime.tryParse(json['created_at'] as String? ?? '');
    final lastModifiedAt = DateTime.tryParse(
      json['last_modified_at'] as String? ?? '',
    );
    if (id is! String ||
        id.isEmpty ||
        editionId != qpcV4ResearchAnnotationEditionId ||
        startIdentity is! String ||
        endIdentity is! String ||
        (comment != null && comment is! String) ||
        createdAt == null ||
        lastModifiedAt == null) {
      throw const FormatException('Malformed Quran annotation');
    }
    switch (granularity) {
      case QuranAnnotationGranularity.ayah:
        AyahKey.parse(startIdentity);
        AyahKey.parse(endIdentity);
      case QuranAnnotationGranularity.word:
        WordKey.parse(startIdentity);
        WordKey.parse(endIdentity);
    }
    return QuranAnnotation(
      id: id,
      editionId: editionId as String,
      granularity: granularity,
      startIdentity: startIdentity,
      endIdentity: endIdentity,
      colorId: colorId,
      comment: comment as String?,
      createdAt: createdAt.toUtc(),
      lastModifiedAt: lastModifiedAt.toUtc(),
    );
  }

  final String id;
  final String editionId;
  final QuranAnnotationGranularity granularity;
  final String startIdentity;
  final String endIdentity;
  final QuranHighlightColorId colorId;
  final String? comment;
  final DateTime createdAt;
  final DateTime lastModifiedAt;

  AyahKey? get ayahStart => granularity == QuranAnnotationGranularity.ayah
      ? AyahKey.parse(startIdentity)
      : null;
  AyahKey? get ayahEnd => granularity == QuranAnnotationGranularity.ayah
      ? AyahKey.parse(endIdentity)
      : null;
  WordKey? get wordStart => granularity == QuranAnnotationGranularity.word
      ? WordKey.parse(startIdentity)
      : null;
  WordKey? get wordEnd => granularity == QuranAnnotationGranularity.word
      ? WordKey.parse(endIdentity)
      : null;

  QuranAnnotation copyWith({
    QuranHighlightColorId? colorId,
    String? comment,
    bool clearComment = false,
    DateTime? lastModifiedAt,
  }) => QuranAnnotation(
    id: id,
    editionId: editionId,
    granularity: granularity,
    startIdentity: startIdentity,
    endIdentity: endIdentity,
    colorId: colorId ?? this.colorId,
    comment: clearComment ? null : (comment ?? this.comment),
    createdAt: createdAt,
    lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'edition_id': editionId,
    'granularity': granularity.name,
    'start_identity': startIdentity,
    'end_identity': endIdentity,
    'color_id': colorId.name,
    if (comment != null) 'comment': comment,
    'created_at': createdAt.toUtc().toIso8601String(),
    'last_modified_at': lastModifiedAt.toUtc().toIso8601String(),
  };

  bool containsAyah(AyahKey key) {
    final start = ayahStart;
    final end = ayahEnd;
    if (start == null || end == null) return false;
    final first = start.compareTo(end) <= 0 ? start : end;
    final last = start.compareTo(end) <= 0 ? end : start;
    return key.compareTo(first) >= 0 && key.compareTo(last) <= 0;
  }

  bool containsWord(WordKey key) {
    if (granularity == QuranAnnotationGranularity.ayah) {
      return containsAyah(key.ayahKey);
    }
    final start = wordStart!;
    final end = wordEnd!;
    final first = start.compareTo(end) <= 0 ? start : end;
    final last = start.compareTo(end) <= 0 ? end : start;
    return key.compareTo(first) >= 0 && key.compareTo(last) <= 0;
  }
}
