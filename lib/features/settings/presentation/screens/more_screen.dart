import 'package:flutter/material.dart';
import 'package:tasbeh/core/theme/app_theme.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.adhkarVibrationEnabled,
    required this.onAdhkarVibrationChanged,
    required this.adhkarSoundEnabled,
    required this.onAdhkarSoundChanged,
    required this.onOpenTasbeehSettings,
    super.key,
  });
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final bool adhkarVibrationEnabled;
  final ValueChanged<bool> onAdhkarVibrationChanged;
  final bool adhkarSoundEnabled;
  final ValueChanged<bool> onAdhkarSoundChanged;
  final VoidCallback onOpenTasbeehSettings;

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
                Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                  color: colors.divider.withValues(alpha: .6),
                ),
                ListTile(
                  onTap: onOpenTasbeehSettings,
                  leading: Icon(Icons.tune_rounded, color: colors.secondary),
                  title: const Text('إعدادات السبحة'),
                  subtitle: const Text('الهدف والسبحة العائمة'),
                  trailing: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'تفاعل الأذكار',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.outline.withValues(alpha: .55)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: adhkarVibrationEnabled,
                  onChanged: onAdhkarVibrationChanged,
                  secondary: Icon(
                    Icons.vibration_rounded,
                    color: colors.secondary,
                  ),
                  title: const Text('اهتزاز عند الذكر'),
                ),
                Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                  color: colors.divider.withValues(alpha: .6),
                ),
                SwitchListTile(
                  value: adhkarSoundEnabled,
                  onChanged: onAdhkarSoundChanged,
                  secondary: Icon(
                    Icons.volume_up_outlined,
                    color: colors.secondary,
                  ),
                  title: const Text('صوت عند الذكر'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
