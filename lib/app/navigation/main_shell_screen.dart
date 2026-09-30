import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tasbeh/shared/widgets/app_decorative_background.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_app_scope.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_controller.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_settings.dart';
import 'package:tasbeh/features/adhkar/presentation/screens/adhkar_categories_screen.dart';
import 'package:tasbeh/features/tasbeeh/presentation/screens/floating_tasbeeh_settings_screen.dart';
import 'package:tasbeh/features/journey/presentation/screens/journey_screen.dart';
import 'package:tasbeh/app/navigation/app_placeholder_screen.dart';
import 'package:tasbeh/core/assets/rafiqi_icons.dart';
import 'package:tasbeh/features/tasbeeh/presentation/screens/tasbeeh_home_screen.dart';
import 'package:tasbeh/features/tasbeeh/presentation/screens/tasbeeh_statistics_screen.dart';
import 'package:tasbeh/features/tasbeeh/presentation/screens/manual_tasbeeh_logging.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/features/tasbeeh/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:tasbeh/features/settings/presentation/screens/more_screen.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_local_repository.dart';
import 'package:tasbeh/features/adhkar/presentation/screens/wird_reader_screen.dart';
import 'package:tasbeh/features/home/presentation/home_screen.dart';

/// Owns the five top-level destinations and cross-feature navigation only.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({
    required this.adhkarVibrationEnabled,
    required this.onAdhkarVibrationChanged,
    required this.adhkarSoundEnabled,
    required this.onAdhkarSoundChanged,
    super.key,
  });

  final bool adhkarVibrationEnabled;
  final ValueChanged<bool> onAdhkarVibrationChanged;
  final bool adhkarSoundEnabled;
  final ValueChanged<bool> onAdhkarSoundChanged;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen>
    with WidgetsBindingObserver {
  /// Application-scoped Tasbeeh authority (Phase 2A). The shell no longer
  /// creates or disposes its own controller; the scope outlives every route.
  TasbeehController get _tasbeeh => TasbeehAppScope.controller;
  int _tabIndex = 0;
  bool _tasbeehInitialized = false;
  final _visitedTabs = <int>{0};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    TasbeehAppScope.ensureInitialized().then((_) {
      _tasbeehInitialized = true;
    });
  }

  void _selectTab(int index) {
    setState(() {
      _tabIndex = index;
      _visitedTabs.add(index);
    });
  }

  Future<void> _ensureTasbeehInitialized() =>
      TasbeehAppScope.ensureInitialized();

  Future<void> _openTasbeeh() async {
    await _ensureTasbeehInitialized();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TasbeehHomeScreen(
          state: _tasbeeh.state,
          onIncrement: _incrementTasbeeh,
          onResetSession: _tasbeeh.resetSession,
          onDecrement: _tasbeeh.decrement,
          onOpenSettings: _openTasbeehSettings,
          phrases: _tasbeeh.phrases,
          onSelectDhikr: _tasbeeh.selectDhikr,
          onAddCustomPhrase: (text) async {
            await _tasbeeh.addCustomPhrase(text);
          },
          onOpenStatistics: _openTasbeehStatistics,
          onOpenManualLog: _openManualTasbeehLog,
          focusController: _tasbeeh,
          hapticEnabled: _tasbeeh.settings.hapticFeedbackEnabled,
          onHapticChanged: (enabled) async {
            await _tasbeeh.replaceSettings(
              _tasbeeh.settings.copyWith(hapticFeedbackEnabled: enabled),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openJourney() async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const JourneyScreen()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _tasbeehInitialized) {
      _tasbeeh.reload();
    } else if (_tasbeehInitialized &&
        (state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused ||
            state == AppLifecycleState.detached)) {
      _tasbeeh.flushPendingIncrements();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _startFloatingTasbeeh() async {
    await _ensureTasbeehInitialized();
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

  Future<void> _incrementTasbeeh() async {
    await _ensureTasbeehInitialized();
    final completedTask = await _tasbeeh.increment();
    if (!mounted || !completedTask) return;
    _showMessage('أحسنت، أكملت المهمة');
  }

  Future<void> _openTasbeehStatistics() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const TasbeehStatisticsScreen()),
    );
  }

  Future<void> _openManualTasbeehHistory() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ManualTasbeehHistoryScreen(phrases: _tasbeeh.phrases),
      ),
    );
  }

  Future<void> _openManualTasbeehLog() async {
    await _ensureTasbeehInitialized();
    if (!mounted) return;
    final selected = _tasbeeh.phrases.firstWhere(
      (phrase) => phrase.id == _tasbeeh.state.selectedDhikrId,
      orElse: () => _tasbeeh.phrases.first,
    );
    final draft = await showModalBottomSheet<ManualTasbeehDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ManualTasbeehEntrySheet(
        phrases: _tasbeeh.phrases,
        initialPhrase: selected,
        onOpenHistory: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _openManualTasbeehHistory();
          });
        },
      ),
    );
    if (draft == null || !mounted) return;
    final completedTask = await _tasbeeh.recordPhysicalManual(
      phrase: draft.phrase,
      count: draft.count,
    );
    if (!mounted) return;
    _showMessage(
      completedTask
          ? 'أحسنت، تم تسجيل الذكر وإكمال المهمة'
          : 'تم تسجيل ${ArabicNumerals.integer(draft.count)} مرة',
    );
  }

  Future<void> _openAdhkarReader(String categoryId) async {
    final category = await AdhkarLocalRepository.loadResolvedCategory(
      categoryId,
    );
    if (!mounted) return;
    if (category == null) {
      _showMessage('هذا الورد غير متوفر أو تم حذفه');
      return;
    }
    await Navigator.of(context).push<void>(
  PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (context, animation, secondaryAnimation) {
      return AppDecorativeBackground(
        child: WirdReaderScreen(
          category: category,
          vibrationEnabled: widget.adhkarVibrationEnabled,
          soundEnabled: widget.adhkarSoundEnabled,
        ),
      );
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        ),
        child: child,
      );
    },
  ),
);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        onOpenTasbeeh: _openTasbeeh,
        onOpenAdhkar: _openAdhkarReader,
        onOpenJourney: _openJourney,
      ),
      AdhkarCategoriesScreen(
        vibrationEnabled: widget.adhkarVibrationEnabled,
        soundEnabled: widget.adhkarSoundEnabled,
      ),
      const AppPlaceholderScreen(
        icon: RafiqiIcons.quran,
        title: 'القرآن الكريم',
        message: 'قريبًا ستتمكن من متابعة قراءتك من حيث توقفت',
      ),
      const AppPlaceholderScreen(
        icon: RafiqiIcons.adhan,
        title: 'مواقيت الصلاة',
        message: 'قريبًا: مواقيت الصلاة والتنبيه بموعد الأذان',
      ),
      const MoreScreen(),
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
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 94),
                child: IndexedStack(
                  index: _tabIndex,
                  children: [
                    for (var index = 0; index < pages.length; index++)
                      TickerMode(
                        enabled: index == _tabIndex,
                        child: _visitedTabs.contains(index)
                            ? pages[index]
                            : const SizedBox.shrink(),
                      ),
                  ],
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
                  onChanged: _selectTab,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTasbeehSettings() async {
    await _ensureTasbeehInitialized();
    if (!mounted) return;
    final result = await Navigator.of(context).push<TasbeehSettings>(
      MaterialPageRoute(
        builder: (_) => FloatingTasbeehSettingsScreen(
          initialSettings: _tasbeeh.settings,
          onStartOverlay: _startFloatingTasbeeh,
          onStopOverlay: _stopFloatingTasbeeh,
        ),
      ),
    );
    if (result != null) await _tasbeeh.replaceSettings(result);
  }
}
