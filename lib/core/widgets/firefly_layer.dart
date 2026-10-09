import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/app_theme.dart';

/// Softly drifting, twinkling fireflies. Decorative and non-interactive;
/// one ticker and one painter for the whole swarm.
class FireflyLayer extends StatefulWidget {
  const FireflyLayer({
    super.key,
    this.count = 14,
    this.seed = 7,
    this.maxRadius = 4,
  });

  final int count;
  final int seed;
  final double maxRadius;

  @override
  State<FireflyLayer> createState() => _FireflyLayerState();
}

class _Firefly {
  _Firefly(math.Random r, double maxRadius)
    : x = r.nextDouble(),
      y = r.nextDouble(),
      radius = maxRadius * (0.55 + r.nextDouble() * 0.45),
      speed = 0.15 + r.nextDouble() * 0.25,
      phase = r.nextDouble() * math.pi * 2,
      twinkle = 1.2 + r.nextDouble() * 1.8,
      wanderX = 0.03 + r.nextDouble() * 0.05,
      wanderY = 0.02 + r.nextDouble() * 0.04;

  final double x, y, radius, speed, phase, twinkle, wanderX, wanderY;
}

class _FireflyLayerState extends State<FireflyLayer>
    with SingleTickerProviderStateMixin {
  final _time = ValueNotifier<double>(0);
  late List<_Firefly> _flies;
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _seed();
    _ticker = createTicker((e) => _time.value = e.inMicroseconds / 1e6)
      ..start();
  }

  @override
  void didUpdateWidget(FireflyLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count || oldWidget.seed != widget.seed) {
      _seed();
    }
  }

  void _seed() {
    final r = math.Random(widget.seed);
    _flies = List.generate(widget.count, (_) => _Firefly(r, widget.maxRadius));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _FireflyPainter(_flies, _time),
        ),
      ),
    );
  }
}

class _FireflyPainter extends CustomPainter {
  _FireflyPainter(this.flies, this.time) : super(repaint: time);

  final List<_Firefly> flies;
  final ValueNotifier<double> time;

  final _glow = Paint();
  final _core = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    for (final f in flies) {
      final a = t * f.speed + f.phase;
      final dx =
          (f.x + math.sin(a) * f.wanderX + math.sin(a * 0.37) * f.wanderX) %
          1.0;
      final dy =
          (f.y + math.cos(a * 0.8) * f.wanderY - t * 0.004 * f.speed) % 1.0;
      final p = Offset(dx * size.width, dy * size.height);
      final glow = (math.sin(t * f.twinkle + f.phase) * 0.5 + 0.5);
      _glow.color = AppPalette.fireflyGlow.withValues(
        alpha: 0.10 + 0.22 * glow,
      );
      _core.color = AppPalette.firefly.withValues(alpha: 0.55 + 0.45 * glow);
      canvas
        ..drawCircle(p, f.radius * (2.6 + glow), _glow)
        ..drawCircle(p, f.radius * (0.7 + 0.3 * glow), _core);
    }
  }

  @override
  bool shouldRepaint(_FireflyPainter old) => old.flies != flies;
}
