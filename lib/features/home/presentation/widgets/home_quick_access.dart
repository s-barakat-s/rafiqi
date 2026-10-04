part of '../home_screen.dart';

/// "الوصول السريع" — secondary feature shortcuts, not tabs.
class _QuickAccessSection extends StatelessWidget {
  const _QuickAccessSection({
    required this.onOpenTasbeeh,
    required this.onOpenJourney,
    required this.onOpenCalendar,
    required this.onOpenStatistics,
    required this.onOpenSettings,
    required this.onComingSoon,
  });

  final VoidCallback onOpenTasbeeh;
  final VoidCallback onOpenJourney;
  final VoidCallback onOpenCalendar;
  final VoidCallback? onOpenStatistics;
  final VoidCallback? onOpenSettings;
  final VoidCallback onComingSoon;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final items = [
      _QuickAccessItem('التسبيح', RafiqiIcons.tasbeeh, onOpenTasbeeh),
      _QuickAccessItem('القبلة', RafiqiIcons.qibla, onComingSoon),
      _QuickAccessItem('رحلتي', RafiqiIcons.journey, onOpenJourney),
      _QuickAccessItem('التقويم', RafiqiIcons.calendar, onOpenCalendar),
      // No matching app icon exists for statistics yet — Material fallback.
      _QuickAccessItem(
        'الإحصائيات',
        null,
        onOpenStatistics ?? onComingSoon,
        fallbackIcon: Icons.query_stats_rounded,
      ),
      _QuickAccessItem(
        'الإعدادات',
        RafiqiIcons.settings,
        onOpenSettings ?? onComingSoon,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 12),
          child: Text(
            'الوصول السريع',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Sits directly on the botanical background — no glass wrapper,
        // no BackdropFilters per item.
        LayoutBuilder(
          builder: (context, constraints) {
            const columns = 3;
            final gap = constraints.maxWidth < 340 ? 8.0 : 12.0;
            final itemWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Column(
              children: [
                for (var row = 0; row < 2; row++)
                  Padding(
                    padding: EdgeInsets.only(bottom: row == 0 ? gap : 0),
                    child: Row(
                      children: [
                        for (var col = 0; col < columns; col++)
                          SizedBox(
                            width: itemWidth,
                            child: _QuickAccessTile(
                              item: items[row * columns + col],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickAccessItem {
  const _QuickAccessItem(
    this.label,
    this.icon,
    this.onTap, {
    this.fallbackIcon,
  });

  final String label;

  /// Existing app SVG icon; null → [fallbackIcon] (Material) is used.
  final String? icon;
  final VoidCallback onTap;
  final IconData? fallbackIcon;
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({required this.item});

  final _QuickAccessItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final brightness = Theme.of(context).brightness;
    final usesRafiqiDarkSurface =
        brightness == Brightness.dark && colors.isRafiqi;
    final rafiqiCardSurface = colors.isRafiqi
        ? brightness == Brightness.light
              ? AppPalette.rafiqiLightCardSurface
              : AppPalette.rafiqiDarkCardSurface
        : null;
    final iconColor = colors.primary;
    final icon = item.icon != null
        ? RafiqiSvgIcon(item.icon!, size: 24, color: iconColor)
        : Icon(item.fallbackIcon, size: 24, color: iconColor);
    return Semantics(
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular shortcut container — subtle fill, soft border,
              // no shadow, no selected state (these are shortcuts, not tabs).
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      rafiqiCardSurface ??
                      colors.surfaceElevated.withValues(alpha: .88),
                  border: Border.all(
                    color: usesRafiqiDarkSurface
                        ? AppPalette.rafiqiLightPrimary.withValues(alpha: .28)
                        : colors.outline.withValues(alpha: .6),
                  ),
                ),
                child: icon,
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
