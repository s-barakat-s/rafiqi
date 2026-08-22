import 'package:flutter/material.dart';
import 'package:tasbeh/app/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.onOpenTasbeeh, super.key});
  final VoidCallback onOpenTasbeeh;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '١٧ صفر ١٤٤٨ هـ',
                      style: text.bodyMedium?.copyWith(
                        color: colors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'السبت، ٢٢ أغسطس',
                      style: text.labelLarge?.copyWith(
                        color: colors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.gold.withValues(alpha: .45)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_outlined,
                      size: 18,
                      color: colors.gold,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '١٢ يومًا',
                      style: text.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'السلام عليكم',
            style: const TextStyle(
              fontFamily: 'ArefRuqaa',
              fontSize: 38,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'جعل الله يومك عامرًا بذكره',
            style: text.titleMedium?.copyWith(color: colors.secondaryText),
          ),
          const SizedBox(height: 26),
          const _MorningHero(),
          const SizedBox(height: 30),
          const _SectionTitle('وردك اليوم'),
          const SizedBox(height: 8),
          const _ProgressRow(
            label: 'أذكار الصباح',
            value: 'مكتمل',
            progress: 1,
            complete: true,
          ),
          const _ProgressRow(
            label: 'الاستغفار',
            value: '٧٢ / ١٠٠',
            progress: .72,
          ),
          const _ProgressRow(
            label: 'الصلاة على النبي ﷺ',
            value: '٢٠ / ٥٠',
            progress: .4,
          ),
          const SizedBox(height: 28),
          const _SectionTitle('الوصول السريع'),
          const SizedBox(height: 14),
          _QuickActions(onOpenTasbeeh: onOpenTasbeeh),
          const SizedBox(height: 28),
          const _SectionTitle('ذكر اليوم'),
          const SizedBox(height: 14),
          const _DhikrOfTheDay(),
        ],
      ),
    );
  }
}

class _MorningHero extends StatelessWidget {
  const _MorningHero();
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.emerald,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.gold.withValues(alpha: .55)),
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            top: -36,
            end: -30,
            child: Icon(
              Icons.filter_vintage_outlined,
              size: 150,
              color: colors.gold.withValues(alpha: .08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أذكار الصباح',
                style: const TextStyle(
                  fontFamily: 'ArefRuqaa',
                  color: Color(0xFFF3EBDD),
                  fontSize: 29,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'بداية مطمئنة ليومك',
                style: text.bodyLarge?.copyWith(color: const Color(0xFFD8D0C2)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: 8 / 24,
                        minHeight: 7,
                        backgroundColor: Colors.white.withValues(alpha: .14),
                        color: colors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '٨ من ٢٤',
                    style: text.labelLarge?.copyWith(
                      color: const Color(0xFFF3EBDD),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {},
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('متابعة الورد'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_back_rounded, size: 19),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontFamily: 'ArefRuqaa',
      fontSize: 25,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.progress,
    this.complete = false,
  });
  final String label, value;
  final double progress;
  final bool complete;
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.emerald.withValues(alpha: .11),
            ),
            child: Icon(
              complete ? Icons.check_rounded : Icons.circle_outlined,
              size: 18,
              color: complete ? colors.gold : colors.emerald,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: colors.divider.withValues(alpha: .45),
                    color: colors.gold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: colors.secondaryText),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onOpenTasbeeh});
  final VoidCallback onOpenTasbeeh;
  @override
  Widget build(BuildContext context) {
    const actions = [
      (Icons.dark_mode_outlined, 'أذكار المساء'),
      (Icons.mosque_outlined, 'بعد الصلاة'),
      (Icons.bookmark_border_rounded, 'المفضلة'),
      (Icons.radio_button_checked_rounded, 'السبحة'),
    ];
    return Row(
      children: List.generate(
        actions.length,
        (index) => Expanded(
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              end: index == actions.length - 1 ? 0 : 8,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: index == 3 ? onOpenTasbeeh : () {},
              child: Container(
                height: 92,
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.appColors.gold.withValues(alpha: .25),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      actions[index].$1,
                      color: context.appColors.gold,
                      size: 25,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      actions[index].$2,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DhikrOfTheDay extends StatelessWidget {
  const _DhikrOfTheDay();
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.parchment,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.gold.withValues(alpha: .35)),
      ),
      child: Column(
        children: [
          Text(
            'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Amiri',
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
