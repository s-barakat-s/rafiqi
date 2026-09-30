import 'package:flutter/material.dart';
import 'package:tasbeh/core/theme/app_theme.dart';

/// Global app background rendered as one calm, vertical gradient.
class AppDecorativeBackground extends StatelessWidget {
  const AppDecorativeBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = _buildGradient(context.appColors, theme.brightness);

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: child,
    );
  }
}

LinearGradient _buildGradient(AppColors colors, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final topTint = Color.alphaBlend(
    colors.primary.withValues(alpha: isDark ? .16 : .28),
    colors.background,
  );
  final middleTint = Color.alphaBlend(
    colors.primary.withValues(alpha: isDark ? .07 : .09),
    colors.background,
  );

  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [topTint, middleTint, colors.background],
    stops: isDark ? const [0.0, 0.42, 1.0] : const [0.0, 0.45, 1.0],
  );
}
