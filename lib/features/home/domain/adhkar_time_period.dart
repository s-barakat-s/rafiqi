enum AdhkarTimePeriod {
  morning,
  evening;

  static const eveningStartsAtHour = 12;

  static AdhkarTimePeriod at(DateTime dateTime) {
    final local = dateTime.toLocal();
    return local.hour < eveningStartsAtHour ? morning : evening;
  }

  static AdhkarTimePeriod now() => at(DateTime.now());

  String get categoryId => switch (this) {
    morning => 'morning',
    evening => 'evening',
  };

  String get dailyTaskId => switch (this) {
    morning => 'morning_adhkar',
    evening => 'evening_adhkar',
  };
}
