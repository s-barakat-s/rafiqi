import 'package:flutter/material.dart';
import 'package:tasbeh/app/theme/app_theme.dart';

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
    (
      Icons.radio_button_checked_rounded,
      Icons.radio_button_checked_rounded,
      'السبحة',
    ),
    (Icons.route_outlined, Icons.route_rounded, 'رحلتي'),
    (Icons.grid_view_outlined, Icons.grid_view_rounded, 'المزيد'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          border: Border.all(color: colors.gold.withValues(alpha: 0.28)),
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
                              ? colors.gold
                              : (selected
                                    ? colors.emerald.withValues(alpha: 0.12)
                                    : Colors.transparent),
                          border: center
                              ? Border.all(
                                  color: colors.gold.withValues(alpha: 0.55),
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Icon(
                          selected ? item.$2 : item.$1,
                          size: center ? 23 : 21,
                          color: center
                              ? const Color(0xFF173C35)
                              : (selected ? colors.gold : colors.secondaryText),
                        ),
                      ),
                      if (!center) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.$3,
                          maxLines: 1,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: selected
                                ? colors.gold
                                : colors.secondaryText,
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
