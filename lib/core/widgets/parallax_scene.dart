import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// One layer of a [ParallaxScene].
class ParallaxLayer {
  const ParallaxLayer({
    required this.child,
    required this.depth,
    this.drift = 12,
    this.bob = 0,
    this.fitViewport = false,
  });

  final Widget child;

  /// 0 = far away (moves least), 1 = nearest (moves most).
  final double depth;

  /// Horizontal idle drift, in logical pixels, at full depth.
  final double drift;

  /// Vertical idle sway, in logical pixels.
  final double bob;

  /// Lay the child out in the visible area instead of the overscanned one,
  /// so fractional positions inside it map exactly to the screen.
  final bool fitViewport;
}

/// Stacked layers that drift slowly on their own and shift by depth with
/// [offset] (e.g. while swiping pages). Each layer is a repaint boundary, so
/// moving it only re-composites.
class ParallaxScene extends StatefulWidget {
  const ParallaxScene({
    super.key,
    required this.layers,
    this.offset = 0,
    this.offsetListenable,
    this.period = const Duration(seconds: 18),
    this.overscan = 48,
  });

  final List<ParallaxLayer> layers;

  /// Extra shift from -1 to 1, scaled by each layer's depth.
  final double offset;

  /// A changing extra shift (e.g. a carousel swipe); added to [offset]
  /// without rebuilding the layers.
  final ValueListenable<double>? offsetListenable;
  final Duration period;

  /// How far layers extend past the edges so drift never shows a gap.
  final double overscan;

  @override
  State<ParallaxScene> createState() => _ParallaxSceneState();
}

class _ParallaxSceneState extends State<ParallaxScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [for (final layer in widget.layers) _layer(layer)],
        ),
      ),
    );
  }

  Widget _layer(ParallaxLayer layer) {
    final o = widget.overscan;
    return Positioned(
      left: -o,
      right: -o,
      top: -o * 0.5,
      bottom: -o * 0.5,
      child: AnimatedBuilder(
        animation: widget.offsetListenable == null
            ? _clock
            : Listenable.merge([_clock, widget.offsetListenable]),
        builder: (context, child) {
          final offset = widget.offset + (widget.offsetListenable?.value ?? 0);
          // One shared phase: layers at equal depth move together, so
          // characters stay planted on the ground they stand on.
          final a = _clock.value * math.pi * 2;
          final dx =
              math.sin(a) * layer.drift * layer.depth +
              offset * o * layer.depth;
          final dy = math.cos(a * 2) * layer.bob;
          return Transform.translate(offset: Offset(dx, dy), child: child);
        },
        child: RepaintBoundary(
          child: layer.fitViewport
              ? Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: o,
                    vertical: o * 0.5,
                  ),
                  child: layer.child,
                )
              : layer.child,
        ),
      ),
    );
  }
}
