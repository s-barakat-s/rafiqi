part of '../screens/tasbeeh_home_screen.dart';

class _CounterHero extends StatelessWidget {
  const _CounterHero({
    required this.count,
    required this.target,
    required this.onTap,
  });

  final int count;
  final int? target;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        Semantics(
          button: true,
          label: 'زيادة عداد التسبيح',
          value: ArabicNumerals.integer(count),
          child: Material(
            color: Colors.transparent,
            child: InkResponse(
              key: const ValueKey('tasbeeh-counter-tap-area'),
              onTap: onTap,
              radius: 126,
              containedInkWell: true,
              customBorder: const CircleBorder(),
              highlightColor: colors.selected.withValues(alpha: .12),
              splashColor: colors.progress.withValues(alpha: .10),
              child: Ink(
                width: 252,
                height: 252,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.surfaceElevated.withValues(alpha: .48),
                ),
                child: CustomPaint(
                  painter: _BeadRingPainter(
                    target: target,
                    activeCount: count,
                    activeColor: colors.progress,
                    inactiveColor: colors.outlineStrong,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ArabicNumerals.integer(count),
                          style: TextStyle(
                            fontFamily: AppFonts.ui,
                            color: colors.textPrimary,
                            fontSize: 66,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'العدد الحالي',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          target == null
              ? 'الهدف مفتوح'
              : 'الهدف ${ArabicNumerals.integer(target!)}',
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _BeadRingPainter extends CustomPainter {
  const _BeadRingPainter({
    required this.target,
    required this.activeCount,
    required this.activeColor,
    required this.inactiveColor,
  });

  final int? target;
  final int activeCount;
  final Color activeColor;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final beadCount = target ?? 24;
    final radius = size.shortestSide / 2 - 11;
    final beadRadius = beadCount <= 33 ? 3.6 : 2.15;
    final inactivePaint = Paint()
      ..color = inactiveColor.withValues(alpha: target == null ? .55 : .72);
    final activePaint = Paint()..color = activeColor;

    for (var index = 0; index < beadCount; index++) {
      final angle = -math.pi / 2 + (math.pi * 2 * index / beadCount);
      final position = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final isActive = target != null && index < activeCount;
      canvas.drawCircle(
        position,
        isActive ? beadRadius + .45 : beadRadius,
        isActive ? activePaint : inactivePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BeadRingPainter oldDelegate) {
    return oldDelegate.target != target ||
        oldDelegate.activeCount != activeCount ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
