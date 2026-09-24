import 'package:flutter/material.dart';
import 'package:tasbeh/core/theme/app_theme.dart';

class AppDecorativeBackground extends StatefulWidget {
  const AppDecorativeBackground({required this.child, super.key});

  static const _image = AssetImage('assets/image/home/backgroung.png');

  final Widget child;

  @override
  State<AppDecorativeBackground> createState() => _AppDecorativeBackgroundState();
}

class _AppDecorativeBackgroundState extends State<AppDecorativeBackground> {
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    // Warm the same cache key used below while the startup intro is visible.
    precacheImage(AppDecorativeBackground._image, context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: ColoredBox(color: colors.background),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: Image(
                      image: AppDecorativeBackground._image,
                      color: colors.primary.withValues(alpha: isDark ? .32 : .40),
                      colorBlendMode: BlendMode.srcIn,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      excludeFromSemantics: true,
                      gaplessPlayback: true,
                    ),
              ),
            ),
          ),
        ),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}
