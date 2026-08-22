import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_counter_logic.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_overlay_launcher.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_overlay_messenger.dart';
import 'package:tasbeh/features/tasbeeh/data/tasbeeh_local_storage.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_settings.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_state.dart';
import 'package:tasbeh/features/tasbeeh/presentation/screens/azkar_placeholder_screen.dart';
import 'package:tasbeh/features/tasbeeh/presentation/screens/floating_tasbeeh_settings_screen.dart';
import 'package:tasbeh/features/tasbeeh/presentation/screens/statistics_placeholder_screen.dart';
import 'package:tasbeh/features/tasbeeh/presentation/screens/tasbeeh_home_screen.dart';
import 'package:tasbeh/features/tasbeeh/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:tasbeh/features/home/presentation/home_screen.dart';
import 'package:tasbeh/app/theme/app_theme.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({
    required this.isDarkMode,
    required this.onThemeChanged,
    super.key,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen>
    with WidgetsBindingObserver {
  final _storage = TasbeehLocalStorage();
  TasbeehState _state = TasbeehState.initial();
  TasbeehSettings _settings = TasbeehSettings.initial();
  StreamSubscription<TasbeehStateMessage>? _overlaySubscription;
  StreamSubscription<TasbeehSettingsMessage>? _overlaySettingsSubscription;
  ReceivePort? _mainAppPort;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedData();
    _mainAppPort = TasbeehOverlayMessenger.registerMainAppPort(
      _applyIncomingOverlayMessage,
    );
    _overlaySubscription = TasbeehOverlayMessenger.stateMessages.listen(
      _applyIncomingOverlayMessage,
    );
    _overlaySettingsSubscription = TasbeehOverlayMessenger.settingsMessages
        .listen(_applyIncomingOverlaySettingsMessage);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _overlaySubscription?.cancel();
    _overlaySettingsSubscription?.cancel();
    _mainAppPort?.close();
    TasbeehOverlayMessenger.unregisterMainAppPort();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSavedData();
    }
  }

  Future<void> _loadSavedData() async {
    final loadedState = await _storage.load();
    final loadedSettings = await _storage.loadSettings();
    if (!mounted) return;

    setState(() {
      _state = loadedState;
      _settings = loadedSettings;
    });
  }

  Future<void> _applyState(
    TasbeehState state, {
    bool notifyOverlay = true,
  }) async {
    await _storage.save(state);
    if (!mounted) return;

    setState(() {
      _state = state;
    });

    if (notifyOverlay && await FlutterOverlayWindow.isActive()) {
      await TasbeehOverlayMessenger.sendStateUpdate(
        state,
        source: TasbeehOverlayMessenger.sourceApp,
      );
    }
  }

  Future<void> _applyIncomingOverlayMessage(TasbeehStateMessage message) async {
    if (message.source != TasbeehOverlayMessenger.sourceOverlay) {
      return;
    }

    await _storage.save(message.state);
    if (!mounted) return;

    setState(() {
      _state = message.state;
    });
  }

  Future<void> _applyIncomingOverlaySettingsMessage(
    TasbeehSettingsMessage message,
  ) async {
    if (message.source != TasbeehOverlayMessenger.sourceOverlay) {
      return;
    }

    await _storage.saveSettings(message.settings);
    if (!mounted) return;

    setState(() {
      _settings = message.settings;
    });
  }

  Future<void> _incrementTasbeeh() async {
    await _applyState(TasbeehCounterLogic.increment(_state));
  }

  Future<void> _resetSession() async {
    await _applyState(TasbeehCounterLogic.resetSession(_state));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _startFloatingTasbeeh() async {
    final hasPermission = await FlutterOverlayWindow.isPermissionGranted();

    if (!hasPermission) {
      final granted = await FlutterOverlayWindow.requestPermission() ?? false;
      if (!mounted) return;

      if (!granted) {
        _showMessage('فعّل إذن الظهور فوق التطبيقات ثم حاول مرة أخرى');
        return;
      }
    }

    final overlaySettings = _settings.copyWith(
      overlayMode: TasbeehSettings.overlayModeExpanded,
    );
    await _storage.saveSettings(overlaySettings);
    if (!mounted) return;

    setState(() {
      _settings = overlaySettings;
    });

    await TasbeehOverlayLauncher.restartOverlay(settings: overlaySettings);

    await TasbeehOverlayMessenger.sendStateUpdate(
      _state,
      source: TasbeehOverlayMessenger.sourceApp,
    );
    await TasbeehOverlayMessenger.sendSettingsUpdate(
      overlaySettings,
      source: TasbeehOverlayMessenger.sourceApp,
    );

    if (!mounted) return;
    _showMessage('تم تشغيل السبحة العائمة');
  }

  Future<void> _stopFloatingTasbeeh() async {
    await FlutterOverlayWindow.closeOverlay();
    if (!mounted) return;

    _showMessage('تم إيقاف السبحة العائمة');
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onOpenTasbeeh: () => setState(() => _tabIndex = 2)),
      const AzkarPlaceholderScreen(),
      TasbeehHomeScreen(
        state: _state,
        onIncrement: _incrementTasbeeh,
        onResetSession: _resetSession,
        onStartFloating: _startFloatingTasbeeh,
        onStopFloating: _stopFloatingTasbeeh,
      ),
      StatisticsPlaceholderScreen(state: _state),
      _MoreScreen(
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
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
          initialSettings: _settings,
          state: _state,
        ),
      ),
    );
    if (result != null && mounted) setState(() => _settings = result);
  }
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen({
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onOpenTasbeehSettings,
  });
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final VoidCallback onOpenTasbeehSettings;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
        children: [
          Text(
            'المزيد',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'المظهر وإعدادات تجربتك',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: colors.secondaryText),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.gold.withValues(alpha: .28)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: isDarkMode,
                  onChanged: onThemeChanged,
                  secondary: Icon(
                    isDarkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    color: colors.gold,
                  ),
                  title: const Text('الوضع الداكن'),
                  subtitle: const Text('خلفية حبرية مريحة للعين'),
                ),
                Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                  color: colors.divider.withValues(alpha: .6),
                ),
                ListTile(
                  onTap: onOpenTasbeehSettings,
                  leading: Icon(Icons.tune_rounded, color: colors.gold),
                  title: const Text('إعدادات السبحة'),
                  subtitle: const Text('الهدف والسبحة العائمة'),
                  trailing: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
