class TasbeehDailyRecord {
  const TasbeehDailyRecord({
    required this.dayKey,
    required this.dhikrId,
    required this.dhikrTextSnapshot,
    required this.appCount,
    required this.overlayCount,
  });

  final String dayKey;
  final String dhikrId;
  final String dhikrTextSnapshot;
  final int appCount;
  final int overlayCount;
  int get inAppCount => appCount + overlayCount;

  factory TasbeehDailyRecord.fromJson(Map<String, dynamic> json) =>
      TasbeehDailyRecord(
        dayKey: json['dayKey'] as String,
        dhikrId: json['dhikrId'] as String,
        dhikrTextSnapshot: json['dhikrTextSnapshot'] as String,
        appCount: json['appCount'] as int? ?? json['inAppCount'] as int? ?? 0,
        overlayCount: json['overlayCount'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'dayKey': dayKey,
    'dhikrId': dhikrId,
    'dhikrTextSnapshot': dhikrTextSnapshot,
    'appCount': appCount,
    'overlayCount': overlayCount,
  };

  TasbeehDailyRecord copyWith({
    int? appCount,
    int? overlayCount,
    String? dhikrTextSnapshot,
  }) =>
      TasbeehDailyRecord(
        dayKey: dayKey,
        dhikrId: dhikrId,
        dhikrTextSnapshot: dhikrTextSnapshot ?? this.dhikrTextSnapshot,
        appCount: appCount ?? this.appCount,
        overlayCount: overlayCount ?? this.overlayCount,
      );
}

enum TasbeehActivitySource {
  app,
  overlay,
  physicalManual,
  dailyTaskExternal,
}
