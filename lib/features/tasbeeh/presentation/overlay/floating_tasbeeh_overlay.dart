import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_settings.dart';
import 'package:tasbeh/features/tasbeeh/domain/models/tasbeeh_state.dart';
import 'package:tasbeh/features/tasbeeh/presentation/overlay/overlay_dimensions.dart';

class FloatingTasbeehOverlay extends StatefulWidget {
  const FloatingTasbeehOverlay({
    required this.state,
    required this.settings,
    required this.sizeConfig,
    required this.isCollapsed,
    required this.useEdgeGestureInsetFallback,
    required this.onTap,
    required this.onPullExpand,
    required this.onDragEnd,
    super.key,
  });

  final TasbeehState state;
  final TasbeehSettings settings;
  final OverlaySizeConfig sizeConfig;
  final bool isCollapsed;
  final bool useEdgeGestureInsetFallback;
  final VoidCallback onTap;
  final VoidCallback onPullExpand;
  final VoidCallback onDragEnd;

  @override
  State<FloatingTasbeehOverlay> createState() => _FloatingTasbeehOverlayState();
}

class _FloatingTasbeehOverlayState extends State<FloatingTasbeehOverlay>
    with SingleTickerProviderStateMixin {
  static const double _expandPullThreshold = 40;
  static const double _maxPullPreviewDistance = 80;
  static const double _collapsedHandleEdgeInset = 20;
  static const double _minHandleHitWidth = 22;
  static const double _maxHandleHitWidth = 28;

  late final AnimationController _handleSnapBackController;
  Animation<double>? _handleSnapBackAnimation;
  bool _isPressed = false;
  double _pullDistance = 0;

  @override
  void initState() {
    super.initState();
    _handleSnapBackController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 220),
        )..addListener(() {
          final animation = _handleSnapBackAnimation;
          if (animation == null || !mounted) {
            return;
          }

          setState(() {
            _pullDistance = animation.value;
          });
        });
  }

  @override
  void dispose() {
    _handleSnapBackController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FloatingTasbeehOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isCollapsed && oldWidget.isCollapsed) {
      _resetPullState();
    }
  }

  Future<void> _handleTap() async {
    if (widget.settings.hapticFeedbackEnabled) {
      HapticFeedback.lightImpact();
    }

    if (widget.settings.tapAnimationEnabled) {
      setState(() {
        _isPressed = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 90));
      if (mounted) {
        setState(() {
          _isPressed = false;
        });
      }
    }

    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
            child: child,
          ),
        );
      },
      child: widget.isCollapsed
          ? _buildCollapsedHandle()
          : _buildExpandedCapsule(),
    );
  }

  Widget _buildCollapsedHandle() {
    final config = widget.sizeConfig;
    final settings = widget.settings;
    final handleWidth = _handleThickness(settings, config);
    final handleHeight = _handleHeight(widget.settings, config);
    final handleColor = _handleColor(settings);
    final sideAlignment = _sideAlignment(settings);
    final hitWidth = _handleHitWidth(config);
    final pullOffset = _pullOffset(settings);
    final windowWidth = config.collapsedWindowWidth;
    final windowHeight = _collapsedWindowHeight(settings, config);
    final edgePadding = _collapsedHandleEdgePadding(settings, config);

    debugPrint(
      'Collapsed handle layout: '
      'window=${windowWidth.toStringAsFixed(1)}x'
      '${windowHeight.toStringAsFixed(1)}, '
      'hit=${hitWidth.toStringAsFixed(1)}x'
      '${handleHeight.toStringAsFixed(1)}, '
      'visual=${handleWidth.toStringAsFixed(1)}x'
      '${handleHeight.toStringAsFixed(1)}, '
      'side=${settings.floatingSide}, '
      'edgeInsetFallback=${widget.useEdgeGestureInsetFallback}, '
      'padding=$edgePadding',
    );

    return SizedBox(
      key: const ValueKey('collapsed-handle'),
      width: windowWidth,
      height: windowHeight,
      child: Stack(
        children: [
          Align(
            alignment: sideAlignment,
            child: Padding(
              padding: edgePadding,
              child: Transform.translate(
                offset: Offset(pullOffset, 0),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: _handleCollapsedDragStart,
                  onHorizontalDragUpdate: _handleCollapsedDragUpdate,
                  onHorizontalDragEnd: (_) => _handleCollapsedDragEnd(),
                  onHorizontalDragCancel: _snapBackHandle,
                  child: SizedBox(
                    width: hitWidth,
                    height: handleHeight,
                    child: Align(
                      alignment: sideAlignment,
                      child: Container(
                        width: handleWidth,
                        height: handleHeight,
                        decoration: BoxDecoration(
                          color: handleColor.withValues(
                            alpha: settings.opacity.clamp(0.4, 1),
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedCapsule() {
    final config = widget.sizeConfig;
    final settings = widget.settings;
    final sideAlignment = _sideAlignment(settings);
    final capsule = SizedBox(
      width: config.capsuleWidth,
      height: config.capsuleHeight,
      child: _buildCapsuleContent(),
    );

    return GestureDetector(
      key: const ValueKey('expanded-capsule'),
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      onPanEnd: (_) => widget.onDragEnd(),
      child: SizedBox(
        width: config.overlayWidth,
        height: config.overlayHeight,
        child: Align(
          alignment: sideAlignment,
          child: AnimatedScale(
            scale: widget.settings.tapAnimationEnabled && _isPressed ? 0.96 : 1,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOutCubic,
            child: Opacity(opacity: settings.opacity, child: capsule),
          ),
        ),
      ),
    );
  }

  Widget _buildCapsuleContent() {
    final config = widget.sizeConfig;
    final settings = widget.settings;
    final accentColor = settings.resolvedAccentColor;
    final showDivider = settings.showTotal && settings.showDivider;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _backgroundColors(settings),
              ),
              border: _borderFor(settings, accentColor),
            ),
          ),
        ),
        if (settings.showBeads)
          Positioned.fill(
            child: CustomPaint(
              painter: _TasbeehBeadsPainter(
                currentCount: widget.state.currentCount,
                targetCount: widget.state.targetCount,
                activeColor: accentColor,
                beadRadius: _beadRadius(settings, config),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            18 * _scale(config),
            settings.showTotal ? 42 * _scale(config) : 34 * _scale(config),
            18 * _scale(config),
            settings.showTotal ? 32 * _scale(config) : 34 * _scale(config),
          ),
          child: settings.showTotal
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 7,
                      child: _CountText(
                        value: widget.state.currentCount,
                        color: accentColor,
                        fontSize: config.currentFontSize,
                      ),
                    ),
                    if (showDivider)
                      Container(
                        width: 34 * _scale(config),
                        height: 1,
                        margin: EdgeInsets.symmetric(
                          vertical: 8 * _scale(config),
                        ),
                        color: const Color(0xFF40505C),
                      )
                    else
                      SizedBox(height: 12 * _scale(config)),
                    Expanded(
                      flex: 4,
                      child: _CountText(
                        value: widget.state.totalCount,
                        color: const Color(0xFF93A2AE),
                        fontSize: config.totalFontSize,
                      ),
                    ),
                  ],
                )
              : Center(
                  child: _CountText(
                    value: widget.state.currentCount,
                    color: accentColor,
                    fontSize: config.currentFontSize * 1.08,
                  ),
                ),
        ),
      ],
    );
  }

  void _handleCollapsedDragStart(DragStartDetails _) {
    _handleSnapBackController.stop();
    setState(() {
      _pullDistance = 0;
    });
  }

  void _handleCollapsedDragUpdate(DragUpdateDetails details) {
    final inwardDelta = _inwardDragDistance(details.delta.dx);
    if (inwardDelta <= 0) {
      return;
    }

    setState(() {
      _pullDistance = (_pullDistance + inwardDelta)
          .clamp(0, _maxPullPreviewDistance)
          .toDouble();
    });
  }

  void _handleCollapsedDragEnd() {
    if (_pullDistance >= _expandPullThreshold) {
      _completePullExpand();
      return;
    }

    _snapBackHandle();
  }

  void _completePullExpand() {
    _handleSnapBackAnimation =
        Tween<double>(begin: _pullDistance, end: _expandPullThreshold).animate(
          CurvedAnimation(
            parent: _handleSnapBackController,
            curve: Curves.easeOutCubic,
          ),
        );

    _handleSnapBackController
      ..reset()
      ..forward().whenComplete(() {
        if (!mounted) {
          return;
        }

        _resetPullState();
        widget.onPullExpand();
      });
  }

  void _snapBackHandle() {
    if (_pullDistance <= 0) {
      _resetPullState();
      return;
    }

    _handleSnapBackAnimation = Tween<double>(begin: _pullDistance, end: 0)
        .animate(
          CurvedAnimation(
            parent: _handleSnapBackController,
            curve: Curves.easeOutCubic,
          ),
        );

    _handleSnapBackController
      ..reset()
      ..forward().whenComplete(() {
        if (mounted) {
          _resetPullState();
        }
      });
  }

  void _resetPullState() {
    if (!mounted) {
      return;
    }

    setState(() {
      _pullDistance = 0;
    });
  }

  double _inwardDragDistance(double dx) {
    if (_isLeftSide(widget.settings)) {
      return math.max(0, dx);
    }

    return math.max(0, -dx);
  }

  double _pullOffset(TasbeehSettings settings) {
    final inwardDirection = _isLeftSide(settings) ? 1.0 : -1.0;
    return inwardDirection * math.min(_pullDistance, _collapsedHandleEdgeInset);
  }

  EdgeInsets _collapsedHandleEdgePadding(
    TasbeehSettings settings,
    OverlaySizeConfig config,
  ) {
    if (!widget.useEdgeGestureInsetFallback) {
      return EdgeInsets.zero;
    }

    final availableInset =
        (config.collapsedWindowWidth - _handleHitWidth(config) - 8)
            .clamp(0, _collapsedHandleEdgeInset)
            .toDouble();

    if (_isLeftSide(settings)) {
      return EdgeInsets.only(left: availableInset);
    }

    return EdgeInsets.only(right: availableInset);
  }

  double _handleHitWidth(OverlaySizeConfig config) {
    return (config.collapsedHandleWidth * 1.5)
        .clamp(_minHandleHitWidth, _maxHandleHitWidth)
        .toDouble();
  }

  double _scale(OverlaySizeConfig config) => config.overlayWidth / 140;

  Alignment _sideAlignment(TasbeehSettings settings) {
    return _isLeftSide(settings) ? Alignment.centerLeft : Alignment.centerRight;
  }

  bool _isLeftSide(TasbeehSettings settings) {
    return settings.floatingSide == TasbeehSettings.sideLeft;
  }

  List<Color> _backgroundColors(TasbeehSettings settings) {
    return switch (settings.backgroundIntensity) {
      TasbeehSettings.backgroundVeryDark => const [
        Color(0xFF090D12),
        Color(0xFF030506),
      ],
      TasbeehSettings.backgroundSoftDark => const [
        Color(0xFF22303D),
        Color(0xFF111820),
      ],
      _ => const [Color(0xFF16202A), Color(0xFF080D12)],
    };
  }

  BoxBorder? _borderFor(TasbeehSettings settings, Color accentColor) {
    return switch (settings.borderStyle) {
      TasbeehSettings.borderNone => null,
      TasbeehSettings.borderBright => Border.all(
        color: accentColor.withValues(alpha: 0.75),
        width: 1.6,
      ),
      _ => Border.all(color: const Color(0xFF263746), width: 1.2),
    };
  }

  double _beadRadius(TasbeehSettings settings, OverlaySizeConfig config) {
    final multiplier = switch (settings.beadSize) {
      TasbeehSettings.beadSmall => 0.78,
      TasbeehSettings.beadLarge => 1.18,
      _ => 1.0,
    };
    return config.beadRadius * multiplier;
  }

  Color _handleColor(TasbeehSettings settings) {
    return switch (settings.handleColorMode) {
      TasbeehSettings.handleAccent => settings.resolvedAccentColor,
      TasbeehSettings.handleGray => const Color(0xFF9CA3AF),
      _ => Colors.white,
    };
  }

  double _handleThickness(TasbeehSettings settings, OverlaySizeConfig config) {
    final scale = _scale(config);
    return switch (settings.handleThickness) {
      TasbeehSettings.handleThin => 4 * scale,
      TasbeehSettings.handleThick => 8 * scale,
      _ => 6 * scale,
    };
  }

  double _handleHeight(TasbeehSettings settings, OverlaySizeConfig config) {
    final scale = _scale(config);
    final height = switch (settings.handleHeight) {
      TasbeehSettings.handleShort => 150 * scale,
      TasbeehSettings.handleTall => 230 * scale,
      _ => config.collapsedHandleHeight,
    };
    return height.clamp(120, _collapsedWindowHeight(settings, config) - 16);
  }

  double _collapsedWindowHeight(
    TasbeehSettings settings,
    OverlaySizeConfig config,
  ) {
    final scale = _scale(config);
    final handleHeight = switch (settings.handleHeight) {
      TasbeehSettings.handleShort => 150 * scale,
      TasbeehSettings.handleTall => 230 * scale,
      _ => config.collapsedHandleHeight,
    };

    return (handleHeight + 32).clamp(180, 540).toDouble();
  }
}

class _CountText extends StatelessWidget {
  const _CountText({
    required this.value,
    required this.color,
    required this.fontSize,
  });

  final int value;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value.toString(),
          maxLines: 1,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            height: 0.95,
          ),
        ),
      ),
    );
  }
}

