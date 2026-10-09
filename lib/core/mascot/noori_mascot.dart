import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../progress/wardrobe.dart';
import '../theme/app_theme.dart';
import 'noori_outfit.dart';
import 'noori_painter.dart';
import 'noori_pose.dart';

export 'noori_pose.dart' show NooriState;

/// Noori the owl. Drawn in code; one ticker drives every part.
///
/// Tapping Noori makes her hop happily for a moment, then she returns to
/// [state]. She wears her wardrobe outfit unless [outfit] is given.
class NooriMascot extends ConsumerStatefulWidget {
  const NooriMascot({
    super.key,
    this.state = NooriState.idle,
    this.size = AppSizes.mascotMd,
    this.pointLeft = false,
    this.look = 0,
    this.outfit,
    this.onTap,
  });

  final NooriState state;
  final double size;

  /// In [NooriState.pointing], which wing points.
  final bool pointLeft;

  /// Where she looks, -1 (left) to 1 (right); eased, so it can change
  /// every frame.
  final double look;

  /// Overrides the outfit, e.g. to preview one in the wardrobe.
  final NooriOutfit? outfit;
  final VoidCallback? onTap;

  @override
  ConsumerState<NooriMascot> createState() => _NooriMascotState();
}

class _NooriMascotState extends ConsumerState<NooriMascot>
    with SingleTickerProviderStateMixin {
  final _pose = NooriPose();
  late final _driver = NooriPoseDriver(_pose);
  late final Ticker _ticker;
  Timer? _tapJoy;

  @override
  void initState() {
    super.initState();
    _syncDriver();
    _ticker = createTicker(
      (elapsed) => _driver.tick(elapsed.inMicroseconds / 1e6),
    )..start();
  }

  @override
  void didUpdateWidget(NooriMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _driver.look = widget.look;
    if (_tapJoy == null) _syncDriver();
  }

  void _syncDriver() {
    _driver
      ..state = widget.state
      ..pointLeft = widget.pointLeft
      ..look = widget.look;
  }

  void _handleTap() {
    widget.onTap?.call();
    _tapJoy?.cancel();
    _driver.state = NooriState.happy;
    _tapJoy = Timer(const Duration(milliseconds: 1300), () {
      _tapJoy = null;
      if (mounted) _syncDriver();
    });
  }

  @override
  void dispose() {
    _tapJoy?.cancel();
    _ticker.dispose();
    _pose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.size * NooriPainter.designH / NooriPainter.designW;
    return Semantics(
      label: 'Noori',
      button: widget.onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size(widget.size, height),
            painter: NooriPainter(
              _pose,
              outfit: widget.outfit ?? ref.watch(nooriOutfitProvider),
            ),
          ),
        ),
      ),
    );
  }
}
