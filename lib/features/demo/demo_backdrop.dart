import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/parallax_scene.dart';

/// Simple layered jungle used to exercise [ParallaxScene] in the demo.
List<ParallaxLayer> demoJungleLayers(
  BuildContext context, {
  required bool night,
}) {
  final c = context.colors;
  Color tint(Color base) =>
      night ? Color.lerp(base, AppPalette.navy, 0.6)! : base;
  return [
    ParallaxLayer(
      depth: 0,
      drift: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.skyTop, c.skyBottom],
          ),
        ),
      ),
    ),
    ParallaxLayer(
      depth: 0.3,
      drift: 14,
      child: CustomPaint(
        painter: _HillsPainter(tint(AppPalette.leafLight), top: 0.55, seed: 1),
      ),
    ),
    ParallaxLayer(
      depth: 0.6,
      drift: 16,
      child: CustomPaint(
        painter: _HillsPainter(tint(AppPalette.leafMid), top: 0.7, seed: 2),
      ),
    ),
    ParallaxLayer(
      depth: 1,
      drift: 18,
      bob: 4,
      child: CustomPaint(painter: _LeavesPainter(tint(AppPalette.leafDark))),
    ),
  ];
}

class _HillsPainter extends CustomPainter {
  _HillsPainter(this.color, {required this.top, required this.seed});

  final Color color;
  final double top;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(seed);
    final baseY = size.height * top;
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, baseY);
    var x = 0.0;
    while (x < size.width) {
      final w = size.width * (0.18 + r.nextDouble() * 0.16);
      final h = size.height * (0.04 + r.nextDouble() * 0.06);
      path.quadraticBezierTo(x + w / 2, baseY - h * 2, x + w, baseY);
      x += w;
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_HillsPainter old) => old.color != color;
}

class _LeavesPainter extends CustomPainter {
  _LeavesPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    void leaf(Offset base, double angle, double len) {
      canvas
        ..save()
        ..translate(base.dx, base.dy)
        ..rotate(angle)
        ..drawPath(
          Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(len * 0.35, -len * 0.5, 0, -len)
            ..quadraticBezierTo(-len * 0.35, -len * 0.5, 0, 0),
          paint,
        )
        ..restore();
    }

    final h = size.height;
    for (final (x, a, l) in const [
      (0.02, 0.5, 0.22),
      (0.08, 0.1, 0.18),
      (0.14, 0.9, 0.16),
      (0.9, -0.5, 0.22),
      (0.96, -0.1, 0.18),
      (0.84, -0.9, 0.15),
    ]) {
      leaf(Offset(size.width * x, h + 10), a, h * l);
    }
  }

  @override
  bool shouldRepaint(_LeavesPainter old) => old.color != color;
}
