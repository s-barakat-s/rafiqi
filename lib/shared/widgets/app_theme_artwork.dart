import 'package:flutter/material.dart';

/// Theme-aware raster artwork that cross-fades variants and decodes near the
/// rendered width instead of retaining the full source bitmap in memory.
class AppThemeArtwork extends StatelessWidget {
  const AppThemeArtwork({
    required this.asset,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.onFrameReady,
    super.key,
  });

  static const transitionDuration = Duration(milliseconds: 140);

  final String asset;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final VoidCallback? onFrameReady;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final logicalWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final physicalWidth =
            (logicalWidth * MediaQuery.devicePixelRatioOf(context)).ceil();
        final cacheWidth = (((physicalWidth + 63) ~/ 64) * 64)
            .clamp(64, 4096)
            .toInt();

        return AnimatedSwitcher(
          duration: transitionDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            fit: StackFit.expand,
            children: [...previousChildren, ?currentChild],
          ),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Image.asset(
            asset,
            key: ValueKey((asset, cacheWidth)),
            width: double.infinity,
            height: double.infinity,
            fit: fit,
            alignment: alignment,
            cacheWidth: cacheWidth,
            filterQuality: FilterQuality.medium,
            excludeFromSemantics: true,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) onFrameReady?.call();
              return child;
            },
          ),
        );
      },
    );
  }
}
