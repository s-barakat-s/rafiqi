import 'package:meta/meta.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';

enum QuranDatasetKind { production, syntheticTest }

@immutable
final class QuranCoreMetadata {
  const QuranCoreMetadata({
    required this.sourceProvider,
    required this.sourceResourceName,
    required this.sourceReference,
    required this.sourceVersion,
    required this.sourceAcquiredAt,
    required this.sourceChecksum,
    required this.schemaVersion,
    required this.ingestionToolVersion,
    required this.licenseOrUsageReference,
    required this.attributionNotes,
    required this.expectedSurahCount,
    required this.expectedAyahCount,
    required this.datasetKind,
  });

  final String sourceProvider;
  final String sourceResourceName;
  final String sourceReference;
  final String sourceVersion;
  final DateTime sourceAcquiredAt;
  final String sourceChecksum;
  final int schemaVersion;
  final String ingestionToolVersion;
  final String licenseOrUsageReference;
  final String attributionNotes;
  final int expectedSurahCount;
  final int expectedAyahCount;
  final QuranDatasetKind datasetKind;
}

@immutable
final class QuranSurah {
  const QuranSurah({
    required this.number,
    required this.nameArabic,
    required this.ayahCount,
  });
  final int number;
  final String nameArabic;
  final int ayahCount;
}

@immutable
final class QuranAyah {
  const QuranAyah({
    required this.key,
    required this.globalIndex,
    required this.textUthmani,
    this.textSearch,
  });
  final AyahKey key;
  final int globalIndex;
  final String textUthmani;
  final String? textSearch;
}

@immutable
sealed class QuranBoundary {
  const QuranBoundary(this.number, this.startsAt);
  final int number;
  final AyahKey startsAt;
}

final class QuranJuz extends QuranBoundary {
  const QuranJuz(super.number, super.startsAt);
}

final class QuranHizb extends QuranBoundary {
  const QuranHizb(super.number, super.startsAt);
}

final class QuranRubElHizb extends QuranBoundary {
  const QuranRubElHizb(super.number, super.startsAt);
}

@immutable
final class QuranSajdah {
  const QuranSajdah({required this.key, required this.kind});
  final AyahKey key;
  final String kind;
}
