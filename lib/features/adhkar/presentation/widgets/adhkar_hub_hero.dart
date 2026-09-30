import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_local_repository.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_collection_overrides_repository.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_progress_repository.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar_progress.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/presentation/screens/wird_reader_screen.dart';
import 'package:tasbeh/features/home/domain/adhkar_time_period.dart';
import 'package:tasbeh/shared/widgets/app_theme_artwork.dart';

/// Image-led top Hero of the Adhkar Hub, showing the collection relevant
/// right now (morning/evening) using the same theme-aware artwork as the
/// Home hero. Entirely tappable; opens the existing reader route.
class AdhkarHubHero extends StatefulWidget {
  const AdhkarHubHero({required this.onOpen, super.key});

  /// Opens/continues the current Adhkar reader (existing route/callback).
  final Future<void> Function(AdhkarCategory category) onOpen;

  @override
  State<AdhkarHubHero> createState() => _AdhkarHubHeroState();
}

class _AdhkarHubHeroState extends State<AdhkarHubHero>
    with WidgetsBindingObserver {
  AdhkarCategory? _category;
  AdhkarProgressSummary? _summary;
  ValueListenable<int>? _progressChanges;
  ValueListenable<int>? _definitionChanges;
  Timer? _timeBoundaryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _scheduleTimeBoundary();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progressChanges?.removeListener(_onProgressChanged);
    _definitionChanges?.removeListener(_onDefinitionChanged);
    _timeBoundaryTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
      _scheduleTimeBoundary();
    }
  }

  void _onProgressChanged() => _loadSummary();

  void _onDefinitionChanged() => _load();

  void _scheduleTimeBoundary() {
    _timeBoundaryTimer?.cancel();
    final now = DateTime.now();
    final boundary = AdhkarTimePeriod.nextBoundaryAfter(now);
    _timeBoundaryTimer = Timer(
      boundary.difference(now) + const Duration(milliseconds: 10),
      () {
        if (!mounted) return;
        _load();
        _scheduleTimeBoundary();
      },
    );
  }

  Future<void> _load() async {
    final targetId = AdhkarTimePeriod.now().categoryId;
    final category = await AdhkarLocalRepository.loadResolvedCategory(targetId);
    if (category == null || !mounted) return;
    final summary = await AdhkarProgressRepository.instance.loadSummary(
      category,
    );
    if (!mounted || AdhkarTimePeriod.now().categoryId != targetId) return;
    if (_category?.id != targetId) {
      _progressChanges?.removeListener(_onProgressChanged);
      _progressChanges = AdhkarProgressRepository.instance.changesFor(targetId)
        ..addListener(_onProgressChanged);
      _definitionChanges?.removeListener(_onDefinitionChanged);
      _definitionChanges =
          AdhkarCollectionOverridesRepository.instance.changesFor(targetId)
            ..addListener(_onDefinitionChanged);
    }
    setState(() {
      _category = category;
      _summary = summary;
    });
  }

  Future<void> _loadSummary() async {
    final category = _category;
    if (category == null) return;
    final summary = await AdhkarProgressRepository.instance.loadSummary(
      category,
    );
    if (!mounted || _category?.id != category.id || summary == _summary) return;
    setState(() => _summary = summary);
  }

  @override
  Widget build(BuildContext context) {
    final category = _category;
    return Material(
      color: Colors.transparent,
      child: category == null
          ? _buildHeroBody(context)
          : Hero(
              tag: WirdReaderScreen.heroTagFor(category.id),
              flightShuttleBuilder: WirdReaderScreen.heroFlightShuttle,
              child: _buildHeroBody(context),
            ),
    );
  }

  Widget _buildHeroBody(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final isMorning = _category?.kind != AdhkarCategoryKind.evening;
    final foreground = colors.imageForeground;
    final mutedForeground = colors.imageForegroundMuted;
    final backgroundAsset = colors.heroAsset(
      isMorning: isMorning,
      brightness: theme.brightness,
    );
    final title = isMorning ? 'أذكار الصباح' : 'أذكار المساء';
    final summary = _summary;

    return InkWell(
      onTap: _category == null ? null : () => widget.onOpen(_category!),
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(28),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: AppThemeArtwork(
                asset: backgroundAsset,
                alignment: colors.usesExplicitControlRoles
                    ? Alignment.centerLeft
                    : Alignment.center,
              ),
            ),
            // Subtle readability overlay, strongest near the text side.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [
                      colors.imageScrim.withValues(
                        alpha: colors.heroScrimOpacity(
                          isMorning: isMorning,
                          brightness: theme.brightness,
                        ),
                      ),
                      colors.imageScrim.withValues(alpha: 0),
                    ],
                    stops: const [0, .62],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: foreground.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: foreground.withValues(alpha: .28),
                      ),
                    ),
                    child: Text(
                      'الورد الحالي',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      color: foreground,
                      fontSize: 34,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _progressSummaryText(summary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: mutedForeground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'اضغط للمتابعة',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_back_rounded,
                        size: 17,
                        color: foreground,
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Thin real-progress line at the bottom.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: summary == null || summary.totalSteps == 0
                          ? 0
                          : summary.completedSteps / summary.totalSteps,
                      minHeight: 4,
                      backgroundColor: foreground.withValues(alpha: .22),
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _progressSummaryText(AdhkarProgressSummary? summary) {
    if (summary == null || summary.totalSteps == 0) {
      return 'لم تبدأ بعد — ابدأ ذكرك الآن';
    }
    final percent = (summary.completedSteps / summary.totalSteps * 100).round();
    return '${ArabicNumerals.integer(summary.completedSteps)} من ${ArabicNumerals.integer(summary.totalSteps)} ذكر • ${ArabicNumerals.integer(percent)}٪';
  }
}
