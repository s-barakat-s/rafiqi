import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/core/time/local_day.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar_progress.dart';

class AdhkarProgressRepository extends ChangeNotifier {
  AdhkarProgressRepository._();
  static final instance = AdhkarProgressRepository._();

  static const _keyPrefix = 'adhkar.readingProgress.';

  Future<AdhkarReadingProgress> load(
    AdhkarCategory category, {
    DateTime? day,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final dayKey = localDayKey(day ?? DateTime.now());
    var encoded = prefs.getString(_storageKey(category.id, dayKey));
    encoded ??= await _migrateLegacyProgress(prefs, category.id, dayKey);
    if (encoded == null) {
      return AdhkarReadingProgress.initial(category, day: day);
    }

    try {
      final json = jsonDecode(encoded) as Map<String, dynamic>;
      return _validatedProgress(category, dayKey, json);
    } on Object {
      return AdhkarReadingProgress.initial(category, day: day);
    }
  }

  Future<void> save(AdhkarReadingProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey(progress.categoryId, progress.dayKey),
      jsonEncode(progress.toJson()),
    );
    notifyListeners();
  }

  Future<AdhkarProgressSummary> loadSummary(
    AdhkarCategory category, {
    DateTime? day,
  }) async {
    final progress = await load(category, day: day);
    DhikrItem? currentItem;
    if (!progress.isCompleted) {
      for (final item in category.items) {
        if (item.id == progress.currentStepId) {
          currentItem = item;
          break;
        }
      }
    }
    final hasPartialCurrent =
        currentItem != null &&
        progress.remainingCount < currentItem.repeatCount;
    return AdhkarProgressSummary(
      categoryId: category.id,
      completedSteps: progress.isCompleted
          ? category.items.length
          : progress.completedStepIds.length,
      totalSteps: category.items.length,
      isCompleted: progress.isCompleted,
      hasProgress: progress.completedStepIds.isNotEmpty || hasPartialCurrent,
    );
  }

  Future<void> clear(String categoryId, {DateTime? day}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(
      _storageKey(categoryId, localDayKey(day ?? DateTime.now())),
    );
    notifyListeners();
  }

  AdhkarReadingProgress _validatedProgress(
    AdhkarCategory category,
    String dayKey,
    Map<String, dynamic> json,
  ) {
    final itemsById = {for (final item in category.items) item.id: item};
    final rawCompleted =
        (json['completedStepIds'] as List<dynamic>? ?? const [])
            .whereType<String>();
    final completed = rawCompleted.where(itemsById.containsKey).toSet();
    final storedCompleted = json['isCompleted'] == true;
    final rawRemaining = json['remainingCounts'];
    final remainingCounts = <String, int>{};
    if (rawRemaining is Map<String, dynamic>) {
      for (final entry in rawRemaining.entries) {
        final item = itemsById[entry.key];
        final value = entry.value;
        if (item != null && value is int && !completed.contains(item.id)) {
          remainingCounts[item.id] = value.clamp(1, item.repeatCount);
        }
      }
    }
    if (storedCompleted) {
      return AdhkarReadingProgress(
        categoryId: category.id,
        dayKey: dayKey,
        currentStepId: null,
        remainingCount: 0,
        completedStepIds: itemsById.keys.toSet(),
        remainingCounts: const {},
        isCompleted: true,
        lastUpdatedAt: _date(json['lastUpdatedAt']) ?? DateTime.now(),
        completedAt: _date(json['completedAt']),
      );
    }

    final storedStepId = json['currentStepId'] as String?;
    final currentItem = itemsById[storedStepId];
    if (currentItem != null && !completed.contains(currentItem.id)) {
      final storedRemaining = json['remainingCount'] as int?;
      final remaining = (storedRemaining ?? currentItem.repeatCount).clamp(
        1,
        currentItem.repeatCount,
      );
      remainingCounts.putIfAbsent(currentItem.id, () => remaining);
      return AdhkarReadingProgress(
        categoryId: category.id,
        dayKey: dayKey,
        currentStepId: currentItem.id,
        remainingCount: remaining,
        completedStepIds: completed,
        remainingCounts: remainingCounts,
        isCompleted: false,
        lastUpdatedAt: _date(json['lastUpdatedAt']) ?? DateTime.now(),
      );
    }

    final nextItem = category.items.cast<DhikrItem?>().firstWhere(
      (item) => item != null && !completed.contains(item.id),
      orElse: () => null,
    );
    if (nextItem == null) {
      final now = DateTime.now();
      return AdhkarReadingProgress(
        categoryId: category.id,
        dayKey: dayKey,
        currentStepId: null,
        remainingCount: 0,
        completedStepIds: itemsById.keys.toSet(),
        remainingCounts: const {},
        isCompleted: true,
        lastUpdatedAt: now,
        completedAt: _date(json['completedAt']) ?? now,
      );
    }
    return AdhkarReadingProgress(
      categoryId: category.id,
      dayKey: dayKey,
      currentStepId: nextItem.id,
      remainingCount: nextItem.repeatCount,
      completedStepIds: completed,
      remainingCounts: remainingCounts,
      isCompleted: false,
      lastUpdatedAt: _date(json['lastUpdatedAt']) ?? DateTime.now(),
    );
  }

  DateTime? _date(Object? value) {
    return value is String ? DateTime.tryParse(value) : null;
  }

  Future<String?> _migrateLegacyProgress(
    SharedPreferences prefs,
    String categoryId,
    String requestedDayKey,
  ) async {
    final legacyKey = '$_keyPrefix$categoryId';
    final encoded = prefs.getString(legacyKey);
    if (encoded == null) return null;
    try {
      final json = jsonDecode(encoded) as Map<String, dynamic>;
      final updatedAt = _date(json['lastUpdatedAt']) ?? DateTime.now();
      final legacyDayKey = localDayKey(updatedAt);
      await prefs.setString(_storageKey(categoryId, legacyDayKey), encoded);
      await prefs.remove(legacyKey);
      return legacyDayKey == requestedDayKey ? encoded : null;
    } on Object {
      await prefs.remove(legacyKey);
      return null;
    }
  }

  static String _storageKey(String categoryId, String dayKey) =>
      '$_keyPrefix$dayKey.$categoryId';

  static String localDayKey(DateTime value) {
    return LocalDay.key(value);
  }
}
