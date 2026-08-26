import 'package:flutter/material.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/tasbeeh/presentation/widgets/tasbeeh_nav_icon.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    required this.currentIndex,
    required this.onChanged,
    super.key,
  });
  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'الرئيسية'),
    (Icons.auto_stories_outlined, Icons.auto_stories_rounded, 'الأذكار'),
    (Icons.circle_outlined, Icons.circle, 'السبحة'),
    (Icons.route_outlined, Icons.route_rounded, 'رحلتي'),
    (Icons.grid_view_outlined, Icons.grid_view_rounded, 'المزيد'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = isDark ? AppPalette.drySage : colors.primary;
    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          border: Border.all(color: colors.outline.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final selected = currentIndex == index;
            final center = index == 2;
            return Expanded(
              child: Semantics(
                selected: selected,
                button: true,
                label: item.$3,
                child: InkWell(
                  onTap: () => onChanged(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: center ? 42 : 32,
                        height: center ? 42 : 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: center
                              ? (isDark ? colors.secondary : colors.selected)
                              : (selected
                                    ? colors.selected
                                    : Colors.transparent),
                          border: center && !isDark
                              ? Border.all(color: colors.outline, width: 2)
                              : null,
                        ),
                        child: center
                            ? IconTheme(
                                data: IconThemeData(
                                  color: theme.colorScheme.onSecondary,
                                ),
                                child: TasbeehNavIcon(selected: selected),
                              )
                            : Icon(
                                selected ? item.$2 : item.$1,
                                size: 21,
                                color: selected
                                    ? activeColor
                                    : colors.navigationInactive,
                              ),
                      ),
                      if (!center) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.$3,
                          maxLines: 1,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: selected
                                ? activeColor
                                : colors.navigationInactive,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
