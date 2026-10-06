import 'package:tasbeh/features/quran/domain/mushaf/mushaf_models.dart';

/// Maps a physical RTL Mushaf sequence to a zero-based lazy PageView index.
///
/// UI code should keep this mapping in one place. With an LTR PageView axis,
/// advancing the Mushaf uses a decreasing view index and a rightward gesture.
final class MushafPageIndexMapper {
  MushafPageIndexMapper({required this.editionId, required this.pageCount}) {
    if (pageCount < 1) throw ArgumentError.value(pageCount, 'pageCount');
  }

  final MushafEditionId editionId;
  final int pageCount;

  int viewIndexFor(MushafPageKey key) {
    _validateKey(key);
    return pageCount - key.pageNumber;
  }

  MushafPageKey pageKeyForViewIndex(int index) {
    if (index < 0 || index >= pageCount) {
      throw RangeError.range(index, 0, pageCount - 1, 'index');
    }
    return MushafPageKey(editionId, pageCount - index);
  }

  MushafPageKey? nextPage(MushafPageKey current) {
    _validateKey(current);
    return current.pageNumber == pageCount
        ? null
        : MushafPageKey(editionId, current.pageNumber + 1);
  }

  MushafPageKey? previousPage(MushafPageKey current) {
    _validateKey(current);
    return current.pageNumber == 1
        ? null
        : MushafPageKey(editionId, current.pageNumber - 1);
  }

  void _validateKey(MushafPageKey key) {
    if (key.mushafId != editionId || key.pageNumber > pageCount) {
      throw ArgumentError.value(key, 'key', 'does not belong to this edition');
    }
  }
}
