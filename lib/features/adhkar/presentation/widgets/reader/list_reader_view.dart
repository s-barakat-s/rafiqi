part of '../../screens/wird_reader_screen.dart';

typedef _ListDecrement =
    Future<void> Function(
      DhikrItem item, {
      Future<void> Function()? animateRemoval,
    });

class _ListReaderView extends StatelessWidget {
  const _ListReaderView({
    required this.reader,
    required this.onDecrement,
    required this.onRestart,
    super.key,
  });

  final WirdReaderController reader;
  final _ListDecrement onDecrement;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    if (reader.isComplete) {
      return _CompletionState(total: reader.total, onRestart: onRestart);
    }
    return ListView.separated(
      key: const PageStorageKey('wird-list-reader'),
      padding: const EdgeInsets.fromLTRB(1, 4, 1, 18),
      itemCount: reader.remainingItems.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = reader.remainingItems[index];
        return _ListDhikrCard(
          key: ValueKey(item.id),
          categoryId: reader.category.id,
          item: item,
          remaining: reader.remainingFor(item.id),
          enabled: !reader.isTransitioning,
          onDecrement: onDecrement,
        );
      },
    );
  }
}

class _ListDhikrCard extends StatefulWidget {
  const _ListDhikrCard({
    required this.categoryId,
    required this.item,
    required this.remaining,
    required this.enabled,
    required this.onDecrement,
    super.key,
  });

  final String categoryId;
  final DhikrItem item;
  final int remaining;
  final bool enabled;
  final _ListDecrement onDecrement;

  @override
  State<_ListDhikrCard> createState() => _ListDhikrCardState();
}

class _ListDhikrCardState extends State<_ListDhikrCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _removal;
  late final CurvedAnimation _exitProgress;
  late final Animation<double> _remainingSize;
  late final Animation<Offset> _exitPosition;
  bool _handlingTap = false;

  @override
  void initState() {
    super.initState();
    _removal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _exitProgress = CurvedAnimation(
      parent: _removal,
      curve: Curves.easeInOutCubic,
    );
    _remainingSize = ReverseAnimation(_exitProgress);
    _exitPosition = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -.08),
    ).animate(_exitProgress);
  }

  @override
  void dispose() {
    _exitProgress.dispose();
    _removal.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    if (!widget.enabled || _handlingTap) return;
    _handlingTap = true;
    await widget.onDecrement(
      widget.item,
      animateRemoval: widget.remaining == 1
          ? () => _removal.forward(from: 0)
          : null,
    );
    if (mounted) _handlingTap = false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final source = _conciseSource(widget.item);
    final virtue =
        widget.item.virtuePreview ?? _virtuePreview(widget.item.virtue);
    final card = SizeTransition(
      sizeFactor: _remainingSize,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _remainingSize,
        child: SlideTransition(
          position: _exitPosition,
          child: Material(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: widget.enabled ? _tap : null,
              splashFactory: NoSplash.splashFactory,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.outlineStrong),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _RemainingPill(
                        item: widget.item,
                        remaining: widget.remaining,
                      ),
                    ),
                    if (widget.item.instruction != null) ...[
                      const SizedBox(height: 14),
                      _PracticeInstruction(text: widget.item.instruction!),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      widget.item.text,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontFamily: AppFonts.reading,
                        fontSize: _dhikrFontSize(widget.item),
                        height: 1.8,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Divider(color: colors.divider.withValues(alpha: .65)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (source.isNotEmpty)
                          Text(
                            source,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        if (virtue != null)
                          Text(
                            'الفضل: $virtue',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.textSecondary),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return _DhikrDetailsTransition(
      item: widget.item,
      child: card,
    );
  }
}

class _RemainingPill extends StatelessWidget {
  const _RemainingPill({required this.item, required this.remaining});
  final DhikrItem item;
  final int remaining;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: context.appColors.counterSurface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      item.isPrelude
          ? 'مقدمة الورد'
          : '${ArabicNumerals.integer(remaining)} ${remaining == 1 ? 'مرة متبقية' : 'مرات متبقية'}',
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: context.appColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
