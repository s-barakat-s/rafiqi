import 'package:flutter/foundation.dart';

/// Last Quran reading position shown on the Home "Continue Quran" card.
@immutable
class QuranReadingPosition {
  const QuranReadingPosition({
    required this.surahName,
    this.page,
    this.ayah,
    this.progress,
  });

  final String surahName;

  /// Last read page, if tracked.
  final int? page;

  /// Last read ayah, if tracked.
  final int? ayah;

  /// Overall reading progress in 0..1, if tracked. Rendered only when known.
  final double? progress;
}

/// Isolated presentation source for the Home Quran card.
///
/// No Quran reader exists yet, so this currently reports no saved position
/// (the card shows its empty state). Replace [load] with a real reading
/// progress repository later without touching the UI.
abstract final class QuranReadingSource {
  static const Future<QuranReadingPosition?> Function() load =
      _loadPlaceholder;

  static Future<QuranReadingPosition?> _loadPlaceholder() async => null;
}
