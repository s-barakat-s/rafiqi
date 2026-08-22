import 'package:flutter/material.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_state.dart';

enum TasbeehTarget {
  thirtyThree('33', 33, TasbeehState.targetMode33),
  ninetyNine('99', 99, TasbeehState.targetMode99),
  open('مفتوح', null, TasbeehState.targetModeOpen);

  const TasbeehTarget(this.label, this.value, this.targetMode);

  final String label;
  final int? value;
  final String targetMode;

  static TasbeehTarget fromMode(String targetMode) {
    return switch (targetMode) {
      TasbeehState.targetMode99 => TasbeehTarget.ninetyNine,
      TasbeehState.targetModeOpen => TasbeehTarget.open,
      _ => TasbeehTarget.thirtyThree,
    };
  }
}

class TargetSelector extends StatelessWidget {
  const TargetSelector({
    required this.selectedTarget,
    required this.onChanged,
    this.title = 'الهدف',
    super.key,
  });

  final TasbeehTarget selectedTarget;
  final ValueChanged<TasbeehTarget> onChanged;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF2F6048),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: TasbeehTarget.values.map((target) {
            final selected = target == selectedTarget;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => onChanged(target),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF2F6048)
                          : const Color(0xFFFFF8E8),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF2F6048)
                            : const Color(0xFFDDEDDD),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        target.label,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFFFFFBF0)
                              : const Color(0xFF6F7F73),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
