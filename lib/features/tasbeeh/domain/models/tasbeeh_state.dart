import 'package:tasbeh/core/time/local_day.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_phrase.dart';

class TasbeehState {
  const TasbeehState({
    required this.currentCount,
    required this.totalCount,
    required this.dailyTotal,
    required this.dailyDateKey,
    required this.targetMode,
    required this.selectedDhikrId,
    required this.selectedDhikrText,
    required this.sessionCounts,
  });

  factory TasbeehState.initial() {
    return TasbeehState(
      currentCount: 0,
      totalCount: 0,
      dailyTotal: 0,
      dailyDateKey: LocalDay.key(DateTime.now()),
      targetMode: targetMode33,
      selectedDhikrId: TasbeehPhrase.defaultPhrases.first.id,
      selectedDhikrText: TasbeehPhrase.defaultPhrases.first.text,
      sessionCounts: const {},
    );
  }

  factory TasbeehState.fromJson(Map<String, Object?> json) {
    final selectedId = json['selectedDhikrId'] as String? ??
        TasbeehPhrase.defaultPhrases.first.id;
    final selectedText = json['selectedDhikrText'] as String? ??
        TasbeehPhrase.builtInById(selectedId).text;
    final rawSessions = json['sessionCounts'];
    final Map<String, int> sessions = rawSessions is Map
        ? <String, int>{
            for (final entry in rawSessions.entries)
              entry.key.toString(): entry.value is int ? entry.value as int : 0,
          }
        : <String, int>{};
    return TasbeehState(
      currentCount: sessions[selectedId] ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      dailyTotal: json['dailyTotal'] as int? ?? 0,
      dailyDateKey: json['dailyDateKey'] as String? ?? '',
      targetMode: _normalizeTargetMode(json['targetMode'] as String?),
      selectedDhikrId: selectedId,
      selectedDhikrText: selectedText,
      sessionCounts: sessions,
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
  final String selectedDhikrId;
  final String selectedDhikrText;
  final Map<String, int> sessionCounts;

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
      'selectedDhikrId': selectedDhikrId,
      'selectedDhikrText': selectedDhikrText,
      'sessionCounts': sessionCounts,
    };
  }

  TasbeehState copyWith({
    int? currentCount,
    int? totalCount,
    int? dailyTotal,
    String? dailyDateKey,
    String? targetMode,
    String? selectedDhikrId,
    String? selectedDhikrText,
    Map<String, int>? sessionCounts,
  }) {
    return TasbeehState(
      currentCount: currentCount ?? this.currentCount,
      totalCount: totalCount ?? this.totalCount,
      dailyTotal: dailyTotal ?? this.dailyTotal,
      dailyDateKey: dailyDateKey ?? this.dailyDateKey,
      targetMode: _normalizeTargetMode(targetMode ?? this.targetMode),
      selectedDhikrId: selectedDhikrId ?? this.selectedDhikrId,
      selectedDhikrText: selectedDhikrText ?? this.selectedDhikrText,
      sessionCounts: sessionCounts ?? this.sessionCounts,
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
