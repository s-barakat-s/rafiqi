import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';
import 'package:tasbeh/features/adhkar/presentation/screens/wird_reader_screen.dart';
import 'package:tasbeh/features/adhkar/presentation/widgets/adhkar_category_title_hero.dart';

class AdhkarCategoryGrid extends StatelessWidget {
  const AdhkarCategoryGrid({
    required this.categories,
    required this.vibrationEnabled,
    required this.soundEnabled,
    super.key,
  });

  final List<AdhkarCategory> categories;
  final bool vibrationEnabled;
  final bool soundEnabled;

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
          itemCount: categories.length,
          itemBuilder: (context, index) => _CategoryContainer(
            category: categories[index],
            vibrationEnabled: vibrationEnabled,
            soundEnabled: soundEnabled,
          ),
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
  });

  final AdhkarCategory category;
  final bool vibrationEnabled;
  final bool soundEnabled;

  @override
  State<_CategoryContainer> createState() => _CategoryContainerState();
}

class _CategoryContainerState extends State<_CategoryContainer> {
  bool _opening = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: colors.outline.withValues(alpha: .65)),
    );

    return OpenContainer<void>(
      transitionType: ContainerTransitionType.fade,
      transitionDuration: const Duration(milliseconds: 500),
      closedElevation: 0,
      openElevation: 0,
      closedColor: theme.colorScheme.surface,
      middleColor: colors.surfaceElevated,
      openColor: theme.scaffoldBackgroundColor,
      closedShape: shape,
      openShape: const RoundedRectangleBorder(),
      tappable: false,
      onClosed: (_) {
        if (mounted) setState(() => _opening = false);
      },
      openBuilder: (context, _) => WirdReaderScreen(
        category: widget.category,
        vibrationEnabled: widget.vibrationEnabled,
        soundEnabled: widget.soundEnabled,
      ),
      closedBuilder: (context, openContainer) => _AdhkarCategoryTile(
        category: widget.category,
        onTap: () {
          if (_opening) return;
          setState(() => _opening = true);
          openContainer();
        },
      ),
    );
  }
}

class _AdhkarCategoryTile extends StatelessWidget {
  const _AdhkarCategoryTile({required this.category, required this.onTap});

  final AdhkarCategory category;
  final VoidCallback onTap;

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
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            AdhkarCategoryTitleHero(
              category: category,
              child: Text(
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
};
