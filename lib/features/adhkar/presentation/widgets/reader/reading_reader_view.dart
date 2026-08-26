part of '../../screens/wird_reader_screen.dart';

class _ReadingReaderView extends StatefulWidget {
  const _ReadingReaderView({
    required this.category,
    required this.sessionGeneration,
    required this.onProgressChanged,
    required this.onComplete,
    super.key,
  });

  final AdhkarCategory category;
  final int sessionGeneration;
  final ValueChanged<double> onProgressChanged;
  final Future<void> Function() onComplete;

  @override
  State<_ReadingReaderView> createState() => _ReadingReaderViewState();
}

class _ReadingReaderViewState extends State<_ReadingReaderView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_syncProgress);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncProgress());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_syncProgress)
      ..dispose();
    super.dispose();
  }

  void _syncProgress() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final maxExtent = position.maxScrollExtent;
    if (maxExtent <= 0) {
      widget.onProgressChanged(0.0);
      return;
    }
    if (position.pixels >= maxExtent || position.extentAfter <= 0.001) {
      widget.onProgressChanged(1.0);
      return;
    }
    if (position.pixels <= 0) {
      widget.onProgressChanged(0.0);
      return;
    }
    final progress = (position.pixels / maxExtent).clamp(0.0, 1.0);
    widget.onProgressChanged(progress);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ListView(
      controller: _scrollController,
      key: PageStorageKey(
        'wird-reading-reader-${widget.category.id}-${widget.sessionGeneration}',
      ),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 30),
      children: [
        Text(
          widget.category.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Divider(color: colors.outlineStrong),
        ...widget.category.items.map(
          (item) => _DhikrDetailsTransition(
            item: item,
            child: _ReadingEntry(item: item),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: widget.onComplete,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('أتممت قراءة الورد'),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _ReadingEntry extends StatelessWidget {
  const _ReadingEntry({required this.item});
  final DhikrItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final source = _conciseSource(item);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item.instruction != null) ...[
            Text(
              item.instruction!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            item.text,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontFamily: AppFonts.reading,
              fontSize: 25,
              height: 1.9,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _readingCountLabel(item),
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (source.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              source,
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
          const SizedBox(height: 18),
          Divider(color: colors.divider.withValues(alpha: .65)),
        ],
      ),
    );
  }
}

String _readingCountLabel(DhikrItem item) {
  if (item.countDescription?.trim().isNotEmpty == true) {
    return item.countDescription!.trim();
  }
  if (item.repeatCount == 1) return 'يُقال مرة';
  return 'يُقال ${ArabicNumerals.integer(item.repeatCount)} مرات';
}
