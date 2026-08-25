import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:tasbeh/core/theme/app_theme.dart';

class FloatingControlsCard extends StatefulWidget {
  const FloatingControlsCard({
    required this.onStart,
    required this.onStop,
    super.key,
  });

  final Future<void> Function() onStart;
  final Future<void> Function() onStop;

  @override
  State<FloatingControlsCard> createState() => _FloatingControlsCardState();
}

class _FloatingControlsCardState extends State<FloatingControlsCard>
    with WidgetsBindingObserver {
  bool _isActive = false;
  bool _isChanging = false;

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
    if (state == AppLifecycleState.resumed) _refreshActiveState();
  }

  Future<void> _refreshActiveState() async {
    final active = await FlutterOverlayWindow.isActive();
    if (mounted) setState(() => _isActive = active);
  }

  Future<void> _toggle(bool enabled) async {
    if (_isChanging) return;
    setState(() => _isChanging = true);
    if (enabled) {
      await widget.onStart();
    } else {
      await widget.onStop();
    }
    final active = await FlutterOverlayWindow.isActive();
    if (!mounted) return;
    setState(() {
      _isActive = active;
      _isChanging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.outline.withValues(alpha: .7)),
          bottom: BorderSide(color: colors.outline.withValues(alpha: .7)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'السبحة العائمة',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isActive
                      ? 'نشطة فوق التطبيقات'
                      : 'عدّاد صغير أثناء استخدام هاتفك',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isActive,
            onChanged: _isChanging ? null : _toggle,
          ),
        ],
      ),
    );
  }
}
