class TasbeehState {
  const TasbeehState({
    required this.currentCount,
    required this.totalCount,
    required this.targetMode,
  });

  factory TasbeehState.initial() {
    return const TasbeehState(
      currentCount: 0,
      totalCount: 0,
      targetMode: targetMode33,
    );
  }

  factory TasbeehState.fromJson(Map<String, Object?> json) {
    return TasbeehState(
      currentCount: json['currentCount'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      targetMode: _normalizeTargetMode(json['targetMode'] as String?),
    );
  }

  static const targetMode33 = '33';
  static const targetMode99 = '99';
  static const targetModeOpen = 'open';

  final int currentCount;
  final int totalCount;
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
      'targetMode': targetMode,
    };
  }

  TasbeehState copyWith({
    int? currentCount,
    int? totalCount,
    String? targetMode,
  }) {
    return TasbeehState(
      currentCount: currentCount ?? this.currentCount,
      totalCount: totalCount ?? this.totalCount,
      targetMode: _normalizeTargetMode(targetMode ?? this.targetMode),
    );
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
