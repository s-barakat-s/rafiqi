part of '../../screens/wird_reader_screen.dart';

typedef _ListDecrement =
    Future<void> Function(
      DhikrItem item, {
      Future<void> Function()? animateRemoval,
    });

class _ListReaderView extends StatefulWidget {
  const _ListReaderView({
    required this.reader,
    required this.onDecrement,
    required this.onRestart,
    required this.audio,
    required this.onAudioPressed,
    super.key,
  });

  final WirdReaderController reader;
  final _ListDecrement onDecrement;
  final VoidCallback onRestart;
  final DhikrAudioController? audio;
  final ValueChanged<DhikrItem> onAudioPressed;

  @override
  State<_ListReaderView> createState() => _ListReaderViewState();
}

class _ListReaderViewState extends State<_ListReaderView> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, BuildContext> _itemContexts = {};
  String? _lastActiveId;

  List<DhikrItem> _orderedRemainingItems() {
    final defaultItems = widget.reader.remainingItems;
    final sessionOrder = widget.audio?.sessionCardOrder ?? const <String>[];
    if (sessionOrder.isEmpty) return defaultItems;
    final byId = {for (final item in defaultItems) item.id: item};
    return [
      for (final id in sessionOrder)
        if (byId.containsKey(id)) byId.remove(id)!,
      ...byId.values,
    ];
  }

  @override
  void initState() {
    super.initState();
    final activeId = widget.audio?.currentDhikrId;
    if (activeId != null) {
      _lastActiveId = activeId;
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(activeId));
    }
  }

  @override
  void didUpdateWidget(covariant _ListReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final activeId = widget.audio?.currentDhikrId;
    if (activeId != _lastActiveId) {
      _lastActiveId = activeId;
      if (activeId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(activeId));
      }
    }
  }

  Future<void> _reveal(String id) async {
    if (!mounted || !_scrollController.hasClients) return;
    var itemContext = _itemContexts[id];
    if (itemContext == null) {
      final items = _orderedRemainingItems();
      final index = items.indexWhere((item) => item.id == id);
      if (index < 0) return;
      final target = items.length <= 1
          ? 0.0
          : _scrollController.position.maxScrollExtent *
                (index / (items.length - 1));
      await _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
      if (!mounted) return;
      itemContext = _itemContexts[id];
    }
    if (itemContext == null || !itemContext.mounted) return;
    final itemBox = itemContext.findRenderObject() as RenderBox?;
    final viewportBox = context.findRenderObject() as RenderBox?;
    if (itemBox == null || viewportBox == null) return;
    final itemTop = itemBox.localToGlobal(Offset.zero).dy;
    final itemBottom = itemTop + itemBox.size.height;
    final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;
    final viewportBottom = viewportTop + viewportBox.size.height;
    if (itemTop < viewportTop + 12 || itemBottom > viewportBottom - 12) {
      await Scrollable.ensureVisible(
        itemContext,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: .18,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reader.isComplete) {
      return _CompletionState(
        total: widget.reader.total,
        onRestart: widget.onRestart,
      );
    }
    final remainingItems = _orderedRemainingItems();
    return ListView.separated(
      controller: _scrollController,
      key: const PageStorageKey('wird-list-reader'),
      padding: const EdgeInsets.fromLTRB(1, 4, 1, 18),
      itemCount: remainingItems.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = remainingItems[index];
        return Builder(
          builder: (itemContext) {
            _itemContexts[item.id] = itemContext;
            return _ListDhikrCard(
              key: ValueKey(item.id),
              categoryId: widget.reader.category.id,
              item: item,
              remaining: widget.reader.remainingFor(item.id),
              enabled: !widget.reader.isTransitioning,
              onDecrement: widget.onDecrement,
              audio: widget.audio,
              onAudioPressed: widget.onAudioPressed,
            );
          },
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
    required this.audio,
    required this.onAudioPressed,
    super.key,
  });

  final String categoryId;
  final DhikrItem item;
  final int remaining;
  final bool enabled;
  final _ListDecrement onDecrement;
  final DhikrAudioController? audio;
  final ValueChanged<DhikrItem> onAudioPressed;

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
          child: AppGlassSurface(
            borderRadius: BorderRadius.circular(18),
            level: AppGlassSurfaceLevel.reader,
            grouped: true,
            borderColor: widget.audio?.isCurrent(widget.item.id) ?? false
                ? colors.progress
                : colors.outlineStrong,
            child: InkWell(
              onTap: widget.enabled ? _tap : null,
              splashFactory: NoSplash.splashFactory,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
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
                        const SizedBox(height: 4),
                        _DhikrAudioAction(
                          active:
                              widget.audio?.isCurrent(widget.item.id) ?? false,
                          phase: widget.audio?.phase,
                          status: widget.audio?.status,
                          onPressed: () => widget.onAudioPressed(widget.item),
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
    return _DhikrDetailsTransition(item: widget.item, child: card);
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
