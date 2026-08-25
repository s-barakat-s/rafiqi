import 'package:flutter/material.dart';
import 'package:tasbeh/core/formatting/arabic_numerals.dart';
import 'package:tasbeh/core/theme/app_theme.dart';

class AutoHideSelector extends StatelessWidget {
  const AutoHideSelector({
    required this.autoCollapseSeconds,
    required this.onChanged,
    super.key,
  });

  final int? autoCollapseSeconds;
  final ValueChanged<int?> onChanged;

  static const _options = <int?>[null, 5, 10, 20, 30];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الإخفاء التلقائي',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _options.map((seconds) {
            final selected = seconds == autoCollapseSeconds;
            return ChoiceChip(
              label: Text(
                seconds == null
                    ? 'إيقاف'
                    : '${ArabicNumerals.integer(seconds)} ث',
              ),
              selected: selected,
              showCheckmark: false,
              selectedColor: colors.selected,
              backgroundColor: Colors.transparent,
              side: BorderSide(color: colors.outline),
              labelStyle: TextStyle(
                color: selected ? colors.textPrimary : colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) => onChanged(seconds),
            );
          }).toList(),
        ),
      ],
    );
  }
}
