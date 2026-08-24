import 'package:flutter/material.dart';
import 'package:tasbeh/app/theme/app_theme.dart';
import 'package:tasbeh/features/tasbeeh/presentation/widgets/soft_section_card.dart';

class DhikrCard extends StatelessWidget {
  const DhikrCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SoftSectionCard(
      child: Stack(
        children: [
          Positioned(
            left: -12,
            top: -18,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 72,
              color: context.appColors.selected.withValues(alpha: 0.18),
            ),
          ),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEAF5EA),
                ),
                child: const Icon(
                  Icons.bookmark_rounded,
                  color: Color(0xFF2F6048),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سُبْحَانَ اللهِ',
                      style: TextStyle(
                        color: Color(0xFF2F6048),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Subhan Allah',
                      style: TextStyle(
                        color: Color(0xFF6EA676),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'سبحان الله وبحمده',
                      style: TextStyle(
                        color: Color(0xFF6F7F73),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
