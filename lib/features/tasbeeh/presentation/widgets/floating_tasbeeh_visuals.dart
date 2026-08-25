part of '../overlay/floating_tasbeeh_overlay.dart';

class _CountText extends StatelessWidget {
  const _CountText({
    required this.value,
    required this.color,
    required this.fontSize,
  });

  final int value;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          ArabicNumerals.integer(value),
          maxLines: 1,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            height: 0.95,
          ),
        ),
      ),
    );
  }
}

class _TasbeehBeadsPainter extends CustomPainter {
  const _TasbeehBeadsPainter({
    required this.currentCount,
    required this.targetCount,
    required this.activeColor,
    required this.beadRadius,
  });

  final int currentCount;
  final int? targetCount;
  final Color activeColor;
  final double beadRadius;

  static const _inactiveColor = Color(0xFF4B5660);
  static const _openModeDotCount = 33;

  @override
  void paint(Canvas canvas, Size size) {
    final dotCount = targetCount ?? _openModeDotCount;
    if (dotCount <= 0) {
      return;
    }

    final highlightedCount = targetCount == null
        ? 0
        : _highlightedDots(currentCount, dotCount);
    const capsuleMargin = 12.0;
    const borderInset = 5.5;
    final rect = Rect.fromLTWH(
      capsuleMargin + borderInset,
      capsuleMargin + borderInset,
      size.width - ((capsuleMargin + borderInset) * 2),
      size.height - ((capsuleMargin + borderInset) * 2),
    );
    final radius = rect.width / 2;
    final verticalLength = math.max(0.0, rect.height - (2 * radius));
    final perimeter = (2 * verticalLength) + (2 * math.pi * radius);
    final radiusForCount = dotCount > 60
        ? math.min(beadRadius, 1.55)
        : beadRadius;

    for (var index = 0; index < dotCount; index++) {
      final distance = dotCount == 1 ? 0.0 : perimeter * index / dotCount;
      final center = _pointOnCapsule(rect, radius, verticalLength, distance);
      final isActive = index < highlightedCount;

      final dotPaint = Paint()
        ..color = isActive ? activeColor : _inactiveColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radiusForCount, dotPaint);
    }
  }

  int _highlightedDots(int current, int target) {
    if (target <= 0 || current <= 0) {
      return 0;
    }

    return current.clamp(0, target);
  }

  Offset _pointOnCapsule(
    Rect rect,
    double radius,
    double verticalLength,
    double distance,
  ) {
    final left = rect.left;
    final right = rect.right;
    final top = rect.top;
    final bottom = rect.bottom;
    final centerX = rect.center.dx;
    final topCenterY = top + radius;
    final bottomCenterY = bottom - radius;
    final arcLength = math.pi * radius;

    if (distance <= verticalLength) {
      return Offset(left, bottomCenterY - distance);
    }

    var remaining = distance - verticalLength;
    if (remaining <= arcLength) {
      final theta = math.pi - (remaining / radius);
      return Offset(
        centerX + (radius * math.cos(theta)),
        topCenterY - (radius * math.sin(theta)),
      );
    }

    remaining -= arcLength;
    if (remaining <= verticalLength) {
      return Offset(right, topCenterY + remaining);
    }

    remaining -= verticalLength;
    final theta = remaining / radius;
    return Offset(
      centerX + (radius * math.cos(theta)),
      bottomCenterY + (radius * math.sin(theta)),
    );
  }

  @override
  bool shouldRepaint(covariant _TasbeehBeadsPainter oldDelegate) {
    return oldDelegate.currentCount != currentCount ||
        oldDelegate.targetCount != targetCount ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.beadRadius != beadRadius;
  }
}
