import 'package:tasbeh/core/time/local_day.dart';

class TasbeehState {
  const TasbeehState({
    required this.currentCount,
    required this.totalCount,
    required this.dailyTotal,
    required this.dailyDateKey,
    required this.targetMode,
  });

  factory TasbeehState.initial() {
    return TasbeehState(
      currentCount: 0,
      totalCount: 0,
      dailyTotal: 0,
      dailyDateKey: LocalDay.key(DateTime.now()),
      targetMode: targetMode33,
    );
  }

  factory TasbeehState.fromJson(Map<String, Object?> json) {
    return TasbeehState(
      currentCount: json['currentCount'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      dailyTotal: json['dailyTotal'] as int? ?? 0,
      dailyDateKey: json['dailyDateKey'] as String? ?? '',
      targetMode: _normalizeTargetMode(json['targetMode'] as String?),
    ).forCurrentDay();
  }

  static const targetMode33 = '33';
  static const targetMode99 = '99';
  static const targetModeOpen = 'open';

  final int currentCount;

  /// The all-time count. Kept as `totalCount` for overlay compatibility.
  final int totalCount;
  final int dailyTotal;
  final String dailyDateKey;
  final String targetMode;

  int? get targetCount {
    return switch (targetMode) {
      targetMode33 => 33,
      targetMode99 => 99,
      targetModeOpen => null,
      _ => 33,
    };
  }

  Map<String, Object?> toJson() {
    return {
      'type': 'state_update',
      'currentCount': currentCount,
      'totalCount': totalCount,
      'dailyTotal': dailyTotal,
      'dailyDateKey': dailyDateKey,
      'targetMode': targetMode,
    };
  }

  TasbeehState copyWith({
    int? currentCount,
    int? totalCount,
    int? dailyTotal,
    String? dailyDateKey,
    String? targetMode,
  }) {
    return TasbeehState(
      currentCount: currentCount ?? this.currentCount,
      totalCount: totalCount ?? this.totalCount,
      dailyTotal: dailyTotal ?? this.dailyTotal,
      dailyDateKey: dailyDateKey ?? this.dailyDateKey,
      targetMode: _normalizeTargetMode(targetMode ?? this.targetMode),
    );
  }

  TasbeehState forCurrentDay([DateTime? now]) {
    final today = LocalDay.key(now ?? DateTime.now());
    if (dailyDateKey == today) return this;
    return copyWith(dailyTotal: 0, dailyDateKey: today);
  }

  static String _normalizeTargetMode(String? targetMode) {
    return switch (targetMode) {
      targetMode33 => targetMode33,
      targetMode99 => targetMode99,
      targetModeOpen => targetModeOpen,
      _ => targetMode33,
    };
  }
}
