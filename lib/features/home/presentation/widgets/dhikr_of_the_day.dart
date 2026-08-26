part of '../home_screen.dart';

class _DhikrOfTheDay extends StatefulWidget {
  const _DhikrOfTheDay();

  @override
  State<_DhikrOfTheDay> createState() => _DhikrOfTheDayState();
}

class _DhikrOfTheDayState extends State<_DhikrOfTheDay> {
  final _repository = DailyDhikrRepository.instance;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repository.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dhikr = _repository.currentDhikr;
    if (dhikr == null) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.outline.withValues(alpha: .65)),
        ),
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, .035),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(dhikr.id),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.outline.withValues(alpha: .65)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _repository.decrement,
              borderRadius: BorderRadius.circular(14),
              splashFactory: NoSplash.splashFactory,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: colors.counterSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${ArabicNumerals.integer(_repository.remainingCount)} ${_repository.remainingCount == 1 ? 'مرة متبقية' : 'مرات متبقية'}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      dhikr.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: AppFonts.reading,
                        fontSize: 23,
                        height: 1.75,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (dhikr.virtueShort.isNotEmpty) ...[
              Text(
                dhikr.virtueShort,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.secondaryText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    dhikr.sourceShort,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.secondaryText,
                    ),
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
      ),
    );
  }
}
