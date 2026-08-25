part of '../screens/journey_screen.dart';

class _JourneyHero extends StatelessWidget {
  const _JourneyHero({
    required this.current,
    required this.longest,
    required this.weekCompleted,
  });
  final int current;
  final int longest;
  final int weekCompleted;
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 25),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outline.withValues(alpha: .7)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_fire_department_outlined,
            color: colors.secondary,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            ArabicNumerals.integer(current),
            style: const TextStyle(
              color: AppPalette.dustGrey,
              fontSize: 52,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'يومًا متواصلًا',
            style: TextStyle(
              fontFamily: AppFonts.display,
              color: AppPalette.dustGrey,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: colors.outline.withValues(alpha: .55)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _HeroDetail(
                label: 'أطول سلسلة',
                value: '${ArabicNumerals.integer(longest)} يومًا',
              ),
              Container(
                width: 1,
                height: 34,
                color: colors.outline.withValues(alpha: .55),
              ),
              _HeroDetail(
                label: 'هذا الأسبوع',
                value:
                    '${ArabicNumerals.integer(weekCompleted)} من ${ArabicNumerals.integer(7)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroDetail extends StatelessWidget {
  const _HeroDetail({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: AppPalette.dustGrey,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        style: const TextStyle(color: Color(0xFFCDC5B8), fontSize: 12),
      ),
    ],
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final String? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      if (trailing != null)
        Text(
          trailing!,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: context.appColors.secondary),
        ),
    ],
  );
}
