import 'package:flutter/material.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/shared/widgets/rafiqi_svg_icon.dart';

/// Minimal placeholder destination for a main tab whose feature is not
/// implemented yet (القرآن / الأذان). Content-only stub — no business logic.
class AppPlaceholderScreen extends StatelessWidget {
  const AppPlaceholderScreen({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final String icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RafiqiSvgIcon(icon, size: 56, color: colors.primary),
            const SizedBox(height: 18),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
