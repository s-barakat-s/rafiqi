import 'package:sqflite/sqflite.dart';
import 'package:tasbeh/features/quran/application/search/arabic_search_normalizer.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/search/quran_search.dart';

final class SqfliteQuranSearchRepository implements QuranSearchRepository {
  const SqfliteQuranSearchRepository(this._database);

  final Database _database;

  @override
  Future<List<QuranSearchResult>> search(String query, {int limit = 50}) async {
    if (limit < 1 || limit > 100) {
      throw ArgumentError.value(limit, 'limit', 'must be between 1 and 100');
    }
    final normalized = ArabicSearchNormalizer.normalize(query);
    if (normalized.isEmpty) {
      throw const QuranSearchQueryException(
        'Search query must contain at least one letter or number',
      );
    }
    final tokens = ArabicSearchNormalizer.tokens(query).toSet().toList();
    final placeholders = List.filled(tokens.length, '?').join(', ');
    final rows = await _database.rawQuery(
      '''SELECT a.surah_number, a.ayah_number, a.text_uthmani,
                s.name_arabic, d.normalized_text,
                CASE WHEN d.normalized_text = ? THEN 0 ELSE 1 END AS match_rank,
                a.global_index
         FROM ayah_search_documents AS d
         JOIN ayahs AS a ON a.global_index = d.global_index
         JOIN surahs AS s ON s.number = a.surah_number
         JOIN ayah_search_terms AS t ON t.global_index = d.global_index
         WHERE t.token IN ($placeholders)
         GROUP BY d.global_index
         HAVING COUNT(DISTINCT t.token) = ?
         ORDER BY match_rank ASC, a.global_index ASC
         LIMIT ?''',
      [normalized, ...tokens, tokens.length, limit],
    );
    return List.unmodifiable(
      rows.map((row) {
        final rank = row['match_rank']! as int;
        return QuranSearchResult(
          ayahKey: AyahKey(
            row['surah_number']! as int,
            row['ayah_number']! as int,
          ),
          surahNameArabic: row['name_arabic']! as String,
          displayText: row['text_uthmani']! as String,
          matchKind: rank == 0
              ? QuranSearchMatchKind.exact
              : QuranSearchMatchKind.allTerms,
          rank: rank,
        );
      }),
    );
  }
}
