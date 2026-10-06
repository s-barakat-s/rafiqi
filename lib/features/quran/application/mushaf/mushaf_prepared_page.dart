import 'package:flutter/foundation.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_models.dart';
import 'package:tasbeh/features/quran/domain/mushaf/mushaf_rendering.dart';

@immutable
final class MushafPreparedWord {
  const MushafPreparedWord({
    required this.placement,
    required this.rendererWord,
  });

  final MushafWordPlacement placement;
  final MushafRenderWord rendererWord;
  WordKey get wordKey => placement.wordKey;
  AyahKey get ayahKey => placement.ayahKey;
}

@immutable
final class MushafPreparedLine {
  const MushafPreparedLine({required this.line, required this.words});

  final MushafLine line;
  final List<MushafPreparedWord> words;
}

@immutable
final class MushafPreparedPage {
  MushafPreparedPage({
    required this.edition,
    required this.page,
    required this.lines,
    required this.rendererPage,
  }) : _wordsByKey = Map.unmodifiable({
         for (final line in lines)
           for (final word in line.words) word.wordKey: word,
       });

  final MushafEdition edition;
  final MushafPage page;
  final List<MushafPreparedLine> lines;
  final MushafRendererPage rendererPage;
  final Map<WordKey, MushafPreparedWord> _wordsByKey;

  MushafPageKey get key => page.key;
  Iterable<MushafPreparedWord> get words => lines.expand((line) => line.words);

  MushafPreparedWord? word(WordKey key) => _wordsByKey[key];

  MushafPreparedWord? hitTest(MushafNormalizedPoint point) {
    for (final word in words) {
      if (word.rendererWord.regions.any((region) => region.contains(point))) {
        return word;
      }
    }
    return null;
  }

  List<MushafNormalizedRect> regionsForAyah(AyahKey ayahKey) =>
      List.unmodifiable(
        words
            .where((word) => word.ayahKey == ayahKey)
            .expand((word) => word.rendererWord.regions),
      );
}
