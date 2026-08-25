part of '../../screens/wird_reader_screen.dart';

class _FocusReaderView extends StatelessWidget {
  const _FocusReaderView({
    required this.reader,
    required this.transition,
    required this.onTap,
    required this.onRestart,
    super.key,
  });

  final WirdReaderController reader;
  final Animation<double> transition;
  final VoidCallback onTap;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    if (reader.isComplete) {
      return _CompletionState(total: reader.total, onRestart: onRestart);
    }
    return _ReaderDeck(
      categoryId: reader.category.id,
      current: reader.current,
      next: reader.itemAfter(1),
      third: reader.itemAfter(2),
      fourth: reader.itemAfter(3),
      remaining: reader.remaining,
      transition: transition,
      onTap: onTap,
    );
  }
}
