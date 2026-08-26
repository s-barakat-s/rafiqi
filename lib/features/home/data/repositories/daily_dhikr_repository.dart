import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/core/time/local_day.dart';
import 'package:tasbeh/features/home/domain/entities/daily_dhikr.dart';

class DailyDhikrRepository extends ChangeNotifier {
  DailyDhikrRepository._();
  static final DailyDhikrRepository instance = DailyDhikrRepository._();

  static const String _kDayKey = 'daily_dhikr_day_key';
  static const String _kShuffledIds = 'daily_dhikr_shuffled_ids';
  static const String _kCurrentIndex = 'daily_dhikr_current_index';
  static const String _kRemainingCount = 'daily_dhikr_remaining_count';
  static const String _kLastCompletedId = 'daily_dhikr_last_completed_id';

  List<DailyDhikr> _allItems = const [];
  List<String> _shuffledIds = const [];
  int _currentIndex = 0;
  int _remainingCount = 1;
  String _dayKey = '';
  String? _lastCompletedId;
  bool _initialized = false;
  bool _isUpdating = false;

  bool get initialized => _initialized;
  List<DailyDhikr> get allItems => _allItems;
  int get remainingCount => _remainingCount;
  int get currentIndex => _currentIndex;
  int get totalInCycle => _shuffledIds.length;
  String get dayKey => _dayKey;

  DailyDhikr? get currentDhikr {
    if (_allItems.isEmpty || _shuffledIds.isEmpty) return null;
    final safeIndex = _currentIndex.clamp(0, _shuffledIds.length - 1);
    final id = _shuffledIds[safeIndex];
    return _allItems.firstWhere(
      (item) => item.id == id,
      orElse: () => _allItems.first,
    );
  }

  Future<void> initialize({DateTime? now}) async {
    final today = LocalDay.date(now ?? DateTime.now());
    final todayKey = LocalDay.key(today);

    if (_allItems.isEmpty) {
      final raw = await rootBundle.loadString(
        'assets/data/adhkar/daily_dhikr.json',
      );
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final list = data['items'] as List<dynamic>;
      _allItems = list
          .map((item) => DailyDhikr.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    }

    if (_allItems.isEmpty) {
      _initialized = true;
      notifyListeners();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedDayKey = prefs.getString(_kDayKey);
    final savedShuffledIds = prefs.getStringList(_kShuffledIds);
    final savedIndex = prefs.getInt(_kCurrentIndex);
    final savedRemaining = prefs.getInt(_kRemainingCount);
    _lastCompletedId = prefs.getString(_kLastCompletedId);

    if (savedDayKey == todayKey &&
        savedShuffledIds != null &&
        savedShuffledIds.isNotEmpty &&
        savedShuffledIds.every(
          (id) => _allItems.any((item) => item.id == id),
        )) {
      _dayKey = todayKey;
      _shuffledIds = List<String>.from(savedShuffledIds);
      _currentIndex = (savedIndex ?? 0).clamp(0, _shuffledIds.length - 1);
      final current = currentDhikr;
      final defaultRepeat = current?.repeatCount ?? 1;
      _remainingCount = (savedRemaining != null && savedRemaining > 0)
          ? savedRemaining
          : defaultRepeat;
    } else {
      // New day or first launch: start fresh daily shuffled order
      _dayKey = todayKey;
      _shuffledIds = _generateShuffledOrder(todayKey);
      _currentIndex = 0;
      final current = currentDhikr;
      _remainingCount = current?.repeatCount ?? 1;
      await _persist(prefs);
    }

    _initialized = true;
    notifyListeners();
  }

  List<String> _generateShuffledOrder(String seedKey) {
    final items = List<DailyDhikr>.from(_allItems);
    final random = Random(seedKey.hashCode);
    items.shuffle(random);

    // Avoid immediately repeating the last completed item if pool > 1
    if (_lastCompletedId != null &&
        items.length > 1 &&
        items.first.id == _lastCompletedId) {
      final temp = items[0];
      items[0] = items[1];
      items[1] = temp;
    }

    return items.map((e) => e.id).toList(growable: false);
  }

  Future<void> decrement() async {
    if (_isUpdating) return;
    _isUpdating = true;
    try {
      await _decrementUnlocked();
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> _decrementUnlocked() async {
    if (!_initialized || _allItems.isEmpty || _shuffledIds.isEmpty) return;

    if (_remainingCount > 1) {
      _remainingCount--;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kRemainingCount, _remainingCount);
      notifyListeners();
      return;
    }

    // Remaining count reached 0 -> advance to next dhikr
    final completedId = currentDhikr?.id;
    _lastCompletedId = completedId;

    if (_currentIndex + 1 < _shuffledIds.length) {
      _currentIndex++;
    } else {
      // Pool ended: reshuffle and avoid immediate repeat
      final items = List<DailyDhikr>.from(_allItems);
      items.shuffle(Random());
      if (_lastCompletedId != null &&
          items.length > 1 &&
          items.first.id == _lastCompletedId) {
        final temp = items[0];
        items[0] = items[1];
        items[1] = temp;
      }
      _shuffledIds = items.map((e) => e.id).toList(growable: false);
      _currentIndex = 0;
    }

    final newDhikr = currentDhikr;
    _remainingCount = newDhikr?.repeatCount ?? 1;

    final prefs = await SharedPreferences.getInstance();
    await _persist(prefs);
    notifyListeners();
  }

  Future<void> _persist(SharedPreferences prefs) async {
    await prefs.setString(_kDayKey, _dayKey);
    await prefs.setStringList(_kShuffledIds, _shuffledIds);
    await prefs.setInt(_kCurrentIndex, _currentIndex);
    await prefs.setInt(_kRemainingCount, _remainingCount);
    if (_lastCompletedId != null) {
      await prefs.setString(_kLastCompletedId, _lastCompletedId!);
    }
  }

  @visibleForTesting
  Future<void> resetForTesting() async {
    _allItems = const [];
    _shuffledIds = const [];
    _currentIndex = 0;
    _remainingCount = 1;
    _dayKey = '';
    _lastCompletedId = null;
    _initialized = false;
    _isUpdating = false;
  }
}
