/// Typed model representing an item in daily_dhikr.json.
class DailyDhikr {
  const DailyDhikr({
    required this.id,
    required this.category,
    required this.text,
    required this.repeatCount,
    required this.countType,
    required this.countDescription,
    required this.sourceShort,
    required this.sourceFull,
    required this.virtueShort,
    required this.virtueFull,
    required this.authenticity,
  });

  final String id;
  final String category;
  final String text;
  final int repeatCount;
  final String countType;
  final String countDescription;
  final String sourceShort;
  final String sourceFull;
  final String virtueShort;
  final String virtueFull;
  final String authenticity;

  factory DailyDhikr.fromJson(Map<String, dynamic> json) {
    final source = json['source'] as Map<String, dynamic>? ?? const {};
    final virtue = json['virtue'] as Map<String, dynamic>? ?? const {};
    final sourceMeta = json['sourceMeta'] as Map<String, dynamic>? ?? const {};

    return DailyDhikr(
      id: json['id'] as String,
      category: json['category'] as String? ?? '',
      text: json['text'] as String,
      repeatCount: json['repeatCount'] as int? ?? 1,
      countType: json['countType'] as String? ?? '',
      countDescription: json['countDescription'] as String? ?? '',
      sourceShort: source['short'] as String? ?? '',
      sourceFull: source['full'] as String? ?? '',
      virtueShort: virtue['short'] as String? ?? '',
      virtueFull: virtue['full'] as String? ?? '',
      authenticity: sourceMeta['authenticity'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'text': text,
    'repeatCount': repeatCount,
    'countType': countType,
    'countDescription': countDescription,
    'source': {'short': sourceShort, 'full': sourceFull},
    'virtue': {'short': virtueShort, 'full': virtueFull},
    'sourceMeta': {'authenticity': authenticity},
  };
}
