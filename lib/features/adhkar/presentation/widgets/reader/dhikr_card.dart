part of '../../screens/wird_reader_screen.dart';

class _DhikrCard extends StatelessWidget {
  const _DhikrCard({
    required this.categoryId,
    required this.item,
    required this.remaining,
    required this.enabled,
    this.onTap,
    super.key,
  });
  final String categoryId;
  final DhikrItem item;
  final int remaining;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final conciseSource = _conciseSource(item);
    final virtuePreview = item.virtuePreview ?? _virtuePreview(item.virtue);
    final hasMetadata = conciseSource.isNotEmpty || virtuePreview != null;
    final card = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineStrong),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.counterSurface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: colors.outline.withValues(alpha: .7),
                    ),
                  ),
                  child: Text(
                    item.isPrelude
                        ? 'مقدمة الورد'
                        : '${ArabicNumerals.integer(remaining)} ${remaining == 1 ? 'مرة متبقية' : 'مرات متبقية'}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isLight ? colors.secondary : AppPalette.drySage,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.instruction != null) ...[
                          _PracticeInstruction(text: item.instruction!),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          item.text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: AppFonts.reading,
                            height: 1.85,
                            fontWeight: FontWeight.w400,
                          ).copyWith(fontSize: _dhikrFontSize(item)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Divider(color: colors.divider.withValues(alpha: .55)),
              const SizedBox(height: 8),
              if (hasMetadata)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (conciseSource.isNotEmpty)
                        Text(
                          conciseSource,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: AppFonts.ui,
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (virtuePreview != null) ...[
                        if (conciseSource.isNotEmpty)
                          const SizedBox(height: 3),
                        Text(
                          'الفضل: $virtuePreview',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: AppFonts.ui,
                            color: colors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (!enabled) return card;
    return _DhikrDetailsTransition(
      item: item,
      child: card,
    );
  }
}

class _PracticeInstruction extends StatelessWidget {
  const _PracticeInstruction({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      fontFamily: AppFonts.ui,
      color: context.appColors.textSecondary,
      height: 1.55,
      fontWeight: FontWeight.w600,
    ),
  );
}

int _dhikrLength(DhikrItem item) => item.text.runes.length;

bool _isLongDhikr(DhikrItem item) => _dhikrLength(item) > 600;

bool _isMediumDhikr(DhikrItem item) => _dhikrLength(item) > 360;

double _dhikrFontSize(DhikrItem item) {
  if (_isLongDhikr(item)) return 22;
  if (_isMediumDhikr(item)) return 24;
  return 26;
}

String _conciseSource(DhikrItem item) {
  if (item.surah != null) {
    final ayah = item.ayahFrom == null
        ? ''
        : item.ayahTo != null && item.ayahTo != item.ayahFrom
        ? ': ${ArabicNumerals.integer(item.ayahFrom!)}–${ArabicNumerals.integer(item.ayahTo!)}'
        : ': ${ArabicNumerals.integer(item.ayahFrom!)}';
    return '${item.surah}$ayah';
  }
  return item.source ?? '';
}

String? _virtuePreview(String? virtue) {
  if (virtue == null) return null;
  var preview = virtue.trim();
  if (preview.isEmpty) return null;

  // A leading bracketed citation is useful in the details sheet, but the card
  // already has a dedicated concise source line.
  preview = preview.replaceFirst(RegExp(r'^\[[^\]]+\]\s*'), '').trim();
  if (preview.isEmpty) return null;
  const limit = 150;
  if (preview.runes.length <= limit) return preview;

  final shortened = String.fromCharCodes(preview.runes.take(limit));
  RegExpMatch? sentenceEnd;
  for (final match in RegExp(r'[.!؟؛]').allMatches(shortened)) {
    sentenceEnd = match;
  }
  if (sentenceEnd != null && sentenceEnd.end >= 70) {
    return shortened.substring(0, sentenceEnd.end).trim();
  }
  return '${shortened.trimRight()}…';
}
