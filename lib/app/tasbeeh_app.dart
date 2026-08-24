import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasbeh/app/theme/app_theme.dart';
import 'package:tasbeh/features/tasbeeh/presentation/screens/main_shell_screen.dart';

class TasbeehApp extends StatefulWidget {
  const TasbeehApp({super.key});

  @override
  State<TasbeehApp> createState() => _TasbeehAppState();
}

class _TasbeehAppState extends State<TasbeehApp> {
  static const _themeKey = 'app_dark_theme';
  static const _adhkarVibrationKey = 'adhkar_tap_vibration';
  static const _adhkarSoundKey = 'adhkar_tap_sound';
  ThemeMode _themeMode = ThemeMode.light;
  bool _adhkarVibrationEnabled = true;
  bool _adhkarSoundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _themeMode = (preferences.getBool(_themeKey) ?? false)
          ? ThemeMode.dark
          : ThemeMode.light;
      _adhkarVibrationEnabled =
          preferences.getBool(_adhkarVibrationKey) ?? true;
      _adhkarSoundEnabled = preferences.getBool(_adhkarSoundKey) ?? true;
    });
  }

  Future<void> _setDarkMode(bool enabled) async {
    setState(() => _themeMode = enabled ? ThemeMode.dark : ThemeMode.light);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_themeKey, enabled);
  }

  Future<void> _setAdhkarVibration(bool enabled) async {
    setState(() => _adhkarVibrationEnabled = enabled);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_adhkarVibrationKey, enabled);
  }

  Future<void> _setAdhkarSound(bool enabled) async {
    setState(() => _adhkarSoundEnabled = enabled);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_adhkarSoundKey, enabled);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تسبيح',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: MainShellScreen(
        isDarkMode: _themeMode == ThemeMode.dark,
        onThemeChanged: _setDarkMode,
        adhkarVibrationEnabled: _adhkarVibrationEnabled,
        onAdhkarVibrationChanged: _setAdhkarVibration,
        adhkarSoundEnabled: _adhkarSoundEnabled,
        onAdhkarSoundChanged: _setAdhkarSound,
      ),
    );
  }
}
