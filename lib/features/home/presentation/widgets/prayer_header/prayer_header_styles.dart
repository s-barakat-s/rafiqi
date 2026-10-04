import 'package:flutter/material.dart';
import 'package:tasbeh/core/theme/app_theme.dart';

abstract final class PrayerHeaderStyles {
  static const _otherLightPrimary = Color(0xFF1F4A33);
  static const _otherLightSurface = Color(0xFFFBFAF3);
  static const _otherActionPrimary = Color(0xFF184E36);
  static const _otherActiveDot = Color(0xFF91A884);
  static const _referenceHeaderSurface = Color(0xFFFCFCF8);
  static const _referenceActivePrayer = Color(0xFFE9EAD5);
  static const _referenceSeparator = Color(0xFFE9E9E1);
  static const referenceActiveSurface = Color(0xFFE9E9D5);

  static const stripRadius = 24.0;
  static const activeItemRadius = 14.0;
  static const actionRadius = 999.0;

  // OpenType features
  static const thmanyahGeneralFeatures = <FontFeature>[FontFeature('ss01', 1)];

  static const thmanyahDecorativeFeatures = <FontFeature>[
    FontFeature('ss01', 1),
    FontFeature('salt', 1),
    FontFeature('swsh', 1),
  ];

  static const outfitNumberFeatures = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  static bool _isLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light;

  static bool _isRafiqiLight(BuildContext context) =>
      _isLight(context) && context.appColors.isRafiqi;

  static bool isRafiqiDark(BuildContext context) =>
      !_isLight(context) && context.appColors.isRafiqi;

  static Color primary(BuildContext context) => _isRafiqiLight(context)
      ? context.appColors.primary
      : _isLight(context)
      ? _otherLightPrimary
      : context.appColors.primary;

  static Color surface(BuildContext context) => _isRafiqiLight(context)
      ? context.appColors.background
      : _isLight(context)
      ? _otherLightSurface
      : context.appColors.surfaceElevated;

  static Color actionPrimary(BuildContext context) => context.appColors.isRafiqi
      ? context.appColors.primary
      : _otherActionPrimary;

  static Color activeDot(BuildContext context) => context.appColors.isRafiqi
      ? context.appColors.secondary
      : _otherActiveDot;

  static Color activeSurface(BuildContext context) => _isLight(context)
      ? referenceActiveSurface
      : context.appColors.primaryContainer;

  static Color actionSurface(BuildContext context) => isRafiqiDark(context)
      ? context.appColors.surface.withValues(alpha: .76)
      : _referenceHeaderSurface;

  static Color actionBorder(BuildContext context) => isRafiqiDark(context)
      ? context.appColors.border.withValues(alpha: .82)
      : Colors.transparent;

  static Color actionIconSurface(BuildContext context) => isRafiqiDark(context)
      ? context.appColors.primaryContainer
      : _referenceActivePrayer;

  static Color filledActionIconSurface(BuildContext context) =>
      isRafiqiDark(context)
      ? context.appColors.primaryContainer
      : actionPrimary(context);

  static Color actionIconForeground(BuildContext context) =>
      isRafiqiDark(context) ? context.appColors.primary : Colors.white;

  static Color stripSurface(BuildContext context) => _isRafiqiLight(context)
      ? AppPalette.rafiqiLightCardSurface
      : isRafiqiDark(context)
      ? AppPalette.rafiqiDarkCardSurface
      : _referenceHeaderSurface;

  static Color stripBorder(BuildContext context) => isRafiqiDark(context)
      ? context.appColors.border.withValues(alpha: .72)
      : Colors.transparent;

  static Color separator(BuildContext context) => isRafiqiDark(context)
      ? context.appColors.border.withValues(alpha: .46)
      : _referenceSeparator;

  static Color activePrayerSurface(BuildContext context) =>
      isRafiqiDark(context)
      ? context.appColors.primaryContainer.withValues(alpha: .86)
      : _referenceActivePrayer;

