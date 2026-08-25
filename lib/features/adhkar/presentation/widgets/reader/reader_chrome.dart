part of '../../screens/wird_reader_screen.dart';

class _CompletionState extends StatelessWidget {
  const _CompletionState({
    required this.total,
    required this.onRestart,
    super.key,
  });
  final int total;
  final VoidCallback onRestart;
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.selected.withValues(alpha: .24),
                border: Border.all(color: colors.outline),
              ),
              child: Icon(
                Icons.check_rounded,
                size: 38,
                color: colors.progress,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'تم وردك',
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 34,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${ArabicNumerals.integer(total)} / ${ArabicNumerals.integer(total)}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: colors.secondaryText),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('إعادة القراءة'),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.ios_share_outlined),
                  label: const Text('مشاركة'),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('إضافة إلى وردك اليومي'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: () {},
    tooltip: label,
    visualDensity: VisualDensity.compact,
    icon: Icon(icon, size: 21),
  );
}

class _ReaderTitle extends StatelessWidget {
  const _ReaderTitle({required this.category});

  final AdhkarCategory category;

  @override
  Widget build(BuildContext context) {
    final asset = switch (category.id) {
      'morning' => 'assets/calligraphy/morning_adhkar.png',
      'evening' => 'assets/calligraphy/evening_adhkar.png',
      'after_prayer' => 'assets/calligraphy/after_prayer_adhkar.png',
      _ => null,
    };
    if (asset == null) {
      return Text(
        category.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: AppFonts.display,
          fontSize: 25,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return CalligraphyTitle(
      asset: asset,
      semanticLabel: category.title,
      height: 42,
    );
  }
}
