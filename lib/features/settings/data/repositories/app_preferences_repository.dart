import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/core/theme/rafiqi_palette.dart';
import 'package:tasbeh/features/settings/domain/app_preferences.dart';
import 'package:tasbeh/features/adhkar/domain/entities/wird_reader_mode.dart';

class AppPreferencesRepository extends ChangeNotifier {
  AppPreferencesRepository._();

  static final instance = AppPreferencesRepository._();

  static const _themeKey = 'app_dark_theme';
  static const _paletteKey = 'app_color_palette';
  static const _adhkarVibrationKey = 'adhkar_tap_vibration';
  static const _adhkarSoundKey = 'adhkar_tap_sound';
  static const _readerModeKey = 'adhkar_reader_mode';

  AppPreferences _value = const AppPreferences();
  Future<void>? _initialization;
  final ValueNotifier<int> _appearanceChanges = ValueNotifier<int>(0);
  final ValueNotifier<int> _adhkarFeedbackChanges = ValueNotifier<int>(0);
  final ValueNotifier<int> _readerModeChanges = ValueNotifier<int>(0);

  AppPreferences get value => _value;
  ValueListenable<int> get appearanceChanges => _appearanceChanges;
  ValueListenable<int> get adhkarFeedbackChanges => _adhkarFeedbackChanges;
  ValueListenable<int> get readerModeChanges => _readerModeChanges;

  Future<void> initialize() => _initialization ??= _load();

  Future<void> _load() async {
    final storage = await SharedPreferences.getInstance();
    final storedPalette = storage.getString(_paletteKey);
    final palette = RafiqiPalette.fromStorage(storedPalette);
    if (storedPalette != null && storedPalette != palette.name) {
      await storage.setString(_paletteKey, palette.name);
    }
    _value = AppPreferences(
      themeMode: (storage.getBool(_themeKey) ?? false)
          ? ThemeMode.dark
          : ThemeMode.light,
      palette: palette,
      adhkarVibrationEnabled: storage.getBool(_adhkarVibrationKey) ?? true,
      adhkarSoundEnabled: storage.getBool(_adhkarSoundKey) ?? true,
      readerMode: WirdReaderMode.values.firstWhere(
        (mode) => mode.name == storage.getString(_readerModeKey),
        orElse: () => WirdReaderMode.focus,
      ),
    );
    _appearanceChanges.value++;
    _adhkarFeedbackChanges.value++;
    _readerModeChanges.value++;
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    _value = _value.copyWith(
      themeMode: enabled ? ThemeMode.dark : ThemeMode.light,
    );
    _appearanceChanges.value++;
    notifyListeners();
    final storage = await SharedPreferences.getInstance();
    await storage.setBool(_themeKey, enabled);
  }

  Future<void> setPalette(RafiqiPalette palette) async {
    _value = _value.copyWith(palette: palette);
    _appearanceChanges.value++;
    notifyListeners();
    final storage = await SharedPreferences.getInstance();
    await storage.setString(_paletteKey, palette.name);
  }

  Future<void> setAdhkarVibration(bool enabled) async {
    _value = _value.copyWith(adhkarVibrationEnabled: enabled);
    _adhkarFeedbackChanges.value++;
    notifyListeners();
    final storage = await SharedPreferences.getInstance();
    await storage.setBool(_adhkarVibrationKey, enabled);
  }

  Future<void> setAdhkarSound(bool enabled) async {
    _value = _value.copyWith(adhkarSoundEnabled: enabled);
    _adhkarFeedbackChanges.value++;
    notifyListeners();
    final storage = await SharedPreferences.getInstance();
    await storage.setBool(_adhkarSoundKey, enabled);
  }

  Future<void> setReaderMode(WirdReaderMode mode) async {
    _value = _value.copyWith(readerMode: mode);
    _readerModeChanges.value++;
    notifyListeners();
    final storage = await SharedPreferences.getInstance();
    await storage.setString(_readerModeKey, mode.name);
  }
}
