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
    super.key,
  });

  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final AppGlassSurfaceLevel level;
  final bool grouped;
  final Color? borderColor;
  final Widget child;

  static double opacityFor(
    Brightness brightness,
    AppGlassSurfaceLevel level,
  ) {
    return switch ((level, brightness)) {
      (AppGlassSurfaceLevel.major, Brightness.light) => .86,
      (AppGlassSurfaceLevel.major, Brightness.dark) => .84,
      (AppGlassSurfaceLevel.reader, Brightness.light) => .94,
      (AppGlassSurfaceLevel.reader, Brightness.dark) => .90,
    };
  }

  static double blurFor(
    Brightness brightness,
    AppGlassSurfaceLevel level,
  ) {
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
        color: surfaceColor.withValues(alpha: opacity),
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

enum AppTranslucentSurfaceLevel { collection, inner }

enum AppTranslucentSurfaceBorder { subtle, standard }

class AppTranslucentSurface extends StatelessWidget {
  const AppTranslucentSurface({
    required this.borderRadius,
    required this.child,
    this.level = AppTranslucentSurfaceLevel.inner,
    this.border = AppTranslucentSurfaceBorder.subtle,
    this.borderColor,
    this.tintWithPrimaryInLight = false,
    super.key,
  });

  final BorderRadius borderRadius;
  final Widget child;
  final AppTranslucentSurfaceLevel level;
  final AppTranslucentSurfaceBorder border;
  final Color? borderColor;
  final bool tintWithPrimaryInLight;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = switch (level) {
      AppTranslucentSurfaceLevel.collection => colors.surface,
      AppTranslucentSurfaceLevel.inner => colors.surfaceElevated,
    };
    final opacity = switch ((level, isDark)) {
      (AppTranslucentSurfaceLevel.collection, false) => .93,
      (AppTranslucentSurfaceLevel.collection, true) => .88,
      (AppTranslucentSurfaceLevel.inner, false) => .95,
      (AppTranslucentSurfaceLevel.inner, true) => .90,
    };
    final tintedColor = !isDark && tintWithPrimaryInLight
        ? Color.alphaBlend(
            colors.primary.withValues(alpha: .075),
            baseColor,
          )
        : baseColor;
    final borderOpacity = switch ((border, isDark)) {
      (AppTranslucentSurfaceBorder.subtle, false) => .25,
      (AppTranslucentSurfaceBorder.subtle, true) => .35,
      (AppTranslucentSurfaceBorder.standard, _) => .65,
    };

    return Material(
      color: tintedColor.withValues(alpha: opacity),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(
          color: (borderColor ?? colors.outline).withValues(
            alpha: borderOpacity,
          ),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
