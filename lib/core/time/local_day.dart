abstract final class LocalDay {
  static DateTime date(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static String key(DateTime value) {
    final local = date(value);
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  static DateTime parse(String value) {
    final parts = value.split('-').map(int.parse).toList(growable: false);
    if (parts.length != 3) {
      throw FormatException('Invalid local day key: $value');
    }
    return DateTime(parts[0], parts[1], parts[2]);
  }
}
