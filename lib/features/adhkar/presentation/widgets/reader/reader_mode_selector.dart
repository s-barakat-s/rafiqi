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

class _ReaderModeButton extends StatefulWidget {
  const _ReaderModeButton({
    required this.selected,
    required this.hapticsEnabled,
    required this.onSelected,
  });

  final WirdReaderMode selected;
  final bool hapticsEnabled;
  final ValueChanged<WirdReaderMode> onSelected;

  @override
  State<_ReaderModeButton> createState() => _ReaderModeButtonState();
}

class _ReaderModeButtonState extends State<_ReaderModeButton> {
  static const _popupWidth = 150.0;
  static const _optionHeight = 44.0;
  OverlayEntry? _popup;
  ValueNotifier<WirdReaderMode>? _candidate;
  ValueNotifier<bool>? _pressed;
  double _popupGlobalLeft = 0;
  double _popupGlobalTop = 0;

  void _openQuickSelector(LongPressStartDetails details) {
    if (_popup != null) return;
    final box = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    final buttonTopLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonBottom = buttonTopLeft.dy + box.size.height;
    final popupLeft = (buttonTopLeft.dx + box.size.width / 2 - _popupWidth / 2)
        .clamp(8.0, overlay.size.width - _popupWidth - 8)
        .toDouble();
    final popupTop = buttonBottom + 8;
    final overlayOrigin = overlay.localToGlobal(Offset.zero);
    _popupGlobalLeft = overlayOrigin.dx + popupLeft;
    _popupGlobalTop = overlayOrigin.dy + popupTop;
    final candidate = ValueNotifier(widget.selected);
    final pressed = ValueNotifier(true);
    _candidate = candidate;
    _pressed = pressed;
    _popup = OverlayEntry(
      builder: (context) => Positioned(
        left: popupLeft,
        top: popupTop,
        width: _popupWidth,
        child: IgnorePointer(
          child: _ModeDragPopup(candidate: candidate, pressed: pressed),
        ),
      ),
    );
    Overlay.of(context).insert(_popup!);
  }

  void _trackQuickSelection(LongPressMoveUpdateDetails details) {
    final candidate = _candidate;
    if (candidate == null) return;
    final position = details.globalPosition;
    if (position.dy < _popupGlobalTop - 12 ||
        position.dy >
            _popupGlobalTop +
                (_optionHeight * WirdReaderMode.values.length) +
                12 ||
        position.dx < _popupGlobalLeft ||
        position.dx > _popupGlobalLeft + _popupWidth) {
      return;
    }
    final optionIndex = ((position.dy - _popupGlobalTop) / _optionHeight)
        .floor()
        .clamp(0, WirdReaderMode.values.length - 1)
        .toInt();
    final next = WirdReaderMode.values[optionIndex];
    if (next == candidate.value) return;
    candidate.value = next;
    if (widget.hapticsEnabled) HapticFeedback.selectionClick();
  }

  Future<void> _finishQuickSelection() async {
    final selected = _candidate?.value ?? widget.selected;
    _pressed?.value = false;
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (!mounted) return;
    _closeQuickSelector();
    widget.onSelected(selected);
  }

  void _closeQuickSelector() {
    _popup?.remove();
    _popup = null;
    _candidate?.dispose();
    _candidate = null;
    _pressed?.dispose();
    _pressed = null;
  }

  @override
  void dispose() {
    _closeQuickSelector();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'طريقة قراءة الورد',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showReaderModeSelector(
          context,
          selected: widget.selected,
          onSelected: widget.onSelected,
        ),
        onLongPressStart: _openQuickSelector,
        onLongPressMoveUpdate: _trackQuickSelection,
        onLongPressEnd: (_) => _finishQuickSelection(),
        onLongPressCancel: _closeQuickSelector,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.view_agenda_outlined, size: 21),
        ),
      ),
    );
  }
}

class _ModeDragPopup extends StatelessWidget {
  const _ModeDragPopup({required this.candidate, required this.pressed});

  final ValueNotifier<WirdReaderMode> candidate;
  final ValueNotifier<bool> pressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.surfaceElevated,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: .14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: ValueListenableBuilder<WirdReaderMode>(
        valueListenable: candidate,
        builder: (context, selected, _) => ValueListenableBuilder<bool>(
          valueListenable: pressed,
          builder: (context, isPressed, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in WirdReaderMode.values)
                AnimatedScale(
                  scale: mode == selected && isPressed ? .96 : 1,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOutCubic,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOutCubic,
                    height: _ReaderModeButtonState._optionHeight,
                    alignment: Alignment.center,
                    color: mode == selected
                        ? colors.selected.withValues(
                            alpha: isPressed ? .95 : .72,
                          )
                        : Colors.transparent,
                    child: Text(
                      mode.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: mode == selected
                            ? colors.textPrimary
                            : colors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
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
