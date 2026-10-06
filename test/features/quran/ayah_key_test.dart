import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeh/features/quran/domain/models/ayah_key.dart';

void main() {
  group('AyahKey', () {
    test('parses, serializes, compares, and has value equality', () {
      final key = AyahKey.parse('2:255');
      expect(key, const AyahKey(2, 255));
      expect(key.serialize(), '2:255');
      expect(const AyahKey(1, 7).compareTo(key), lessThan(0));
      expect({key, const AyahKey(2, 255)}, hasLength(1));
    });

    test('rejects malformed and structurally invalid keys', () {
      for (final value in [
        '',
        '2',
        '2:',
        'a:1',
        '0:1',
        '115:1',
        '2:0',
        '2:1:3',
      ]) {
        expect(
          () => AyahKey.parse(value),
          throwsFormatException,
          reason: value,
        );
      }
    });
  });

  test('WordKey is parseable without inventing word data', () {
    expect(WordKey.parse('2:255:3'), WordKey(2, 255, 3));
    expect(WordKey.parse('2:255:3').serialize(), '2:255:3');
    expect(() => WordKey.parse('2:255:0'), throwsFormatException);
  });
}
