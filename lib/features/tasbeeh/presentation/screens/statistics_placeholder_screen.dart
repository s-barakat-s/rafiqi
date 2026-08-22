import 'package:flutter/material.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_state.dart';
import 'package:tasbeh/features/tasbeeh/presentation/widgets/soft_section_card.dart';

class StatisticsPlaceholderScreen extends StatelessWidget {
  const StatisticsPlaceholderScreen({required this.state, super.key});

  final TasbeehState state;

  @override
  Widget build(BuildContext context) {
    final targetLabel = switch (state.targetMode) {
      TasbeehState.targetMode99 => '99',
      TasbeehState.targetModeOpen => 'مفتوح',
      _ => '33',
    };

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
        children: [
        const Text(
          'إحصائيات',
          style: TextStyle(
            color: Color(0xFF2F6048),
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'تابع وردك اليومي وإنجازك',
          style: TextStyle(
            color: Color(0xFF6F7F73),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 22),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.08,
          children: [
            _StatCard(
              'إجمالي اليوم',
              state.totalCount.toString(),
              Icons.all_inclusive_rounded,
            ),
            _StatCard('جلسات اليوم', '1', Icons.spa_rounded),
            _StatCard(
              'أطول سلسلة',
              'قريبًا',
              Icons.local_fire_department_rounded,
            ),
            _StatCard('الهدف الحالي', targetLabel, Icons.flag_rounded),
          ],
        ),
        const SizedBox(height: 16),
        SoftSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تقدم الجلسة',
                style: TextStyle(
                  color: Color(0xFF2F6048),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 12,
                  value: _progress,
                  backgroundColor: const Color(0xFFDDEDDD),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF6EA676)),
                ),
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }

  double? get _progress {
    final target = switch (state.targetMode) {
      TasbeehState.targetMode99 => 99,
      TasbeehState.targetModeOpen => null,
      _ => 33,
    };
    if (target == null) return null;
    return (state.currentCount / target).clamp(0, 1).toDouble();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SoftSectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: const Color(0xFF6EA676), size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF2F6048),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF6F7F73),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
