import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// A lightweight, frameless floating tasbeeh control strip.
/// Tracks overlay active state internally and shows a single toggle button.
class FloatingControlsCard extends StatefulWidget {
  const FloatingControlsCard({
    required this.onStart,
    required this.onStop,
    super.key,
  });

  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  State<FloatingControlsCard> createState() => _FloatingControlsCardState();
}

class _FloatingControlsCardState extends State<FloatingControlsCard>
    with WidgetsBindingObserver {
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshActiveState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshActiveState();
    }
  }

  Future<void> _refreshActiveState() async {
    final active = await FlutterOverlayWindow.isActive();
    if (mounted) setState(() => _isActive = active);
  }

  Future<void> _toggle() async {
    if (_isActive) {
      widget.onStop();
      // Optimistically flip; actual state re-synced on next resume
      if (mounted) setState(() => _isActive = false);
    } else {
      widget.onStart();
      if (mounted) setState(() => _isActive = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // ── Icon badge ────────────────────────────────────────────────────
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6EA676), Color(0xFF2F6048)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2F6048).withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.bubble_chart_rounded,
              color: Color(0xFFFFFBF0),
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // ── Title + subtitle ─────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'السبحة العائمة',
                  style: TextStyle(
                    color: Color(0xFF2F6048),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isActive ? 'نشطة الآن' : 'عدّاد فوق التطبيقات',
                  style: TextStyle(
                    color: _isActive
                        ? const Color(0xFF4CAF72)
                        : const Color(0xFF6F7F73),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Single toggle button ──────────────────────────────────────────
          GestureDetector(
            onTap: _toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: _isActive
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6EA676), Color(0xFF2F6048)],
                      ),
                color: _isActive ? const Color(0xFFFFF8E8) : null,
                borderRadius: BorderRadius.circular(999),
                border: _isActive
                    ? Border.all(
                        color: const Color(0xFF2F6048).withValues(alpha: 0.30),
                        width: 1.4,
                      )
                    : null,
                boxShadow: _isActive
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFF2F6048).withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isActive
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    size: 18,
                    color: _isActive
                        ? const Color(0xFF2F6048).withValues(alpha: 0.85)
                        : const Color(0xFFFFFBF0),
                  ),
                  const SizedBox(width: 5),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      _isActive ? 'إيقاف' : 'تشغيل',
                      key: ValueKey(_isActive),
                      style: TextStyle(
                        color: _isActive
                            ? const Color(0xFF2F6048).withValues(alpha: 0.88)
                            : const Color(0xFFFFFBF0),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
