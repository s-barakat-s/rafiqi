part of '../../screens/wird_reader_screen.dart';

class _ReaderDeck extends StatelessWidget {
  const _ReaderDeck({
    required this.categoryId,
    required this.current,
    required this.next,
    required this.third,
    required this.fourth,
    required this.remaining,
    required this.transition,
    required this.onTap,
  });

  final String categoryId;
  final DhikrItem current;
  final DhikrItem? next;
  final DhikrItem? third;
  final DhikrItem? fourth;
  final int remaining;
  final Animation<double> transition;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    // نخلي الأطراف أوضح شوية
    const nextPeek = 22.0;
    const thirdPeek = 16.0;
    // ده اللي ظاهر فعلاً في الوضع الطبيعي
    const visibleDeckReserve = nextPeek + thirdPeek;

    // نخلي الكارت ياخد مساحة أكبر من الفراغ
    const minCardHeight = 460.0;
    const maxCardHeight = 580.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final rawCardHeight = constraints.maxHeight - visibleDeckReserve - 8;
        final fixedCardHeight = rawCardHeight
            .clamp(minCardHeight, maxCardHeight)
            .toDouble();

        final thirdSurface = Color.lerp(
          colors.previewSurfaceBack,
          colors.previewSurface,
          0.45,
        )!;
        final fourthSurface = colors.previewSurfaceBack;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: fixedCardHeight + visibleDeckReserve,
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                // FOURTH CARD
                //
                // This card exists only as the incoming third preview
                // during the transition.
                if (fourth != null)
                  _AnimatedDeckLayer(
                    key: ValueKey(fourth!.id),
                    transition: transition,
                    height: fixedCardHeight,

                    // Keep the incoming card permanently behind the third card.
                    // When the third card moves upward, this one is revealed immediately.
                    beginOffset: const Offset(0, nextPeek + thirdPeek),
                    endOffset: const Offset(0, nextPeek + thirdPeek),

                    // D starts with exactly C's geometry. It is therefore
                    // physically hidden by C at frame zero, then revealed
                    // continuously as C moves upward.
                    beginScale: .985,
                    endScale: .985,

                    // Never fade the incoming third preview in.
                    beginOpacity: .58,
                    endOpacity: .58,

                    beginContentObscured: 1,
                    endContentObscured: 1,

                    beginSurface: fourthSurface,
                    endSurface: fourthSurface,

                    child: _DhikrCard(
                      categoryId: categoryId,
                      key: ValueKey(fourth!.id),
                      item: fourth!,
                      remaining: fourth!.repeatCount,
                      enabled: false,
                    ),
                  ),

                // THIRD CARD
                if (third != null)
                  _AnimatedDeckLayer(
                    key: ValueKey(third!.id),
                    transition: transition,
                    height: fixedCardHeight,
                    beginOffset: const Offset(0, nextPeek + thirdPeek),
                    endOffset: const Offset(0, nextPeek),
                    beginScale: .985,
                    // Match the next-card start state exactly so committing
                    // the new index cannot produce a role-change snap.
                    endScale: .992,
                    beginOpacity: .58,
                    endOpacity: .82,
                    beginContentObscured: 1,
                    endContentObscured: .96,
                    beginSurface: fourthSurface,
                    endSurface: thirdSurface,
                    child: _DhikrCard(
                      categoryId: categoryId,
                      key: ValueKey(third!.id),
                      item: third!,
                      remaining: third!.repeatCount,
                      enabled: false,
                    ),
                  ),

                // NEXT CARD
                if (next != null)
                  _AnimatedDeckLayer(
                    key: ValueKey(next!.id),
                    transition: transition,
                    height: fixedCardHeight,
                    beginOffset: const Offset(0, nextPeek),
                    endOffset: Offset.zero,
                    beginScale: .992,
                    endScale: 1,
                    beginOpacity: .82,
                    endOpacity: 1,
                    beginContentObscured: .96,
                    endContentObscured: 0,
                    beginSurface: thirdSurface,
                    endSurface: colors.surfaceElevated,
                    child: _DhikrCard(
                      categoryId: categoryId,
                      key: ValueKey(next!.id),
                      item: next!,
                      remaining: next!.repeatCount,
                      enabled: false,
                    ),
                  ),

                // CURRENT CARD
                _AnimatedDeckLayer(
                  key: ValueKey(current.id),
                  transition: transition,
                  height: fixedCardHeight,
                  beginOffset: Offset.zero,
                  endOffset: const Offset(-1.25, 0),
                  beginScale: 1,
                  endScale: 1,
                  beginOpacity: 1,
                  endOpacity: 0,
                  beginContentObscured: 0,
                  endContentObscured: 0,
                  beginSurface: colors.surfaceElevated,
                  endSurface: colors.surfaceElevated,
                  horizontalOffsetFactor: true,
                  child: _DhikrCard(
                    categoryId: categoryId,
                    key: ValueKey(current.id),
                    item: current,
                    remaining: remaining,
                    enabled: true,
                    onTap: onTap,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedDeckLayer extends StatelessWidget {
  const _AnimatedDeckLayer({
    required this.transition,
    required this.height,
    required this.beginOffset,
    required this.endOffset,
    required this.beginScale,
    required this.endScale,
    required this.beginOpacity,
    required this.endOpacity,
    required this.beginContentObscured,
    required this.endContentObscured,
    required this.beginSurface,
    required this.endSurface,
    required this.child,
    this.horizontalOffsetFactor = false,
    super.key,
  });

  final Animation<double> transition;
  final double height;

  final Offset beginOffset;
  final Offset endOffset;

  final double beginScale;
  final double endScale;

  final double beginOpacity;
  final double endOpacity;

  final double beginContentObscured;
  final double endContentObscured;

  final Color beginSurface;
  final Color endSurface;

  final bool horizontalOffsetFactor;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: transition,
            child: child,
            builder: (context, child) {
              final progress = Curves.easeInOutCubic.transform(
                transition.value,
              );

              final offset = Offset(
                _lerp(beginOffset.dx, endOffset.dx, progress),
                _lerp(beginOffset.dy, endOffset.dy, progress),
              );

              final translatedOffset = horizontalOffsetFactor
                  ? Offset(offset.dx * constraints.maxWidth, offset.dy)
                  : offset;

              final surface = Color.lerp(beginSurface, endSurface, progress)!;

              return Transform.translate(
                offset: translatedOffset,
                child: Transform.scale(
                  scale: _lerp(beginScale, endScale, progress),
                  alignment: Alignment.topCenter,
                  child: Opacity(
                    opacity: _lerp(beginOpacity, endOpacity, progress),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Color.lerp(
                            surface,
                            context.appColors.outline,
                            0.35,
                          )!,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.035),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          child!,
                          IgnorePointer(
                            child: Opacity(
                              opacity: _lerp(
                                beginContentObscured,
                                endContentObscured,
                                progress,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: surface,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

double _lerp(num start, num end, double t) {
  return start.toDouble() + (end.toDouble() - start.toDouble()) * t;
}
