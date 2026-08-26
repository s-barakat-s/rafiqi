import 'package:flutter/material.dart';
import 'package:tasbeh/app/navigation/main_shell_screen.dart';
import 'package:tasbeh/app/widgets/rafiqi_startup_intro.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/settings/data/repositories/app_preferences_repository.dart';

class TasbeehApp extends StatefulWidget {
  const TasbeehApp({super.key});

  @override
  State<TasbeehApp> createState() => _TasbeehAppState();
}

class _TasbeehAppState extends State<TasbeehApp> {
  final _preferences = AppPreferencesRepository.instance;

  @override
  void initState() {
    super.initState();
    _preferences.addListener(_onPreferencesChanged);
    _preferences.initialize();
  }

  void _onPreferencesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _preferences.removeListener(_onPreferencesChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = _preferences.value;
    return MaterialApp(
      title: 'رفيقي',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: preferences.themeMode,
      builder: (context, child) => RafiqiStartupIntro(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: MainShellScreen(
        isDarkMode: preferences.isDarkMode,
        onThemeChanged: _preferences.setDarkMode,
        adhkarVibrationEnabled: preferences.adhkarVibrationEnabled,
        onAdhkarVibrationChanged: _preferences.setAdhkarVibration,
        adhkarSoundEnabled: preferences.adhkarSoundEnabled,
        onAdhkarSoundChanged: _preferences.setAdhkarSound,
      ),
    );
  }
}
