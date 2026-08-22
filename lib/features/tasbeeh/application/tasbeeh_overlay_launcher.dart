import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_settings.dart';
import 'package:tasbeh/features/tasbeeh/presentation/overlay/overlay_dimensions.dart';

class TasbeehOverlayLauncher {
  const TasbeehOverlayLauncher._();

  static Future<void> restartOverlay({
    required TasbeehSettings settings,
  }) async {
    if (await FlutterOverlayWindow.isActive()) {
      debugPrint('Closing active overlay before restart');
      await FlutterOverlayWindow.closeOverlay();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    await showOverlay(settings);
  }

  static Future<void> showOverlay(TasbeehSettings settings) async {
    final sideConfig = _configForSide(settings.floatingSide);
    final config = configForScale(settings.sizeScale);
    final width = config.overlayWidth.round();
    final height = config.overlayHeight.round();
    const startPosition = OverlayPosition(0, 0);

    debugPrint(
      'Starting overlay: mode=${settings.overlayMode}, '
      'sizeScale=${settings.sizeScale.toStringAsFixed(2)}, '
      'side=${settings.floatingSide}, '
      'width=$width, '
      'height=$height, '
      'dprConversion=false, '
      'enableDrag=true, '
      'alignment=${sideConfig.alignment.name}, '
      'positionGravity=${sideConfig.positionGravity.name}, '
      'startPosition=$startPosition',
    );

    await FlutterOverlayWindow.showOverlay(
      height: height,
      width: width,
      alignment: sideConfig.alignment,
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilityPublic,
      overlayTitle: 'Floating Tasbeeh',
      overlayContent: 'Tasbeeh overlay is running',
      enableDrag: true,
      positionGravity: sideConfig.positionGravity,
      startPosition: startPosition,
    );
  }

  static _OverlaySideConfig _configForSide(String side) {
    final isLeft = side == TasbeehSettings.sideLeft;
    return _OverlaySideConfig(
      alignment: isLeft
          ? OverlayAlignment.centerLeft
          : OverlayAlignment.centerRight,
      positionGravity: PositionGravity.auto,
    );
  }
}

class _OverlaySideConfig {
  const _OverlaySideConfig({
    required this.alignment,
    required this.positionGravity,
  });

  final OverlayAlignment alignment;
  final PositionGravity positionGravity;
}
