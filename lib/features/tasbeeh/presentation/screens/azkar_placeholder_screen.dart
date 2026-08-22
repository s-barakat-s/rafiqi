import 'package:flutter/material.dart';
import 'package:tasbeh/features/tasbeeh/presentation/widgets/soft_section_card.dart';

class AzkarPlaceholderScreen extends StatelessWidget {
  const AzkarPlaceholderScreen({super.key});

  static const _items = [
    ('أذكار الصباح', Icons.wb_sunny_rounded, 'بداية مطمئنة ليومك'),
    ('أذكار المساء', Icons.nightlight_round, 'سكينة وختم جميل لليوم'),
    ('أذكار النوم', Icons.bedtime_rounded, 'راحة القلب قبل النوم'),
    ('أذكار بعد الصلاة', Icons.mosque_rounded, 'ورد خفيف بعد الفريضة'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
        children: [
          const _PageTitle(
            title: 'أذكار',
            subtitle: 'أذكار الصباح والمساء قريبًا',
          ),
          const SizedBox(height: 22),
          ..._items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SoftSectionCard(
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEAF5EA),
                      ),
                      child: Icon(item.$2, color: const Color(0xFF2F6048)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$1,
                            style: const TextStyle(
                              color: Color(0xFF2F6048),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item.$3,
                            style: const TextStyle(
                              color: Color(0xFF6F7F73),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDEDDD),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'قريبًا',
                        style: TextStyle(
                          color: Color(0xFF2F6048),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF2F6048),
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF6F7F73),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
