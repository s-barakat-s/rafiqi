import 'package:flutter/material.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/core/theme/rafiqi_palette.dart';
import 'package:tasbeh/shared/widgets/app_decorative_background.dart';
import 'package:tasbeh/features/settings/data/repositories/app_preferences_repository.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = AppPreferencesRepository.instance;
    return AnimatedBuilder(
      animation: preferences.appearanceChanges,
      builder: (context, _) {
        final settings = preferences.value;
        final colors = context.appColors;

        return AppDecorativeBackground(
  child: Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: const Text('المظهر'),
    ),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            'ألوان مَآب',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'اختر الألوان التي تناسبك',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final cardWidth = (constraints.maxWidth - spacing) / 2;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final palette in RafiqiPalette.values)
                    SizedBox(
                      width: cardWidth,
                      child: _PaletteCard(
                        palette: palette,
                        selected: palette == settings.palette,
                        onTap: () => preferences.setPalette(palette),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'الوضع',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colors.outline.withValues(alpha: .55),
              ),
            ),
            child: SwitchListTile(
              value: settings.isDarkMode,
              onChanged: preferences.setDarkMode,
              secondary: Icon(
                settings.isDarkMode
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                color: colors.secondary,
              ),
              title: const Text('الوضع الداكن'),
              subtitle: const Text('بدّل بين الوضعين الفاتح والداكن'),
            ),
          ),
        ],
      ),
    ),
  ),
);
      },
    );
  }
}

class _PaletteCard extends StatelessWidget {
  const _PaletteCard({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final RafiqiPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final name = palette.arabicName;
    final swatches = palette.canonicalSwatches;

    return Semantics(
      button: true,
      selected: selected,
      label: selected
          ? '$name، لوحة الألوان المحددة'
          : '$name، اختر لوحة الألوان',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected
                  ? colors.primary.withValues(alpha: .08)
                  : colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? colors.primary
                    : colors.border.withValues(alpha: .6),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: .12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PalettePreview(swatches: swatches, selected: selected),
                const SizedBox(height: 8),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? colors.primary : colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PalettePreview extends StatelessWidget {
  const _PalettePreview({required this.swatches, required this.selected});

  final List<Color> swatches;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: .2),
          width: .5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final color in swatches)
                Expanded(child: ColoredBox(color: color)),
            ],
          ),
          if (selected)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .45),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
