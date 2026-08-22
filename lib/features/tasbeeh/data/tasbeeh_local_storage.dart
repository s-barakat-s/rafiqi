import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_settings.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_state.dart';

class TasbeehLocalStorage {
  static const _currentCountKey = 'tasbeeh.currentCount';
  static const _totalCountKey = 'tasbeeh.totalCount';
  static const _targetModeKey = 'tasbeeh.targetMode';
  static const _autoCollapseSecondsKey = 'tasbeeh.autoCollapseSeconds';
  static const _opacityKey = 'tasbeeh.opacity';
  static const _sizeScaleKey = 'tasbeeh.sizeScale';
  static const _sizePresetKey = 'tasbeeh.sizePreset';
  static const _accentColorKey = 'tasbeeh.accentColor';
  static const _backgroundIntensityKey = 'tasbeeh.backgroundIntensity';
  static const _borderStyleKey = 'tasbeeh.borderStyle';
  static const _showBeadsKey = 'tasbeeh.showBeads';
  static const _beadSizeKey = 'tasbeeh.beadSize';
  static const _showTotalKey = 'tasbeeh.showTotal';
  static const _showDividerKey = 'tasbeeh.showDivider';
  static const _handleColorModeKey = 'tasbeeh.handleColorMode';
  static const _handleThicknessKey = 'tasbeeh.handleThickness';
  static const _handleHeightKey = 'tasbeeh.handleHeight';
  static const _hapticFeedbackEnabledKey = 'tasbeeh.hapticFeedbackEnabled';
  static const _tapAnimationEnabledKey = 'tasbeeh.tapAnimationEnabled';
  static const _floatingSideKey = 'tasbeeh.floatingSide';
  static const _overlayModeKey = 'tasbeeh.overlayMode';

  Future<TasbeehState> load() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    return TasbeehState.fromJson({
      'currentCount': prefs.getInt(_currentCountKey),
      'totalCount': prefs.getInt(_totalCountKey),
      'targetMode': prefs.getString(_targetModeKey),
    });
  }

  Future<void> save(TasbeehState state) async {
    final prefs = await SharedPreferences.getInstance();

    await Future.wait([
      prefs.setInt(_currentCountKey, state.currentCount),
      prefs.setInt(_totalCountKey, state.totalCount),
      prefs.setString(_targetModeKey, state.targetMode),
    ]);
  }

  Future<TasbeehSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    if (!prefs.containsKey(_autoCollapseSecondsKey) &&
        !prefs.containsKey(_sizeScaleKey) &&
        !prefs.containsKey(_sizePresetKey)) {
      return TasbeehSettings.initial();
    }

    return TasbeehSettings.fromJson({
      'opacity': prefs.getDouble(_opacityKey),
      'sizeScale': prefs.getDouble(_sizeScaleKey),
      'sizePreset': prefs.getString(_sizePresetKey),
      'accentColor': prefs.getString(_accentColorKey),
      'backgroundIntensity': prefs.getString(_backgroundIntensityKey),
      'borderStyle': prefs.getString(_borderStyleKey),
      'showBeads': prefs.getBool(_showBeadsKey),
      'beadSize': prefs.getString(_beadSizeKey),
      'showTotal': prefs.getBool(_showTotalKey),
      'showDivider': prefs.getBool(_showDividerKey),
      'autoCollapseSeconds': prefs.getInt(_autoCollapseSecondsKey),
      'handleColorMode': prefs.getString(_handleColorModeKey),
      'handleThickness': prefs.getString(_handleThicknessKey),
      'handleHeight': prefs.getString(_handleHeightKey),
      'hapticFeedbackEnabled': prefs.getBool(_hapticFeedbackEnabledKey),
      'tapAnimationEnabled': prefs.getBool(_tapAnimationEnabledKey),
      'floatingSide': prefs.getString(_floatingSideKey),
      'overlayMode': prefs.getString(_overlayModeKey),
    });
  }

  Future<void> saveSettings(TasbeehSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setDouble(_opacityKey, settings.opacity),
      prefs.setDouble(_sizeScaleKey, settings.sizeScale),
      prefs.setString(_accentColorKey, settings.accentColor),
      prefs.setString(_backgroundIntensityKey, settings.backgroundIntensity),
      prefs.setString(_borderStyleKey, settings.borderStyle),
      prefs.setBool(_showBeadsKey, settings.showBeads),
      prefs.setString(_beadSizeKey, settings.beadSize),
      prefs.setBool(_showTotalKey, settings.showTotal),
      prefs.setBool(_showDividerKey, settings.showDivider),
      prefs.setInt(_autoCollapseSecondsKey, settings.autoCollapseSeconds),
      prefs.setString(_handleColorModeKey, settings.handleColorMode),
      prefs.setString(_handleThicknessKey, settings.handleThickness),
      prefs.setString(_handleHeightKey, settings.handleHeight),
      prefs.setBool(_hapticFeedbackEnabledKey, settings.hapticFeedbackEnabled),
      prefs.setBool(_tapAnimationEnabledKey, settings.tapAnimationEnabled),
      prefs.setString(_floatingSideKey, settings.floatingSide),
      prefs.setString(_overlayModeKey, settings.overlayMode),
    ]);
  }
}
