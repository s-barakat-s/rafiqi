import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:tasbeh/core/assets/rafiqi_icons.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/shared/widgets/rafiqi_svg_icon.dart';

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
    return Semantics(
      button: true,
      toggled: _isActive,
      label: 'السبحة العائمة',
      value: _isActive ? 'نشطة' : 'متوقفة',
      child: Material(
        color: colors.surfaceElevated.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: _isChanging ? null : () => _toggle(!_isActive),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: 88,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _isActive
                    ? colors.primary.withValues(alpha: .32)
                    : colors.border.withValues(alpha: .56),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RafiqiSvgIcon(
                  RafiqiIcons.tasbeeh,
                  size: 27,
                  color: _isActive ? colors.primary : colors.textSecondary,
                ),
                const SizedBox(width: 9),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'السبحة العائمة',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isChanging
                            ? 'جارٍ التحديث…'
                            : _isActive
                            ? 'نشطة الآن'
                            : 'اضغط للتشغيل',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
