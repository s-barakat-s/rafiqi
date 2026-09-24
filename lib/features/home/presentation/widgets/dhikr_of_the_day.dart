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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgAsset = colors.dailyDhikrBackground(theme.brightness);
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: colors.outline.withValues(alpha: .65)),
          image: DecorationImage(
            image: AssetImage(bgAsset),
            fit: BoxFit.cover,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            Colors.black.withValues(alpha: .22),
                            Colors.black.withValues(alpha: .38),
                          ]
                        : [
                            Colors.white.withValues(alpha: .08),
                            Colors.white.withValues(alpha: .20),
                          ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionTitle(
                    'ذكر اليوم',
                    color: isDark ? const Color(0xFFF8FAFC) : null,
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _repository.decrement,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                      child: Column(
                        children: [
                          Text(
                            dhikr.text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppFonts.reading,
                              fontSize: 23,
                              height: 1.75,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFF8FAFC)
                                  : colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${ArabicNumerals.integer(_repository.remainingCount)} ${_repository.remainingCount == 1 ? 'مرة متبقية' : 'مرات متبقية'}',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: isDark
                                  ? const Color(0xFFF1F5F9)
                                  : colors.primary,
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
                        color: isDark
                            ? const Color(0xFFE2E8F0)
                            : colors.secondaryText,
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
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : colors.secondaryText,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        tooltip: 'استماع',
                        icon: RafiqiSvgIcon(
                          RafiqiIcons.sound,
                          size: 22,
                          color: isDark
                              ? const Color(0xFFF8FAFC)
                              : colors.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        tooltip: 'مشاركة',
                        icon: Icon(
                          Icons.ios_share_outlined,
                          color: isDark
                              ? const Color(0xFFF8FAFC)
                              : colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
