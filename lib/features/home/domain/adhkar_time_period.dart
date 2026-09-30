enum AdhkarTimePeriod {
  morning,
  evening;

  static const eveningStartsAtHour = 12;

  static AdhkarTimePeriod at(DateTime dateTime) {
    final local = dateTime.toLocal();
    return local.hour < eveningStartsAtHour ? morning : evening;
  }

  static AdhkarTimePeriod now() => at(DateTime.now());

  static DateTime nextBoundaryAfter(DateTime dateTime) {
    final local = dateTime.toLocal();
    if (local.hour < eveningStartsAtHour) {
      return DateTime(local.year, local.month, local.day, eveningStartsAtHour);
    }
    return DateTime(local.year, local.month, local.day + 1);
  }

  String get categoryId => switch (this) {
    morning => 'morning',
    evening => 'evening',
  };

  String get dailyTaskId => switch (this) {
    morning => 'morning_adhkar',
    evening => 'evening_adhkar',
  };
}
