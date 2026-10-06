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
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: AppThemeArtwork(
                asset: bgAsset,
                alignment: Alignment.centerLeft,
              ),
            ),
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
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    textDirection: TextDirection.ltr,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Wrap(
                            textDirection: TextDirection.ltr,
                            spacing: 4,
                            runSpacing: 0,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                _repository.remainingCount.toString(),
                                textDirection: TextDirection.ltr,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontFamily: AppFonts.outfit,
                                  fontSize: 16,
                                  color: isDark
                                      ? const Color(0xFFF1F5F9)
                                      : colors.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: Text(
                                  _repository.remainingCount == 1
                                      ? 'مرة متبقية'
                                      : 'مرات متبقية',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontFamily: AppFonts.ui,
                                    fontSize: 15,
                                    color: isDark
                                        ? const Color(0xFFF1F5F9)
                                        : colors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        flex: 2,
                        child: _SectionTitle(
                          'ذكر اليوم',
                          color: isDark
                              ? const Color(0xFFF8FAFC)
                              : colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FractionallySizedBox(
                    widthFactor: .68,
                    alignment: Alignment.centerRight,
                    child: Column(
                      key: const ValueKey('daily-dhikr-content-region'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: _repository.decrement,
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Text(
                              dhikr.text,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              softWrap: true,
                              style: TextStyle(
                                fontFamily: AppFonts.reading,
                                fontSize: 28,
                                height: 1.55,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFFF8FAFC)
                                    : colors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        if (dhikr.virtueShort.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            dhikr.virtueShort,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFamily: AppFonts.ui,
                              color: isDark
                                  ? const Color(0xFFE2E8F0)
                                  : colors.secondaryText,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    textDirection: TextDirection.ltr,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? const Color(0xFFF8FAFC)
                              : colors.textPrimary,
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          textDirection: TextDirection.ltr,
                          children: [
                            const Icon(Icons.ios_share_outlined, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'مشاركة',
                              textDirection: TextDirection.rtl,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFamily: AppFonts.ui,
                                color: isDark
                                    ? const Color(0xFFE2E8F0)
                                    : colors.secondaryText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          dhikr.sourceShort,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: AppFonts.ui,
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : colors.secondaryText,
                          ),
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
