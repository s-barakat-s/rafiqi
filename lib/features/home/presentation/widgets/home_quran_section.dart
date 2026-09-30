part of '../home_screen.dart';

/// "Continue Quran" section: resume the last reading position, or show a
/// calm empty state when nothing was saved yet.
class _ContinueQuranCard extends StatefulWidget {
  const _ContinueQuranCard({required this.onContinue, this.onStart});

  /// Opens the exact last reading position (wired by the shell later).
  final Future<void> Function(QuranReadingPosition position) onContinue;

  /// Placeholder route while Quran navigation is not implemented yet.
  final VoidCallback? onStart;

  @override
  State<_ContinueQuranCard> createState() => _ContinueQuranCardState();
}

class _ContinueQuranCardState extends State<_ContinueQuranCard> {
  QuranReadingPosition? _position;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final position = await QuranReadingSource.load();
    if (!mounted) return;
    setState(() {
      _position = position;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final hasPosition = _loaded && _position != null;
    final ctaLabel = hasPosition ? 'تابع القراءة' : 'ابدأ القراءة';

    return AppGlassSurface(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.counterSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: RafiqiSvgIcon(
                  RafiqiIcons.quran,
                  size: 20,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'القرآن الكريم',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_loaded)
            // Avoid layout jump while the (placeholder) source resolves.
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SizedBox(
                height: 18,
                width: 120,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            )
          else if (hasPosition) ...[
            Text(
              'آخر قراءة',
              style: text.labelSmall?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'سورة ${_position!.surahName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.reading,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            if (_metadataLine() != null) ...[
              const SizedBox(height: 4),
              Text(
                _metadataLine()!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
            if (_position!.progress != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: 56,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: _position!.progress!.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: colors.outline.withValues(alpha: .5),
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ] else ...[
            Text(
              'ابدأ رحلتك مع القرآن',
              style: text.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
          ],
          const SizedBox(height: 14),
          Semantics(
            button: true,
            label: ctaLabel,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 148),
              child: SizedBox(
                height: 48,
                child: FilledButton.tonal(
                onPressed: hasPosition
                    ? () => widget.onContinue(_position!)
                    : widget.onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primaryContainer,                  foregroundColor: colors.onPrimaryContainer ?? colors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  visualDensity: VisualDensity.compact,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(ctaLabel),
                    const SizedBox(width: 7),
                    const Icon(Icons.arrow_back_rounded, size: 17),
                  ],
                ),
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }

  /// Shows only metadata that actually exists; never invents page/ayah data.
  String? _metadataLine() {
    final position = _position;
    if (position == null) return null;
    final parts = [
      if (position.page != null)
        'الصفحة ${ArabicNumerals.integer(position.page!)}',
      if (position.ayah != null) 'الآية ${ArabicNumerals.integer(position.ayah!)}',
    ];
    return parts.isEmpty ? null : parts.join(' • ');
  }
}
