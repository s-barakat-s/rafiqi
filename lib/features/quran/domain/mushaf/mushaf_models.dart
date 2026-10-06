import 'package:meta/meta.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/mushaf/resource_provenance.dart';

final class RiwayahId implements Comparable<RiwayahId> {
  const RiwayahId._(this.value);

  factory RiwayahId(String value) {
    if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(value)) {
      throw ArgumentError.value(
        value,
        'value',
        'must be a lowercase stable slug',
      );
    }
    return RiwayahId._(value);
  }

  static final hafsAnAsim = RiwayahId('hafs-an-asim');
  final String value;
  @override
  int compareTo(RiwayahId other) => value.compareTo(other.value);
  @override
  bool operator ==(Object other) => other is RiwayahId && value == other.value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}

final class MushafEditionId implements Comparable<MushafEditionId> {
  const MushafEditionId._(this.value);
  factory MushafEditionId(String value) {
    if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(value)) {
      throw ArgumentError.value(
        value,
        'value',
        'must be a lowercase stable slug',
      );
    }
    return MushafEditionId._(value);
  }
  final String value;
  @override
  int compareTo(MushafEditionId other) => value.compareTo(other.value);
  @override
  bool operator ==(Object other) =>
      other is MushafEditionId && value == other.value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}

enum MushafRenderStrategy { semanticVector, digitalKhatt, qcfGlyphs, pageAsset }

enum MushafLineType { quranText, surahHeading, basmala, specialLayout }

enum MushafLineAlignment { natural, centered, justified }

@immutable
final class MushafEdition {
  MushafEdition({
    required this.id,
    required this.displayName,
    required this.internalName,
    required this.riwayahId,
    required this.editionVersion,
    required this.pageCount,
    required this.nominalLinesPerPage,
    required this.renderStrategy,
    required this.layoutResourceId,
    required this.scriptResourceId,
    required this.provenance,
    this.fontResourceId,
  }) {
    if (displayName.trim().isEmpty ||
        internalName.trim().isEmpty ||
        editionVersion.trim().isEmpty) {
      throw ArgumentError('Edition names and version are required');
    }
    if (pageCount < 1 || nominalLinesPerPage < 1) {
      throw ArgumentError('Edition page and line counts must be positive');
    }
    if (layoutResourceId.trim().isEmpty || scriptResourceId.trim().isEmpty) {
      throw ArgumentError('Edition resource IDs are required');
    }
    if (!provenance.compatibility.riwayahIds.contains(riwayahId.value)) {
      throw ArgumentError(
        'Provenance is incompatible with the edition Riwayah',
      );
    }
  }

  final MushafEditionId id;
  final String displayName;
  final String internalName;
  final RiwayahId riwayahId;
  final String editionVersion;
  final int pageCount;
  final int nominalLinesPerPage;
  final MushafRenderStrategy renderStrategy;
  final String layoutResourceId;
  final String scriptResourceId;
  final String? fontResourceId;
  final QuranResourceProvenance provenance;
}

@immutable
final class MushafPageKey implements Comparable<MushafPageKey> {
  MushafPageKey(this.mushafId, this.pageNumber) {
    if (pageNumber < 1) throw ArgumentError.value(pageNumber, 'pageNumber');
  }

  factory MushafPageKey.parse(String value) {
    final separator = value.lastIndexOf(':');
    if (separator <= 0 || separator == value.length - 1) {
      throw FormatException('Invalid Mushaf page key', value);
    }
    try {
      return MushafPageKey(
        MushafEditionId(value.substring(0, separator)),
        int.parse(value.substring(separator + 1)),
      );
    } on Object {
      throw FormatException('Invalid Mushaf page key', value);
    }
  }

  final MushafEditionId mushafId;
  final int pageNumber;
  String serialize() => '${mushafId.value}:$pageNumber';
  @override
  int compareTo(MushafPageKey other) {
    final edition = mushafId.compareTo(other.mushafId);
    return edition == 0 ? pageNumber.compareTo(other.pageNumber) : edition;
  }

  @override
  bool operator ==(Object other) =>
      other is MushafPageKey &&
      mushafId == other.mushafId &&
      pageNumber == other.pageNumber;
  @override
  int get hashCode => Object.hash(mushafId, pageNumber);
  @override
  String toString() => serialize();
}

@immutable
final class QuranWord {
  const QuranWord({
    required this.key,
    this.textUnicode,
    this.metadata = const {},
  });
  final WordKey key;
  AyahKey get ayahKey => key.ayahKey;
  int get positionInAyah => key.wordNumber;
  final String? textUnicode;
  final Map<String, String> metadata;
}

@immutable
final class WordProviderMapping {
  WordProviderMapping({
    required this.wordKey,
    required this.provider,
    required this.providerWordId,
    required this.resourceVersion,
  }) {
    if (provider.trim().isEmpty ||
        providerWordId.trim().isEmpty ||
        resourceVersion.trim().isEmpty) {
      throw ArgumentError('Provider mapping values are required');
    }
  }
  final WordKey wordKey;
  final String provider;
  final String providerWordId;
  final String resourceVersion;
}

@immutable
final class MushafPage {
  const MushafPage(this.key);
  final MushafPageKey key;
}

@immutable
final class MushafLine {
  MushafLine({
    required this.pageKey,
    required this.lineNumber,
    required this.lineType,
    this.alignment,
    this.firstWordKey,
    this.lastWordKey,
  }) {
    if (lineNumber < 1) throw ArgumentError.value(lineNumber, 'lineNumber');
    if ((firstWordKey == null) != (lastWordKey == null)) {
      throw ArgumentError(
        'First and last WordKey must both be set or both be absent',
      );
    }
    if (firstWordKey != null && firstWordKey!.compareTo(lastWordKey!) > 0) {
      throw ArgumentError('Line WordKey range is reversed');
    }
  }
  final MushafPageKey pageKey;
  final int lineNumber;
  final MushafLineType lineType;
  final MushafLineAlignment? alignment;
  final WordKey? firstWordKey;
  final WordKey? lastWordKey;
}

@immutable
final class MushafWordPlacement {
  MushafWordPlacement({
    required this.pageKey,
    required this.lineNumber,
    required this.wordKey,
    required this.ayahKey,
    required this.positionInLine,
    this.glyphCode,
    this.providerMapping,
  }) {
    if (lineNumber < 1 || positionInLine < 1) {
      throw ArgumentError('Line and position must be positive');
    }
    if (wordKey.ayahKey != ayahKey) {
      throw ArgumentError('WordKey and AyahKey do not agree');
    }
  }
  final MushafPageKey pageKey;
  final int lineNumber;
  final WordKey wordKey;
  final AyahKey ayahKey;
  final int positionInLine;
  final String? glyphCode;
  final WordProviderMapping? providerMapping;
}
