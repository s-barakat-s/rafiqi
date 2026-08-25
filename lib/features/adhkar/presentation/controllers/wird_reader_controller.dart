import 'package:flutter/foundation.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_progress_repository.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar_progress.dart';
import 'package:tasbeh/features/daily_wird/data/repositories/daily_wird_repository.dart';

class ReaderUndoSnapshot {
  const ReaderUndoSnapshot({
    required this.index,
    required this.remaining,
    required this.completedStepIds,
    required this.remainingCounts,
  });

  final int index;
  final int remaining;
  final Set<String> completedStepIds;
  final Map<String, int> remainingCounts;
}

class WirdReaderController extends ChangeNotifier {
  WirdReaderController({
    required this.category,
    AdhkarProgressRepository? progressRepository,
    DailyWirdRepository? dailyWirdRepository,
  }) : _progressRepository =
           progressRepository ?? AdhkarProgressRepository.instance,
       _dailyWirdRepository =
           dailyWirdRepository ?? DailyWirdRepository.instance,
       _remaining = category.items.first.repeatCount;

  final AdhkarCategory category;
  final AdhkarProgressRepository _progressRepository;
  final DailyWirdRepository _dailyWirdRepository;

  int _index = 0;
  int _remaining;
  Set<String> _completedStepIds = {};
  Map<String, int> _remainingCounts = {};

  bool _isLoading = true;
  bool _isTransitioning = false;

  String _activeDayKey = AdhkarProgressRepository.localDayKey(DateTime.now());

  Future<void> _pendingProgressWrite = Future.value();

  final List<ReaderUndoSnapshot> _undoStack = [];

  int get index => _index;
  int get remaining => _remaining;
  int get total => category.items.length;

  bool get isLoading => _isLoading;
  bool get isTransitioning => _isTransitioning;
  bool get isComplete => _completedStepIds.length >= total;

  bool get canUndo => _undoStack.isNotEmpty && !_isTransitioning;

  double get progress => isComplete ? 1 : _completedStepIds.length / total;

  DhikrItem get current => category.items[_index];

  DhikrItem? itemAfter(int distance) {
    final items = remainingItems;
    return distance < items.length ? items[distance] : null;
  }

  List<DhikrItem> get remainingItems => category.items
      .where((item) => !_completedStepIds.contains(item.id))
      .toList(growable: false);

  int remainingFor(String itemId) {
    final item = category.items.firstWhere((entry) => entry.id == itemId);
    return _remainingCounts[itemId] ?? item.repeatCount;
  }

  bool isItemCompleted(String itemId) => _completedStepIds.contains(itemId);

  Future<void> initialize() => _restoreProgress();

  Future<void> resumeIfDayChanged() async {
    final todayKey = AdhkarProgressRepository.localDayKey(DateTime.now());

    if (_activeDayKey != todayKey) {
      _clearUndo();
      await _restoreProgress();
    }
  }

  Future<void> _restoreProgress() async {
    final stored = await _progressRepository.load(category);

    final restoredIndex = stored.isCompleted
        ? total
        : category.items.indexWhere((item) => item.id == stored.currentStepId);

    _index = restoredIndex < 0 ? 0 : restoredIndex;

    _remaining = stored.isCompleted ? 0 : stored.remainingCount;

    _completedStepIds = {...stored.completedStepIds};
    _remainingCounts = {
      for (final item in category.items)
        if (!_completedStepIds.contains(item.id))
          item.id: stored.remainingCounts[item.id] ?? item.repeatCount,
    };
    if (!stored.isCompleted && _index < total) {
      _remainingCounts[current.id] = stored.remainingCount;
      _remaining = _remainingCounts[current.id]!;
    }

    _activeDayKey = stored.dayKey;
    _clearUndo();
    _isLoading = false;

    notifyListeners();
  }

  Future<void> decrement({
    required Future<void> Function() animateExit,
    required VoidCallback resetTransition,
  }) async {
    if (_isTransitioning || isComplete) return;

    await decrementItem(
      current.id,
      animateRemoval: animateExit,
      resetTransition: resetTransition,
    );
  }

