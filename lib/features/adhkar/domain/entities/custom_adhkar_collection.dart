import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';

class CustomDhikrItem {
  const CustomDhikrItem({
    required this.id,
    required this.text,
    required this.repeatCount,
    required this.order,
  });

  final String id;
  final String text;
  final int repeatCount;
  final int order;

  factory CustomDhikrItem.fromJson(Map<String, dynamic> json) =>
      CustomDhikrItem(
        id: json['id'] as String,
        text: json['text'] as String,
        repeatCount: json['repeatCount'] as int,
        order: json['order'] as int,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'repeatCount': repeatCount,
    'order': order,
  };
}

class CustomAdhkarCollection {
  const CustomAdhkarCollection({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final List<CustomDhikrItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdhkarCategory toAdhkarCategory() => AdhkarCategory(
    id: id,
    title: name,
    subtitle: 'ورد شخصي أنشأته أنت',
    kind: AdhkarCategoryKind.custom,
    items: List.unmodifiable(
      (items.toList()..sort((a, b) => a.order.compareTo(b.order))).map(
        (item) => DhikrItem(
          id: item.id,
          order: item.order,
          category: id,
          text: item.text,
          repeatCount: item.repeatCount,
          entryType: DhikrEntryType.single,
        ),
      ),
    ),
  );

  factory CustomAdhkarCollection.fromJson(Map<String, dynamic> json) =>
      CustomAdhkarCollection(
        id: json['id'] as String,
        name: json['name'] as String,
        items: (json['items'] as List<dynamic>)
            .map(
              (item) =>
                  CustomDhikrItem.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'items': items.map((item) => item.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
