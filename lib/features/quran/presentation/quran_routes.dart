import 'package:flutter/material.dart';
import 'package:tasbeh/shared/widgets/app_decorative_background.dart';

Route<T> quranFadeRoute<T>(WidgetBuilder builder) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 180),
  reverseTransitionDuration: const Duration(milliseconds: 160),
  pageBuilder: (context, animation, secondaryAnimation) =>
      AppDecorativeBackground(child: builder(context)),
  transitionsBuilder: (context, animation, secondaryAnimation, child) =>
      FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        ),
        child: child,
      ),
);
