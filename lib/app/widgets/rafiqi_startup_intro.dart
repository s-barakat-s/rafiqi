import 'package:flutter/material.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/shared/widgets/app_theme_artwork.dart';

class RafiqiStartupIntro extends StatefulWidget {
  const RafiqiStartupIntro({required this.child, super.key});

  final Widget child;

  @override
  State<RafiqiStartupIntro> createState() => _RafiqiStartupIntroState();
}

class _RafiqiStartupIntroState extends State<RafiqiStartupIntro> {
  static const _displayDuration = Duration(milliseconds: 240);
  static const _fadeDuration = Duration(milliseconds: 320);
  static const _maxWaitForFrame = Duration(milliseconds: 1500);

  bool _exitScheduled = false;
  bool _isVisible = true;
  bool _isFading = false;

  @override
  void initState() {
    super.initState();
    // Never wedge the app if the splash decode fails or stalls.
    Future<void>.delayed(_maxWaitForFrame, _scheduleExit);
  }

  void _onIntroImageReady() {
    _scheduleExit();
  }

  void _scheduleExit() {
    if (_exitScheduled || !mounted) return;
    _exitScheduled = true;
    Future<void>.delayed(_displayDuration, () {
      if (!mounted) return;
      setState(() => _isFading = true);
      Future<void>.delayed(_fadeDuration, () {
        if (!mounted) return;
        setState(() => _isVisible = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.appColors;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_isVisible)
          AbsorbPointer(
            child: AnimatedScale(
              scale: _isFading ? 1.08 : 1,
              duration: _fadeDuration,
              curve: Curves.easeInOutCubic,
              child: AnimatedOpacity(
                opacity: _isFading ? 0 : 1,
                duration: _fadeDuration,
                curve: Curves.easeInOutCubic,
                child: ColoredBox(
                  color: colors.background,
                  child: AppThemeArtwork(
                    asset: isDark
                        ? 'assets/branding/splash_dark.png'
                        : 'assets/branding/splash_light.png',
                    onFrameReady: _onIntroImageReady,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