  Future<void> decrementItem(
    String itemId, {
    Future<void> Function()? animateRemoval,
    VoidCallback? resetTransition,
  }) async {
    if (_isTransitioning || isComplete || isItemCompleted(itemId)) return;

    await resumeIfDayChanged();

    if (isComplete || isItemCompleted(itemId)) return;

    final itemIndex = category.items.indexWhere((item) => item.id == itemId);
    if (itemIndex < 0) return;
    final currentItem = category.items[itemIndex];
    final itemRemaining = remainingFor(itemId);

    _undoStack.add(
      ReaderUndoSnapshot(
        index: _index,
        remaining: _remaining,
        completedStepIds: {..._completedStepIds},
        remainingCounts: {..._remainingCounts},
      ),
    );

    // Same dhikr still has repetitions remaining.
    if (itemRemaining > 1) {
      _remainingCounts[itemId] = itemRemaining - 1;
      if (itemIndex == _index) _remaining = itemRemaining - 1;

      notifyListeners();

      await _persist(_progressForSession());

      return;
    }

    final completedAt = DateTime.now();

    final completedIds = {..._completedStepIds, currentItem.id};
    final finished = completedIds.length >= total;
    _isTransitioning = true;
    notifyListeners();

    // Start persistence immediately, but do not make the visual
    // transition wait for storage to finish.
    final progressWrite =
        _persist(
          AdhkarReadingProgress(
            categoryId: category.id,
            dayKey: AdhkarProgressRepository.localDayKey(completedAt),
            currentStepId: _firstIncomplete(completedIds)?.id,
            remainingCount: _firstIncomplete(completedIds) == null
                ? 0
                : remainingFor(_firstIncomplete(completedIds)!.id),
            completedStepIds: completedIds,
            remainingCounts: {
              for (final entry in _remainingCounts.entries)
                if (!completedIds.contains(entry.key)) entry.key: entry.value,
            },
            isCompleted: finished,
            lastUpdatedAt: completedAt,
            completedAt: finished ? completedAt : null,
          ),
        ).then((_) async {
          if (finished) {
            await _dailyWirdRepository.setAdhkarReaderCompletion(
              category.id,
              true,
              day: completedAt,
            );
          }
        });

    // Run only the visual card transition here.
    if (animateRemoval != null) await animateRemoval();

    // Important:
    // reset the old animation BEFORE publishing the next deck state,
    // otherwise the newly shifted cards can briefly render at the
    // previous animation's end positions.
    resetTransition?.call();

    _completedStepIds = completedIds;
    _remainingCounts.remove(itemId);
    final nextItem = _firstIncomplete(completedIds);
    _index = nextItem == null ? total : category.items.indexOf(nextItem);

    if (finished) {
      _remaining = 0;
    } else {
      _remaining = remainingFor(nextItem!.id);
    }

    _isTransitioning = false;

    notifyListeners();

    // Persistence is allowed to finish after the visible deck
    // transition has already completed.
    await progressWrite;
  }

  Future<void> undo() async {
    if (!canUndo) return;

    final snapshot = _undoStack.removeLast();

    _index = snapshot.index;
    _remaining = snapshot.remaining;
    _completedStepIds = {...snapshot.completedStepIds};
    _remainingCounts = {...snapshot.remainingCounts};

    notifyListeners();

    await _persist(_progressForSession());
  }

  Future<void> undoStep() => undo();

  Future<void> restart() async {
    await _progressRepository.clear(category.id);

    _index = 0;
    _remaining = category.items.first.repeatCount;

    _completedStepIds = {};
    _remainingCounts = {
      for (final item in category.items) item.id: item.repeatCount,
    };
    _isTransitioning = false;

    _clearUndo();

    notifyListeners();
  }

  AdhkarReadingProgress _progressForSession() {
    final currentItem = _index < total ? current : null;
    return AdhkarReadingProgress(
      categoryId: category.id,
      dayKey: AdhkarProgressRepository.localDayKey(DateTime.now()),
      currentStepId: currentItem?.id,
      remainingCount: _remaining,
      completedStepIds: {..._completedStepIds},
      remainingCounts: {..._remainingCounts},
      isCompleted: isComplete,
      lastUpdatedAt: DateTime.now(),
    );
  }

  DhikrItem? _firstIncomplete(Set<String> completedIds) {
    for (final item in category.items) {
      if (!completedIds.contains(item.id)) return item;
    }
    return null;
  }

  Future<void> completeFromReading() async {
    if (_isTransitioning) return;
    final completedAt = DateTime.now();
    final completedIds = category.items.map((item) => item.id).toSet();

    _isTransitioning = true;
    notifyListeners();

    await _persist(
      AdhkarReadingProgress(
        categoryId: category.id,
        dayKey: AdhkarProgressRepository.localDayKey(completedAt),
        currentStepId: null,
        remainingCount: 0,
        completedStepIds: completedIds,
        remainingCounts: const {},
        isCompleted: true,
        lastUpdatedAt: completedAt,
        completedAt: completedAt,
      ),
    );
    await _dailyWirdRepository.setAdhkarReaderCompletion(
      category.id,
      true,
      day: completedAt,
      source: 'reading',
    );

    _completedStepIds = completedIds;
    _remainingCounts = {};
    _index = total;
    _remaining = 0;
    _isTransitioning = false;
    _clearUndo();
    notifyListeners();
  }

  Future<void> _persist(AdhkarReadingProgress progress) {
    _pendingProgressWrite = _pendingProgressWrite.then(
      (_) => _progressRepository.save(progress),
    );

    return _pendingProgressWrite;
  }

  void _clearUndo() {
    _undoStack.clear();
  }
}
