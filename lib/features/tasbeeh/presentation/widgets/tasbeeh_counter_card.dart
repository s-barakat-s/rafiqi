import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tasbeh/app/formatters/arabic_numerals.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_state.dart';

class TasbeehCounterCard extends StatefulWidget {
  const TasbeehCounterCard({
    required this.currentCount,
    required this.totalCount,
    required this.targetMode,
    required this.onTap,
    super.key,
  });

  final int currentCount;
  final int totalCount;
  final String targetMode;
  final VoidCallback onTap;

  @override
  State<TasbeehCounterCard> createState() => _TasbeehCounterCardState();
}

class _TasbeehCounterCardState extends State<TasbeehCounterCard> {
  bool _pressed = false;

  int? get _targetCount => switch (widget.targetMode) {
        TasbeehState.targetMode99 => 99,
        TasbeehState.targetModeOpen => null,
        _ => 33,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('tasbeeh-counter-tap-area'),
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.965 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = math.min(
              constraints.maxWidth.isFinite ? constraints.maxWidth : 260.0,
              260.0,
            );
            return _CounterRing(
              size: size,
              currentCount: widget.currentCount,
              totalCount: widget.totalCount,
              targetCount: _targetCount,
            );
          },
        ),
      ),
    );
  }
}

// ── Outer circle ──────────────────────────────────────────────────────────────
class _CounterRing extends StatelessWidget {
  const _CounterRing({
    required this.size,
    required this.currentCount,
    required this.totalCount,
    required this.targetCount,
  });

  final double size;
  final int currentCount;
  final int totalCount;
  final int? targetCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.2, -0.3),
          radius: 0.9,
          colors: [Color(0xFFFFFDF5), Color(0xFFEBF5EB)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.88), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F6048).withValues(alpha: 0.20),
            blurRadius: 40,
            spreadRadius: 4,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.75),
            blurRadius: 18,
            offset: const Offset(-8, -8),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _BeadRingPainter(
          currentCount: currentCount,
          targetCount: targetCount,
          circleSize: size,
        ),
        child: Center(
          child: _CenterContent(
            size: size,
            currentCount: currentCount,
            totalCount: totalCount,
          ),
        ),
      ),
    );
  }
}

// ── Center text content ───────────────────────────────────────────────────────
// Uses a fixed SizedBox whose height is guaranteed to fit all text at the
// chosen font/spacing ratios. All sizing is proportional to [size].
class _CenterContent extends StatelessWidget {
  const _CenterContent({
    required this.size,
    required this.currentCount,
    required this.totalCount,
  });

  final double size;
  final int currentCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    // Inner usable diameter — slightly smaller than the bead-ring inner edge.
    // At size=260 → w=140. Heights below must sum to ≤140.
    final w = size * 0.54;

    // Estimated content heights at w=140:
    //   count text  : w*0.38 * 1.0 lineHeight ≈ 53 px  (FittedBox scales down)
    //   gap1        : w*0.020                 ≈  3 px
    //   label1 text : w*0.105 * 1.0           ≈ 15 px
    //   gap2        : w*0.050                 ≈  7 px
    //   label2 text : w*0.098 * 1.0           ≈ 14 px
    //   gap3        : w*0.018                 ≈  3 px
    //   total text  : w*0.210 * 1.0           ≈ 29 px
    //   ──────────────────────────────────────────────
    //   total                                 ≈ 124 px  (< 140 → safe)

    return SizedBox(
      width: w,
      height: w,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── current count (big) ───────────────────────────────────────────
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              ArabicNumerals.integer(currentCount),
              style: TextStyle(
                color: const Color(0xFF1A3D2A),
                fontSize: w * 0.38,
                height: 1.0,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(height: w * 0.020),

          // ── العدد الحالي ──────────────────────────────────────────────────
          Text(
            'العدد الحالي',
            style: TextStyle(
              color: const Color(0xFF557A5F),
              fontSize: w * 0.105,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
          SizedBox(height: w * 0.022),

          // ── subtle divider between the two label sections ─────────────────
          Container(
            width: 22,
            height: 1,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              color: const Color(0xFF4A7A5A).withValues(alpha: 0.28),
            ),
          ),
          SizedBox(height: w * 0.022),

          // ── الإجمالي اليومي ───────────────────────────────────────────────
          Text(
            'الإجمالي اليومي',
            style: TextStyle(
              color: const Color(0xFF6F8A72),
              fontSize: w * 0.098,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
          SizedBox(height: w * 0.018),

          // ── total count ───────────────────────────────────────────────────
          Text(
            ArabicNumerals.integer(totalCount),
            style: TextStyle(
              color: const Color(0xFF2F6048),
              fontSize: w * 0.210,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bead ring painter ─────────────────────────────────────────────────────────
class _BeadRingPainter extends CustomPainter {
  const _BeadRingPainter({
    required this.currentCount,
    required this.targetCount,
    required this.circleSize,
  });

  final int currentCount;
  final int? targetCount;
  final double circleSize;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final target = targetCount ?? 33;
    final active = targetCount == null ? 0 : currentCount.clamp(0, target);
    final outerR = circleSize / 2;

    final maxBeadR = target <= 33 ? 10.0 : target <= 66 ? 6.5 : 4.0;
    final ringR = outerR - maxBeadR - 7.0;
    final arcPerBead = (2 * math.pi * ringR) / target;
    final beadR = math.min(maxBeadR, (arcPerBead - 2.0) / 2.0);

    for (var i = 0; i < target; i++) {
      final angle = -math.pi / 2 + (math.pi * 2 * i / target);
      final bc = Offset(
        center.dx + math.cos(angle) * ringR,
        center.dy + math.sin(angle) * ringR,
      );
      if (i < active) {
        _drawLit(canvas, bc, beadR);
      } else {
        _drawUnlit(canvas, bc, beadR);
      }
    }
  }

  void _drawLit(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r * 1.7,
      Paint()
        ..color = const Color(0xFF2F6048).withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.0,
          colors: const [
            Color(0xFF78C48A),
            Color(0xFF2F6048),
            Color(0xFF183D28),
          ],
          stops: const [0.0, 0.50, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c.translate(-r * 0.30, -r * 0.33),
      r * 0.28,
      Paint()..color = Colors.white.withValues(alpha: 0.58),
    );
  }

  void _drawUnlit(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.0,
          colors: const [
            Color(0xFFFFFDF2),
            Color(0xFFE4D9BC),
            Color(0xFFCCC0A0),
          ],
          stops: const [0.0, 0.60, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c.translate(-r * 0.28, -r * 0.30),
      r * 0.24,
      Paint()..color = Colors.white.withValues(alpha: 0.72),
    );
  }

  @override
  bool shouldRepaint(covariant _BeadRingPainter old) =>
      old.currentCount != currentCount ||
      old.targetCount != targetCount ||
      old.circleSize != circleSize;
}
