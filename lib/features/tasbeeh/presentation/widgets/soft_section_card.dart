import 'package:flutter/material.dart';

class SoftSectionCard extends StatelessWidget {
  const SoftSectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F6048).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 12,
            offset: const Offset(-6, -6),
          ),
        ],
      ),
      child: child,
    );
  }
}
