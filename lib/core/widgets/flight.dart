import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Global centre of the widget holding [key], or null if it isn't laid out.
Offset? centerOf(GlobalKey key) {
  final box = key.currentContext?.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize || !box.attached) return null;
  return box.localToGlobal(box.size.center(Offset.zero));
}

/// Flies [flier] from [from] (global) to the widget holding [to] along a
/// gentle arc, above everything else. With [trail], a firefly glow streaks
/// behind it. Completes when it lands.
Future<void> launchFlight(
  BuildContext context, {
  required Offset from,
  required GlobalKey to,
  required Widget flier,
  Duration duration = const Duration(milliseconds: 950),
  bool trail = false,
  double endScale = 0.4,
}) {
  final target = centerOf(to);
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (target == null || overlay == null) return Future.value();
  final done = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Flight(
      from: from,
      to: target,
      flier: flier,
      duration: duration,
      trail: trail,
      endScale: endScale,
      onDone: () {
        entry.remove();
        if (!done.isCompleted) done.complete();
      },
    ),
  );
  overlay.insert(entry);
  return done.future;
}

/// A single glowing firefly, for [launchFlight].
class FireflyDot extends StatelessWidget {
  const FireflyDot({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppPalette.white,
            AppPalette.firefly,
            AppPalette.fireflyGlow.withValues(alpha: 0),
          ],
          stops: const [0, 0.35, 1],
        ),
      ),
    );
  }
}

class _Flight extends StatefulWidget {
  const _Flight({
    required this.from,
    required this.to,
    required this.flier,
    required this.duration,
    required this.trail,
    required this.endScale,
    required this.onDone,
  });

  final Offset from, to;
  final Widget flier;
  final Duration duration;
  final bool trail;
  final double endScale;
  final VoidCallback onDone;

  @override
  State<_Flight> createState() => _FlightState();
}

class _FlightState extends State<_Flight> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward().whenComplete(widget.onDone);

  // Arc control point: off to the side of the straight line, bowing upward.
  late final Offset _control = () {
    final mid = (widget.from + widget.to) / 2;
    final d = widget.to - widget.from;
    var n = Offset(-d.dy, d.dx) * 0.35;
    if (n.dy > 0) n = -n;
    return mid + n;
  }();

  Offset _at(double t) {
    final u = 1 - t;
    return widget.from * (u * u) + _control * (2 * u * t) + widget.to * (t * t);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = Curves.easeInOutCubic.transform(_c.value);
          final p = _at(t);
          final scale = lerpDouble(
            1,
            widget.endScale,
            Curves.easeIn.transform(_c.value),
          )!;
          return Stack(
            children: [
              if (widget.trail)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TrailPainter([
                      for (var k = 1; k <= 10; k++)
                        _at((t - k * 0.035).clamp(0, 1)),
                    ]),
                  ),
                ),
              Positioned(
                left: p.dx,
                top: p.dy,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: Transform.scale(scale: scale, child: child),
                ),
              ),
            ],
          );
        },
        child: widget.flier,
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < points.length; i++) {
      final f = 1 - i / points.length;
      canvas.drawCircle(
        points[i],
        2 + 6 * f,
        Paint()..color = AppPalette.fireflyGlow.withValues(alpha: 0.5 * f),
      );
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) => true;
}
