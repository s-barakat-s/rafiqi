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
  /// The branded splash holds completely static (no fade, no zoom) for this
  /// long after its first frame is decoded.
  static const _holdDuration = Duration(milliseconds: 2000);

  /// Exit animation: gentle zoom toward the viewer combined with a fade-out,
  /// revealing the already-rendered app underneath.
  static const _exitDuration = Duration(milliseconds: 700);
  static const _exitScale = 1.12;
  static const _maxWaitForFrame = Duration(milliseconds: 3500);

  bool _exitScheduled = false;
  bool _isVisible = true;
  bool _isExiting = false;

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
    Future<void>.delayed(_holdDuration, () {
      if (!mounted) return;
      setState(() => _isExiting = true);
      Future<void>.delayed(_exitDuration, () {
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
        // The real application is always built and rendered underneath; the
        // splash is a pure overlay on top of it.
        widget.child,
        if (_isVisible)
          AbsorbPointer(
            child: AnimatedScale(
              scale: _isExiting ? _exitScale : 1,
              duration: _exitDuration,
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _isExiting ? 0 : 1,
                duration: _exitDuration,
                curve: Curves.easeOutCubic,
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
