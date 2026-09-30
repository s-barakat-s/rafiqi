import 'package:flutter/material.dart';
import 'package:tasbeh/core/assets/rafiqi_icons.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/shared/widgets/app_glass_surface.dart';
import 'package:tasbeh/shared/widgets/rafiqi_svg_icon.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    required this.currentIndex,
    required this.onChanged,
    super.key,
  });
  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const _items = [
    (RafiqiIcons.home, 'الرئيسية'),
    (RafiqiIcons.adhkar, 'الأذكار'),
    (RafiqiIcons.quran, 'القرآن'),
    (RafiqiIcons.adhan, 'الأذان'),
    (RafiqiIcons.more, 'المزيد'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final activeColor = colors.primary;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: AppGlassSurface(
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          height: 80,
          child: Row(
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final selected = currentIndex == index;
            return Expanded(
              child: Semantics(
                selected: selected,
                button: true,
                label: item.$2,
                child: InkWell(
                  onTap: () => onChanged(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        scale: selected ? 1.05 : 1,
                        child: RafiqiSvgIcon(
                          item.$1,
                          size: 23,
                          color: selected
                              ? activeColor
                              : colors.navigationInactive,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.$2,
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
                  ),
                ),
              ),
            );
          }),
          ),
        ),
      ),
    );
  }
}
