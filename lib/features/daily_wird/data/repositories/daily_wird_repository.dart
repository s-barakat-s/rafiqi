import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/core/time/local_day.dart';
import 'package:tasbeh/features/daily_wird/domain/entities/daily_wird.dart';
import 'package:tasbeh/features/daily_wird/domain/services/daily_streak_calculator.dart';

class DailyWirdRepository extends ChangeNotifier {
  DailyWirdRepository._();
  static final instance = DailyWirdRepository._();

  static const _tasksKey = 'home_daily_tasks';
  static const _legacyCompletionPrefix = 'home_daily_completion_';
  static const _historyKey = 'journey_daily_history_v1';

  static const baseTasks = [
    DailyTask(
      id: 'morning_adhkar',
      title: 'أذكار الصباح',
      type: 'ذكر',
      isBase: true,
      taskType: DailyTask.adhkarCollectionTaskType,
      collectionId: 'morning',
    ),
    DailyTask(
      id: 'evening_adhkar',
      title: 'أذكار المساء',
      type: 'ذكر',
      isBase: true,
      taskType: DailyTask.adhkarCollectionTaskType,
      collectionId: 'evening',
    ),
  ];

  bool _initialized = false;
  Future<void>? _initialization;
  List<DailyTask> _customTasks = const [];
  final Map<String, DailyHistoryRecord> _history = {};

