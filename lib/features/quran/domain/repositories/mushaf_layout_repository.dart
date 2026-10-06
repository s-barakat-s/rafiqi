import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_models.dart';

abstract interface class MushafLayoutRepository {
  Future<MushafEdition> getEdition();
  Future<MushafPage?> getPage(MushafPageKey key);
  Future<List<MushafLine>> getPageLines(MushafPageKey key);
  Future<MushafLine?> getLine(MushafPageKey key, int lineNumber);
  Future<List<MushafWordPlacement>> getWordPlacements(MushafPageKey key);
  Future<List<MushafWordPlacement>> locateAyah(AyahKey key);
  Future<MushafWordPlacement?> locateWord(WordKey key);
  Future<MushafPageKey?> getPageForAyah(AyahKey key);
  Future<MushafPageKey?> getPageForWord(WordKey key);
}
