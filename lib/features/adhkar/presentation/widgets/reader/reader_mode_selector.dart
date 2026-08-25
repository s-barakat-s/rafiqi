part of '../../screens/wird_reader_screen.dart';

Future<void> _showReaderModeSelector(
  BuildContext context, {
  required WirdReaderMode selected,
  required ValueChanged<WirdReaderMode> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'طريقة قراءة الورد',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 27,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (final mode in WirdReaderMode.values)
            _ModeOption(
              mode: mode,
              selected: mode == selected,
              onTap: () {
                Navigator.pop(sheetContext);
                onSelected(mode);
              },
            ),
        ],
      ),
    ),
  );
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final WirdReaderMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final icon = switch (mode) {
      WirdReaderMode.focus => Icons.view_carousel_outlined,
      WirdReaderMode.list => Icons.view_agenda_outlined,
      WirdReaderMode.reading => Icons.menu_book_outlined,
    };
    return Semantics(
      selected: selected,
      button: true,
      child: ListTile(
        onTap: onTap,
        minVerticalPadding: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: selected ? colors.selected.withValues(alpha: .7) : null,
        leading: Icon(icon, color: selected ? colors.secondary : null),
        title: Text(
          mode.label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(mode.subtitle),
        trailing: selected
            ? Icon(Icons.check_circle_rounded, color: colors.secondary)
            : null,
      ),
    );
  }
}
