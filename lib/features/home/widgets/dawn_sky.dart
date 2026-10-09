import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Home's living sky: a gradient that drifts slowly through dawn colours
/// (or night ones at bedtime), a soft rising-sun glow and puffy clouds
/// sailing across. One painter, one layer, repainted by a single clock.
class DawnSky extends StatefulWidget {
  const DawnSky({super.key, this.night = false});

  final bool night;

  @override
  State<DawnSky> createState() => _DawnSkyState();
}

class _DawnSkyState extends State<DawnSky> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: AppMotion.skyCycle,
  )..repeat();

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _SkyPainter(_clock, night: widget.night),
      ),
    );
  }
}

class _Cloud {
  const _Cloud(this.y, this.scale, this.speed, this.phase);

  /// Height as a fraction of the screen, size multiplier, laps per cycle.
  final double y, scale;
  final int speed;
  final double phase;
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.clock, {required this.night}) : super(repaint: clock);

  final Animation<double> clock;
  final bool night;

  static const _clouds = [
    _Cloud(0.12, 1.1, 1, 0.1),
    _Cloud(0.24, 0.7, 2, 0.55),
    _Cloud(0.07, 0.55, 2, 0.8),
    _Cloud(0.86, 1.4, 1, 0.35),
  ];

  final _paint = Paint();
  final _cloudPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    final sets = night ? SkyPalette.night : SkyPalette.dawn;

    // Blend between neighbouring palettes with a smooth step.
    final pos = t * sets.length;
    final i = pos.floor() % sets.length;
    final f = pos - pos.floor();
    final k = f * f * (3 - 2 * f);
    final a = sets[i], b = sets[(i + 1) % sets.length];
    final colors = [for (var c = 0; c < 3; c++) Color.lerp(a[c], b[c], k)!];

    final rect = Offset.zero & size;
    _paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
      stops: const [0, 0.58, 1],
    ).createShader(rect);
    canvas.drawRect(rect, _paint);

    // A sun (or moon) glow low on the horizon, breathing gently.
    final glowCentre = Offset(size.width * 0.72, size.height * 0.78);
    final breath = 0.85 + 0.15 * math.sin(t * math.pi * 2 * 3);
    final glowColor = night ? AppPalette.moonCream : AppPalette.sunshine;
    _paint.shader =
        RadialGradient(
          colors: [
            glowColor.withValues(alpha: (night ? 0.22 : 0.45) * breath),
            glowColor.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(center: glowCentre, radius: size.width * 0.8),
        );
    canvas.drawCircle(glowCentre, size.width * 0.8, _paint);
    _paint.shader = null;

    // Clouds drift right to left and wrap around.
    _cloudPaint.color = night ? SkyPalette.cloudNight : SkyPalette.cloudDay;
    final unit = size.width * 0.12;
    for (final c in _clouds) {
      final span = size.width + unit * 6 * c.scale;
      final x = (1 - ((t * c.speed + c.phase) % 1)) * span - unit * 3 * c.scale;
      _drawCloud(canvas, Offset(x, size.height * c.y), unit * c.scale);
    }
  }

  void _drawCloud(Canvas canvas, Offset at, double u) {
    canvas
      ..drawCircle(at + Offset(-u * 0.9, u * 0.2), u * 0.6, _cloudPaint)
      ..drawCircle(at + Offset(-u * 0.2, -u * 0.15), u * 0.85, _cloudPaint)
      ..drawCircle(at + Offset(u * 0.7, u * 0.1), u * 0.65, _cloudPaint)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            at.dx - u * 1.4,
            at.dy,
            at.dx + u * 1.3,
            at.dy + u * 0.7,
          ),
          Radius.circular(u * 0.35),
        ),
        _cloudPaint,
      );
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.night != night;
}
