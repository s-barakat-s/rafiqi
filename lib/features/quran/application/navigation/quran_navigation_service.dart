import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/models/quran_core_models.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_models.dart';
import 'package:tasbeh/features/quran/domain/navigation/quran_navigation.dart';
import 'package:tasbeh/features/quran/domain/repositories/mushaf_layout_repository.dart';
import 'package:tasbeh/features/quran/domain/repositories/quran_repository.dart';

final class QuranNavigationService implements QuranNavigation {
  const QuranNavigationService({
    required QuranRepository quranRepository,
    required MushafLayoutRepository layoutRepository,
    required this.edition,
  }) : _quranRepository = quranRepository,
       _layoutRepository = layoutRepository;

  final QuranRepository _quranRepository;
  final MushafLayoutRepository _layoutRepository;

  @override
  final MushafEdition edition;

  @override
  Future<List<QuranSurah>> getSurahs() => _quranRepository.getSurahs();

  @override
  Future<List<QuranJuz>> getJuzs() => _quranRepository.getJuzs();

  @override
  Future<List<QuranHizb>> getHizbs() => _quranRepository.getHizbs();

  @override
  Future<List<QuranRubElHizb>> getRubs() => _quranRepository.getRubElHizbs();

  @override
  Future<QuranNavigationTarget?> resolveSurahStart(int surahNumber) async {
    final surah = await _quranRepository.getSurah(surahNumber);
    return surah == null ? null : resolveAyah(AyahKey(surah.number, 1));
  }

  @override
  Future<QuranNavigationTarget?> resolveJuzStart(int juzNumber) async {
    final boundary = await _quranRepository.getJuz(juzNumber);
    return boundary == null ? null : resolveAyah(boundary.startsAt);
  }

  @override
  Future<QuranNavigationTarget?> resolveHizbStart(int hizbNumber) async {
    final boundary = await _quranRepository.getHizb(hizbNumber);
    return boundary == null ? null : resolveAyah(boundary.startsAt);
  }

  @override
  Future<QuranNavigationTarget?> resolveRubStart(int rubNumber) async {
    final boundary = await _quranRepository.getRubElHizb(rubNumber);
    return boundary == null ? null : resolveAyah(boundary.startsAt);
  }

  @override
  Future<QuranNavigationTarget?> resolveAyah(AyahKey key) async {
    if (!await _quranRepository.containsAyah(key)) return null;
    final page = await _layoutRepository.getPageForAyah(key);
    if (page == null || page.mushafId != edition.id) return null;
    return QuranNavigationTarget(ayahKey: key, pageKey: page);
  }

  @override
  Future<QuranNavigationTarget?> resolvePage(MushafPageKey key) async {
    if (key.mushafId != edition.id || key.pageNumber > edition.pageCount) {
      return null;
    }
    if (await _layoutRepository.getPage(key) == null) return null;
    final placements = await _layoutRepository.getWordPlacements(key);
    final anchor = placements.firstOrNull?.ayahKey;
    if (anchor == null || !await _quranRepository.containsAyah(anchor)) {
      return null;
    }
    return QuranNavigationTarget(ayahKey: anchor, pageKey: key);
  }
}
