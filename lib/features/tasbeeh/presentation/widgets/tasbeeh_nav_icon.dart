import 'dart:math' as math;

import 'package:flutter/material.dart';

class TasbeehNavIcon extends StatelessWidget {
  const TasbeehNavIcon({this.size = 23, this.selected = false, super.key});

  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _TasbeehNavIconPainter(
        color:
            IconTheme.of(context).color ??
            Theme.of(context).iconTheme.color ??
            Colors.black,
        selected: selected,
      ),
    );
  }
}

class _TasbeehNavIconPainter extends CustomPainter {
  const _TasbeehNavIconPainter({
    required this.color,
    required this.selected,
  });

  final Color color;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - size.height * .04);
    final radius = size.shortestSide * .34;
    final beadPaint = Paint()
      ..color = color
      ..style = selected ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .075;
    final beadRadius = size.shortestSide * (selected ? .052 : .046);

    for (var index = 0; index < 12; index++) {
      final angle = (-math.pi * .72) + (index * math.pi * 1.44 / 11);
      final beadCenter = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(beadCenter, beadRadius, beadPaint);
    }

    final cordPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .075
      ..strokeCap = StrokeCap.round;
    final cordStart = center + Offset(0, radius * .93);
    final knot = Offset(size.width / 2, size.height * .82);
    canvas.drawLine(cordStart, knot, cordPaint);
    canvas.drawLine(
      knot,
      Offset(size.width * .43, size.height * .96),
      cordPaint,
    );
    canvas.drawLine(
      knot,
      Offset(size.width * .57, size.height * .96),
      cordPaint,
    );
  }

  @override
  bool shouldRepaint(_TasbeehNavIconPainter oldDelegate) =>
      color != oldDelegate.color || selected != oldDelegate.selected;
}
