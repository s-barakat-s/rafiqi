class AdhkarCollectionOverrides {
  const AdhkarCollectionOverrides({
    this.hiddenDhikrIds = const {},
    this.repeatCountOverrides = const {},
    this.customOrder = const [],
    this.addedDhikrItems = const [],
  });

  final Set<String> hiddenDhikrIds;
  final Map<String, int> repeatCountOverrides;
  final List<String> customOrder;
  final List<UserAddedDhikr> addedDhikrItems;

  bool get isEmpty =>
      hiddenDhikrIds.isEmpty &&
      repeatCountOverrides.isEmpty &&
      customOrder.isEmpty &&
      addedDhikrItems.isEmpty;

  Map<String, dynamic> toJson() => {
    'hiddenDhikrIds': hiddenDhikrIds.toList(growable: false),
    'repeatCountOverrides': repeatCountOverrides,
    'customOrder': customOrder,
    'addedDhikrItems': addedDhikrItems.map((item) => item.toJson()).toList(),
  };

  factory AdhkarCollectionOverrides.fromJson(Map<String, dynamic> json) {
    final rawCounts = json['repeatCountOverrides'];
    return AdhkarCollectionOverrides(
      hiddenDhikrIds: (json['hiddenDhikrIds'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toSet(),
      repeatCountOverrides: rawCounts is Map<String, dynamic>
          ? {
              for (final entry in rawCounts.entries)
                if (entry.value is int && (entry.value as int) >= 1)
                  entry.key: entry.value as int,
            }
          : const {},
      customOrder: (json['customOrder'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      addedDhikrItems:
          (json['addedDhikrItems'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(UserAddedDhikr.fromJson)
              .toList(),
    );
  }
}

class UserAddedDhikr {
  const UserAddedDhikr({
    required this.id,
    required this.text,
    required this.repeatCount,
  });

  final String id;
  final String text;
  final int repeatCount;

  factory UserAddedDhikr.fromJson(Map<String, dynamic> json) => UserAddedDhikr(
    id: json['id'] as String,
    text: json['text'] as String,
    repeatCount: (json['repeatCount'] as int).clamp(1, 1000000).toInt(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'repeatCount': repeatCount,
  };
}
