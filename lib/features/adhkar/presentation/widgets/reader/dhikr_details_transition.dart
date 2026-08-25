part of '../../screens/wird_reader_screen.dart';

class _DhikrDetailsTransition extends StatelessWidget {
  const _DhikrDetailsTransition({
    required this.categoryId,
    required this.item,
    required this.borderRadius,
    required this.child,
  });

  final String categoryId;
  final DhikrItem item;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: borderRadius);
    return OpenContainer<void>(
      key: ValueKey('dhikr-details-$categoryId-${item.id}'),
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: const Duration(milliseconds: 420),
      tappable: false,
      closedElevation: 0,
      openElevation: 0,
      closedColor: Colors.transparent,
      middleColor: context.appColors.surfaceElevated,
      openColor: context.appColors.background,
      closedShape: shape,
      openShape: const RoundedRectangleBorder(),
      openBuilder: (_, _) => DhikrDetailsScreen(item: item),
      closedBuilder: (_, openContainer) => Semantics(
        button: true,
        hint: 'اضغط مطولًا لعرض تفاصيل الذكر',
        onLongPress: openContainer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: openContainer,
          child: child,
        ),
      ),
    );
  }
}
