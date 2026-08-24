import 'package:flutter/material.dart';
import 'package:tasbeh/app/theme/app_theme.dart';

class CalligraphyTitle extends StatelessWidget {
  const CalligraphyTitle({
    required this.asset,
    required this.semanticLabel,
    required this.height,
    this.alignment = AlignmentDirectional.centerStart,
    this.color,
    this.fallback,
    super.key,
  });

  final String asset;
  final String semanticLabel;
  final double height;
  final AlignmentGeometry alignment;
  final Color? color;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint =
        color ??
        (theme.brightness == Brightness.light
            ? context.appColors.emerald
            : theme.colorScheme.onSurface);
    return Semantics(
      label: semanticLabel,
      image: true,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Image.asset(
          asset,
          alignment: alignment,
          fit: BoxFit.contain,
          color: tint,
          colorBlendMode: BlendMode.srcIn,
          excludeFromSemantics: true,
          errorBuilder: (_, _, _) => Align(
            alignment: alignment,
            child: fallback ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