class _TasbeehBeadsPainter extends CustomPainter {
  const _TasbeehBeadsPainter({
    required this.currentCount,
    required this.targetCount,
    required this.activeColor,
    required this.beadRadius,
  });

  final int currentCount;
  final int? targetCount;
  final Color activeColor;
  final double beadRadius;

  static const _inactiveColor = Color(0xFF4B5660);
  static const _openModeDotCount = 33;

  @override
  void paint(Canvas canvas, Size size) {
    final dotCount = targetCount ?? _openModeDotCount;
    if (dotCount <= 0) {
      return;
    }

    final highlightedCount = targetCount == null
        ? 0
        : _highlightedDots(currentCount, dotCount);
    const capsuleMargin = 12.0;
    const borderInset = 5.5;
    final rect = Rect.fromLTWH(
      capsuleMargin + borderInset,
      capsuleMargin + borderInset,
      size.width - ((capsuleMargin + borderInset) * 2),
      size.height - ((capsuleMargin + borderInset) * 2),
    );
    final radius = rect.width / 2;
    final verticalLength = math.max(0.0, rect.height - (2 * radius));
    final perimeter = (2 * verticalLength) + (2 * math.pi * radius);
    final radiusForCount = dotCount > 60
        ? math.min(beadRadius, 1.55)
        : beadRadius;

    for (var index = 0; index < dotCount; index++) {
      final distance = dotCount == 1 ? 0.0 : perimeter * index / dotCount;
      final center = _pointOnCapsule(rect, radius, verticalLength, distance);
      final isActive = index < highlightedCount;

      final dotPaint = Paint()
        ..color = isActive ? activeColor : _inactiveColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radiusForCount, dotPaint);
    }
  }

  int _highlightedDots(int current, int target) {
    if (target <= 0 || current <= 0) {
      return 0;
    }

    return current.clamp(0, target);
  }

  Offset _pointOnCapsule(
    Rect rect,
    double radius,
    double verticalLength,
    double distance,
  ) {
    final left = rect.left;
    final right = rect.right;
    final top = rect.top;
    final bottom = rect.bottom;
    final centerX = rect.center.dx;
    final topCenterY = top + radius;
    final bottomCenterY = bottom - radius;
    final arcLength = math.pi * radius;

    if (distance <= verticalLength) {
      return Offset(left, bottomCenterY - distance);
    }

    var remaining = distance - verticalLength;
    if (remaining <= arcLength) {
      final theta = math.pi - (remaining / radius);
      return Offset(
        centerX + (radius * math.cos(theta)),
        topCenterY - (radius * math.sin(theta)),
      );
    }

    remaining -= arcLength;
    if (remaining <= verticalLength) {
      return Offset(right, topCenterY + remaining);
    }

    remaining -= verticalLength;
    final theta = remaining / radius;
    return Offset(
      centerX + (radius * math.cos(theta)),
      bottomCenterY + (radius * math.sin(theta)),
    );
  }

  @override
  bool shouldRepaint(covariant _TasbeehBeadsPainter oldDelegate) {
    return oldDelegate.currentCount != currentCount ||
        oldDelegate.targetCount != targetCount ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.beadRadius != beadRadius;
  }
}
