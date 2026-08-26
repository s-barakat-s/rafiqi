import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_state.dart';
import 'package:tasbeh/features/tasbeeh/presentation/widgets/floating_controls_card.dart';

part '../widgets/tasbeeh_counter_hero.dart';
part '../widgets/tasbeeh_stats.dart';

class TasbeehHomeScreen extends StatelessWidget {
  const TasbeehHomeScreen({
    required this.state,
    required this.onIncrement,
    required this.onResetSession,
    required this.onStartFloating,
    required this.onStopFloating,
    required this.onOpenSettings,
    super.key,
  });

  final TasbeehState state;
  final VoidCallback onIncrement;
  final VoidCallback onResetSession;
  final Future<void> Function() onStartFloating;
  final Future<void> Function() onStopFloating;
  final VoidCallback onOpenSettings;

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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'تسبيح',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          color: colors.textPrimary,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onOpenSettings,
                      tooltip: 'إعدادات السبحة العائمة',
                      icon: const Icon(Icons.tune_rounded),
                      color: colors.textSecondary,
                    ),
                  ],
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
