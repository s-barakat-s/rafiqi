import 'package:flutter/material.dart';

class TasbeehSettings {
  const TasbeehSettings({
    required this.opacity,
    required this.sizeScale,
    required this.accentColor,
    required this.backgroundIntensity,
    required this.borderStyle,
    required this.showBeads,
    required this.beadSize,
    required this.showTotal,
    required this.showDivider,
    required this.autoCollapseSeconds,
    required this.handleColorMode,
    required this.handleThickness,
    required this.handleHeight,
    required this.hapticFeedbackEnabled,
    required this.tapAnimationEnabled,
    required this.floatingSide,
    required this.overlayMode,
  });

  factory TasbeehSettings.initial() {
    return const TasbeehSettings(
      opacity: 1,
      sizeScale: defaultSizeScale,
      accentColor: accentGreen,
      backgroundIntensity: backgroundDark,
      borderStyle: borderSubtle,
      showBeads: true,
      beadSize: beadMedium,
      showTotal: true,
      showDivider: true,
      autoCollapseSeconds: 10,
      handleColorMode: handleWhite,
      handleThickness: handleMedium,
      handleHeight: handleMedium,
      hapticFeedbackEnabled: true,
      tapAnimationEnabled: true,
      floatingSide: sideRight,
      overlayMode: overlayModeExpanded,
    );
  }

  factory TasbeehSettings.fromJson(Map<String, Object?> json) {
    return TasbeehSettings(
      opacity: _normalizeOpacity((json['opacity'] as num?)?.toDouble()),
      sizeScale: _normalizeSizeScale(
        (json['sizeScale'] as num?)?.toDouble() ??
            _scaleFromLegacyPreset(json['sizePreset']),
      ),
      accentColor: _normalizeString(
        json['accentColor'],
        validAccentColors,
        accentGreen,
      ),
      backgroundIntensity: _normalizeString(
        json['backgroundIntensity'],
        validBackgroundIntensities,
        backgroundDark,
      ),
      borderStyle: _normalizeString(
        json['borderStyle'],
        validBorderStyles,
        borderSubtle,
      ),
      showBeads: json['showBeads'] as bool? ?? true,
      beadSize: _normalizeString(json['beadSize'], validBeadSizes, beadMedium),
      showTotal: json['showTotal'] as bool? ?? true,
      showDivider: json['showDivider'] as bool? ?? true,
      autoCollapseSeconds: _normalizeAutoCollapseSeconds(
        json['autoCollapseSeconds'] as int?,
      ),
      handleColorMode: _normalizeString(
        json['handleColorMode'],
        validHandleColorModes,
        handleWhite,
      ),
      handleThickness: _normalizeString(
        json['handleThickness'],
        validHandleThicknesses,
        handleMedium,
      ),
      handleHeight: _normalizeString(
        json['handleHeight'],
        validHandleHeights,
        handleMedium,
      ),
      hapticFeedbackEnabled: json['hapticFeedbackEnabled'] as bool? ?? true,
      tapAnimationEnabled: json['tapAnimationEnabled'] as bool? ?? true,
      floatingSide: _normalizeString(
        json['floatingSide'],
        validFloatingSides,
        sideRight,
      ),
      overlayMode: _normalizeString(
        json['overlayMode'],
        validOverlayModes,
        overlayModeExpanded,
      ),
    );
  }

  static const minSizeScale = 0.80;
  static const defaultSizeScale = 1.00;
  static const maxSizeScale = 2.20;

  static const _legacySizeSmall = 'small';
  static const _legacySizeMedium = 'medium';
  static const _legacySizeLarge = 'large';
  static const _legacySizeExtraLarge = 'extraLarge';

  static const accentGreen = 'green';
  static const accentGold = 'gold';
  static const accentBlue = 'blue';
  static const accentPurple = 'purple';
  static const accentRed = 'red';
  static const accentWhite = 'white';

  static const backgroundVeryDark = 'veryDark';
  static const backgroundDark = 'dark';
  static const backgroundSoftDark = 'softDark';

  static const borderNone = 'none';
  static const borderSubtle = 'subtle';
  static const borderBright = 'bright';

  static const beadSmall = 'small';
  static const beadMedium = 'medium';
  static const beadLarge = 'large';

  static const handleWhite = 'white';
  static const handleAccent = 'accent';
  static const handleGray = 'gray';

  static const handleThin = 'thin';
  static const handleMedium = 'medium';
  static const handleThick = 'thick';

  static const handleShort = 'short';
  static const handleTall = 'tall';

  static const sideLeft = 'left';
  static const sideRight = 'right';

  static const overlayModeExpanded = 'expanded';
  static const overlayModeCollapsed = 'collapsed';

  static const validAccentColors = [
    accentGreen,
    accentGold,
    accentBlue,
    accentPurple,
    accentRed,
    accentWhite,
  ];
  static const validBackgroundIntensities = [
    backgroundVeryDark,
    backgroundDark,
    backgroundSoftDark,
  ];
  static const validBorderStyles = [borderNone, borderSubtle, borderBright];
  static const validBeadSizes = [beadSmall, beadMedium, beadLarge];
  static const validHandleColorModes = [handleWhite, handleAccent, handleGray];
  static const validHandleThicknesses = [handleThin, handleMedium, handleThick];
  static const validHandleHeights = [handleShort, handleMedium, handleTall];
  static const validFloatingSides = [sideLeft, sideRight];
  static const validOverlayModes = [overlayModeExpanded, overlayModeCollapsed];

