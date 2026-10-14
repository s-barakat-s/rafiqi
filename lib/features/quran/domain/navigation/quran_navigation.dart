import 'package:meta/meta.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/models/quran_core_models.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_models.dart';

@immutable
final class QuranNavigationTarget {
  const QuranNavigationTarget({required this.ayahKey, required this.pageKey});

  final AyahKey ayahKey;
  final MushafPageKey pageKey;
}

abstract interface class QuranNavigation {
  MushafEdition get edition;

  Future<List<QuranSurah>> getSurahs();
  Future<List<QuranJuz>> getJuzs();
  Future<List<QuranHizb>> getHizbs();
  Future<List<QuranRubElHizb>> getRubs();
  Future<QuranNavigationTarget?> resolveSurahStart(int surahNumber);
  Future<QuranNavigationTarget?> resolveJuzStart(int juzNumber);
  Future<QuranNavigationTarget?> resolveHizbStart(int hizbNumber);
  Future<QuranNavigationTarget?> resolveRubStart(int rubNumber);
  Future<QuranNavigationTarget?> resolveAyah(AyahKey key);
  Future<QuranNavigationTarget?> resolvePage(MushafPageKey key);
}
