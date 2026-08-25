part of '../home_screen.dart';

class _DhikrOfTheDay extends StatelessWidget {
  const _DhikrOfTheDay();
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withValues(alpha: .65)),
      ),
      child: Column(
        children: [
          const Text(
            'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.reading,
              fontSize: 23,
              height: 1.75,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'متفق عليه',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.secondaryText),
                ),
              ),
              IconButton(
                onPressed: () {},
                tooltip: 'استماع',
                icon: const Icon(Icons.volume_up_outlined),
              ),
              IconButton(
                onPressed: () {},
                tooltip: 'مشاركة',
                icon: const Icon(Icons.ios_share_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