  bool get initialized => _initialized;
  List<DailyTask> get tasks => [...baseTasks, ..._customTasks];
  Map<String, DailyHistoryRecord> get history => Map.unmodifiable(_history);
  DailyHistoryRecord get todayRecord => _history[LocalDay.key(DateTime.now())]!;
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
    final today = LocalDay.date(DateTime.now());
    if (_history.isEmpty) {
      final legacyCompleted =
          (preferences.getStringList(
                    '$_legacyCompletionPrefix${LocalDay.key(today)}',
                  ) ??
                  const [])
              .toSet();
      _history[LocalDay.key(today)] = _snapshotFor(
        today,
        completedIds: legacyCompleted,
      );
      return;
    }
    final latest = _history.keys
        .map(LocalDay.parse)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    var cursor = latest.add(const Duration(days: 1));
    while (!cursor.isAfter(today)) {
      _history[LocalDay.key(cursor)] = _snapshotFor(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    _history.putIfAbsent(LocalDay.key(today), () => _snapshotFor(today));
  }

  DailyHistoryRecord _snapshotFor(
    DateTime date, {
    Set<String> completedIds = const {},
  }) => DailyHistoryRecord(
    dateKey: LocalDay.key(date),
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
    final todayKey = LocalDay.key(DateTime.now());
    final current = _history[todayKey] ?? _snapshotFor(DateTime.now());
    _history[todayKey] = _evaluateCompletion(
      current.copyWith(
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
      ),
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _tasksKey,
      _customTasks.map((item) => jsonEncode(item.toJson())).toList(),
    );
    await _saveHistory(preferences);
    notifyListeners();
  }

  bool hasLinkedCollection(String collectionId) => tasks.any(
    (task) =>
        task.taskType == DailyTask.adhkarCollectionTaskType &&
        task.collectionId == collectionId,
  );

  Future<void> renameLinkedCollectionTask(
    String collectionId,
    String title,
  ) async {
    _customTasks = _customTasks
        .map(
          (task) => task.collectionId == collectionId
              ? DailyTask(
                  id: task.id,
                  title: title,
                  type: task.type,
                  goal: task.goal,
                  taskType: task.taskType,
                  collectionId: task.collectionId,
                )
              : task,
        )
        .toList();
    final preferences = await SharedPreferences.getInstance();
    await _saveTasks(preferences);
    notifyListeners();
  }

  Future<void> removeLinkedCollectionTask(String collectionId) async {
    final removedIds = _customTasks
        .where((task) => task.collectionId == collectionId)
        .map((task) => task.id)
        .toSet();
    if (removedIds.isEmpty) return;
    _customTasks = _customTasks
        .where((task) => !removedIds.contains(task.id))
        .toList();
    final todayKey = LocalDay.key(DateTime.now());
    final current = _history[todayKey];
    if (current != null) {
      _history[todayKey] = _evaluateCompletion(
        current.copyWith(
          items: current.items
              .where((item) => !removedIds.contains(item.id))
              .toList(),
        ),
      );
    }
    final preferences = await SharedPreferences.getInstance();
    await _saveTasks(preferences);
    await _saveHistory(preferences);
    notifyListeners();
  }

  Future<void> _saveTasks(SharedPreferences preferences) =>
      preferences.setStringList(
        _tasksKey,
        _customTasks.map((item) => jsonEncode(item.toJson())).toList(),
      );

  static const int maxMonthlyGraceDays = 2;

  int graceDaysUsedInMonth(DateTime month) {
    return _history.values.where((record) {
      final date = LocalDay.parse(record.dateKey);
      return date.year == month.year &&
          date.month == month.month &&
          record.graceUsed &&
          !record.completed;
    }).length;
  }

  int remainingGraceDaysInMonth(DateTime month) {
    final used = graceDaysUsedInMonth(month);
    return used >= maxMonthlyGraceDays ? 0 : maxMonthlyGraceDays - used;
  }

  Future<void> setGraceUsed(DateTime day, bool used) async {
    final date = LocalDay.date(day);
    final today = LocalDay.date(DateTime.now());
    if (!date.isBefore(today)) return;

    final key = LocalDay.key(date);
    final current = _history[key] ?? _snapshotFor(date);
    if (current.completed && used) return;

    if (used && remainingGraceDaysInMonth(date) <= 0) {
      return;
    }

    _history[key] = current.copyWith(graceUsed: used);
    final preferences = await SharedPreferences.getInstance();
    await _saveHistory(preferences);
    notifyListeners();
  }

  Future<void> setCompleted(
    String itemId,
    bool completed, {
    DateTime? day,
    String source = 'manual',
  }) async {
    final date = LocalDay.date(day ?? DateTime.now());
    final key = LocalDay.key(date);
    final current = _history[key] ?? _snapshotFor(date);
    _history[key] = _evaluateCompletion(
      current.copyWith(
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
      ),
    );
    final preferences = await SharedPreferences.getInstance();
    await _saveHistory(preferences);
    notifyListeners();
  }

  Future<void> setAdhkarReaderCompletion(
    String categoryId,
    bool completed, {
    DateTime? day,
    String source = 'reader',
  }) async {
    if (!completed) return;
    final itemId = switch (categoryId) {
      'morning' => 'morning_adhkar',
      'evening' => 'evening_adhkar',
      _ => null,
    };
    if (itemId == null) return;
    if (!_initialized) await initialize();

    final recordDate = LocalDay.date(day ?? DateTime.now());
    final key = LocalDay.key(recordDate);
    final current = _history[key] ?? _snapshotFor(recordDate);
    final updated = _evaluateCompletion(
      current.copyWith(
        items: current.items.map((item) {
          if (item.id != itemId || item.completed) {
            return item;
          }
          return item.copyWith(completed: true, completionSource: source);
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
    final updated = record.graceUsed
        ? record.copyWith(graceUsed: false)
        : record;
    return updated.completedAt != null
        ? updated
        : updated.copyWith(completedAt: completionTime ?? DateTime.now());
  }

  void _evaluateLoadedRecords() {
    final todayKey = LocalDay.key(DateTime.now());
    for (final entry in _history.entries.toList()) {
      final date = LocalDay.parse(entry.key);
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
    if (a.completedAt != b.completedAt ||
        a.graceUsed != b.graceUsed ||
        a.items.length != b.items.length) {
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

  DailyHistoryRecord? recordFor(DateTime date) {
    final day = LocalDay.date(date);
    final key = LocalDay.key(day);
    if (_history.containsKey(key)) {
      return _history[key];
    }
    final today = LocalDay.date(DateTime.now());
    if (day.isAfter(today)) {
      return null;
    }
    final snapshot = _snapshotFor(day);
    _history[key] = snapshot;
    return snapshot;
  }

  int get currentStreak {
    if (!_initialized) return 0;
    return DailyStreakCalculator.current(_history);
  }

  int get longestStreak => DailyStreakCalculator.longest(_history);

  int completedBetween(DateTime start, DateTime end) {
    return DailyStreakCalculator.completedBetween(_history, start, end);
  }
}
