import 'package:flutter/material.dart';

abstract final class AppFonts {
  static const ui = 'IBMPlexSansArabic';
  static const reading = 'Amiri';
  static const display = 'ArefRuqaa';
}

/// Approved brand primitives. Widgets should consume [AppColors] roles.
abstract final class AppPalette {
  static const dustGrey = Color(0xFFDAD7CD);
  static const drySage = Color(0xFFA3B18A);
  static const fern = Color(0xFF588157);
  static const hunterGreen = Color(0xFF3A5A40);
  static const pineTeal = Color(0xFF344E41);
}

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.previewSurface,
    required this.previewSurfaceBack,
    required this.primary,
    required this.secondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.outline,
    required this.outlineStrong,
    required this.selected,
    required this.counterSurface,
    required this.progress,
    required this.navigationInactive,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color previewSurface;
  final Color previewSurfaceBack;
  final Color primary;
  final Color secondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color outline;
  final Color outlineStrong;
  final Color selected;
  final Color counterSurface;
  final Color progress;
  final Color navigationInactive;

  // Compatibility aliases for widgets outside this color-only migration.
  Color get emerald => primary;
  Color get secondaryText => textSecondary;
  Color get parchment => surfaceElevated;
  Color get divider => outline;

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? previewSurface,
    Color? previewSurfaceBack,
    Color? primary,
    Color? secondary,
    Color? textPrimary,
    Color? textSecondary,
    Color? outline,
    Color? outlineStrong,
    Color? selected,
    Color? counterSurface,
    Color? progress,
    Color? navigationInactive,
  }) => AppColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceElevated: surfaceElevated ?? this.surfaceElevated,
    previewSurface: previewSurface ?? this.previewSurface,
    previewSurfaceBack: previewSurfaceBack ?? this.previewSurfaceBack,
    primary: primary ?? this.primary,
    secondary: secondary ?? this.secondary,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    outline: outline ?? this.outline,
    outlineStrong: outlineStrong ?? this.outlineStrong,
    selected: selected ?? this.selected,
    counterSurface: counterSurface ?? this.counterSurface,
    progress: progress ?? this.progress,
    navigationInactive: navigationInactive ?? this.navigationInactive,
  );

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      previewSurface: Color.lerp(previewSurface, other.previewSurface, t)!,
      previewSurfaceBack: Color.lerp(
        previewSurfaceBack,
        other.previewSurfaceBack,
        t,
      )!,
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineStrong: Color.lerp(outlineStrong, other.outlineStrong, t)!,
      selected: Color.lerp(selected, other.selected, t)!,
      counterSurface: Color.lerp(counterSurface, other.counterSurface, t)!,
      progress: Color.lerp(progress, other.progress, t)!,
      navigationInactive: Color.lerp(
        navigationInactive,
        other.navigationInactive,
        t,
      )!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}

abstract final class AppTheme {
  static const _light = AppColors(
    background: Color(0xFFF2F0E9),
    surface: Color(0xFFFAF8F2),
    surfaceElevated: Color(0xFFFAF8F2),
    previewSurface: Color(0xFFE9EAE2),
    previewSurfaceBack: Color(0xFFE1E3DA),
    primary: AppPalette.hunterGreen,
    secondary: AppPalette.fern,
    textPrimary: AppPalette.pineTeal,
    textSecondary: Color(0xFF667068),
    outline: AppPalette.dustGrey,
    outlineStrong: Color(0xFFCDD3C4),
    selected: Color(0xFFDCE3D2),
    counterSurface: Color(0xFFE3E8DA),
    progress: AppPalette.fern,
    navigationInactive: Color(0xFF667068),
  );
  static const _dark = AppColors(
    background: Color(0xFF151A18),
    surface: Color(0xFF1D2420),
    surfaceElevated: Color(0xFF252D28),
    previewSurface: Color(0xFF222925),
    previewSurfaceBack: Color(0xFF1E2521),
    primary: AppPalette.hunterGreen,
    secondary: AppPalette.fern,
    textPrimary: Color(0xFFECE8DF),
    textSecondary: Color(0xFFB8B9B0),
    outline: Color(0xFF354039),
    outlineStrong: Color(0xFF354039),
    selected: Color(0xFF2C382F),
    counterSurface: Color(0xFF29342D),
    progress: AppPalette.fern,
    navigationInactive: Color(0xFF8F9891),
  );

  static ThemeData light() => _build(Brightness.light, _light);
  static ThemeData dark() => _build(Brightness.dark, _dark);

  static ThemeData _build(Brightness brightness, AppColors colors) {
    final base = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: brightness == Brightness.light
          ? AppPalette.dustGrey
          : colors.textPrimary,
      secondary: colors.secondary,
      onSecondary: brightness == Brightness.light
          ? AppPalette.dustGrey
          : colors.textPrimary,
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      outline: colors.outline,
      surfaceContainerHighest: colors.surfaceElevated,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.surface,
      cardColor: colors.surface,
      extensions: [colors],
      fontFamily: AppFonts.ui,
      textTheme: base.apply(
        fontFamily: AppFonts.ui,
        bodyColor: colors.textPrimary,
        displayColor: colors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colors.textPrimary,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.display,
          color: colors.textPrimary,
          fontSize: 25,
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerColor: colors.outline,
      dividerTheme: DividerThemeData(color: colors.outline),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          backgroundColor: colors.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.progress,
        linearTrackColor: colors.outline.withValues(alpha: .4),
        circularTrackColor: colors.outline.withValues(alpha: .4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.surfaceElevated
              : colors.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.secondary
              : colors.outline.withValues(alpha: .55),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.light
            ? AppPalette.pineTeal
            : AppPalette.hunterGreen,
        contentTextStyle: const TextStyle(
          fontFamily: AppFonts.ui,
          color: AppPalette.dustGrey,
        ),
      ),
    );
  }
}
