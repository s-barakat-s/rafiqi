class DailyTask {
  const DailyTask({
    required this.id,
    required this.title,
    required this.type,
    this.goal,
    this.isBase = false,
    this.taskType = manualTaskType,
    this.collectionId,
    this.tasbeehPhraseId,
    this.tasbeehPhraseText,
    this.tasbeehTargetCount,
    this.baselineTotalCount = 0,
  });

  static const manualTaskType = 'manual';
  static const adhkarCollectionTaskType = 'adhkarCollection';
  static const tasbeehTargetTaskType = 'tasbeehTarget';

  final String id;
  final String title;
  final String type;
  final int? goal;
  final bool isBase;
  final String taskType;
  final String? collectionId;
  final String? tasbeehPhraseId;
  final String? tasbeehPhraseText;
  final int? tasbeehTargetCount;
  final int baselineTotalCount;

  factory DailyTask.fromJson(Map<String, dynamic> json) => DailyTask(
    id: json['id'] as String,
    title: json['title'] as String,
    type: json['type'] as String,
    goal: json['goal'] as int?,
    isBase: json['isBase'] as bool? ?? false,
    taskType: json['taskType'] as String? ?? manualTaskType,
    collectionId: json['collectionId'] as String?,
    tasbeehPhraseId: json['tasbeehPhraseId'] as String?,
    tasbeehPhraseText: json['tasbeehPhraseText'] as String?,
    tasbeehTargetCount: json['tasbeehTargetCount'] as int?,
    baselineTotalCount: json['baselineTotalCount'] as int? ??
        json['baselineInAppCount'] as int? ??
        0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'goal': goal,
    'isBase': isBase,
    'taskType': taskType,
    'collectionId': collectionId,
    'tasbeehPhraseId': tasbeehPhraseId,
    'tasbeehPhraseText': tasbeehPhraseText,
    'tasbeehTargetCount': tasbeehTargetCount,
    'baselineTotalCount': baselineTotalCount,
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
    this.taskType = DailyTask.manualTaskType,
    this.collectionId,
    this.tasbeehPhraseId,
    this.tasbeehPhraseText,
    this.tasbeehTargetCount,
    this.progress = 0,
    this.baselineTotalCount = 0,
    this.externalContribution = 0,
  });

  final String id;
  final String title;
  final String type;
  final int? goal;
  final bool completed;
  final String? completionSource;
  final String taskType;
  final String? collectionId;
  final String? tasbeehPhraseId;
  final String? tasbeehPhraseText;
  final int? tasbeehTargetCount;
  final int progress;
  final int baselineTotalCount;
  final int externalContribution;

  DailyItemSnapshot copyWith({
    String? title,
    String? type,
    int? goal,
    bool? completed,
    String? completionSource,
    bool clearCompletionSource = false,
    String? taskType,
    String? collectionId,
    String? tasbeehPhraseId,
    String? tasbeehPhraseText,
    int? tasbeehTargetCount,
    int? progress,
    int? baselineTotalCount,
    int? externalContribution,
  }) => DailyItemSnapshot(
    id: id,
    title: title ?? this.title,
    type: type ?? this.type,
    goal: goal ?? this.goal,
    completed: completed ?? this.completed,
    completionSource: clearCompletionSource
        ? null
        : completionSource ?? this.completionSource,
    taskType: taskType ?? this.taskType,
    collectionId: collectionId ?? this.collectionId,
    tasbeehPhraseId: tasbeehPhraseId ?? this.tasbeehPhraseId,
    tasbeehPhraseText: tasbeehPhraseText ?? this.tasbeehPhraseText,
    tasbeehTargetCount: tasbeehTargetCount ?? this.tasbeehTargetCount,
    progress: progress ?? this.progress,
    baselineTotalCount: baselineTotalCount ?? this.baselineTotalCount,
    externalContribution: externalContribution ?? this.externalContribution,
  );

  factory DailyItemSnapshot.fromJson(Map<String, dynamic> json) =>
      DailyItemSnapshot(
        id: json['id'] as String,
        title: json['title'] as String,
        type: json['type'] as String,
        goal: json['goal'] as int?,
        completed: json['completed'] as bool? ?? false,
        completionSource: json['completionSource'] as String?,
        taskType: json['taskType'] as String? ?? DailyTask.manualTaskType,
        collectionId: json['collectionId'] as String?,
        tasbeehPhraseId: json['tasbeehPhraseId'] as String?,
        tasbeehPhraseText: json['tasbeehPhraseText'] as String?,
        tasbeehTargetCount: json['tasbeehTargetCount'] as int?,
        progress: json['progress'] as int? ?? 0,
        baselineTotalCount: json['baselineTotalCount'] as int? ??
            json['baselineInAppCount'] as int? ??
            0,
        externalContribution: json['externalContribution'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'goal': goal,
    'completed': completed,
    'completionSource': completionSource,
    'taskType': taskType,
    'collectionId': collectionId,
    'tasbeehPhraseId': tasbeehPhraseId,
    'tasbeehPhraseText': tasbeehPhraseText,
    'tasbeehTargetCount': tasbeehTargetCount,
    'progress': progress,
    'baselineTotalCount': baselineTotalCount,
    'externalContribution': externalContribution,
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