  final double opacity;
  final double sizeScale;
  final String accentColor;
  final String backgroundIntensity;
  final String borderStyle;
  final bool showBeads;
  final String beadSize;
  final bool showTotal;
  final bool showDivider;
  final int autoCollapseSeconds;
  final String handleColorMode;
  final String handleThickness;
  final String handleHeight;
  final bool hapticFeedbackEnabled;
  final bool tapAnimationEnabled;
  final String floatingSide;
  final String overlayMode;

  bool get autoCollapseEnabled => autoCollapseSeconds > 0;

  Color get resolvedAccentColor {
    return switch (accentColor) {
      accentGold => const Color(0xFFF1C76A),
      accentBlue => const Color(0xFF60A5FA),
      accentPurple => const Color(0xFFA78BFA),
      accentRed => const Color(0xFFF87171),
      accentWhite => const Color(0xFFF8FAFC),
      _ => const Color(0xFF22C55E),
    };
  }

  Map<String, Object?> toJson() {
    return {
      'type': 'settings_update',
      'opacity': opacity,
      'sizeScale': sizeScale,
      'accentColor': accentColor,
      'backgroundIntensity': backgroundIntensity,
      'borderStyle': borderStyle,
      'showBeads': showBeads,
      'beadSize': beadSize,
      'showTotal': showTotal,
      'showDivider': showDivider,
      'autoCollapseSeconds': autoCollapseSeconds,
      'handleColorMode': handleColorMode,
      'handleThickness': handleThickness,
      'handleHeight': handleHeight,
      'hapticFeedbackEnabled': hapticFeedbackEnabled,
      'tapAnimationEnabled': tapAnimationEnabled,
      'floatingSide': floatingSide,
      'overlayMode': overlayMode,
    };
  }

  TasbeehSettings copyWith({
    double? opacity,
    double? sizeScale,
    String? accentColor,
    String? backgroundIntensity,
    String? borderStyle,
    bool? showBeads,
    String? beadSize,
    bool? showTotal,
    bool? showDivider,
    int? autoCollapseSeconds,
    String? handleColorMode,
    String? handleThickness,
    String? handleHeight,
    bool? hapticFeedbackEnabled,
    bool? tapAnimationEnabled,
    String? floatingSide,
    String? overlayMode,
  }) {
    return TasbeehSettings(
      opacity: _normalizeOpacity(opacity ?? this.opacity),
      sizeScale: _normalizeSizeScale(sizeScale ?? this.sizeScale),
      accentColor: _normalizeString(
        accentColor ?? this.accentColor,
        validAccentColors,
        accentGreen,
      ),
      backgroundIntensity: _normalizeString(
        backgroundIntensity ?? this.backgroundIntensity,
        validBackgroundIntensities,
        backgroundDark,
      ),
      borderStyle: _normalizeString(
        borderStyle ?? this.borderStyle,
        validBorderStyles,
        borderSubtle,
      ),
      showBeads: showBeads ?? this.showBeads,
      beadSize: _normalizeString(
        beadSize ?? this.beadSize,
        validBeadSizes,
        beadMedium,
      ),
      showTotal: showTotal ?? this.showTotal,
      showDivider: showDivider ?? this.showDivider,
      autoCollapseSeconds: _normalizeAutoCollapseSeconds(
        autoCollapseSeconds ?? this.autoCollapseSeconds,
      ),
      handleColorMode: _normalizeString(
        handleColorMode ?? this.handleColorMode,
        validHandleColorModes,
        handleWhite,
      ),
      handleThickness: _normalizeString(
        handleThickness ?? this.handleThickness,
        validHandleThicknesses,
        handleMedium,
      ),
      handleHeight: _normalizeString(
        handleHeight ?? this.handleHeight,
        validHandleHeights,
        handleMedium,
      ),
      hapticFeedbackEnabled:
          hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      tapAnimationEnabled: tapAnimationEnabled ?? this.tapAnimationEnabled,
      floatingSide: _normalizeString(
        floatingSide ?? this.floatingSide,
        validFloatingSides,
        sideRight,
      ),
      overlayMode: _normalizeString(
        overlayMode ?? this.overlayMode,
        validOverlayModes,
        overlayModeExpanded,
      ),
    );
  }

  static double _normalizeOpacity(double? opacity) {
    return (opacity ?? 1).clamp(0.4, 1);
  }

  static double _normalizeSizeScale(double? scale) {
    return (scale ?? defaultSizeScale)
        .clamp(minSizeScale, maxSizeScale)
        .toDouble();
  }

  static double? _scaleFromLegacyPreset(Object? preset) {
    return switch (preset) {
      _legacySizeSmall => 0.85,
      _legacySizeMedium => 1.00,
      _legacySizeLarge => 1.25,
      _legacySizeExtraLarge => 1.60,
      _ => null,
    };
  }

  static int _normalizeAutoCollapseSeconds(int? seconds) {
    return switch (seconds) {
      0 || 5 || 10 || 20 || 30 => seconds!,
      null => 10,
      _ => 10,
    };
  }

  static String _normalizeString(
    Object? value,
    List<String> validValues,
    String fallback,
  ) {
    if (value is String && validValues.contains(value)) {
      return value;
    }

    return fallback;
  }
}
