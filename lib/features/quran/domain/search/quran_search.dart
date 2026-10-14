import 'package:meta/meta.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';

enum QuranSearchMatchKind { exact, allTerms }

@immutable
final class QuranSearchResult {
  const QuranSearchResult({
    required this.ayahKey,
    required this.surahNameArabic,
    required this.displayText,
    required this.matchKind,
    required this.rank,
  });

  final AyahKey ayahKey;
  final String surahNameArabic;
  final String displayText;
  final QuranSearchMatchKind matchKind;
  final int rank;
}

abstract interface class QuranSearchRepository {
  Future<List<QuranSearchResult>> search(String query, {int limit = 50});
}

final class QuranSearchQueryException implements Exception {
  const QuranSearchQueryException(this.message);

  final String message;

  @override
  String toString() => message;
}
