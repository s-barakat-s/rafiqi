enum DhikrEntryType { prelude, single, sequenceStep, compositeStep }

enum AdhkarCategoryKind { morning, evening, afterPrayer, sleep }

class DhikrItem {
  const DhikrItem({
    required this.id,
    required this.order,
    required this.category,
    required this.text,
    required this.repeatCount,
    required this.entryType,
    this.parentId,
    this.countDescription,
    this.instruction,
    this.appliesTo = const [],
    this.source,
    this.fullSource,
    this.virtue,
    this.virtuePreview,
    this.hadithText,
    this.explanation,
    this.audioUrl,
    this.isQuran,
    this.surah,
    this.ayahFrom,
    this.ayahTo,
  });

  final String id;
  final int order;
  final String category;
  final String text;
  final int repeatCount;
  final DhikrEntryType entryType;
  final String? parentId;
  final String? countDescription;
  final String? instruction;
  final List<String> appliesTo;
  final String? source;
  final String? fullSource;
  final String? virtue;
  final String? virtuePreview;
  final String? hadithText;
  final String? explanation;
  final String? audioUrl;
  final bool? isQuran;
  final String? surah;
  final int? ayahFrom;
  final int? ayahTo;

  bool get isPrelude => entryType == DhikrEntryType.prelude;
}

class AdhkarCategory {
  const AdhkarCategory({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String id;
  final AdhkarCategoryKind kind;
  final String title;
  final String subtitle;
  final List<DhikrItem> items;
}
