import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// A slow Ken Burns shot over [child]: a gentle zoom with a drift, lasting
/// 6–10 seconds. [shot] picks one of several framings so consecutive scenes
/// don't move alike. Shot 0 starts unzoomed, so a hero flight lands on the
/// exact frame. Pausing holds the camera still.
class KenBurns extends StatefulWidget {
  const KenBurns({
    super.key,
    required this.child,
    required this.shot,
    this.paused = false,
  });

  final Widget child;
  final int shot;
  final bool paused;

  @override
  State<KenBurns> createState() => _KenBurnsState();
}

class _KenBurnsState extends State<KenBurns>
    with SingleTickerProviderStateMixin {
  // (zoom from, zoom to, focus from, focus to)
  static const _shots = [
    (0.0, 1.0, Alignment(-0.3, 0.2), Alignment(0.3, 0.3)),
    (0.2, 1.0, Alignment(0.4, 0.1), Alignment(-0.2, 0.4)),
    (1.0, 0.15, Alignment(0, 0.6), Alignment(0, 0)),
    (0.1, 0.9, Alignment(0.2, -0.2), Alignment(-0.3, 0.5)),
  ];

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _length,
  );

  Duration get _length {
    final span = AppMotion.kenBurnsMax - AppMotion.kenBurnsMin;
    return AppMotion.kenBurnsMin + span * ((widget.shot * 0.37) % 1);
  }

  @override
  void initState() {
    super.initState();
    if (!widget.paused) _c.forward();
  }

  @override
  void didUpdateWidget(KenBurns oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paused != oldWidget.paused) {
      widget.paused ? _c.stop() : _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (z0, z1, f0, f1) = _shots[widget.shot % _shots.length];
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeInOutSine.transform(_c.value);
        final zoom = 1 + AppSizes.kenBurnsZoom * (z0 + (z1 - z0) * t);
        // Scaling about a point inside the frame always keeps it covered.
        return Transform.scale(
          scale: zoom,
          alignment: Alignment.lerp(f0, f1, t)!,
          child: child,
        );
      },
      child: RepaintBoundary(child: widget.child),
    );
  }
}

/// How the camera gets from one scene to the next.
enum SceneMove {
  /// A soft dissolve with a slight settle.
  dissolve,

  /// The camera pans on: the old scene slides out, the new one in.
  panForward,
  panBack,
}

/// Switches scenes like a film cut: a crossfade or a camera move, never a
/// page curl. Both scenes are repaint boundaries, so the move only
/// re-composites.
class SceneCut extends StatelessWidget {
  const SceneCut({
    super.key,
    required this.sceneKey,
    required this.move,
    required this.child,
    this.rtl = false,
  });

  final Key sceneKey;
  final SceneMove move;
  final Widget child;

  /// Right-to-left stories pan the other way.
  final bool rtl;

  @override
  Widget build(BuildContext context) {
    final dir =
        switch (move) {
          SceneMove.dissolve => 0.0,
          SceneMove.panForward => 1.0,
          SceneMove.panBack => -1.0,
        } *
        (rtl ? -1 : 1);
    return AnimatedSwitcher(
      duration: AppMotion.sceneChange,
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      transitionBuilder: (child, anim) {
        final incoming = child.key == sceneKey;
        final eased = CurvedAnimation(
          parent: anim,
          curve: Curves.easeInOutCubic,
        );
        if (dir == 0) {
          // Dissolve: the new scene fades in over the old, settling from a
          // touch closer.
          return incoming
              ? FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: Tween(begin: 1.06, end: 1.0).animate(eased),
                    child: child,
                  ),
                )
              : child;
        }
        // Pan: old scene leaves one way while the new one arrives.
        final slide = Tween(
          begin: incoming ? Offset(0.35 * dir, 0) : Offset(-0.35 * dir, 0),
          end: Offset.zero,
        ).animate(eased);
        final widgetOut = SlideTransition(position: slide, child: child);
        return incoming
            ? FadeTransition(
                opacity: CurvedAnimation(
                  parent: anim,
                  curve: const Interval(0, 0.7, curve: Curves.easeOut),
                ),
                child: widgetOut,
              )
            : widgetOut;
      },
      child: KeyedSubtree(
        key: sceneKey,
        child: RepaintBoundary(child: child),
      ),
    );
  }
}
