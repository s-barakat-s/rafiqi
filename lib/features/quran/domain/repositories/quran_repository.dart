import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/models/quran_core_models.dart';

abstract interface class QuranRepository {
  Future<QuranCoreMetadata> getMetadata();
  Future<List<QuranSurah>> getSurahs();
  Future<QuranSurah?> getSurah(int surahNumber);
  Future<QuranAyah?> getAyah(AyahKey key);
  Future<bool> containsAyah(AyahKey key);
  Future<List<QuranAyah>> getSurahAyahs(int surahNumber);
  Future<List<QuranAyah>> getAyahRange(AyahKey start, AyahKey end);
  Future<int?> resolveGlobalAyahIndex(AyahKey key);
  Future<QuranJuz?> getJuz(int number);
  Future<QuranHizb?> getHizb(int number);
  Future<QuranRubElHizb?> getRubElHizb(int number);
  Future<List<QuranSajdah>> getSajdahMarkers();
}
