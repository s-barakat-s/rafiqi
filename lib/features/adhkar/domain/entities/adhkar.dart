enum DhikrEntryType { prelude, single, sequenceStep, compositeStep }

enum AdhkarCategoryKind { morning, evening, afterPrayer, sleep, custom }

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

  DhikrItem withRepeatCount(int value) => DhikrItem(
    id: id,
    order: order,
    category: category,
    text: text,
    repeatCount: value,
    entryType: entryType,
    parentId: parentId,
    countDescription: value == repeatCount ? countDescription : null,
    instruction: instruction,
    appliesTo: appliesTo,
    source: source,
    fullSource: fullSource,
    virtue: virtue,
    virtuePreview: virtuePreview,
    hadithText: hadithText,
    explanation: explanation,
    audioUrl: audioUrl,
    isQuran: isQuran,
    surah: surah,
    ayahFrom: ayahFrom,
    ayahTo: ayahTo,
  );
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
