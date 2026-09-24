import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tasbeh/core/theme/rafiqi_palette.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_controller.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_settings.dart';
import 'package:tasbeh/features/adhkar/presentation/screens/adhkar_categories_screen.dart';
import 'package:tasbeh/features/tasbeeh/presentation/screens/floating_tasbeeh_settings_screen.dart';
import 'package:tasbeh/features/journey/presentation/screens/journey_screen.dart';
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
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.selectedPalette,
    required this.onPaletteChanged,
    required this.adhkarVibrationEnabled,
    required this.onAdhkarVibrationChanged,
    required this.adhkarSoundEnabled,
    required this.onAdhkarSoundChanged,
    super.key,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final RafiqiPalette selectedPalette;
  final ValueChanged<RafiqiPalette> onPaletteChanged;
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
  bool _tasbeehInitialized = false;
  final _tasbeehFocusProgress = ValueNotifier<double>(0);
  final _visitedTabs = <int>{0};
  Future<void>? _tasbeehInitialization;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tasbeeh.addListener(_onTasbeehChanged);
  }

  Future<void> _ensureTasbeehInitialized() {
    return _tasbeehInitialization ??= _tasbeeh.initialize().then((_) {
      _tasbeehInitialized = true;
    });
  }

  void _selectTab(int index) {
    setState(() {
      _tabIndex = index;
      _visitedTabs.add(index);
    });
    if (index == 2) {
      if (_tasbeehInitialized) {
        _tasbeeh.reload();
      } else {
        _ensureTasbeehInitialized();
      }
    }
  }

  void _onTasbeehChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tasbeeh.removeListener(_onTasbeehChanged);
    _tasbeeh.dispose();
    _tasbeehFocusProgress.dispose();
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
    final categories = await AdhkarLocalRepository.loadCategories();
    if (!mounted) return;
    final category = categories
        .where((item) => item.id == categoryId)
        .firstOrNull;
    if (category == null) {
      _showMessage('هذا الورد غير متوفر أو تم حذفه');
      return;
    }
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
        onOpenTasbeeh: () => _selectTab(2),
        onOpenAdhkar: _openAdhkarReader,
        onOpenJourney: () => _selectTab(3),
      ),
      AdhkarCategoriesScreen(
        vibrationEnabled: widget.adhkarVibrationEnabled,
        soundEnabled: widget.adhkarSoundEnabled,
      ),
      TasbeehHomeScreen(
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
        onFocusProgress: (progress) {
          if (!mounted) return;
          _tasbeehFocusProgress.value = progress;
        },
        hapticEnabled: _tasbeeh.settings.hapticFeedbackEnabled,
        onHapticChanged: (enabled) async {
          await _tasbeeh.replaceSettings(
            _tasbeeh.settings.copyWith(hapticFeedbackEnabled: enabled),
          );
        },
      ),
      const JourneyScreen(),
      MoreScreen(
        isDarkMode: widget.isDarkMode,
        onThemeChanged: widget.onThemeChanged,
        selectedPalette: widget.selectedPalette,
        onPaletteChanged: widget.onPaletteChanged,
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
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: ValueListenableBuilder<double>(
                valueListenable: _tasbeehFocusProgress,
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
                builder: (context, progress, child) => Padding(
                padding: EdgeInsets.only(
                  bottom: 94 * (1 - Curves.easeInOutCubic.transform(progress)),
                ),
                child: child,
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: ValueListenableBuilder<double>(
                  valueListenable: _tasbeehFocusProgress,
                  child: AppBottomNavBar(
                    currentIndex: _tabIndex,
                    onChanged: _selectTab,
                  ),
                  builder: (context, progress, child) => IgnorePointer(
                  ignoring: progress > 0,
                  child: FractionalTranslation(
                    translation: Offset(0, 1.35 * Curves.easeInCubic.transform(progress)),
                    child: Opacity(
                      opacity: 1 - progress,
                      child: child,
                    ),
                  ),
                ),
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
          state: _tasbeeh.state,
          onStartOverlay: _startFloatingTasbeeh,
          onStopOverlay: _stopFloatingTasbeeh,
        ),
      ),
    );
    if (result != null) await _tasbeeh.replaceSettings(result);
  }
}
