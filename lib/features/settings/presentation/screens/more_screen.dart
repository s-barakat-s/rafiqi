import 'package:flutter/material.dart';
import 'package:tasbeh/core/theme/app_theme.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    required this.isDarkMode,
    required this.onThemeChanged,
    super.key,
  });
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
        children: [
          Text(
            'المزيد',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'المظهر وإعدادات تجربتك',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: colors.secondaryText),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.outline.withValues(alpha: .55)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: isDarkMode,
                  onChanged: onThemeChanged,
                  secondary: Icon(
                    isDarkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    color: colors.secondary,
                  ),
                  title: const Text('الوضع الداكن'),
                  subtitle: const Text('خلفية حبرية مريحة للعين'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
