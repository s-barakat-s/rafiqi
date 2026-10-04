import 'package:flutter/material.dart';
import 'package:tasbeh/core/theme/rafiqi_palette.dart';

abstract final class AppFonts {
  static const ui = 'IBMPlexSansArabic';
  static const reading = 'Amiri';
  static const display = 'ArefRuqaa';
  static const thmanyahSans = 'ThmanyahSans';
  static const thmanyahSerifDisplay = 'ThmanyahSerifDisplay';
  static const thmanyahSerifText = 'ThmanyahSerifText';
  static const outfit = 'Outfit';
}

/// Approved brand primitives. Widgets should consume [AppColors] roles.
abstract final class AppPalette {
  static const rafiqiLightBackground = Color(0xFFF4F3E5);
  static const rafiqiLightCardSurface = Color(0xFFFAF9F2);
  static const rafiqiLightPrimary = Color(0xFF225D47);
  static const rafiqiLightSecondary = Color(0xFF377359);
  static const rafiqiLightHeroForeground = Color(0xFF28594E);
  static const rafiqiLightHeroForegroundMuted = Color(0xFF8A987A);
  static const rafiqiLightHeroActionBackground = Color(0xFF315D50);
  static const rafiqiLightHeroActionForeground = Color(0xFFF5F4E8);

  static const rafiqiDarkBackground = Color.fromARGB(255, 6, 26, 27);
  static const rafiqiDarkSurface = Color(0xFF061515);
  static const rafiqiDarkSurfaceElevated = Color.fromARGB(255, 8, 34, 35);
  static const rafiqiDarkCardSurface = Color(0xFF082223);
  static const rafiqiDarkPrimary = Color(0xFFE5F0D2);
  static const rafiqiDarkSecondary = Color(0xFFD4E5C5);
  static const rafiqiDarkTextSecondary = Color(0xFFA9BDAA);
  static const rafiqiDarkBorder = Color(0xFF3D7065);
  static const rafiqiDarkHeroForeground = Color(0xFFEEF2DD);
  static const rafiqiDarkHeroForegroundMuted = Color(0xFFD4DDCE);
  static const rafiqiDarkHeroReminderForeground = Color(0xFFA9C990);
  static const rafiqiDarkHeroActionBackground = Color(0xFF0B231C);
  static const rafiqiDarkHeroActionForeground = Color(0xFFDDE8C5);

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
    required this.onPrimary,
    required this.onPrimaryMuted,
    required this.primaryContainer,
    required this.accent,
    required this.secondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.outline,
    required this.border,
    required this.outlineStrong,
    required this.selected,
    required this.counterSurface,
    required this.progress,
    required this.progressTrack,
    required this.surfaceSoft,
    required this.success,
    required this.navigationInactive,
    this.onPrimaryContainer,
    this.onSecondary,
    this.secondaryContainer,
    this.onSecondaryContainer,
    this.morningHeroAsset = '',
    this.eveningHeroAsset = '',
    this.imageScrim = const Color(0xFF000000),
    this.imageActionBackground = const Color(0xFFF8FAF7),
    this.imageActionForeground = const Color(0xFF17201B),
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color previewSurface;
  final Color previewSurfaceBack;
  final Color primary;
  final Color onPrimary;
  final Color onPrimaryMuted;
  final Color primaryContainer;
  final Color accent;
  final Color secondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color outline;
  final Color border;
  final Color outlineStrong;
  final Color selected;
  final Color counterSurface;
  final Color progress;
  final Color progressTrack;
  final Color surfaceSoft;
  final Color success;
  final Color navigationInactive;
  final Color? onPrimaryContainer;
  final Color? onSecondary;
  final Color? secondaryContainer;
  final Color? onSecondaryContainer;
  final String morningHeroAsset;
  final String eveningHeroAsset;
  final Color imageScrim;
  final Color imageActionBackground;
  final Color imageActionForeground;

  bool get isRafiqi =>
      morningHeroAsset.startsWith('assets/image/home/rafiqi/') ||
      morningHeroAsset == 'assets/image/home/Morning light.png' ||
      morningHeroAsset == 'assets/image/home/morning dark.png';
  bool get isWard => morningHeroAsset.startsWith('assets/image/home/ward/');
  bool get isAmethyst =>
      morningHeroAsset.startsWith('assets/image/home/amethyst/');
  // Reserved for warning messages; never reuse the burgundy action color.
  Color? get warning => (isLinen || isOcean)
      ? (morningHeroAsset.endsWith('_dark.webp')
            ? const Color(0xFFE5BE78)
            : const Color(0xFF805400))
      : null;
  bool get isLinen => morningHeroAsset.startsWith('assets/image/home/linen/');
  bool get isOcean => morningHeroAsset.startsWith('assets/image/home/ocean/');
  bool get usesExplicitControlRoles =>
      isRafiqi || isWard || isAmethyst || isLinen || isOcean;
  Color get imageForeground =>
      usesExplicitControlRoles ? Colors.white : const Color(0xFFF8FAF7);
  Color get imageForegroundMuted => const Color.fromARGB(255, 254, 254, 254);

