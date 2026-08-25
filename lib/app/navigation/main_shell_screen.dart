import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_controller.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_settings.dart';
import 'package:tasbeh/features/adhkar/presentation/screens/adhkar_categories_screen.dart';
import 'package:tasbeh/features/tasbeeh/presentation/screens/floating_tasbeeh_settings_screen.dart';
import 'package:tasbeh/features/journey/presentation/screens/journey_screen.dart';
import 'package:tasbeh/features/tasbeeh/presentation/screens/tasbeeh_home_screen.dart';
import 'package:tasbeh/features/tasbeeh/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:tasbeh/features/settings/presentation/screens/more_screen.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_local_repository.dart';
import 'package:tasbeh/features/adhkar/presentation/screens/wird_reader_screen.dart';
import 'package:tasbeh/features/home/presentation/home_screen.dart';

/// Owns the five top-level destinations and cross-feature navigation only.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.adhkarVibrationEnabled,
    required this.onAdhkarVibrationChanged,
    required this.adhkarSoundEnabled,
    required this.onAdhkarSoundChanged,
    super.key,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final bool adhkarVibrationEnabled;
  final ValueChanged<bool> onAdhkarVibrationChanged;
  final bool adhkarSoundEnabled;
  final ValueChanged<bool> onAdhkarSoundChanged;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen>
    with WidgetsBindingObserver {
  final _tasbeeh = TasbeehController();
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tasbeeh.addListener(_onTasbeehChanged);
    _tasbeeh.initialize();
  }

  void _onTasbeehChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tasbeeh.removeListener(_onTasbeehChanged);
    _tasbeeh.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tasbeeh.reload();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _startFloatingTasbeeh() async {
    final result = await _tasbeeh.startFloating();
    if (!mounted) return;
    if (result == FloatingTasbeehStartResult.permissionDenied) {
      _showMessage('فعّل إذن الظهور فوق التطبيقات ثم حاول مرة أخرى');
      return;
    }
    _showMessage('تم تشغيل السبحة العائمة');
  }

  Future<void> _stopFloatingTasbeeh() async {
    await _tasbeeh.stopFloating();
    if (!mounted) return;

    _showMessage('تم إيقاف السبحة العائمة');
  }

  Future<void> _openAdhkarReader(String categoryId) async {
    final categories = await AdhkarLocalRepository.loadCategories();
    if (!mounted) return;
    final category = categories.firstWhere((item) => item.id == categoryId);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WirdReaderScreen(
          category: category,
          vibrationEnabled: widget.adhkarVibrationEnabled,
          soundEnabled: widget.adhkarSoundEnabled,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        onOpenTasbeeh: () => setState(() => _tabIndex = 2),
        onOpenAdhkar: _openAdhkarReader,
      ),
      AdhkarCategoriesScreen(
        vibrationEnabled: widget.adhkarVibrationEnabled,
        soundEnabled: widget.adhkarSoundEnabled,
      ),
      TasbeehHomeScreen(
        state: _tasbeeh.state,
        onIncrement: _tasbeeh.increment,
        onResetSession: _tasbeeh.resetSession,
        onStartFloating: _startFloatingTasbeeh,
        onStopFloating: _stopFloatingTasbeeh,
      ),
      const JourneyScreen(),
      MoreScreen(
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
        adhkarVibrationEnabled: widget.adhkarVibrationEnabled,
        onAdhkarVibrationChanged: widget.onAdhkarVibrationChanged,
        adhkarSoundEnabled: widget.adhkarSoundEnabled,
        onAdhkarSoundChanged: widget.onAdhkarSoundChanged,
        onOpenTasbeehSettings: _openTasbeehSettings,
      ),
    ];

    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 94),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey(_tabIndex),
                    child: pages[_tabIndex],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: AppBottomNavBar(
                  currentIndex: _tabIndex,
                  onChanged: (index) => setState(() => _tabIndex = index),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTasbeehSettings() async {
    final result = await Navigator.of(context).push<TasbeehSettings>(
      MaterialPageRoute(
        builder: (_) => FloatingTasbeehSettingsScreen(
          initialSettings: _tasbeeh.settings,
          state: _tasbeeh.state,
        ),
      ),
    );
    if (result != null) await _tasbeeh.replaceSettings(result);
  }
}
