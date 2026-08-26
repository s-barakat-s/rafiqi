import 'package:flutter/material.dart';

class RafiqiStartupIntro extends StatefulWidget {
  const RafiqiStartupIntro({required this.child, super.key});

  final Widget child;

  @override
  State<RafiqiStartupIntro> createState() => _RafiqiStartupIntroState();
}

class _RafiqiStartupIntroState extends State<RafiqiStartupIntro> {
  static const _displayDuration = Duration(milliseconds: 1000);
  static const _fadeDuration = Duration(milliseconds: 320);

  bool _timerStarted = false;
  bool _isVisible = true;
  bool _isFading = false;

  void _onIntroImageReady() {
    if (_timerStarted) return;
    _timerStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startExit();
    });
  }

  Future<void> _startExit() async {
    await Future<void>.delayed(_displayDuration);
    if (!mounted) return;
    setState(() => _isFading = true);

    await Future<void>.delayed(_fadeDuration);
    if (!mounted) return;
    setState(() => _isVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  color: isDark
                      ? const Color(0xFF151A18)
                      : const Color(0xFFF2F0E9),
                  child: Image.asset(
                    isDark
                        ? 'assets/branding/splash_dark.png'
                        : 'assets/branding/splash_light.png',
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    gaplessPlayback: true,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded || frame != null) {
                            _onIntroImageReady();
                          }
                          return child;
                        },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
