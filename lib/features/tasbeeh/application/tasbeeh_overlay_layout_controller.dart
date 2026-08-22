import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_settings.dart';
import 'package:tasbeh/features/tasbeeh/presentation/overlay/overlay_dimensions.dart';

class TasbeehOverlayLayoutController {
  const TasbeehOverlayLayoutController._();

  static Future<bool> applyExpandedLayout(TasbeehSettings settings) {
    final config = configForScale(settings.sizeScale);
    final width = config.overlayWidth.round();
    final height = config.overlayHeight.round();

    debugPrint(
      'Applying expanded overlay layout: '
      'width=$width, height=$height, '
      'sizeScale=${settings.sizeScale.toStringAsFixed(2)}, '
      'side=${settings.floatingSide}, '
      'alignment=${_alignmentForSide(settings.floatingSide)}, '
      'x=0, enableDrag=true',
    );

    return updateLayout(
      width: width,
      height: height,
      x: 0,
      alignment: _alignmentForSide(settings.floatingSide),
      enableDrag: true,
    );
  }

  static Future<bool> applyCollapsedLayout(TasbeehSettings settings) {
    final config = configForScale(settings.sizeScale);
    final width = config.collapsedWindowWidth.round();
    final height = _collapsedWindowHeight(settings, config).round();

    debugPrint(
      'Applying collapsed overlay layout: '
      'width=$width, height=$height, '
      'sizeScale=${settings.sizeScale.toStringAsFixed(2)}, '
      'side=${settings.floatingSide}, '
      'alignment=${_alignmentForSide(settings.floatingSide)}, '
      'x=0, enableDrag=false',
    );

    return updateLayout(
      width: width,
      height: height,
      x: 0,
      alignment: _alignmentForSide(settings.floatingSide),
      enableDrag: false,
    );
  }

  static Future<bool> enableCollapsedGestureExclusion(
    TasbeehSettings settings,
  ) {
    final config = configForScale(settings.sizeScale);
    final width = config.collapsedWindowWidth.round();
    final height = _collapsedWindowHeight(settings, config).round();

    return updateSystemGestureExclusion(
      enabled: true,
      width: width,
      height: height,
    );
  }

  static Future<bool> disableGestureExclusion() {
    return updateSystemGestureExclusion(enabled: false);
  }

  static Future<bool> updateLayout({
    required int width,
    required int height,
    int? x,
    int? y,
    bool? enableDrag,
    String? alignment,
  }) async {
    try {
      debugPrint(
        'Calling updateOverlayLayout: '
        'width=$width, height=$height, x=$x, y=$y, '
        'alignment=$alignment, enableDrag=$enableDrag',
      );
      final result = await FlutterOverlayWindow.updateOverlayLayout(
        width: width,
        height: height,
        x: x,
        y: y,
        enableDrag: enableDrag,
        alignment: alignment,
      );
      final success = result == true;
      debugPrint('updateOverlayLayout native result: $result');
      return success;
    } catch (error, stackTrace) {
      debugPrint('updateOverlayLayout failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  static Future<bool> updateSystemGestureExclusion({
    required bool enabled,
    int? width,
    int? height,
  }) async {
    try {
      debugPrint(
        'Calling updateSystemGestureExclusion: '
        'enabled=$enabled, width=$width, height=$height',
      );
      final result = await FlutterOverlayWindow.updateSystemGestureExclusion(
        enabled: enabled,
        width: width,
        height: height,
      );
      final success = result == true;
      debugPrint('updateSystemGestureExclusion native result: $result');
      return success;
    } catch (error, stackTrace) {
      debugPrint('updateSystemGestureExclusion failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  static double collapsedWindowHeight(
    TasbeehSettings settings,
    OverlaySizeConfig config,
  ) {
    return _collapsedWindowHeight(settings, config);
  }

  static double _collapsedWindowHeight(
    TasbeehSettings settings,
    OverlaySizeConfig config,
  ) {
    final scale = config.overlayWidth / 140;
    final handleHeight = switch (settings.handleHeight) {
      TasbeehSettings.handleShort => 150 * scale,
      TasbeehSettings.handleTall => 230 * scale,
      _ => config.collapsedHandleHeight,
    };

    return (handleHeight + 32).clamp(180, 540).toDouble();
  }

  static String _alignmentForSide(String side) {
    return side == TasbeehSettings.sideLeft ? 'centerLeft' : 'centerRight';
  }
}
