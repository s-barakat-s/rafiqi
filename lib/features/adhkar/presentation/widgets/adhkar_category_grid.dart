import 'package:flutter/material.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/presentation/screens/wird_reader_screen.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final aspectRatio = constraints.maxWidth < 360 ? .9 : .96;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: aspectRatio,
          ),
          itemCount: categories.length + 1,
          itemBuilder: (context, index) {
            if (index == categories.length) {
              return _CreateCustomCollectionCard(onTap: onCreateCustom);
            }
            return _CategoryContainer(
              category: categories[index],
              vibrationEnabled: vibrationEnabled,
              soundEnabled: soundEnabled,
              onCustomize: onCustomize,
            );
          },
        );
      },
    );
  }
}

class _CategoryContainer extends StatefulWidget {
  const _CategoryContainer({
    required this.category,
    required this.vibrationEnabled,
    required this.soundEnabled,
    required this.onCustomize,
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outline.withValues(alpha: .65)),
      ),
      clipBehavior: Clip.antiAlias,
      child: _AdhkarCategoryTile(
        category: widget.category,
        onTap: _openReader,
        onCustomize: () => widget.onCustomize(widget.category),
      ),
    );
  }

  Future<void> _openReader() async {
    if (_opening) return;
    setState(() => _opening = true);
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, animation, secondaryAnimation) =>
            WirdReaderScreen(
          category: widget.category,
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
    required this.onTap,
    required this.onCustomize,
  });

  final AdhkarCategory category;
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
                IconButton(
                  onPressed: onCustomize,
                  tooltip: 'تخصيص الورد',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.tune_rounded, size: 19),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.selected.withValues(alpha: .24),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${ArabicNumerals.integer(category.items.length)} أذكار',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: colors.emerald.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _categoryIcon(category.kind),
                color: colors.secondary,
                size: 24,
              ),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.secondaryText,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _categoryIcon(AdhkarCategoryKind kind) => switch (kind) {
  AdhkarCategoryKind.morning => Icons.wb_sunny_outlined,
  AdhkarCategoryKind.evening => Icons.nightlight_outlined,
  AdhkarCategoryKind.afterPrayer => Icons.mosque_outlined,
  AdhkarCategoryKind.sleep => Icons.bedtime_outlined,
  AdhkarCategoryKind.custom => Icons.auto_awesome_motion_outlined,
};

class _CreateCustomCollectionCard extends StatelessWidget {
  const _CreateCustomCollectionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline_rounded, color: colors.secondary),
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
