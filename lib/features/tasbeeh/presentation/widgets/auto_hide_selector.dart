import 'package:flutter/material.dart';

class AutoHideSelector extends StatelessWidget {
  const AutoHideSelector({
    required this.autoCollapseSeconds,
    required this.onChanged,
    super.key,
  });

  final int? autoCollapseSeconds;
  final ValueChanged<int?> onChanged;

  static const _options = <int?>[5, 10, 20, 30, null];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الإخفاء التلقائي',
          style: TextStyle(
            color: Color(0xFF2F6048),
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _options.map((seconds) {
            final selected = seconds == autoCollapseSeconds;
            return ChoiceChip(
              label: Text(seconds == null ? 'إيقاف' : '$seconds ث'),
              selected: selected,
              showCheckmark: false,
              selectedColor: const Color(0xFF2F6048),
              labelStyle: TextStyle(
                color: selected
                    ? const Color(0xFFFFFBF0)
                    : const Color(0xFF6F7F73),
                fontWeight: FontWeight.w800,
              ),
              onSelected: (_) => onChanged(seconds),
            );
          }).toList(),
        ),
      ],
    );
  }
}
