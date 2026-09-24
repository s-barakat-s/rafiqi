import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_daily_record.dart';

class ManualTasbeehEntry {
  const ManualTasbeehEntry({
    required this.id,
    required this.dayKey,
    required this.timestamp,
    required this.dhikrId,
    required this.dhikrTextSnapshot,
    required this.count,
  });

  final String id;
  final String dayKey;
  final DateTime timestamp;
  final String dhikrId;
  final String dhikrTextSnapshot;
  final int count;
  TasbeehActivitySource get source => TasbeehActivitySource.physicalManual;

  factory ManualTasbeehEntry.fromJson(Map<String, dynamic> json) =>
      ManualTasbeehEntry(
        id: json['id'] as String,
        dayKey: json['dayKey'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        dhikrId: json['dhikrId'] as String,
        dhikrTextSnapshot: json['dhikrTextSnapshot'] as String,
        count: json['count'] as int,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'dayKey': dayKey,
    'timestamp': timestamp.toIso8601String(),
    'dhikrId': dhikrId,
    'dhikrTextSnapshot': dhikrTextSnapshot,
    'count': count,
  };

  ManualTasbeehEntry copyWith({
    String? dhikrId,
    String? dhikrTextSnapshot,
    int? count,
  }) => ManualTasbeehEntry(
    id: id,
    dayKey: dayKey,
    timestamp: timestamp,
    dhikrId: dhikrId ?? this.dhikrId,
    dhikrTextSnapshot: dhikrTextSnapshot ?? this.dhikrTextSnapshot,
    count: count ?? this.count,
  );
}