  double heroScrimOpacity({
    required bool isMorning,
    required Brightness brightness,
  }) {
    if (isOcean) {
      return brightness == Brightness.light
          ? (isMorning ? .66 : .60)
          : (isMorning ? .44 : .36);
    }
    if (isLinen) {
      return brightness == Brightness.light
          ? (isMorning ? .72 : .66)
          : (isMorning ? .46 : .42);
    }
    if (isAmethyst) {
      return brightness == Brightness.light
          ? (isMorning ? .64 : .56)
          : (isMorning ? .44 : .36);
    }
    if (isWard) {
      return brightness == Brightness.light
          ? (isMorning ? .64 : .60)
          : (isMorning ? .46 : .42);
    }
    if (!isRafiqi) return .28;
    return brightness == Brightness.light
        ? (isMorning ? .58 : .52)
        : (isMorning ? .40 : .36);
  }

  String heroAsset({required bool isMorning, required Brightness brightness}) {
    final themedAsset = isMorning ? morningHeroAsset : eveningHeroAsset;
    if (themedAsset.isNotEmpty) return themedAsset;
    return switch ((isMorning, brightness)) {
      (true, Brightness.light) => 'assets/image/home/Morning_light.webp',
      (true, Brightness.dark) => 'assets/image/home/Morning_dark.webp',
      (false, Brightness.light) => 'assets/image/home/evening_light.webp',
      (false, Brightness.dark) => 'assets/image/home/evening_dark.webp',
    };
  }

