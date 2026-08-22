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
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(
      () => _themeMode = (preferences.getBool(_themeKey) ?? false)
          ? ThemeMode.dark
          : ThemeMode.light,
    );
  }

  Future<void> _setDarkMode(bool enabled) async {
    setState(() => _themeMode = enabled ? ThemeMode.dark : ThemeMode.light);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_themeKey, enabled);
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
      ),
    );
  }
}
