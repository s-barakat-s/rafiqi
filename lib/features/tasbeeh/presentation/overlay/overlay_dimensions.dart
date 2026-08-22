class OverlaySizeConfig {
  const OverlaySizeConfig({
    required this.overlayWidth,
    required this.overlayHeight,
    required this.capsuleWidth,
    required this.capsuleHeight,
    required this.currentFontSize,
    required this.totalFontSize,
    required this.beadRadius,
    required this.collapsedHandleWidth,
    required this.collapsedHandleHeight,
    required this.collapsedWindowWidth,
    required this.collapsedWindowHeight,
  });

  final double overlayWidth;
  final double overlayHeight;
  final double capsuleWidth;
  final double capsuleHeight;
  final double currentFontSize;
  final double totalFontSize;
  final double beadRadius;
  final double collapsedHandleWidth;
  final double collapsedHandleHeight;
  final double collapsedWindowWidth;
  final double collapsedWindowHeight;
}

OverlaySizeConfig configForScale(double scale) {
  final safeScale = scale.clamp(0.80, 2.20).toDouble();

  return OverlaySizeConfig(
    overlayWidth: (140 * safeScale).clamp(112, 320).toDouble(),
    overlayHeight: (280 * safeScale).clamp(224, 620).toDouble(),
    capsuleWidth: (108 * safeScale).clamp(86.4, 260).toDouble(),
    capsuleHeight: (245 * safeScale).clamp(196, 560).toDouble(),
    currentFontSize: 44 * safeScale,
    totalFontSize: 18 * safeScale,
    beadRadius: 2.4 * safeScale,
    collapsedHandleWidth: (16 * safeScale).clamp(12.8, 28).toDouble(),
    collapsedHandleHeight: (200 * safeScale).clamp(160, 440).toDouble(),
    collapsedWindowWidth: 64,
    collapsedWindowHeight: (220 * safeScale).clamp(180, 540).toDouble(),
  );
}
