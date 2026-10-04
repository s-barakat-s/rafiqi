import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:tasbeh/core/theme/app_theme.dart';

enum AppGlassSurfaceLevel { major, reader }

class AppGlassSurface extends StatelessWidget {
  const AppGlassSurface({
    required this.borderRadius,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.level = AppGlassSurfaceLevel.major,
    this.grouped = false,
    this.borderColor,
    this.backgroundColor,
    super.key,
  });

  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final AppGlassSurfaceLevel level;
  final bool grouped;
  final Color? borderColor;
  final Color? backgroundColor;
  final Widget child;

  static double opacityFor(Brightness brightness, AppGlassSurfaceLevel level) {
    return switch ((level, brightness)) {
      (AppGlassSurfaceLevel.major, Brightness.light) => .86,
      (AppGlassSurfaceLevel.major, Brightness.dark) => .84,
      (AppGlassSurfaceLevel.reader, Brightness.light) => .94,
      (AppGlassSurfaceLevel.reader, Brightness.dark) => .90,
    };
  }

  static double blurFor(Brightness brightness, AppGlassSurfaceLevel level) {
    return switch ((level, brightness)) {
      (AppGlassSurfaceLevel.major, Brightness.light) => 6,
      (AppGlassSurfaceLevel.major, Brightness.dark) => 4,
      (AppGlassSurfaceLevel.reader, _) => 4,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final brightness = Theme.of(context).brightness;
    final opacity = opacityFor(brightness, level);
    final blur = blurFor(brightness, level);
    final surfaceColor = switch (level) {
      AppGlassSurfaceLevel.major => colors.surface,
      AppGlassSurfaceLevel.reader => colors.surfaceElevated,
    };
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? surfaceColor.withValues(alpha: opacity),
        borderRadius: borderRadius,
        border: Border.all(
          color: (borderColor ?? colors.outline).withValues(alpha: .65),
        ),
      ),
      child: Padding(
        padding: padding,
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );

    return ClipRRect(
      borderRadius: borderRadius,
      // Reader cards repeat and overlap during deck/list transitions. Keep
      // their readable translucent fill without resampling underlying cards.
      child: level == AppGlassSurfaceLevel.reader
          ? content
          : grouped
          ? BackdropFilter.grouped(
              filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: content,
            )
          : BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: content,
            ),
    );
  }
}
