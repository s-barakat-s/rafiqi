import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tasbeh/app/formatters/arabic_numerals.dart';
import 'package:tasbeh/app/theme/app_theme.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_state.dart';
import 'package:tasbeh/features/tasbeeh/presentation/widgets/floating_controls_card.dart';

class TasbeehHomeScreen extends StatelessWidget {
  const TasbeehHomeScreen({
    required this.state,
    required this.onIncrement,
    required this.onResetSession,
    required this.onStartFloating,
    required this.onStopFloating,
    super.key,
  });

  final TasbeehState state;
  final VoidCallback onIncrement;
  final VoidCallback onResetSession;
  final Future<void> Function() onStartFloating;
  final Future<void> Function() onStopFloating;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final target = state.targetCount;

    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        bottom: false,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 132),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'تسبيح',
                  style: TextStyle(
                    fontFamily: 'ArefRuqaa',
                    color: colors.textPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ذِكرٌ يطمئن به القلب',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                _CounterHero(
                  count: state.currentCount,
                  target: target,
                  onTap: onIncrement,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    onPressed: onResetSession,
                    icon: const Icon(Icons.refresh_rounded, size: 19),
                    label: const Text('تصفير الجلسة'),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'تسبيحات اليوم',
                        value: state.dailyTotal,
                      ),
                    ),
                    const _StatsDivider(),
                    Expanded(
                      child: _StatCard(
                        label: 'الإجمالي الكلي',
                        value: state.totalCount,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                FloatingControlsCard(
                  onStart: onStartFloating,
                  onStop: onStopFloating,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
                            fontFamily: 'IBMPlexSansArabic',
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        Text(
          ArabicNumerals.integer(value),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _StatsDivider extends StatelessWidget {
  const _StatsDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: context.appColors.outline.withValues(alpha: .75),
    );
  }
}
