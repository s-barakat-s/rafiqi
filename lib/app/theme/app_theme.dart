import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.gold,
    required this.emerald,
    required this.secondaryText,
    required this.parchment,
    required this.divider,
  });
  final Color gold;
  final Color emerald;
  final Color secondaryText;
  final Color parchment;
  final Color divider;

  @override
  AppColors copyWith({
    Color? gold,
    Color? emerald,
    Color? secondaryText,
    Color? parchment,
    Color? divider,
  }) => AppColors(
    gold: gold ?? this.gold,
    emerald: emerald ?? this.emerald,
    secondaryText: secondaryText ?? this.secondaryText,
    parchment: parchment ?? this.parchment,
    divider: divider ?? this.divider,
  );

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      gold: Color.lerp(gold, other.gold, t)!,
      emerald: Color.lerp(emerald, other.emerald, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      parchment: Color.lerp(parchment, other.parchment, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}

abstract final class AppTheme {
  static const _light = AppColors(
    gold: Color(0xFFB89252),
    emerald: Color(0xFF173C35),
    secondaryText: Color(0xFF7C7568),
    parchment: Color(0xFFFBF6EB),
    divider: Color(0xFFD9CDB8),
  );
  static const _dark = AppColors(
    gold: Color(0xFFC5A15F),
    emerald: Color(0xFF244C42),
    secondaryText: Color(0xFFB8AFA1),
    parchment: Color(0xFF192832),
    divider: Color(0xFF405057),
  );

  static ThemeData light() => _build(
    Brightness.light,
    const Color(0xFFF5EFE3),
    const Color(0xFFFBF6EB),
    const Color(0xFF173C35),
    _light,
  );
  static ThemeData dark() => _build(
    Brightness.dark,
    const Color(0xFF0D1722),
    const Color(0xFF15222C),
    const Color(0xFFF3EBDD),
    _dark,
  );

  static ThemeData _build(
    Brightness brightness,
    Color background,
    Color surface,
    Color foreground,
    AppColors colors,
  ) {
    final base = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.emerald,
      onPrimary: const Color(0xFFF8F0E1),
      secondary: colors.gold,
      onSecondary: const Color(0xFF241C10),
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
      surface: surface,
      onSurface: foreground,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      extensions: [colors],
      fontFamily: 'IBMPlexSansArabic',
      textTheme: base.apply(
        fontFamily: 'IBMPlexSansArabic',
        bodyColor: foreground,
        displayColor: foreground,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: foreground,
        titleTextStyle: TextStyle(
          fontFamily: 'ArefRuqaa',
          color: foreground,
          fontSize: 25,
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerColor: colors.divider,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          backgroundColor: colors.gold,
          foregroundColor: const Color(0xFF173C35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.emerald,
        contentTextStyle: const TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          color: Color(0xFFF3EBDD),
        ),
      ),
    );
  }
}
