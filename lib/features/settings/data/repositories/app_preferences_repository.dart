import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/features/settings/domain/app_preferences.dart';
import 'package:tasbeh/features/adhkar/domain/entities/wird_reader_mode.dart';

class AppPreferencesRepository extends ChangeNotifier {
  AppPreferencesRepository._();

  static final instance = AppPreferencesRepository._();

  static const _themeKey = 'app_dark_theme';
  static const _adhkarVibrationKey = 'adhkar_tap_vibration';
  static const _adhkarSoundKey = 'adhkar_tap_sound';
  static const _readerModeKey = 'adhkar_reader_mode';

  AppPreferences _value = const AppPreferences();
  Future<void>? _initialization;

  AppPreferences get value => _value;

  Future<void> initialize() => _initialization ??= _load();

  Future<void> _load() async {
    final storage = await SharedPreferences.getInstance();
    _value = AppPreferences(
      themeMode: (storage.getBool(_themeKey) ?? false)
          ? ThemeMode.dark
          : ThemeMode.light,
      adhkarVibrationEnabled: storage.getBool(_adhkarVibrationKey) ?? true,
      adhkarSoundEnabled: storage.getBool(_adhkarSoundKey) ?? true,
      readerMode: WirdReaderMode.values.firstWhere(
        (mode) => mode.name == storage.getString(_readerModeKey),
        orElse: () => WirdReaderMode.focus,
      ),
    );
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    _value = _value.copyWith(
      themeMode: enabled ? ThemeMode.dark : ThemeMode.light,
    );
    notifyListeners();
    final storage = await SharedPreferences.getInstance();
    await storage.setBool(_themeKey, enabled);
  }

  Future<void> setAdhkarVibration(bool enabled) async {
    _value = _value.copyWith(adhkarVibrationEnabled: enabled);
    notifyListeners();
    final storage = await SharedPreferences.getInstance();
    await storage.setBool(_adhkarVibrationKey, enabled);
  }

  Future<void> setAdhkarSound(bool enabled) async {
    _value = _value.copyWith(adhkarSoundEnabled: enabled);
    notifyListeners();
    final storage = await SharedPreferences.getInstance();
    await storage.setBool(_adhkarSoundKey, enabled);
  }

  Future<void> setReaderMode(WirdReaderMode mode) async {
    _value = _value.copyWith(readerMode: mode);
    notifyListeners();
    final storage = await SharedPreferences.getInstance();
    await storage.setString(_readerModeKey, mode.name);
  }
}