  String dailyDhikrBackground(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    if (isWard) {
      return isDark
          ? 'assets/image/zekr/ward_zekr_dark.png'
          : 'assets/image/zekr/ward_zekr_light.png';
    }
    if (isAmethyst) {
      return isDark
          ? 'assets/image/zekr/amethyst_zekr_dark.png'
          : 'assets/image/zekr/amethyst_zekr_light.png';
    }
    if (isLinen) {
      return isDark
          ? 'assets/image/zekr/linen_zekr_dark.png'
          : 'assets/image/zekr/linen_zekr_light.png';
    }
    if (isOcean) {
      return isDark
          ? 'assets/image/zekr/ocean_zekr_dark.png'
          : 'assets/image/zekr/ocean_zekr_light.png';
    }
    return isDark
        ? 'assets/image/zekr/rafiqi_zekr_dark.png'
        : 'assets/image/zekr/rafiqi_zekr_light.png';
  }

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
    Color? onPrimary,
    Color? onPrimaryMuted,
    Color? primaryContainer,
    Color? accent,
    Color? secondary,
    Color? textPrimary,
    Color? textSecondary,
    Color? outline,
    Color? border,
    Color? outlineStrong,
    Color? selected,
    Color? counterSurface,
    Color? progress,
    Color? progressTrack,
    Color? surfaceSoft,
    Color? success,
    Color? navigationInactive,
    Color? onPrimaryContainer,
    Color? onSecondary,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    String? morningHeroAsset,
    String? eveningHeroAsset,
    Color? imageScrim,
    Color? imageActionBackground,
    Color? imageActionForeground,
  }) => AppColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceElevated: surfaceElevated ?? this.surfaceElevated,
    previewSurface: previewSurface ?? this.previewSurface,
    previewSurfaceBack: previewSurfaceBack ?? this.previewSurfaceBack,
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    onPrimaryMuted: onPrimaryMuted ?? this.onPrimaryMuted,
    primaryContainer: primaryContainer ?? this.primaryContainer,
    accent: accent ?? this.accent,
    secondary: secondary ?? this.secondary,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    outline: outline ?? this.outline,
    border: border ?? this.border,
    outlineStrong: outlineStrong ?? this.outlineStrong,
    selected: selected ?? this.selected,
    counterSurface: counterSurface ?? this.counterSurface,
    progress: progress ?? this.progress,
    progressTrack: progressTrack ?? this.progressTrack,
    surfaceSoft: surfaceSoft ?? this.surfaceSoft,
    success: success ?? this.success,
    navigationInactive: navigationInactive ?? this.navigationInactive,
    onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
    onSecondary: onSecondary ?? this.onSecondary,
    secondaryContainer: secondaryContainer ?? this.secondaryContainer,
    onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
    morningHeroAsset: morningHeroAsset ?? this.morningHeroAsset,
    eveningHeroAsset: eveningHeroAsset ?? this.eveningHeroAsset,
    imageScrim: imageScrim ?? this.imageScrim,
    imageActionBackground: imageActionBackground ?? this.imageActionBackground,
    imageActionForeground: imageActionForeground ?? this.imageActionForeground,
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
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      onPrimaryMuted: Color.lerp(onPrimaryMuted, other.onPrimaryMuted, t)!,
      primaryContainer: Color.lerp(
        primaryContainer,
        other.primaryContainer,
        t,
      )!,
      accent: Color.lerp(accent, other.accent, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      border: Color.lerp(border, other.border, t)!,
      outlineStrong: Color.lerp(outlineStrong, other.outlineStrong, t)!,
      selected: Color.lerp(selected, other.selected, t)!,
      counterSurface: Color.lerp(counterSurface, other.counterSurface, t)!,
      progress: Color.lerp(progress, other.progress, t)!,
      progressTrack: Color.lerp(progressTrack, other.progressTrack, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      navigationInactive: Color.lerp(
        navigationInactive,
        other.navigationInactive,
        t,
      )!,
      onPrimaryContainer: Color.lerp(
        onPrimaryContainer,
        other.onPrimaryContainer,
        t,
      ),
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t),
      secondaryContainer: Color.lerp(
        secondaryContainer,
        other.secondaryContainer,
        t,
      ),
      onSecondaryContainer: Color.lerp(
        onSecondaryContainer,
        other.onSecondaryContainer,
        t,
      ),
      // Select the destination artwork at the start of the theme animation.
      // AppThemeArtwork cross-fades it while the color roles interpolate.
      morningHeroAsset: t <= 0 ? morningHeroAsset : other.morningHeroAsset,
      eveningHeroAsset: t <= 0 ? eveningHeroAsset : other.eveningHeroAsset,
      imageScrim: Color.lerp(imageScrim, other.imageScrim, t)!,
      imageActionBackground: Color.lerp(
        imageActionBackground,
        other.imageActionBackground,
        t,
      )!,
      imageActionForeground: Color.lerp(
        imageActionForeground,
        other.imageActionForeground,
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
    background: AppPalette.rafiqiLightBackground,
    surface: Color(0xFFFFFEFA),
    surfaceElevated: Color(0xFFFFFFFF),
    previewSurface: Color(0xFFE8EDE2),
    previewSurfaceBack: Color(0xFFE2E8DD),
    primary: AppPalette.rafiqiLightPrimary,
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryMuted: Color(0xFFDDE4DB),
    primaryContainer: Color(0xFFE8EDE2),
    accent: AppPalette.drySage,
    secondary: AppPalette.rafiqiLightSecondary,
    textPrimary: Color(0xFF202D26),
    textSecondary: Color(0xFF5D695F),
    outline: Color(0xFFDDE2D7),
    border: Color(0xFFDDE2D7),
    outlineStrong: Color(0xFF788575),
    selected: Color(0xFFE8EDE2),
    counterSurface: Color(0xFFE8EDE2),
    progress: AppPalette.fern,
    progressTrack: Color(0xFFD9DED3),
    surfaceSoft: Color(0xFFE8EDE2),
    success: Color(0xFF4F7953),
    navigationInactive: Color(0xFF5D695F),
    onPrimaryContainer: AppPalette.rafiqiLightPrimary,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE2E8DD),
    onSecondaryContainer: Color(0xFF344E41),
    morningHeroAsset: 'assets/image/home/Morning light.png',
    eveningHeroAsset: 'assets/image/home/evening light.png',
    imageScrim: Color(0xFF17251B),
    imageActionBackground: Color(0xFFFFFEFA),
    imageActionForeground: AppPalette.rafiqiLightPrimary,
  );
  static const _dark = AppColors(
    background: AppPalette.rafiqiDarkBackground,
    surface: AppPalette.rafiqiDarkSurface,
    surfaceElevated: AppPalette.rafiqiDarkSurfaceElevated,
    previewSurface: AppPalette.rafiqiDarkSurfaceElevated,
    previewSurfaceBack: Color(0xFF0A302C),
    primary: AppPalette.rafiqiDarkPrimary,
    onPrimary: AppPalette.rafiqiDarkBackground,
    onPrimaryMuted: Color(0xFF5C7468),
    primaryContainer: Color(0xFF123C37),
    accent: Color(0xFFC4D8B4),
    secondary: AppPalette.rafiqiDarkSecondary,
    textPrimary: AppPalette.rafiqiDarkPrimary,
    textSecondary: AppPalette.rafiqiDarkTextSecondary,
    outline: AppPalette.rafiqiDarkBorder,
    border: AppPalette.rafiqiDarkBorder,
    outlineStrong: Color(0xFF477E70),
    selected: Color(0xFF123C37),
    counterSurface: AppPalette.rafiqiDarkSurfaceElevated,
    progress: AppPalette.rafiqiDarkSecondary,
    progressTrack: Color(0xFF1A3C36),
    surfaceSoft: Color(0xFF0A302C),
    success: Color(0xFFC1D7AF),
    navigationInactive: Color(0xFF9DAFA1),
    onPrimaryContainer: AppPalette.rafiqiDarkPrimary,
    onSecondary: AppPalette.rafiqiDarkBackground,
    secondaryContainer: Color(0xFF123C37),
    onSecondaryContainer: AppPalette.rafiqiDarkPrimary,
    morningHeroAsset: 'assets/image/home/morning dark.png',
    eveningHeroAsset: 'assets/image/home/evening dark.png',
    imageScrim: Color(0xFF17251B),
    imageActionBackground: Color(0xFFB5CAA2),
    imageActionForeground: Color(0xFF17251B),
  );

  static const _oceanLight = AppColors(
    background: Color(0xFFF2FAFC),
    surface: Color(0xFFFCFEFF),
    surfaceSoft: Color(0xFFE0F3F8),
    primary: Color(0xFF00689D),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFCAF0F8),
    onPrimaryContainer: Color(0xFF03415D),
    secondary: Color(0xFF006B7D),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD4F2F5),
    onSecondaryContainer: Color(0xFF06464F),
    textPrimary: Color(0xFF142D40),
    textSecondary: Color(0xFF536B7B),
    outline: Color(0xFFD4E5EC),
    outlineStrong: Color(0xFF718B9B),
    surfaceElevated: Color(0xFFFFFFFF),
    previewSurface: Color(0xFFE0F3F8),
    previewSurfaceBack: Color(0xFFD4F2F5),
    onPrimaryMuted: Color(0xFFCAF0F8),
    accent: Color(0xFF0077B6),
    border: Color(0xFFD4E5EC),
    selected: Color(0xFFCAF0F8),
    counterSurface: Color(0xFFE0F3F8),
    progress: Color(0xFF00689D),
    progressTrack: Color(0xFFD4E5EC),
    success: Color(0xFF326747),
    navigationInactive: Color(0xFF536B7B),
    imageScrim: Color(0xFF102C40),
    imageActionBackground: Color(0xFFFCFEFF),
    imageActionForeground: Color(0xFF00689D),
    morningHeroAsset: 'assets/image/home/ocean/morning_light.webp',
    eveningHeroAsset: 'assets/image/home/ocean/evening_light.webp',
  );

  static const _oceanDark = AppColors(
    background: Color(0xFF101923),
    surface: Color(0xFF182634),
    surfaceSoft: Color(0xFF233747),
    primary: Color(0xFF90E0EF),
    onPrimary: Color(0xFF073642),
    primaryContainer: Color(0xFF194758),
    onPrimaryContainer: Color(0xFFCAF0F8),
    secondary: Color(0xFF9FCFEF),
    onSecondary: Color(0xFF123247),
    secondaryContainer: Color(0xFF29465E),
    onSecondaryContainer: Color(0xFFD8EDFC),
    textPrimary: Color(0xFFEFF7FB),
    textSecondary: Color(0xFFB1C5D2),
    outline: Color(0xFF344C5E),
    outlineStrong: Color(0xFF819EAF),
    surfaceElevated: Color(0xFF233747),
    previewSurface: Color(0xFF233747),
    previewSurfaceBack: Color(0xFF29465E),
    onPrimaryMuted: Color(0xFF194758),
    accent: Color(0xFF9FCFEF),
    border: Color(0xFF344C5E),
    selected: Color(0xFF194758),
    counterSurface: Color(0xFF233747),
    progress: Color(0xFF90E0EF),
    progressTrack: Color(0xFF344C5E),
    success: Color(0xFF9AC9AC),
    navigationInactive: Color(0xFFB1C5D2),
    imageScrim: Color(0xFF102C40),
    imageActionBackground: Color(0xFF90E0EF),
    imageActionForeground: Color(0xFF073642),
    morningHeroAsset: 'assets/image/home/ocean/morning_dark.webp',
    eveningHeroAsset: 'assets/image/home/ocean/evening_dark.webp',
  );

  static const _linenLight = AppColors(
    background: Color(0xFFF5F1EB),
    surface: Color(0xFFFFFCF8),
    surfaceSoft: Color(0xFFEDE5DC),
    primary: Color(0xFF715747),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE3D5CA),
    onPrimaryContainer: Color(0xFF403127),
    secondary: Color(0xFF62635A),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFEDEDE9),
    onSecondaryContainer: Color(0xFF35382F),
    textPrimary: Color(0xFF302A25),
    textSecondary: Color(0xFF6D6259),
    outline: Color(0xFFDFD5CA),
    outlineStrong: Color(0xFF928173),
    surfaceElevated: Color(0xFFFFFFFF),
    previewSurface: Color(0xFFEDE5DC),
    previewSurfaceBack: Color(0xFFEDEDE9),
    onPrimaryMuted: Color(0xFFE3D5CA),
    accent: Color(0xFF928173),
    border: Color(0xFFDFD5CA),
    selected: Color(0xFFE3D5CA),
    counterSurface: Color(0xFFEDE5DC),
    progress: Color(0xFF715747),
    progressTrack: Color(0xFFDFD5CA),
    success: Color(0xFF326747),
    navigationInactive: Color(0xFF6D6259),
    imageScrim: Color(0xFF302A25),
    imageActionBackground: Color(0xFFFFFCF8),
    imageActionForeground: Color(0xFF715747),
    morningHeroAsset: 'assets/image/home/linen/morning_light.webp',
    eveningHeroAsset: 'assets/image/home/linen/evening_light.webp',
  );

  static const _linenDark = AppColors(
    background: Color(0xFF191715),
    surface: Color(0xFF25211E),
    surfaceSoft: Color(0xFF332D28),
    primary: Color(0xFFD5BDAF),
    onPrimary: Color(0xFF30231B),
    primaryContainer: Color(0xFF4A3A30),
    onPrimaryContainer: Color(0xFFF5EBE0),
    secondary: Color(0xFFC9CAC0),
    onSecondary: Color(0xFF292B24),
    secondaryContainer: Color(0xFF383A32),
    onSecondaryContainer: Color(0xFFEDEDE9),
    textPrimary: Color(0xFFF5EFE8),
    textSecondary: Color(0xFFC3B6AA),
    outline: Color(0xFF4A4037),
    outlineStrong: Color(0xFFA49383),
    surfaceElevated: Color(0xFF332D28),
    previewSurface: Color(0xFF332D28),
    previewSurfaceBack: Color(0xFF383A32),
    onPrimaryMuted: Color(0xFF4A3A30),
    accent: Color(0xFFD5BDAF),
    border: Color(0xFF4A4037),
    selected: Color(0xFF4A3A30),
    counterSurface: Color(0xFF332D28),
    progress: Color(0xFFD5BDAF),
    progressTrack: Color(0xFF4A4037),
    success: Color(0xFF9AC9AC),
    navigationInactive: Color(0xFFC3B6AA),
    imageScrim: Color(0xFF302A25),
    imageActionBackground: Color(0xFFD5BDAF),
    imageActionForeground: Color(0xFF30231B),
    morningHeroAsset: 'assets/image/home/linen/morning_dark.webp',
    eveningHeroAsset: 'assets/image/home/linen/evening_dark.webp',
  );

  static const _amethystLight = AppColors(
    background: Color(0xFFF8F5FC),
    surface: Color(0xFFFFFCFF),
    surfaceSoft: Color(0xFFEEE7F5),
    primary: Color(0xFF5E548E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE8DFF2),
    onPrimaryContainer: Color(0xFF231942),
    secondary: Color(0xFF79577F),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF3E3EF),
    onSecondaryContainer: Color(0xFF503454),
    textPrimary: Color(0xFF291F3A),
    textSecondary: Color(0xFF6D617A),
    outline: Color(0xFFE1D8E9),
    outlineStrong: Color(0xFF8E7D9F),
    surfaceElevated: Color(0xFFFFFFFF),
    previewSurface: Color(0xFFEEE7F5),
    previewSurfaceBack: Color(0xFFF3E3EF),
    onPrimaryMuted: Color(0xFFE8DFF2),
    accent: Color(0xFF9F86C0),
    border: Color(0xFFE1D8E9),
    selected: Color(0xFFE8DFF2),
    counterSurface: Color(0xFFEEE7F5),
    progress: Color(0xFF5E548E),
    progressTrack: Color(0xFFE1D8E9),
    success: Color(0xFF326747),
    navigationInactive: Color(0xFF6D617A),
    imageScrim: Color(0xFF231942),
    imageActionBackground: Color(0xFFFFFCFF),
    imageActionForeground: Color(0xFF5E548E),
    morningHeroAsset: 'assets/image/home/amethyst/morning_light.webp',
    eveningHeroAsset: 'assets/image/home/amethyst/evening_light.webp',
  );

  static const _amethystDark = AppColors(
    background: Color(0xFF171222),
    surface: Color(0xFF231B33),
    surfaceSoft: Color(0xFF302540),
    primary: Color(0xFFCEB9E8),
    onPrimary: Color(0xFF231942),
    primaryContainer: Color(0xFF44345E),
    onPrimaryContainer: Color(0xFFF0E5FF),
    secondary: Color(0xFFE0B1CB),
    onSecondary: Color(0xFF3C2437),
    secondaryContainer: Color(0xFF51394C),
    onSecondaryContainer: Color(0xFFFFE3F2),
    textPrimary: Color(0xFFF4EEF9),
    textSecondary: Color(0xFFC4B6D0),
    outline: Color(0xFF493B59),
    outlineStrong: Color(0xFF9E8BAF),
    surfaceElevated: Color(0xFF302540),
    previewSurface: Color(0xFF302540),
    previewSurfaceBack: Color(0xFF51394C),
    onPrimaryMuted: Color(0xFF44345E),
    accent: Color(0xFFE0B1CB),
    border: Color(0xFF493B59),
    selected: Color(0xFF44345E),
    counterSurface: Color(0xFF302540),
    progress: Color(0xFFCEB9E8),
    progressTrack: Color(0xFF493B59),
    success: Color(0xFF9AC9AC),
    navigationInactive: Color(0xFFC4B6D0),
    imageScrim: Color(0xFF231942),
    imageActionBackground: Color(0xFFCEB9E8),
    imageActionForeground: Color(0xFF231942),
    morningHeroAsset: 'assets/image/home/amethyst/morning_dark.webp',
    eveningHeroAsset: 'assets/image/home/amethyst/evening_dark.webp',
  );

  static const _wardLight = AppColors(
    background: Color(0xFFFFF7F9),
    surface: Color(0xFFFFFCFD),
    surfaceSoft: Color(0xFFFFE5EC),
    primary: Color(0xFF9C3658),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFC2D1),
    onPrimaryContainer: Color(0xFF65243D),
    secondary: Color(0xFF705467),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF1E5EE),
    onSecondaryContainer: Color(0xFF493342),
    textPrimary: Color(0xFF34232D),
    textSecondary: Color(0xFF745E6A),
    outline: Color(0xFFEEDCE3),
    outlineStrong: Color(0xFF957582),
    surfaceElevated: Color(0xFFFFFFFF),
    previewSurface: Color(0xFFFFE5EC),
    previewSurfaceBack: Color(0xFFF1E5EE),
    onPrimaryMuted: Color(0xFFFFE5EC),
    accent: Color(0xFFFB6F92),
    border: Color(0xFFEEDCE3),
    selected: Color(0xFFFFC2D1),
    counterSurface: Color(0xFFFFE5EC),
    progress: Color(0xFF9C3658),
    progressTrack: Color(0xFFEEDCE3),
    success: Color(0xFF326747),
    navigationInactive: Color(0xFF745E6A),
    imageScrim: Color(0xFF281522),
    imageActionBackground: Color(0xFFFFF7F9),
    imageActionForeground: Color(0xFF9C3658),
    morningHeroAsset: 'assets/image/home/ward/morning_light.webp',
    eveningHeroAsset: 'assets/image/home/ward/evening_light.webp',
  );

  static const _wardDark = AppColors(
    background: Color(0xFF191218),
    surface: Color(0xFF241B23),
    surfaceSoft: Color(0xFF322531),
    primary: Color(0xFFFFB3C6),
    onPrimary: Color(0xFF432132),
    primaryContainer: Color(0xFF4B2D3D),
    onPrimaryContainer: Color(0xFFFFE5EC),
    secondary: Color(0xFFD4B9CC),
    onSecondary: Color(0xFF352332),
    secondaryContainer: Color(0xFF40303F),
    onSecondaryContainer: Color(0xFFF1DFEE),
    textPrimary: Color(0xFFF9EFF4),
    textSecondary: Color(0xFFC8B4C0),
    outline: Color(0xFF4B3947),
    outlineStrong: Color(0xFFA58B9C),
    surfaceElevated: Color(0xFF322531),
    previewSurface: Color(0xFF322531),
    previewSurfaceBack: Color(0xFF40303F),
    onPrimaryMuted: Color(0xFF593A4B),
    accent: Color(0xFFFF8FAB),
    border: Color(0xFF4B3947),
    selected: Color(0xFF4B2D3D),
    counterSurface: Color(0xFF322531),
    progress: Color(0xFFFFB3C6),
    progressTrack: Color(0xFF4B3947),
    success: Color(0xFF9AC9AC),
    navigationInactive: Color(0xFFC8B4C0),
    imageScrim: Color(0xFF281522),
    imageActionBackground: Color(0xFFFFB3C6),
    imageActionForeground: Color(0xFF432132),
    morningHeroAsset: 'assets/image/home/ward/morning_dark.webp',
    eveningHeroAsset: 'assets/image/home/ward/evening_dark.webp',
  );

  static AppColors _derivedColors(
    RafiqiPalette palette,
    Brightness brightness,
  ) {
    final swatches = palette.canonicalSwatches;
    final (
      lightPrimary,
      darkPrimary,
      accent,
      lightest,
      darkest,
    ) = switch (palette) {
      RafiqiPalette.blush => (
        Color.lerp(swatches[4], Colors.black, .38)!,
        swatches[2],
        swatches[3],
        swatches[0],
        Color.lerp(swatches[4], Colors.black, .78)!,
      ),
      RafiqiPalette.amethyst => (
        swatches[1],
        swatches[3],
        swatches[2],
        swatches[4],
        swatches[0],
      ),
      RafiqiPalette.linen => (
        Color.lerp(swatches[4], Colors.black, .58)!,
        swatches[4],
        swatches[3],
        swatches[2],
        Color.lerp(swatches[4], Colors.black, .82)!,
      ),
      RafiqiPalette.ocean => (
        swatches[1],
        swatches[3],
        swatches[2],
        swatches[4],
        swatches[0],
      ),
      RafiqiPalette.rafiqi => throw StateError(
        'The Rafiqi palette uses its original fixed mapping.',
      ),
    };

    if (brightness == Brightness.light) {
      final background = Color.lerp(lightest, Colors.white, .78)!;
      final surface = Color.lerp(lightest, Colors.white, .94)!;
      final surfaceSoft = Color.lerp(lightest, Colors.white, .58)!;
      final border = Color.lerp(lightPrimary, Colors.white, .84)!;
      final primaryContainer = Color.lerp(lightPrimary, Colors.white, .86)!;
      final textPrimary = Color.lerp(darkest, Colors.black, .68)!;
      final textSecondary = Color.lerp(darkest, Colors.black, .42)!;
      final onPrimary =
          ThemeData.estimateBrightnessForColor(lightPrimary) == Brightness.dark
          ? Colors.white
          : Colors.black;
      return AppColors(
        background: background,
        surface: surface,
        surfaceElevated: Color.lerp(lightest, Colors.white, .98)!,
        previewSurface: surfaceSoft,
        previewSurfaceBack: primaryContainer,
        primary: lightPrimary,
        onPrimary: onPrimary,
        onPrimaryMuted: Color.lerp(onPrimary, lightPrimary, .25)!,
        primaryContainer: primaryContainer,
        accent: accent,
        secondary: lightPrimary,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        outline: border,
        border: border,
        outlineStrong: Color.lerp(lightPrimary, Colors.white, .72)!,
        selected: primaryContainer,
        counterSurface: surfaceSoft,
        progress: accent,
        progressTrack: border,
        surfaceSoft: surfaceSoft,
        success: lightPrimary,
        navigationInactive: textSecondary,
      );
    }

    final background = Color.lerp(darkest, Colors.black, .18)!;
    final surface = Color.lerp(background, Colors.white, .055)!;
    final surfaceElevated = Color.lerp(background, Colors.white, .105)!;
    final surfaceSoft = Color.lerp(background, Colors.white, .075)!;
    final border = Color.lerp(lightest, background, .8)!;
    final primaryContainer = Color.lerp(darkPrimary, background, .72)!;
    final textPrimary = Color.lerp(lightest, Colors.white, .7)!;
    final textSecondary = Color.lerp(lightest, Colors.white, .28)!;
    final onPrimary =
        ThemeData.estimateBrightnessForColor(darkPrimary) == Brightness.dark
        ? Colors.white
        : background;
    return AppColors(
      background: background,
      surface: surface,
      surfaceElevated: surfaceElevated,
      previewSurface: surfaceSoft,
      previewSurfaceBack: primaryContainer,
      primary: darkPrimary,
      onPrimary: onPrimary,
      onPrimaryMuted: Color.lerp(onPrimary, darkPrimary, .25)!,
      primaryContainer: primaryContainer,
      accent: accent,
      secondary: darkPrimary,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      outline: border,
      border: border,
      outlineStrong: Color.lerp(lightest, background, .68)!,
      selected: primaryContainer,
      counterSurface: surfaceSoft,
      progress: accent,
      progressTrack: border,
      surfaceSoft: surfaceSoft,
      success: darkPrimary,
      navigationInactive: textSecondary,
    );
  }

  static ThemeData light() => _build(Brightness.light, _light);
  static ThemeData dark() => _build(Brightness.dark, _dark);

  static ThemeData build({
    required RafiqiPalette palette,
    required Brightness brightness,
  }) {
    return _build(brightness, colorsFor(palette, brightness));
  }

  static AppColors colorsFor(RafiqiPalette palette, Brightness brightness) {
    if (palette == RafiqiPalette.rafiqi) {
      return brightness == Brightness.light ? _light : _dark;
    }
    if (palette == RafiqiPalette.blush) {
      return brightness == Brightness.light ? _wardLight : _wardDark;
    }
    if (palette == RafiqiPalette.amethyst) {
      return brightness == Brightness.light ? _amethystLight : _amethystDark;
    }
    if (palette == RafiqiPalette.linen) {
      return brightness == Brightness.light ? _linenLight : _linenDark;
    }
    if (palette == RafiqiPalette.ocean) {
      return brightness == Brightness.light ? _oceanLight : _oceanDark;
    }
    return _derivedColors(palette, brightness);
  }

  static ThemeData _build(Brightness brightness, AppColors colors) {
    final base = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;
    final controlForeground = brightness == Brightness.light
        ? colors.onPrimary
        : ThemeData.estimateBrightnessForColor(colors.primary) ==
              Brightness.light
        ? colors.background
        : colors.textPrimary;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.usesExplicitControlRoles
          ? colors.onPrimary
          : controlForeground,
      primaryContainer: colors.primaryContainer,
      onPrimaryContainer: colors.onPrimaryContainer ?? colors.textPrimary,
      secondary: colors.secondary,
      onSecondary: colors.onSecondary ?? controlForeground,
      secondaryContainer: colors.secondaryContainer ?? colors.surfaceSoft,
      onSecondaryContainer: colors.onSecondaryContainer ?? colors.textPrimary,
      error: colors.usesExplicitControlRoles && brightness == Brightness.dark
          ? const Color(0xFFFFB4AB)
          : const Color(0xFFBA1A1A),
      onError: colors.usesExplicitControlRoles && brightness == Brightness.dark
          ? const Color(0xFF690005)
          : Colors.white,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      onSurfaceVariant: colors.textSecondary,
      outline: colors.usesExplicitControlRoles
          ? colors.outlineStrong
          : colors.outline,
      outlineVariant: colors.border,
      surfaceContainerLow: colors.surfaceSoft,
      surfaceContainer: colors.usesExplicitControlRoles
          ? colors.surfaceSoft
          : colors.surface,
      surfaceContainerHigh: colors.surfaceElevated,
      surfaceContainerHighest: colors.surfaceElevated,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.surface,
      cardColor: colors.surface,
      iconTheme: IconThemeData(
        color: colors.usesExplicitControlRoles
            ? colors.primary
            : colors.textPrimary,
      ),
      inputDecorationTheme: colors.usesExplicitControlRoles
          ? InputDecorationTheme(
              filled: true,
              fillColor: colors.surface,
              hintStyle: TextStyle(color: colors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colors.outlineStrong),
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: colors.primary, width: 2),
                borderRadius: BorderRadius.circular(14),
              ),
            )
          : null,
      bottomSheetTheme: colors.usesExplicitControlRoles
          ? BottomSheetThemeData(
              backgroundColor: colors.surface,
              surfaceTintColor: Colors.transparent,
            )
          : null,
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
        linearTrackColor: colors.progressTrack,
        circularTrackColor: colors.progressTrack,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? (colors.usesExplicitControlRoles
                    ? colors.onSecondary!
                    : colors.surfaceElevated)
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
            ? colors.textPrimary
            : colors.primary,
        contentTextStyle: TextStyle(
          fontFamily: AppFonts.ui,
          color: colors.onPrimary,
        ),
      ),
    );
  }
}

ThemeData buildRafiqiTheme({
  required RafiqiPalette palette,
  required Brightness brightness,
}) => AppTheme.build(palette: palette, brightness: brightness);

AppColors rafiqiPaletteColors({
  required RafiqiPalette palette,
  required Brightness brightness,
}) => AppTheme.colorsFor(palette, brightness);
