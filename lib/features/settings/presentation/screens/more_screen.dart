import 'package:flutter/material.dart';
import 'package:tasbeh/core/assets/rafiqi_icons.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/settings/presentation/screens/appearance_screen.dart';
import 'package:tasbeh/shared/widgets/rafiqi_svg_icon.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

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
            'إعدادات تجربتك',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: colors.secondaryText),
          ),
          const SizedBox(height: 24),
          Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: colors.outline.withValues(alpha: .55)),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
       onTap: () => Navigator.of(context).push<void>(
  PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (context, animation, secondaryAnimation) =>
        const AppearanceScreen(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        ),
        child: child,
      );
    },
  ),
),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: RafiqiSvgIcon(
                RafiqiIcons.themePalette,
                color: colors.primary,
              ),
              title: const Text('المظهر'),
              subtitle: const Text('اختر الألوان والوضع المناسب لك'),
              trailing: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
