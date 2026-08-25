import 'package:flutter/material.dart';
import 'package:tasbeh/features/adhkar/domain/entities/wird_reader_mode.dart';

@immutable
class AppPreferences {
  const AppPreferences({
    this.themeMode = ThemeMode.light,
    this.adhkarVibrationEnabled = true,
    this.adhkarSoundEnabled = true,
    this.readerMode = WirdReaderMode.focus,
  });

  final ThemeMode themeMode;
  final bool adhkarVibrationEnabled;
  final bool adhkarSoundEnabled;
  final WirdReaderMode readerMode;

  bool get isDarkMode => themeMode == ThemeMode.dark;

  AppPreferences copyWith({
    ThemeMode? themeMode,
    bool? adhkarVibrationEnabled,
    bool? adhkarSoundEnabled,
    WirdReaderMode? readerMode,
  }) => AppPreferences(
    themeMode: themeMode ?? this.themeMode,
    adhkarVibrationEnabled:
        adhkarVibrationEnabled ?? this.adhkarVibrationEnabled,
    adhkarSoundEnabled: adhkarSoundEnabled ?? this.adhkarSoundEnabled,
    readerMode: readerMode ?? this.readerMode,
  );
}
