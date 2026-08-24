import 'package:flutter/material.dart';
import 'package:tasbeh/app/formatters/arabic_numerals.dart';

class CountCard extends StatelessWidget {
  const CountCard({
    required this.label,
    required this.count,
    this.isPrimary = false,
    super.key,
  });

  final String label;
  final int count;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isPrimary
            ? colorScheme.primaryContainer.withValues(alpha: 0.34)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPrimary
              ? colorScheme.primary.withValues(alpha: 0.35)
              : colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            ArabicNumerals.integer(count),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: isPrimary ? colorScheme.primary : colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              height: 0.95,
            ),
          ),
        ],
      ),
    );
  }
}
