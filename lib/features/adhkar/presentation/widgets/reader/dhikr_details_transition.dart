part of '../../screens/wird_reader_screen.dart';

class _DhikrDetailsTransition extends StatelessWidget {
  const _DhikrDetailsTransition({
    required this.item,
    required this.child,
  });

  final DhikrItem item;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    void openDetails() {
      Navigator.of(context).push<void>(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 240),
          pageBuilder: (context, animation, secondaryAnimation) =>
              DhikrDetailsScreen(
                item: item,
              ),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            final progress = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return AnimatedBuilder(
              animation: progress,
              child: FadeTransition(opacity: progress, child: child),
              builder: (context, child) => Transform.translate(
                offset: Offset(
                  0,
                  (animation.status == AnimationStatus.reverse ? 8 : 12) *
                      (1 - progress.value),
                ),
                child: child,
              ),
            );
          },
        ),
      );
    }

    return Semantics(
      button: true,
      hint: 'اضغط مطولًا لعرض تفاصيل الذكر',
      onLongPress: openDetails,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: openDetails,
        child: child,
      ),
    );
  }
}
