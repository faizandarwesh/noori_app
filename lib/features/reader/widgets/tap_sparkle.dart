import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// A little burst of firefly sparks where a child tapped empty scenery, so
/// every tap answers with something. Calls [onDone] when it has faded.
class TapSparkle extends StatefulWidget {
  const TapSparkle({super.key, required this.at, required this.onDone});

  final Offset at;
  final VoidCallback onDone;

  static const size = 120.0;

  @override
  State<TapSparkle> createState() => _TapSparkleState();
}

class _TapSparkleState extends State<TapSparkle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const s = TapSparkle.size;
    return Positioned(
      left: widget.at.dx - s / 2,
      top: widget.at.dy - s / 2,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            size: const Size.square(s),
            painter: _SparkPainter(_c),
          ),
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.anim) : super(repaint: anim);

  final Animation<double> anim;
  static const _sparks = 8;

  final _glow = Paint();
  final _core = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOutCubic.transform(anim.value);
    final fade = 1 - anim.value;
    final c = size.center(Offset.zero);
    final reach = size.width * 0.42;
    for (var i = 0; i < _sparks; i++) {
      final a = i / _sparks * math.pi * 2 + 0.3;
      final p = c + Offset(math.cos(a), math.sin(a)) * reach * t;
      final r = 2.2 + 2.6 * (1 - t);
      _glow.color = AppPalette.fireflyGlow.withValues(alpha: 0.4 * fade);
      _core.color = AppPalette.firefly.withValues(alpha: fade);
      canvas
        ..drawCircle(p, r * 2.6, _glow)
        ..drawCircle(p, r, _core);
    }
    // A soft ring where the finger landed.
    canvas.drawCircle(
      c,
      reach * 0.5 * t,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppPalette.white.withValues(alpha: 0.6 * fade),
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) => false;
}
