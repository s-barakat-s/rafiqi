import 'package:meta/meta.dart';

@immutable
final class AyahKey implements Comparable<AyahKey> {
  const AyahKey(this.surahNumber, this.ayahNumber)
    : assert(surahNumber >= 1 && surahNumber <= 114),
      assert(ayahNumber >= 1);

  factory AyahKey.parse(String value) {
    final match = RegExp(r'^(\d{1,3}):(\d+)$').firstMatch(value);
    if (match == null) throw FormatException('Invalid Ayah key', value);
    final surah = int.parse(match.group(1)!);
    final ayah = int.parse(match.group(2)!);
    if (surah < 1 || surah > 114 || ayah < 1) {
      throw FormatException('Ayah key is out of range', value);
    }
    return AyahKey(surah, ayah);
  }

  final int surahNumber;
  final int ayahNumber;

  String serialize() => '$surahNumber:$ayahNumber';

  @override
  int compareTo(AyahKey other) =>
      switch (surahNumber.compareTo(other.surahNumber)) {
        0 => ayahNumber.compareTo(other.ayahNumber),
        final result => result,
      };

  @override
  bool operator ==(Object other) =>
      other is AyahKey &&
      surahNumber == other.surahNumber &&
      ayahNumber == other.ayahNumber;

  @override
  int get hashCode => Object.hash(surahNumber, ayahNumber);

  @override
  String toString() => serialize();
}

@immutable
final class WordKey implements Comparable<WordKey> {
  const WordKey._(this.surahNumber, this.ayahNumber, this.wordNumber);

  factory WordKey(int surahNumber, int ayahNumber, int wordNumber) {
    if (surahNumber < 1 ||
        surahNumber > 114 ||
        ayahNumber < 1 ||
        wordNumber < 1) {
      throw ArgumentError('Word key components are out of range');
    }
    return WordKey._(surahNumber, ayahNumber, wordNumber);
  }

  factory WordKey.fromAyah(AyahKey ayahKey, int wordNumber) =>
      WordKey(ayahKey.surahNumber, ayahKey.ayahNumber, wordNumber);

  factory WordKey.parse(String value) {
    final match = RegExp(r'^(\d{1,3}):(\d+):(\d+)$').firstMatch(value);
    if (match == null) throw FormatException('Invalid Word key', value);
    final key = AyahKey.parse('${match.group(1)}:${match.group(2)}');
    final word = int.parse(match.group(3)!);
    if (word < 1) throw FormatException('Word key is out of range', value);
    return WordKey.fromAyah(key, word);
  }

  final int surahNumber;
  final int ayahNumber;
  final int wordNumber;

  AyahKey get ayahKey => AyahKey(surahNumber, ayahNumber);

  String serialize() => '${ayahKey.serialize()}:$wordNumber';

  @override
  int compareTo(WordKey other) {
    final ayahResult = ayahKey.compareTo(other.ayahKey);
    return ayahResult == 0
        ? wordNumber.compareTo(other.wordNumber)
        : ayahResult;
  }

  @override
  bool operator ==(Object other) =>
      other is WordKey &&
      surahNumber == other.surahNumber &&
      ayahNumber == other.ayahNumber &&
      wordNumber == other.wordNumber;

  @override
  int get hashCode => Object.hash(surahNumber, ayahNumber, wordNumber);

  @override
  String toString() => serialize();
}
