import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tasbeh/core/theme/app_theme.dart';

class RafiqiSvgIcon extends StatelessWidget {
  const RafiqiSvgIcon(
    this.assetName, {
    this.size = 24,
    this.color,
    this.semanticsLabel,
    super.key,
  });

  final String assetName;
  final double size;
  final Color? color;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? context.appColors.primary;
    return SvgPicture.asset(
      assetName,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: semanticsLabel == null,
    );
  }
}
