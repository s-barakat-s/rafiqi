import 'package:flutter/material.dart';
import 'package:tasbeh/app/navigation/main_shell_screen.dart';
import 'package:tasbeh/app/widgets/rafiqi_startup_intro.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/settings/data/repositories/app_preferences_repository.dart';
import 'package:tasbeh/shared/widgets/app_decorative_background.dart';

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
    _preferences.appearanceChanges.addListener(_onAppearanceChanged);
    _preferences.initialize();
  }

  void _onAppearanceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _preferences.appearanceChanges.removeListener(_onAppearanceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = _preferences.value;
    return MaterialApp(
      title: 'رفيقي',
      debugShowCheckedModeBanner: false,
      theme: buildRafiqiTheme(
        palette: preferences.palette,
        brightness: Brightness.light,
      ),
      darkTheme: buildRafiqiTheme(
        palette: preferences.palette,
        brightness: Brightness.dark,
      ),
      themeMode: preferences.themeMode,
      builder: (context, child) => RafiqiStartupIntro(
        child: AppDecorativeBackground(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
      home: ValueListenableBuilder<int>(
        valueListenable: _preferences.adhkarFeedbackChanges,
        builder: (context, _, _) {
          final feedback = _preferences.value;
          return MainShellScreen(
            adhkarVibrationEnabled: feedback.adhkarVibrationEnabled,
            onAdhkarVibrationChanged: _preferences.setAdhkarVibration,
            adhkarSoundEnabled: feedback.adhkarSoundEnabled,
            onAdhkarSoundChanged: _preferences.setAdhkarSound,
          );
        },
      ),
    );
  }
}
