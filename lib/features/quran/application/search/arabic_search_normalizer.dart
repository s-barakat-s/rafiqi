abstract final class ArabicSearchNormalizer {
  static final _combiningMarks = RegExp(
    '[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]',
  );
  static final _alefVariants = RegExp('[\u0622\u0623\u0625\u0671]');
  static final _nonLettersOrNumbers = RegExp(r'[^\p{L}\p{N}]+', unicode: true);
  static final _whitespace = RegExp(r'\s+');

  static String normalize(String input) => input
      .toLowerCase()
      .replaceAll(_combiningMarks, '')
      .replaceAll('\u0640', '')
      .replaceAll(_alefVariants, '\u0627')
      .replaceAll(_nonLettersOrNumbers, ' ')
      .replaceAll(_whitespace, ' ')
      .trim();

  static List<String> tokens(String input) {
    final normalized = normalize(input);
    return normalized.isEmpty
        ? const []
        : List.unmodifiable(normalized.split(' '));
  }
}
