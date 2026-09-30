import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tasbeh/core/assets/rafiqi_icons.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_collection_overrides_repository.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_local_repository.dart';
import 'package:tasbeh/features/adhkar/data/repositories/adhkar_progress_repository.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar_progress.dart';
import 'package:tasbeh/features/adhkar/presentation/screens/wird_reader_screen.dart';
import 'package:tasbeh/shared/widgets/app_glass_surface.dart';
import 'package:tasbeh/shared/widgets/rafiqi_svg_icon.dart';

class AdhkarCategoryGrid extends StatelessWidget {
  const AdhkarCategoryGrid({
    required this.categories,
    required this.vibrationEnabled,
    required this.soundEnabled,
    required this.onCustomize,
    required this.onCreateCustom,
    super.key,
  });

  final List<AdhkarCategory> categories;
  final bool vibrationEnabled;
  final bool soundEnabled;
  final Future<void> Function(AdhkarCategory category) onCustomize;
  final VoidCallback onCreateCustom;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Text(
            'جميع الأذكار',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: BackdropGroup(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final aspectRatio = constraints.maxWidth < 360 ? .92 : .98;
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: aspectRatio,
                  ),
                  itemCount: categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == categories.length) {
                      return _CreateCustomCollectionCard(onTap: onCreateCustom);
                    }
                    return _CategoryContainer(
                      key: ValueKey(categories[index].id),
                      category: categories[index],
                      vibrationEnabled: vibrationEnabled,
                      soundEnabled: soundEnabled,
                      onCustomize: onCustomize,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryContainer extends StatefulWidget {
  const _CategoryContainer({
    required this.category,
    required this.vibrationEnabled,
    required this.soundEnabled,
    required this.onCustomize,
    super.key,
  });

  final AdhkarCategory category;
  final bool vibrationEnabled;
  final bool soundEnabled;
  final Future<void> Function(AdhkarCategory category) onCustomize;

  @override
  State<_CategoryContainer> createState() => _CategoryContainerState();
}

class _CategoryContainerState extends State<_CategoryContainer> {
  bool _opening = false;
  AdhkarProgressSummary? _summary;
  late ValueListenable<int> _progressChanges;
  late ValueListenable<int> _definitionChanges;

  @override
  void initState() {
    super.initState();
    _progressChanges = AdhkarProgressRepository.instance.changesFor(
      widget.category.id,
    );
    _progressChanges.addListener(_onProgressChanged);
    _definitionChanges =
        AdhkarCollectionOverridesRepository.instance.changesFor(
          widget.category.id,
        )..addListener(_onDefinitionChanged);
    _loadProgress();
  }

  @override
  void didUpdateWidget(covariant _CategoryContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category.id != widget.category.id) {
      _progressChanges.removeListener(_onProgressChanged);
      _progressChanges = AdhkarProgressRepository.instance.changesFor(
        widget.category.id,
      );
      _progressChanges.addListener(_onProgressChanged);
      _definitionChanges.removeListener(_onDefinitionChanged);
      _definitionChanges =
          AdhkarCollectionOverridesRepository.instance.changesFor(
            widget.category.id,
          )..addListener(_onDefinitionChanged);
    }
    if (oldWidget.category != widget.category) _loadProgress();
  }

  @override
  void dispose() {
    _progressChanges.removeListener(_onProgressChanged);
    _definitionChanges.removeListener(_onDefinitionChanged);
    super.dispose();
  }

  void _onProgressChanged() => _loadProgress();

  Future<void> _onDefinitionChanged() async {
    final category = await AdhkarLocalRepository.loadResolvedCategory(
      widget.category.id,
    );
    if (category != null && mounted) await _loadProgress(category);
  }

  Future<void> _loadProgress([AdhkarCategory? resolvedCategory]) async {
    final category = resolvedCategory ?? widget.category;
    final summary = await AdhkarProgressRepository.instance.loadSummary(
      category,
    );
    if (!mounted || widget.category.id != category.id || summary == _summary) {
      return;
    }
    setState(() => _summary = summary);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final summary = _summary;
    final hasProgress =
        summary != null &&
        summary.hasProgress &&
        summary.totalSteps > 0 &&
        !summary.isCompleted;

    return AppGlassSurface(
      borderRadius: BorderRadius.circular(20),
      grouped: true,
      borderColor: hasProgress ? colors.primary.withValues(alpha: .45) : null,
      child: _AdhkarCategoryTile(
        category: widget.category,
        hasProgress: hasProgress,
        progress: hasProgress
            ? summary.completedSteps / summary.totalSteps
            : null,
        onTap: _openReader,
        onCustomize: () => widget.onCustomize(widget.category),
      ),
    );
  }

  Future<void> _openReader() async {
    if (_opening) return;
    setState(() => _opening = true);
    final category = await AdhkarLocalRepository.loadResolvedCategory(
      widget.category.id,
    );
    if (!mounted || category == null) {
      if (mounted) setState(() => _opening = false);
      return;
    }
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, animation, secondaryAnimation) =>
            WirdReaderScreen(
              category: category,
              vibrationEnabled: widget.vibrationEnabled,
              soundEnabled: widget.soundEnabled,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final progress = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return AnimatedBuilder(
            animation: progress,
            child: FadeTransition(opacity: progress, child: child),
            builder: (context, child) => Transform.translate(
              offset: Offset(
                0,
                (animation.status == AnimationStatus.reverse ? 8 : 12) *
                    (1 - progress.value),
              ),
              child: child,
            ),
          );
        },
      ),
    );
    if (mounted) setState(() => _opening = false);
  }
}

