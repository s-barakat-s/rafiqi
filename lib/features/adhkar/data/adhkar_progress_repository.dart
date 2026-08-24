import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/features/adhkar/domain/adhkar_data.dart';

class AdhkarReadingProgress {
  const AdhkarReadingProgress({
    required this.categoryId,
    required this.dayKey,
    required this.currentStepId,
    required this.remainingCount,
    required this.completedStepIds,
    required this.isCompleted,
    required this.lastUpdatedAt,
    this.completedAt,
  });

  factory AdhkarReadingProgress.initial(
    AdhkarCategory category, {
    DateTime? day,
  }) {
    final first = category.items.first;
    return AdhkarReadingProgress(
      categoryId: category.id,
      dayKey: AdhkarProgressRepository.localDayKey(day ?? DateTime.now()),
      currentStepId: first.id,
      remainingCount: first.repeatCount,
      completedStepIds: const {},
      isCompleted: false,
      lastUpdatedAt: DateTime.now(),
    );
  }

  final String categoryId;
  final String dayKey;
  final String? currentStepId;
  final int remainingCount;
  final Set<String> completedStepIds;
  final bool isCompleted;
  final DateTime lastUpdatedAt;
  final DateTime? completedAt;

  Map<String, Object?> toJson() => {
    'categoryId': categoryId,
    'dayKey': dayKey,
    'currentStepId': currentStepId,
    'remainingCount': remainingCount,
    'completedStepIds': completedStepIds.toList(growable: false),
    'isCompleted': isCompleted,
    'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };
}

class AdhkarProgressSummary {
  const AdhkarProgressSummary({
    required this.categoryId,
    required this.completedSteps,
    required this.totalSteps,
    required this.isCompleted,
    required this.hasProgress,
  });

  final String categoryId;
  final int completedSteps;
  final int totalSteps;
  final bool isCompleted;
  final bool hasProgress;
}

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
    final hasPartialCurrent = currentItem != null &&
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
    final rawCompleted = (json['completedStepIds'] as List<dynamic>? ?? const [])
        .whereType<String>();
    final completed = rawCompleted
        .where(itemsById.containsKey)
        .toSet();
    final storedCompleted = json['isCompleted'] == true;
    if (storedCompleted) {
      return AdhkarReadingProgress(
        categoryId: category.id,
        dayKey: dayKey,
        currentStepId: null,
        remainingCount: 0,
        completedStepIds: itemsById.keys.toSet(),
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
      return AdhkarReadingProgress(
        categoryId: category.id,
        dayKey: dayKey,
        currentStepId: currentItem.id,
        remainingCount: remaining,
        completedStepIds: completed,
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
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}
