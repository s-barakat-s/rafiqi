/// Formats app-generated numbers without altering source or religious text.
abstract final class ArabicNumerals {
  static const _westernDigits = '0123456789';
  static const _arabicIndicDigits = '٠١٢٣٤٥٦٧٨٩';

  static String integer(int value, {bool groupThousands = true}) {
    final sign = value.isNegative ? '−' : '';
    final raw = value.abs().toString();
    final grouped = groupThousands
        ? raw.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '٬')
        : raw;
    return '$sign${digits(grouped)}';
  }

  static String percent(num value) => '${integer(value.round())}٪';

  /// Converts app-generated numeric text only. Religious/source text should
  /// remain untouched and must not be passed through this formatter.
  static String digits(String value) {
    return value.replaceAllMapped(RegExp(r'\d'), (match) {
      final index = _westernDigits.indexOf(match.group(0)!);
      return _arabicIndicDigits[index];
    });
  }
}