  // Base Thmanyah General Arabic style
  static TextStyle thmanyahGeneral({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) => TextStyle(
    fontFamily: AppFonts.thmanyahSans,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    fontFeatures: thmanyahGeneralFeatures,
  );

  // Base Thmanyah Decorative Arabic style
  static TextStyle thmanyahDecorative({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) => TextStyle(
    fontFamily: AppFonts.thmanyahSans,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    fontFeatures: thmanyahDecorativeFeatures,
  );

  // Base Outfit Numeric style
  static TextStyle outfitNumber({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: AppFonts.outfit,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    fontFeatures: outfitNumberFeatures,
  );

  // Hijri Arabic text/month (General Thmanyah)
  static TextStyle hijriDate(BuildContext context) => TextStyle(
    fontFamily: AppFonts.thmanyahSans,
    fontSize: 13.5,
    height: 1.25,
    fontWeight: FontWeight.w500,
    color: primary(context),
    fontFeatures: thmanyahGeneralFeatures,
  );

  // Numeric portions of Hijri date (Outfit)
  static TextStyle hijriNumber(BuildContext context) => TextStyle(
    fontFamily: AppFonts.outfit,
    fontSize: 13.5,
    height: 1.25,
    fontWeight: FontWeight.w500,
    color: primary(context),
    fontFeatures: outfitNumberFeatures,
  );

  // "الآن" label (General Thmanyah)
  static TextStyle nowLabel(BuildContext context) => TextStyle(
    fontFamily: AppFonts.thmanyahSans,
    fontSize: 13.5,
    height: 1.05,
    fontWeight: FontWeight.w400,
    color: context.appColors.isRafiqi
        ? context.appColors.primary
        : context.appColors.textSecondary,
    fontFeatures: thmanyahGeneralFeatures,
  );

  // Current prayer name (Decorative Thmanyah)
  static TextStyle prayerName(BuildContext context) => TextStyle(
    fontFamily: AppFonts.thmanyahSans,
    fontSize: 21,
    height: 1.05,
    fontWeight: FontWeight.w700,
    color: primary(context),
    fontFeatures: thmanyahDecorativeFeatures,
  );

  // Large current prayer time (Outfit)
  static TextStyle currentTime(BuildContext context) => TextStyle(
    fontFamily: AppFonts.outfit,
    fontSize: 59,
    height: .88,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    color: primary(context),
    fontFeatures: outfitNumberFeatures,
  );

  // Period: AM/PM or ص/م (General Thmanyah)
  static TextStyle period(BuildContext context) => TextStyle(
    fontFamily: AppFonts.thmanyahSans,
    fontSize: 15,
    height: 1,
    fontWeight: FontWeight.w700,
    color: primary(context),
    fontFeatures: thmanyahGeneralFeatures,
  );

  // Action button Arabic labels (General Thmanyah)
  static TextStyle action(BuildContext context) => TextStyle(
    fontFamily: AppFonts.thmanyahSans,
    fontSize: 10.5,
    height: 1.15,
    fontWeight: FontWeight.w500,
    color: context.appColors.textPrimary,
    fontFeatures: thmanyahGeneralFeatures,
  );

  // The 5 prayer names in strip (Decorative Thmanyah)
  static TextStyle prayerLabel(BuildContext context, {required bool active}) =>
      TextStyle(
        fontFamily: AppFonts.thmanyahSans,
        fontSize: 12.5,
        height: 1.15,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        color: active
            ? primary(context)
            : _isRafiqiLight(context)
            ? context.appColors.secondary
            : context.appColors.textPrimary,
        fontFeatures: thmanyahDecorativeFeatures,
      );

  // The 5 prayer times in strip (Outfit)
  static TextStyle prayerTime(BuildContext context, {required bool active}) =>
      TextStyle(
        fontFamily: AppFonts.outfit,
        fontSize: 11.5,
        height: 1.15,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        color: active
            ? primary(context)
            : _isRafiqiLight(context)
            ? context.appColors.secondary
            : context.appColors.textSecondary,
        fontFeatures: outfitNumberFeatures,
      );

  // Mixed Arabic + Numbers parser for Text.rich
  static List<InlineSpan> buildMixedTextSpans({
    required String text,
    required TextStyle arabicStyle,
    required TextStyle numberStyle,
  }) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\d+');
    var lastIndex = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: arabicStyle,
          ),
        );
      }
      spans.add(TextSpan(text: match.group(0), style: numberStyle));
      lastIndex = match.end;
    }
    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex), style: arabicStyle));
    }
    return spans;
  }
}
