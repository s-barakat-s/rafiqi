import 'package:tasbeh/core/time/local_day.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';

class AdhkarReadingProgress {
  const AdhkarReadingProgress({
    required this.categoryId,
    required this.dayKey,
    required this.currentStepId,
    required this.remainingCount,
    required this.completedStepIds,
    this.remainingCounts = const {},
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
      dayKey: LocalDay.key(day ?? DateTime.now()),
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
  final Map<String, int> remainingCounts;
  final bool isCompleted;
  final DateTime lastUpdatedAt;
  final DateTime? completedAt;

  Map<String, Object?> toJson() => {
    'categoryId': categoryId,
    'dayKey': dayKey,
    'currentStepId': currentStepId,
    'remainingCount': remainingCount,
    'completedStepIds': completedStepIds.toList(growable: false),
    'remainingCounts': remainingCounts,
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
