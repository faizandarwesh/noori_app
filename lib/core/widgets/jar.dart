import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Glass jar with a cork lid. [interiorOf] gives the space inside the glass,
/// where the Word Jar lays out its cards.
class JarPainter extends CustomPainter {
  const JarPainter({this.glow = 0});

  /// 0–1: a warm glow inside (more words, more glow).
  final double glow;

  static Rect interiorOf(Size s) => Rect.fromLTRB(
    s.width * 0.12,
    s.height * 0.2,
    s.width * 0.88,
    s.height * 0.94,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = RRect.fromRectAndCorners(
      Rect.fromLTRB(w * 0.06, h * 0.16, w * 0.94, h),
      topLeft: Radius.circular(w * 0.16),
      topRight: Radius.circular(w * 0.16),
      bottomLeft: Radius.circular(w * 0.2),
      bottomRight: Radius.circular(w * 0.2),
    );
    final neck = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.2, h * 0.08, w * 0.8, h * 0.19),
      Radius.circular(w * 0.05),
    );

    // Glass.
    final glass = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          AppPalette.sky.withValues(alpha: 0.35),
          AppPalette.white.withValues(alpha: 0.22),
          AppPalette.sky.withValues(alpha: 0.4),
        ],
      ).createShader(body.outerRect);
    canvas
      ..drawRRect(body, glass)
      ..drawRRect(neck, glass);
    if (glow > 0) {
      canvas.drawRRect(
        body.deflate(w * 0.04),
        Paint()
          ..shader = RadialGradient(
            colors: [
              AppPalette.fireflyGlow.withValues(alpha: 0.35 * glow),
              AppPalette.fireflyGlow.withValues(alpha: 0),
            ],
          ).createShader(body.outerRect),
      );
    }
    final rim = Paint()
      ..color = AppPalette.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.025).clamp(1.5, 3);
    canvas
      ..drawRRect(body, rim)
      ..drawRRect(neck, rim);
    // Shine.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.14, h * 0.28, w * 0.06, h * 0.5),
        Radius.circular(w * 0.03),
      ),
      Paint()..color = AppPalette.white.withValues(alpha: 0.55),
    );
    // Cork lid.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.16, 0, w * 0.84, h * 0.1),
        Radius.circular(w * 0.05),
      ),
      Paint()..color = AppPalette.trunk,
    );
  }

  @override
  bool shouldRepaint(JarPainter old) => old.glow != glow;
}

/// A small jar, for buttons and as a flight target.
class JarIcon extends StatelessWidget {
  const JarIcon({super.key, this.size = AppSizes.iconLg, this.glow = 0.6});

  final double size;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 0.8, size),
      painter: JarPainter(glow: glow),
    );
  }
}
