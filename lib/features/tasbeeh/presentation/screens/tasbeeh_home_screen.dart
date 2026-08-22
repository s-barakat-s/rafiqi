import 'package:flutter/material.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_state.dart';
import 'package:tasbeh/features/tasbeeh/presentation/widgets/floating_controls_card.dart';
import 'package:tasbeh/features/tasbeeh/presentation/widgets/tasbeeh_counter_card.dart';

class TasbeehHomeScreen extends StatelessWidget {
  const TasbeehHomeScreen({
    required this.state,
    required this.onIncrement,
    required this.onResetSession,
    required this.onStartFloating,
    required this.onStopFloating,
    super.key,
  });

  final TasbeehState state;
  final VoidCallback onIncrement;
  final VoidCallback onResetSession;
  final VoidCallback onStartFloating;
  final VoidCallback onStopFloating;

  static const _backgroundAsset = 'assets/image/background.png';
  static const _creamBg = Color(0xFFFFF8E8);

  @override
  Widget build(BuildContext context) {
    // Hero covers status bar + title + counter + controls
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = screenHeight * 0.82;

    return Stack(
      children: [
        // ── 1. Full-bleed hero image — starts at y=0, behind status bar ────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: heroHeight,
          child: Image.asset(
            _backgroundAsset,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: Color(0xFFD6EDD6),
            ),
          ),
        ),

        // ── 2. Top status-bar readability tint (very subtle dark-to-transparent) ─
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0D1F0D).withValues(alpha: 0.28),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // ── 3. Main fade: image fades to cream background ───────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: heroHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _creamBg.withValues(alpha: 0.0),
                  _creamBg.withValues(alpha: 0.10),
                  _creamBg.withValues(alpha: 0.68),
                  _creamBg,
                ],
                stops: const [0.0, 0.38, 0.74, 1.0],
              ),
            ),
          ),
        ),

        // ── 4. Scrollable content — SafeArea only here, not on the image ────────
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title ───────────────────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 24, 4, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'تسبيح',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFF8F5EA),
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          shadows: [
                            Shadow(
                              color: Color(0x501A3A1A),
                              offset: Offset(0, 2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'ذكرٌ يطمئن به القلب',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFE6E2D2),
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              color: Color(0x381A3A1A),
                              offset: Offset(0, 1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Counter ─────────────────────────────────────────────────────
                const SizedBox(height: 28),
                Center(
                  child: TasbeehCounterCard(
                    currentCount: state.currentCount,
                    totalCount: state.totalCount,
                    targetMode: state.targetMode,
                    onTap: onIncrement,
                  ),
                ),

                // ── Reset session pill ───────────────────────────────────────────
                const SizedBox(height: 22),
                Center(
                  child: _ResetPill(onTap: onResetSession),
                ),

                // ── Floating tasbeeh strip (frameless) ──────────────────────────
                const SizedBox(height: 20),
                Divider(
                  color: const Color(0xFF2F6048).withValues(alpha: 0.10),
                  thickness: 1,
                  indent: 4,
                  endIndent: 4,
                ),
                const SizedBox(height: 14),
                FloatingControlsCard(
                  onStart: onStartFloating,
                  onStop: onStopFloating,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Premium reset pill ────────────────────────────────────────────────────────
class _ResetPill extends StatelessWidget {
  const _ResetPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E8).withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFF2F6048).withValues(alpha: 0.22),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2F6048).withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF2F6048),
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'تصفير الجلسة',
              style: TextStyle(
                color: Color(0xFF2F6048),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
