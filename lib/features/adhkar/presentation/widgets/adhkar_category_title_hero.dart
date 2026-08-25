import 'package:flutter/material.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/adhkar/domain/entities/adhkar.dart';

class AdhkarCategoryTitleHero extends StatelessWidget {
  const AdhkarCategoryTitleHero({
    required this.category,
    required this.child,
    super.key,
  });

  final AdhkarCategory category;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'adhkar-title-${category.id}',
      transitionOnUserGestures: true,
      flightShuttleBuilder:
          (flightContext, animation, direction, fromContext, toContext) {
            return Material(
              color: Colors.transparent,
              child: Center(
                child: Text(
                  category.title,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(flightContext).colorScheme.onSurface,
                  ),
                ),
              ),
            );
          },
      child: Material(color: Colors.transparent, child: child),
    );
  }
}
