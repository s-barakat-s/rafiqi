part of '../home_screen.dart';

/// Image-led Quran card that resumes the last reading position when available.
class _ContinueQuranCard extends StatefulWidget {
  const _ContinueQuranCard({required this.onContinue, this.onStart});

  /// Opens the exact last reading position (wired by the shell later).
  final Future<void> Function(QuranReadingPosition position) onContinue;

  /// Placeholder route while Quran navigation is not implemented yet.
  final VoidCallback? onStart;

  @override
  State<_ContinueQuranCard> createState() => _ContinueQuranCardState();
}

class _ContinueQuranCardState extends State<_ContinueQuranCard> {
  static const _lightAsset = 'assets/image/home/Quran light.png';
  static const _darkAsset = 'assets/image/home/Quran dark.png';

  QuranReadingPosition? _position;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final position = await QuranReadingSource.load();
    if (!mounted) return;
    setState(() => _position = position);
  }

  Future<void> _handleTap() async {
    final position = _position;
    if (position != null) {
      await widget.onContinue(position);
      return;
    }
    widget.onStart?.call();
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = Theme.of(context).brightness == Brightness.dark
        ? _darkAsset
        : _lightAsset;

    return Semantics(
      button: true,
      label: 'فتح القرآن الكريم',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth;

            return Stack(
              children: [
                Image.asset(
                  assetPath,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                  excludeFromSemantics: true,
                ),
                Positioned(
                  right: cardWidth * 0.14,
                  bottom: cardWidth * 0.045,
                  width: cardWidth * 0.38,
                  child: const _MockQuranReadingProgress(),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleTap,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MockQuranReadingProgress extends StatelessWidget {
  const _MockQuranReadingProgress();

  static const _fontFeatures = <FontFeature>[FontFeature('ss01', 1)];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          key: const ValueKey('quran-reading-progress-mock'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                'أكمل القراءة',
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.thmanyahSans,
                  fontFeatures: _fontFeatures,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                  color: colors.imageForeground,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                'سورة البقرة • الآية 157',
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.thmanyahSans,
                  fontFeatures: _fontFeatures,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.05,
                  color: colors.imageForegroundMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
