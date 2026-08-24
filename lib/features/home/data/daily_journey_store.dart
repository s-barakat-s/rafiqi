import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  }) =>
      DailyItemSnapshot(
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
  });

  final String dateKey;
  final List<DailyItemSnapshot> items;
  final DateTime? completedAt;
  bool get completed =>
      items.isNotEmpty && items.every((item) => item.completed);
  int get completedCount => items.where((item) => item.completed).length;

  DailyHistoryRecord copyWith({
    List<DailyItemSnapshot>? items,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) => DailyHistoryRecord(
    dateKey: dateKey,
    items: items ?? this.items,
    completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
  );

  factory DailyHistoryRecord.fromJson(Map<String, dynamic> json) =>
      DailyHistoryRecord(
        dateKey: json['date'] as String,
        items: (json['items'] as List<dynamic>)
            .map(
              (item) =>
                  DailyItemSnapshot.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
        completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {
    'date': dateKey,
    'completed': completed,
    'completedAt': completedAt?.toIso8601String(),
    'items': items.map((item) => item.toJson()).toList(),
  };
}

class DailyJourneyStore extends ChangeNotifier {
  DailyJourneyStore._();
  static final instance = DailyJourneyStore._();

  static const _tasksKey = 'home_daily_tasks';
  static const _legacyCompletionPrefix = 'home_daily_completion_';
  static const _historyKey = 'journey_daily_history_v1';

  static const baseTasks = [
    DailyTask(
      id: 'morning_adhkar',
      title: 'أذكار الصباح',
      type: 'ذكر',
      isBase: true,
    ),
    DailyTask(
      id: 'evening_adhkar',
      title: 'أذكار المساء',
      type: 'ذكر',
      isBase: true,
    ),
  ];

  bool _initialized = false;
  Future<void>? _initialization;
  List<DailyTask> _customTasks = const [];
  final Map<String, DailyHistoryRecord> _history = {};

  bool get initialized => _initialized;
  List<DailyTask> get tasks => [...baseTasks, ..._customTasks];
  Map<String, DailyHistoryRecord> get history => Map.unmodifiable(_history);
  DailyHistoryRecord get todayRecord => _history[dateKey(DateTime.now())]!;
  bool get readyForStreak => todayRecord.completed;

  Future<void> initialize() {
    return _initialization ??= _initialize().whenComplete(() {
      _initialization = null;
    });
  }

  Future<void> _initialize() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    _customTasks = (preferences.getStringList(_tasksKey) ?? const [])
        .map(
          (value) =>
              DailyTask.fromJson(jsonDecode(value) as Map<String, dynamic>),
        )
        .toList();
    _history
      ..clear()
      ..addEntries(
        (preferences.getStringList(_historyKey) ?? const []).map((value) {
          final record = DailyHistoryRecord.fromJson(
            jsonDecode(value) as Map<String, dynamic>,
          );
          return MapEntry(record.dateKey, record);
        }),
      );
    _resolveCalendarDays(preferences);
    _evaluateLoadedRecords();
    _initialized = true;
    await _saveHistory(preferences);
    notifyListeners();
  }

  void _resolveCalendarDays(SharedPreferences preferences) {
    final today = calendarDate(DateTime.now());
    if (_history.isEmpty) {
      final legacyCompleted =
          (preferences.getStringList(
                    '$_legacyCompletionPrefix${dateKey(today)}',
                  ) ??
                  const [])
              .toSet();
      _history[dateKey(today)] = _snapshotFor(
        today,
        completedIds: legacyCompleted,
      );
      return;
    }
    final latest = _history.keys
        .map(parseDateKey)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    var cursor = latest.add(const Duration(days: 1));
    while (!cursor.isAfter(today)) {
      _history[dateKey(cursor)] = _snapshotFor(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    _history.putIfAbsent(dateKey(today), () => _snapshotFor(today));
  }

  DailyHistoryRecord _snapshotFor(
    DateTime date, {
    Set<String> completedIds = const {},
  }) => DailyHistoryRecord(
    dateKey: dateKey(date),
    items: tasks
        .map(
          (task) => DailyItemSnapshot(
            id: task.id,
            title: task.title,
            type: task.type,
            goal: task.goal,
            completed: completedIds.contains(task.id),
            completionSource: completedIds.contains(task.id) ? 'manual' : null,
          ),
        )
        .toList(),
  );

  Future<void> addTask(DailyTask task) async {
    _customTasks = [..._customTasks, task];
    final todayKey = dateKey(DateTime.now());
    final current = _history[todayKey] ?? _snapshotFor(DateTime.now());
    _history[todayKey] = _evaluateCompletion(current.copyWith(
      items: [
        ...current.items,
        DailyItemSnapshot(
          id: task.id,
          title: task.title,
          type: task.type,
          goal: task.goal,
          completed: false,
        ),
      ],
    ));
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _tasksKey,
      _customTasks.map((item) => jsonEncode(item.toJson())).toList(),
    );
    await _saveHistory(preferences);
    notifyListeners();
  }

  Future<void> setCompleted(
    String itemId,
    bool completed, {
    String source = 'manual',
  }) async {
    final key = dateKey(DateTime.now());
    final current = _history[key] ?? _snapshotFor(DateTime.now());
    final isLatchedAdhkar =
        itemId == 'morning_adhkar' || itemId == 'evening_adhkar';
    if (!completed &&
        isLatchedAdhkar &&
        current.items.any((item) => item.id == itemId && item.completed)) {
      return;
    }
    _history[key] = _evaluateCompletion(current.copyWith(
      items: current.items
          .map(
            (item) => item.id == itemId
                ? item.copyWith(
                    completed: completed,
                    completionSource: completed ? source : null,
                    clearCompletionSource: !completed,
                  )
                : item,
          )
          .toList(),
    ));
    final preferences = await SharedPreferences.getInstance();
    await _saveHistory(preferences);
    notifyListeners();
  }

  Future<void> synchronizeAdhkarCompletion({
    required bool morningCompletedInReader,
    required bool eveningCompletedInReader,
  }) async {
    final key = dateKey(DateTime.now());
    final current = _history[key] ?? _snapshotFor(DateTime.now());
    final readerState = {
      'morning_adhkar': morningCompletedInReader,
      'evening_adhkar': eveningCompletedInReader,
    };
    final updatedItems = current.items.map((item) {
      final readerCompleted = readerState[item.id];
      if (readerCompleted != true || item.completed) {
        return item;
      }
      return item.copyWith(
        completed: true,
        completionSource: 'reader',
      );
    }).toList();
    final updated = _evaluateCompletion(current.copyWith(items: updatedItems));
    if (_sameRecord(current, updated)) return;
    _history[key] = updated;
    final preferences = await SharedPreferences.getInstance();
    await _saveHistory(preferences);
    notifyListeners();
  }

  Future<void> setAdhkarReaderCompletion(
    String categoryId,
    bool completed, {
    DateTime? day,
  }) async {
    if (!completed) return;
    final itemId = switch (categoryId) {
      'morning' => 'morning_adhkar',
      'evening' => 'evening_adhkar',
      _ => null,
    };
    if (itemId == null) return;
    if (!_initialized) await initialize();

    final recordDate = calendarDate(day ?? DateTime.now());
    final key = dateKey(recordDate);
    final current = _history[key] ?? _snapshotFor(recordDate);
    final updated = _evaluateCompletion(
      current.copyWith(
        items: current.items.map((item) {
          if (item.id != itemId || item.completed) {
            return item;
          }
          return item.copyWith(
            completed: true,
            completionSource: 'reader',
          );
        }).toList(),
      ),
    );
    if (_sameRecord(current, updated)) return;
    _history[key] = updated;
    final preferences = await SharedPreferences.getInstance();
    await _saveHistory(preferences);
    notifyListeners();
  }

  DailyHistoryRecord _evaluateCompletion(
    DailyHistoryRecord record, {
    DateTime? completionTime,
  }) {
    if (!record.completed) {
      return record.completedAt == null
          ? record
          : record.copyWith(clearCompletedAt: true);
    }
    return record.completedAt != null
        ? record
        : record.copyWith(completedAt: completionTime ?? DateTime.now());
  }

  void _evaluateLoadedRecords() {
    final todayKey = dateKey(DateTime.now());
    for (final entry in _history.entries.toList()) {
      final date = parseDateKey(entry.key);
      final fallbackCompletionTime = entry.key == todayKey
          ? DateTime.now()
          : DateTime(date.year, date.month, date.day, 23, 59, 59);
      _history[entry.key] = _evaluateCompletion(
        entry.value,
        completionTime: fallbackCompletionTime,
      );
    }
  }

  bool _sameRecord(DailyHistoryRecord a, DailyHistoryRecord b) {
    if (a.completedAt != b.completedAt || a.items.length != b.items.length) {
      return false;
    }
    for (var index = 0; index < a.items.length; index++) {
      final left = a.items[index];
      final right = b.items[index];
      if (left.id != right.id ||
          left.completed != right.completed ||
          left.completionSource != right.completionSource) {
        return false;
      }
    }
    return true;
  }

  Future<void> _saveHistory(SharedPreferences preferences) =>
      preferences.setStringList(
        _historyKey,
        (_history.values.toList()
              ..sort((a, b) => a.dateKey.compareTo(b.dateKey)))
            .map((record) => jsonEncode(record.toJson()))
            .toList(),
      );

  DailyHistoryRecord? recordFor(DateTime date) => _history[dateKey(date)];

  int get currentStreak {
    if (!_initialized) return 0;
    final today = calendarDate(DateTime.now());
    var cursor = todayRecord.completed
        ? today
        : today.subtract(const Duration(days: 1));
    var streak = 0;
    while (_history[dateKey(cursor)]?.completed ?? false) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get longestStreak {
    final records = _history.values.toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    var longest = 0;
    var running = 0;
    DateTime? previous;
    for (final record in records) {
      final date = parseDateKey(record.dateKey);
      final consecutive =
          previous != null && date.difference(previous).inDays == 1;
      running = record.completed ? (consecutive ? running + 1 : 1) : 0;
      if (running > longest) longest = running;
      previous = date;
    }
    return longest;
  }

  int completedBetween(DateTime start, DateTime end) {
    var count = 0;
    var cursor = calendarDate(start);
    final last = calendarDate(end);
    while (!cursor.isAfter(last)) {
      if (_history[dateKey(cursor)]?.completed ?? false) count++;
      cursor = cursor.add(const Duration(days: 1));
    }
    return count;
  }
}

DateTime calendarDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String dateKey(DateTime value) {
  final date = calendarDate(value);
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

DateTime parseDateKey(String value) {
  final parts = value.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}
