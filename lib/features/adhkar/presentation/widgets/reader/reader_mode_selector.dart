part of '../../screens/wird_reader_screen.dart';

/// Single-button mode switch used by the common reader header.
class _ReaderModeButton extends StatelessWidget {
  const _ReaderModeButton({required this.selected, required this.onSelected});

  final WirdReaderMode selected;
  final ValueChanged<WirdReaderMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final modes = WirdReaderMode.values;
    final next = modes[(modes.indexOf(selected) + 1) % modes.length];
    return Tooltip(
      message: 'التبديل إلى ${next.label}',
      child: Semantics(
        button: true,
        label: 'طريقة القراءة الحالية: ${selected.label}',
        hint: 'اضغط للتبديل إلى ${next.label}',
        child: SizedBox.square(
          dimension: 40,
          child: IconButton(
            onPressed: () => onSelected(next),
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: RafiqiSvgIcon(
              _readerModeIcon(selected),
              size: 19,
              color: colors.imageForeground,
            ),
          ),
        ),
      ),
    );
  }
}

String _readerModeIcon(WirdReaderMode mode) => switch (mode) {
  WirdReaderMode.focus => RafiqiIcons.cardView,
  WirdReaderMode.list => RafiqiIcons.listView,
  WirdReaderMode.reading => RafiqiIcons.readingView,
};
