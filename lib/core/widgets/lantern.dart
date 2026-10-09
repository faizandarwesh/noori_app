import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../i18n/app_lang.dart';
import '../theme/app_theme.dart';

/// Noori's lantern: glows brighter the more fireflies it holds, with a few
/// fireflies flitting inside. The count bounces whenever it changes.
class Lantern extends StatefulWidget {
  const Lantern({
    super.key,
    required this.count,
    this.size = AppSizes.lantern,
    this.showCount = true,
  });

  final int count;
  final double size;

  /// False shows just the glowing lantern, brighter as [count] grows.
  final bool showCount;

  @override
  State<Lantern> createState() => _LanternState();
}

/// How brightly a lantern holding [count] fireflies glows, 0.25 to 1.
double glowFor(int count) => (0.25 + count / 40).clamp(0.25, 1.0);

class _LanternState extends State<Lantern> with SingleTickerProviderStateMixin {
  late final AnimationController _flit = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _flit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final glow = glowFor(widget.count);
    return Semantics(
      label: 'Fireflies: ${widget.count}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              size: Size(widget.size * 0.78, widget.size),
              painter: _LanternPainter(_flit, glow: glow),
            ),
          ),
          if (widget.showCount) ...[
            const SizedBox(width: AppSizes.space1),
            Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.space3,
                    vertical: AppSizes.space1,
                  ),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    boxShadow: const [
                      BoxShadow(
                        color: AppPalette.shadow,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    '${widget.count}',
                    style: AppTypography.style(
                      AppLang.en,
                      role: TextRole.label,
                      color: c.onSurface,
                      weight: 700,
                    ),
                  ),
                )
                // Re-keyed on every change so the bump replays.
                .animate(key: ValueKey(widget.count))
                .scaleXY(
                  begin: 1.4,
                  end: 1,
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),
          ],
        ],
      ),
    );
  }
}

class _LanternPainter extends CustomPainter {
  _LanternPainter(this.anim, {required this.glow}) : super(repaint: anim);

  final Animation<double> anim;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final metal = Paint()..color = AppPalette.trunk;
    final t = anim.value * math.pi * 2;

    // Soft halo.
    canvas.drawCircle(
      Offset(w / 2, h * 0.6),
      w * (0.75 + 0.05 * math.sin(t * 2)),
      Paint()..color = AppPalette.fireflyGlow.withValues(alpha: 0.25 * glow),
    );
    // Handle and cap.
    canvas
      ..drawArc(
        Rect.fromLTWH(w * 0.3, 0, w * 0.4, h * 0.3),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = AppPalette.trunk
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.18, h * 0.14, w * 0.64, h * 0.12),
          const Radius.circular(4),
        ),
        metal,
      );
    // Glass.
    final glass = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.26, w * 0.76, h * 0.62),
      Radius.circular(w * 0.22),
    );
    canvas.drawRRect(
      glass,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(AppPalette.cream, AppPalette.firefly, glow)!,
            Color.lerp(
              AppPalette.cream,
              AppPalette.fireflyGlow,
              glow,
            )!.withValues(alpha: 0.9),
          ],
        ).createShader(glass.outerRect),
    );
    // Fireflies inside.
    for (var i = 0; i < 3; i++) {
      final a = t + i * 2.1;
      final p = Offset(
        w / 2 + math.sin(a * (1 + i * 0.3)) * w * 0.2,
        h * 0.57 + math.cos(a * (1.3 + i * 0.2)) * h * 0.16,
      );
      canvas
        ..drawCircle(
          p,
          4.5,
          Paint()..color = AppPalette.white.withValues(alpha: 0.5),
        )
        ..drawCircle(p, 2.2, Paint()..color = AppPalette.coral);
    }
    // Base.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.2, h * 0.86, w * 0.6, h * 0.1),
        const Radius.circular(4),
      ),
      metal,
    );
  }

  @override
  bool shouldRepaint(_LanternPainter old) => old.glow != glow;
}
