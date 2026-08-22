import 'package:flutter/material.dart';

// IslamicSceneHeader is kept for backward compatibility.
// The active layout now lives in TasbeehHomeScreen (full-bleed Stack).
// This widget is no longer used as the primary page section.
class IslamicSceneHeader extends StatelessWidget {
  const IslamicSceneHeader({
    required this.currentCount,
    required this.totalCount,
    required this.targetMode,
    required this.onIncrement,
    super.key,
  });

  final int currentCount;
  final int totalCount;
  final String targetMode;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _IslamicScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()..color = Colors.white.withValues(alpha: 0.42);
    final greenPaint = Paint()
      ..color = const Color(0xFF6EA676).withValues(alpha: 0.20);
    final deepPaint = Paint()
      ..color = const Color(0xFF2F6048).withValues(alpha: 0.20);
    final goldPaint = Paint()
      ..color = const Color(0xFFC7A96B).withValues(alpha: 0.24);

    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.20),
      54,
      lightPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.32),
      82,
      greenPaint,
    );

    final ground = Path()
      ..moveTo(0, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.66,
        size.width,
        size.height * 0.78,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(ground, greenPaint);

    final mosqueBase = Rect.fromLTWH(
      size.width * 0.38,
      size.height * 0.58,
      size.width * 0.32,
      size.height * 0.20,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(mosqueBase, const Radius.circular(12)),
      deepPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.44,
        size.height * 0.38,
        size.width * 0.20,
        size.height * 0.32,
      ),
      3.14,
      3.14,
      false,
      deepPaint..style = PaintingStyle.fill,
    );

    for (final x in [size.width * 0.34, size.width * 0.74]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height * 0.37, 12, size.height * 0.42),
          const Radius.circular(8),
        ),
        deepPaint,
      );
      canvas.drawCircle(Offset(x + 6, size.height * 0.34), 11, deepPaint);
    }

    final kaaba = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.10, size.height * 0.58, 58, 48),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      kaaba,
      Paint()..color = const Color(0xFF2F6048).withValues(alpha: 0.28),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.10, size.height * 0.67, 58, 7),
      goldPaint,
    );

    final rayPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.36)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.23 + (i * 0.075));
      canvas.drawLine(
        Offset(size.width * 0.72, y),
        Offset(size.width * 0.96, y - 18),
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
