import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/core/time/local_day.dart';
import 'package:tasbeh/features/daily_wird/domain/entities/daily_wird.dart';
import 'package:tasbeh/features/daily_wird/domain/services/daily_streak_calculator.dart';
import 'package:tasbeh/features/tasbeeh/data/repositories/tasbeeh_repository.dart';

class DailyWirdRepository extends ChangeNotifier {
  DailyWirdRepository._();
  static final instance = DailyWirdRepository._();

  static const _tasksKey = 'home_daily_tasks';
  static const _legacyCompletionPrefix = 'home_daily_completion_';
  static const _historyKey = 'journey_daily_history_v1';
  static const _historyIndexKey = 'journey_daily_history_v2.index';
  static const _historyRecordPrefix = 'journey_daily_history_v2.';

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
  DailyHistoryRecord get todayRecord => _ensureTodayRecord();
  bool get readyForStreak => todayRecord.completed;

  DailyHistoryRecord _ensureTodayRecord() {
    final today = LocalDay.date(DateTime.now());
    final todayKey = LocalDay.key(today);
    return _history.putIfAbsent(todayKey, () => _snapshotFor(today));
  }

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
    await _loadIndexedHistory(preferences);
    _resolveCalendarDays(preferences);
    _evaluateLoadedRecords();
    _initialized = true;
    await _saveHistory(preferences);
    notifyListeners();
  }

  Future<void> _loadIndexedHistory(SharedPreferences preferences) async {
    var keys = preferences.getStringList(_historyIndexKey);
    if (keys == null) {
      final migrated = (preferences.getStringList(_historyKey) ?? const [])
          .map(
            (value) => DailyHistoryRecord.fromJson(
              jsonDecode(value) as Map<String, dynamic>,
            ),
          )
          .toList();
      keys = migrated.map((record) => record.dateKey).toList();
      await Future.wait([
        for (final record in migrated)
          preferences.setString(
            '$_historyRecordPrefix${record.dateKey}',
            jsonEncode(record.toJson()),
          ),
        preferences.setStringList(_historyIndexKey, keys),
      ]);
    }

    _history.clear();
    for (final key in keys) {
      final encoded = preferences.getString('$_historyRecordPrefix$key');
      if (encoded == null) continue;
      final record = DailyHistoryRecord.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      _history[record.dateKey] = record;
    }
  }

  Future<void> refreshDayForTasbeeh([DateTime? day]) async {
    final date = LocalDay.date(day ?? DateTime.now());
    final key = LocalDay.key(date);
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    if (!_initialized) {
      _customTasks = (preferences.getStringList(_tasksKey) ?? const [])
          .map(
            (value) =>
                DailyTask.fromJson(jsonDecode(value) as Map<String, dynamic>),
          )
          .toList();
    }
    final encoded = preferences.getString('$_historyRecordPrefix$key');
    if (encoded != null) {
      _history[key] = DailyHistoryRecord.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
    } else if (!_initialized) {
      await _loadIndexedHistory(preferences);
    }
    _initialized = true;
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
    _ensureTodayRecord();
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
            taskType: task.taskType,
            collectionId: task.collectionId,
            tasbeehPhraseId: task.tasbeehPhraseId,
            tasbeehPhraseText: task.tasbeehPhraseText,
            tasbeehTargetCount: task.tasbeehTargetCount,
            baselineTotalCount: 0,
            progress: 0,
            completed: completedIds.contains(task.id),
            completionSource: completedIds.contains(task.id) ? 'manual' : null,
          ),
        )
        .toList(),
  );

  Future<void> addTask(DailyTask task) async {
    if (task.taskType == DailyTask.tasbeehTargetTaskType &&
        task.tasbeehPhraseId != null &&
        hasLinkedTasbeehTask(
          task.tasbeehPhraseId!,
          task.tasbeehTargetCount ?? 0,
        )) {
      await updateTasbeehTaskTarget(
        phraseId: task.tasbeehPhraseId!,
        targetCount: task.tasbeehTargetCount ?? task.goal ?? 33,
        title: task.title,
      );
      return;
    }
    final baseline =
        task.taskType == DailyTask.tasbeehTargetTaskType &&
            task.tasbeehPhraseId != null
        ? await TasbeehRepository().eligibleCountForDay(
            LocalDay.key(DateTime.now()),
            task.tasbeehPhraseId!,
          )
        : 0;
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
            taskType: task.taskType,
            collectionId: task.collectionId,
            tasbeehPhraseId: task.tasbeehPhraseId,
            tasbeehPhraseText: task.tasbeehPhraseText,
            tasbeehTargetCount: task.tasbeehTargetCount,
            baselineTotalCount: baseline,
            progress: 0,
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

  Future<void> updateTasbeehTaskTarget({
    required String phraseId,
    required int targetCount,
    required String title,
  }) async {
    final taskIndex = _customTasks.indexWhere(
      (task) =>
          task.taskType == DailyTask.tasbeehTargetTaskType &&
          task.tasbeehPhraseId == phraseId,
    );
    if (taskIndex < 0 || targetCount <= 0) return;
    final oldTask = _customTasks[taskIndex];
    final updatedTask = DailyTask(
      id: oldTask.id,
      title: title,
      type: oldTask.type,
      goal: targetCount,
      isBase: oldTask.isBase,
      taskType: oldTask.taskType,
      collectionId: oldTask.collectionId,
      tasbeehPhraseId: oldTask.tasbeehPhraseId,
      tasbeehPhraseText: oldTask.tasbeehPhraseText,
      tasbeehTargetCount: targetCount,
    );
    _customTasks = [
      for (var i = 0; i < _customTasks.length; i++)
        if (i == taskIndex) updatedTask else _customTasks[i],
    ];

    final todayKey = LocalDay.key(DateTime.now());
    final current = _history[todayKey] ?? _snapshotFor(DateTime.now());
    final currentEligible = await TasbeehRepository().eligibleCountForDay(
      todayKey,
      phraseId,
    );
    final items = current.items.map((item) {
      if (item.id != oldTask.id) return item;
      final eligibleProgress = (currentEligible - item.baselineTotalCount)
          .clamp(0, targetCount)
          .toInt();
      final progress = (eligibleProgress + item.externalContribution)
          .clamp(0, targetCount)
          .toInt();
      final completed = progress >= targetCount;
      return item.copyWith(
        title: title,
        goal: targetCount,
        tasbeehTargetCount: targetCount,
        progress: progress,
        completed: completed,
        completionSource: completed ? item.completionSource ?? 'tasbeeh' : null,
        clearCompletionSource: !completed,
      );
    }).toList();
    _history[todayKey] = _evaluateCompletion(current.copyWith(items: items));
    final preferences = await SharedPreferences.getInstance();
    await _saveTasks(preferences);
    await _saveHistory(preferences);
    notifyListeners();
  }

  bool hasLinkedCollection(String collectionId) => tasks.any(
    (task) =>
        (task.taskType == DailyTask.adhkarCollectionTaskType &&
            task.collectionId == collectionId) ||
        (collectionId == 'morning' && task.id == 'morning_adhkar') ||
        (collectionId == 'evening' && task.id == 'evening_adhkar'),
  );

  bool hasLinkedTasbeehTask(String phraseId, int targetCount) => tasks.any(
    (task) =>
        task.taskType == DailyTask.tasbeehTargetTaskType &&
        task.tasbeehPhraseId == phraseId,
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
                  tasbeehPhraseId: task.tasbeehPhraseId,
                  tasbeehPhraseText: task.tasbeehPhraseText,
                  tasbeehTargetCount: task.tasbeehTargetCount,
                  baselineTotalCount: task.baselineTotalCount,
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
    final existing = current.items
        .where((item) => item.id == itemId)
        .firstOrNull;
    final isTasbeeh =
        existing?.taskType == DailyTask.tasbeehTargetTaskType &&
        existing?.tasbeehPhraseId != null;
    final currentEligible = isTasbeeh
        ? await TasbeehRepository().eligibleCountForDay(
            key,
            existing!.tasbeehPhraseId!,
          )
        : 0;
    _history[key] = _evaluateCompletion(
      current.copyWith(
        items: current.items.map((item) {
          if (item.id != itemId) return item;
          if (item.taskType != DailyTask.tasbeehTargetTaskType) {
            return item.copyWith(
              completed: completed,
              completionSource: completed ? source : null,
              clearCompletionSource: !completed,
            );
          }
          final target = item.tasbeehTargetCount ?? item.goal ?? 33;
          if (!completed) {
            return item.copyWith(
              completed: false,
              progress: 0,
              baselineTotalCount: currentEligible,
              externalContribution: 0,
              clearCompletionSource: true,
            );
          }
          final eligibleProgress = (currentEligible - item.baselineTotalCount)
              .clamp(0, target)
              .toInt();
          final missing = (target - eligibleProgress).clamp(0, target).toInt();
          return item.copyWith(
            completed: true,
            progress: target,
            externalContribution: missing,
            completionSource: source,
          );
        }).toList(),
      ),
    );
    final preferences = await SharedPreferences.getInstance();
    await _saveHistory(preferences);
    notifyListeners();
  }

  Future<bool> syncTasbeehProgress({
    required String dhikrId,
    required int currentEligibleTotal,
    DateTime? day,
  }) async {
    final date = LocalDay.date(day ?? DateTime.now());
    final key = LocalDay.key(date);
    final current = _history[key] ?? _snapshotFor(date);
    var newlyCompleted = false;
    final items = current.items.map((item) {
      if (item.taskType != DailyTask.tasbeehTargetTaskType ||
          item.tasbeehPhraseId != dhikrId) {
        return item;
      }
      final target = item.tasbeehTargetCount ?? item.goal ?? 33;
      final eligibleProgress = (currentEligibleTotal - item.baselineTotalCount)
          .clamp(0, target)
          .toInt();
      final calculatedProgress = (eligibleProgress + item.externalContribution)
          .clamp(0, target)
          .toInt();
      final manuallyCompleted =
          item.completed && item.completionSource == 'manual';
      final progress = manuallyCompleted ? target : calculatedProgress;
      final finished = progress >= target;
      if (finished && !item.completed) newlyCompleted = true;
      return item.copyWith(
        progress: progress,
        completed: finished || manuallyCompleted,
        completionSource: manuallyCompleted
            ? 'manual'
            : finished
            ? 'tasbeeh'
            : null,
        clearCompletionSource: !finished && !manuallyCompleted,
      );
    }).toList();
    final updated = _evaluateCompletion(current.copyWith(items: items));
    if (_sameRecord(current, updated)) return newlyCompleted;
    _history[key] = updated;
    final preferences = await SharedPreferences.getInstance();
    await _saveRecord(preferences, updated);
    notifyListeners();
    return newlyCompleted;
  }

  Map<String, int> externalContributionsBetween(DateTime start, DateTime end) {
    final result = <String, int>{};
    for (final record in _history.values) {
      final day = LocalDay.parse(record.dateKey);
      if (day.isBefore(LocalDay.date(start)) ||
          day.isAfter(LocalDay.date(end))) {
        continue;
      }
      for (final item in record.items) {
        final id = item.tasbeehPhraseId;
        if (id == null || item.externalContribution <= 0) continue;
        result[id] = (result[id] ?? 0) + item.externalContribution;
      }
    }
    return result;
  }

  Future<void> setAdhkarReaderCompletion(
    String categoryId,
    bool completed, {
    DateTime? day,
    String source = 'reader',
  }) async {
    if (!completed) return;
    if (!_initialized) await initialize();

    final recordDate = LocalDay.date(day ?? DateTime.now());
    final key = LocalDay.key(recordDate);
    final current = _history[key] ?? _snapshotFor(recordDate);
    final updated = _evaluateCompletion(
      current.copyWith(
        items: current.items.map((item) {
          final matchesCategory =
              (categoryId == 'morning' && item.id == 'morning_adhkar') ||
              (categoryId == 'evening' && item.id == 'evening_adhkar') ||
              (item.taskType == DailyTask.adhkarCollectionTaskType &&
                  item.collectionId == categoryId);
          if (!matchesCategory || item.completed) {
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
          left.completionSource != right.completionSource ||
          left.progress != right.progress ||
          left.baselineTotalCount != right.baselineTotalCount ||
          left.externalContribution != right.externalContribution) {
        return false;
      }
    }
    return true;
  }

  Future<void> _saveHistory(SharedPreferences preferences) async {
    final keys = _history.keys.toList()..sort();
    await Future.wait([
      for (final key in keys)
        preferences.setString(
          '$_historyRecordPrefix$key',
          jsonEncode(_history[key]!.toJson()),
        ),
      preferences.setStringList(_historyIndexKey, keys),
    ]);
  }

  Future<void> _saveRecord(
    SharedPreferences preferences,
    DailyHistoryRecord record,
  ) async {
    final keys = preferences.getStringList(_historyIndexKey) ?? <String>[];
    await Future.wait([
      preferences.setString(
        '$_historyRecordPrefix${record.dateKey}',
        jsonEncode(record.toJson()),
      ),
      if (!keys.contains(record.dateKey))
        preferences.setStringList(_historyIndexKey, [...keys, record.dateKey]),
    ]);
  }

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
    return _snapshotFor(day);
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
