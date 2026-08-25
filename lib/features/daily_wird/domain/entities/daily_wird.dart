class DailyTask {
  const DailyTask({
    required this.id,
    required this.title,
    required this.type,
    this.goal,
    this.isBase = false,
  });

  final String id;
  final String title;
  final String type;
  final int? goal;
  final bool isBase;

  factory DailyTask.fromJson(Map<String, dynamic> json) => DailyTask(
    id: json['id'] as String,
    title: json['title'] as String,
    type: json['type'] as String,
    goal: json['goal'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'goal': goal,
  };
}

class DailyItemSnapshot {
  const DailyItemSnapshot({
    required this.id,
    required this.title,
    required this.type,
    required this.completed,
    this.goal,
    this.completionSource,
  });

  final String id;
  final String title;
  final String type;
  final int? goal;
  final bool completed;
  final String? completionSource;

  DailyItemSnapshot copyWith({
    bool? completed,
    String? completionSource,
    bool clearCompletionSource = false,
  }) => DailyItemSnapshot(
    id: id,
    title: title,
    type: type,
    goal: goal,
    completed: completed ?? this.completed,
    completionSource: clearCompletionSource
        ? null
        : completionSource ?? this.completionSource,
  );

  factory DailyItemSnapshot.fromJson(Map<String, dynamic> json) =>
      DailyItemSnapshot(
        id: json['id'] as String,
        title: json['title'] as String,
        type: json['type'] as String,
        goal: json['goal'] as int?,
        completed: json['completed'] as bool? ?? false,
        completionSource: json['completionSource'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'goal': goal,
    'completed': completed,
    'completionSource': completionSource,
  };
}

class DailyHistoryRecord {
  const DailyHistoryRecord({
    required this.dateKey,
    required this.items,
    this.completedAt,
    this.graceUsed = false,
  });

  final String dateKey;
  final List<DailyItemSnapshot> items;
  final DateTime? completedAt;
  final bool graceUsed;

  bool get completed =>
      items.isNotEmpty && items.every((item) => item.completed);
  int get completedCount => items.where((item) => item.completed).length;

  DailyHistoryRecord copyWith({
    List<DailyItemSnapshot>? items,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    bool? graceUsed,
  }) => DailyHistoryRecord(
    dateKey: dateKey,
    items: items ?? this.items,
    completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
    graceUsed: graceUsed ?? this.graceUsed,
  );

  factory DailyHistoryRecord.fromJson(Map<String, dynamic> json) =>
      DailyHistoryRecord(
        dateKey: json['date'] as String,
        items:
            (json['items'] as List<dynamic>?)
                ?.map(
                  (item) =>
                      DailyItemSnapshot.fromJson(item as Map<String, dynamic>),
                )
                .toList() ??
            const [],
        completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
        graceUsed: json['graceUsed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
    'date': dateKey,
    'completed': completed,
    'completedAt': completedAt?.toIso8601String(),
    'graceUsed': graceUsed,
    'items': items.map((item) => item.toJson()).toList(),
  };
}

/// Authoritative source for today's wird and immutable daily snapshots.