class _AdhkarCategoryTile extends StatelessWidget {
  const _AdhkarCategoryTile({
    required this.category,
    required this.hasProgress,
    required this.progress,
    required this.onTap,
    required this.onCustomize,
  });

  final AdhkarCategory category;
  final bool hasProgress;
  final double? progress;
  final VoidCallback onTap;
  final VoidCallback onCustomize;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    return InkWell(
      key: ValueKey('adhkar-category-${category.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon tile with an optional subtle primary tint when the
                // collection has real progress.
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.emerald.withValues(
                      alpha: hasProgress ? .16 : .1,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: RafiqiSvgIcon(
                    _categoryIcon(category.kind),
                    color: colors.secondary,
                    size: 23,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onCustomize,
                  tooltip: 'تخصيص الورد',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.tune_rounded, size: 19),
                ),
              ],
            ),
            const Spacer(),
            Text(
              category.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 20,
                height: 1.15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.secondaryText,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            // Bottom meta row: real progress bar (only when it exists),
            // then the real dhikr count.
            Row(
              children: [
                if (hasProgress) ...[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        backgroundColor: colors.outline.withValues(alpha: .5),
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  '${ArabicNumerals.integer(category.items.length)} ذكر',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _categoryIcon(AdhkarCategoryKind kind) => switch (kind) {
  AdhkarCategoryKind.morning => RafiqiIcons.morningAdhkar,
  AdhkarCategoryKind.evening => RafiqiIcons.eveningAdhkar,
  AdhkarCategoryKind.afterPrayer => RafiqiIcons.afterPrayerAdhkar,
  AdhkarCategoryKind.sleep => RafiqiIcons.sleepAdhkar,
  AdhkarCategoryKind.custom => RafiqiIcons.customWird,
};

class _CreateCustomCollectionCard extends StatelessWidget {
  const _CreateCustomCollectionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppGlassSurface(
      borderRadius: BorderRadius.circular(20),
      grouped: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RafiqiSvgIcon(RafiqiIcons.customWird, color: colors.secondary),
              const SizedBox(height: 12),
              const Text(
                'إنشاء ورد خاص',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'أذكارك الخاصة',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
