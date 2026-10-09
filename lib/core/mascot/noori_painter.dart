import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../theme/app_colors.dart';
import 'noori_outfit.dart';
import 'noori_pose.dart';

/// Draws Noori from primitive shapes in a 200x230 design box.
/// Each part reads its own value from [NooriPose], so parts move separately.
class NooriPainter extends CustomPainter {
  NooriPainter(this.pose, {this.outfit = const NooriOutfit()})
    : super(repaint: pose);

  final NooriPose pose;

  /// Her scarf colour and hat, from the wardrobe.
  final NooriOutfit outfit;

  static const designW = 200.0;
  static const designH = 230.0;
  static const _groundY = 222.0;

  // Anatomy anchors.
  static const _headC = Offset(100, 86);
  static const _headR = 56.0;
  static const _neck = Offset(100, 128);
  static const _bodyRect = Rect.fromLTWH(36, 92, 128, 116);
  static const _bellyRect = Rect.fromLTWH(62, 128, 76, 70);
  static const _leftEye = Offset(77, 88);
  static const _rightEye = Offset(123, 88);
  static const _eyeR = 21.0;
  static const _leftShoulder = Offset(44, 128);
  static const _rightShoulder = Offset(156, 128);

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / designW, size.height / designH);
    canvas
      ..save()
      ..translate(
        (size.width - designW * s) / 2,
        (size.height - designH * s) / 2,
      )
      ..scale(s);

    _groundShadow(canvas);

    canvas
      ..save()
      ..translate(0, pose.bob - pose.jump);

    _feet(canvas);

    // Body breathes around the feet.
    _withBreath(canvas, () {
      _body(canvas);
      _belly(canvas);
      _wing(canvas, _leftShoulder, pose.leftWing, mirror: false);
      _wing(canvas, _rightShoulder, -pose.rightWing, mirror: true);
    });

    // Head tilts around the neck.
    canvas
      ..save()
      ..translate(_neck.dx, _neck.dy)
      ..rotate(pose.tilt)
      ..translate(-_neck.dx, -_neck.dy);
    _head(canvas);
    _eye(canvas, _leftEye);
    _eye(canvas, _rightEye);
    _cheeks(canvas);
    _beak(canvas);
    _hat(canvas);
    canvas.restore();

    // The scarf sits over the bottom of the head.
    _withBreath(canvas, () => _scarf(canvas));

    _thinkDots(canvas);
    _sparkles(canvas);
    _zzz(canvas);

    canvas
      ..restore()
      ..restore();
  }

  void _withBreath(Canvas canvas, VoidCallback draw) {
    canvas
      ..save()
      ..translate(100, 205)
      ..scale(1 + pose.breath, 1 - pose.breath)
      ..translate(-100, -205);
    draw();
    canvas.restore();
  }

  void _groundShadow(Canvas canvas) {
    final lift = (pose.jump / 24).clamp(0.0, 1.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(100, _groundY),
        width: 96 * (1 - lift * 0.35),
        height: 12 * (1 - lift * 0.35),
      ),
      Paint()..color = NooriPalette.groundShadow,
    );
  }

  void _feet(Canvas canvas) {
    final paint = Paint()..color = NooriPalette.feet;
    for (final x in const [84.0, 116.0]) {
      for (final dx in const [-6.0, 0.0, 6.0]) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x + dx, 208), width: 9, height: 12),
          paint,
        );
      }
    }
  }

  Paint _featherGradient(Rect r) => Paint()
    ..shader = const RadialGradient(
      center: Alignment(-0.4, -0.5),
      radius: 1.0,
      colors: [
        NooriPalette.bodyLight,
        NooriPalette.body,
        NooriPalette.bodyDark,
      ],
      stops: [0.0, 0.55, 1.0],
    ).createShader(r);

  void _body(Canvas canvas) {
    canvas.drawOval(_bodyRect, _featherGradient(_bodyRect));
  }

  void _belly(Canvas canvas) {
    canvas.drawOval(_bellyRect, Paint()..color = NooriPalette.belly);
    canvas
      ..save()
      ..clipPath(Path()..addOval(_bellyRect.deflate(4)));
    final scallop = Paint()
      ..color = NooriPalette.bellyScallop
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (var row = 0; row < 3; row++) {
      final y = 150.0 + row * 14;
      final shift = row.isOdd ? 6.0 : 0.0;
      for (var x = 66.0 + shift; x < 136; x += 12) {
        canvas.drawArc(
          Rect.fromCenter(center: Offset(x, y), width: 10, height: 8),
          0.2,
          math.pi - 0.4,
          false,
          scallop,
        );
      }
    }
    canvas.restore();
  }

  void _wing(
    Canvas canvas,
    Offset pivot,
    double angle, {
    required bool mirror,
  }) {
    canvas
      ..save()
      ..translate(pivot.dx, pivot.dy)
      ..rotate(angle);
    const len = 58.0;
    final w = mirror ? -1.0 : 1.0;
    final path = Path()
      ..moveTo(0, -4)
      ..quadraticBezierTo(-16 * w, 18, -4 * w, len)
      ..quadraticBezierTo(4 * w, len + 2, 10 * w, len - 8)
      ..quadraticBezierTo(16 * w, 20, 0, -4)
      ..close();
    final bounds = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [NooriPalette.body, NooriPalette.bodyDark],
        ).createShader(bounds),
    );
    final feather = Paint()
      ..color = NooriPalette.bodyLight.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final y in const [34.0, 42.0, 50.0]) {
      canvas.drawLine(Offset(-6 * w, y), Offset(6 * w, y - 4), feather);
    }
    canvas.restore();
  }

  void _scarf(Canvas canvas) {
    final band = Path()
      ..moveTo(52, 118)
      ..quadraticBezierTo(100, 140, 148, 118)
      ..lineTo(150, 131)
      ..quadraticBezierTo(100, 156, 50, 131)
      ..close();
    final scarf = outfit.scarf;
    final paint = Paint()..color = scarf.color;
    if (scarf.isRainbow) {
      paint.shader = const LinearGradient(colors: NooriPalette.rainbow)
          .createShader(const Rect.fromLTWH(50, 118, 100, 40));
    }
    canvas.drawPath(band, paint);
    canvas.drawPath(
      Path()
        ..moveTo(56, 126)
        ..quadraticBezierTo(100, 148, 144, 126),
      Paint()
        ..color = scarf.stripe
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Tail sways.
    canvas
      ..save()
      ..translate(128, 138)
      ..rotate(pose.scarfSway);
    final tail = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-8, -2, 18, 42),
      const Radius.circular(7),
    );
    if (scarf.isRainbow) {
      paint.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: NooriPalette.rainbow,
      ).createShader(tail.outerRect);
    }
    canvas.drawRRect(tail, paint);
    final stripe = Paint()..color = scarf.stripe;
    canvas
      ..drawRect(const Rect.fromLTWH(-8, 16, 18, 4), stripe)
      ..drawRect(const Rect.fromLTWH(-8, 27, 18, 4), stripe);
    canvas.restore();
  }

  /// The hat sits on top of her head, between the ear tufts, and tilts
  /// with it.
  void _hat(Canvas canvas) => paintHat(canvas, outfit.hat);

  /// Draws [hat] in Noori's 200x230 design space (it sits around x 70–130,
  /// y 0–45), so the wardrobe can show hats on their own.
  static void paintHat(Canvas canvas, NooriHat hat) {
    switch (hat) {
      case NooriHat.none:
        return;
      case NooriHat.bow:
        final bow = Paint()..color = NooriPalette.bow;
        canvas
          ..drawPath(
            Path()
              ..moveTo(100, 34)
              ..quadraticBezierTo(78, 14, 74, 30)
              ..quadraticBezierTo(76, 46, 100, 34)
              ..close(),
            bow,
          )
          ..drawPath(
            Path()
              ..moveTo(100, 34)
              ..quadraticBezierTo(122, 14, 126, 30)
              ..quadraticBezierTo(124, 46, 100, 34)
              ..close(),
            bow,
          )
          ..drawCircle(
            const Offset(100, 34),
            6,
            Paint()..color = NooriPalette.bowKnot,
          );
      case NooriHat.flower:
        const c = Offset(126, 42);
        final petal = Paint()..color = NooriPalette.petal;
        for (var i = 0; i < 5; i++) {
          final a = i * math.pi * 2 / 5 - math.pi / 2;
          canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * 9, 7, petal);
        }
        canvas.drawCircle(c, 6, Paint()..color = NooriPalette.petalCentre);
      case NooriHat.party:
        final cone = Path()
          ..moveTo(82, 38)
          ..lineTo(100, 2)
          ..lineTo(118, 38)
          ..close();
        canvas
          ..drawPath(cone, Paint()..color = NooriPalette.partyHat)
          ..save()
          ..clipPath(cone);
        final stripe = Paint()
          ..color = NooriPalette.partyStripe
          ..strokeWidth = 4;
        for (var y = 10.0; y < 40; y += 10) {
          canvas.drawLine(Offset(80, y + 8), Offset(120, y - 4), stripe);
        }
        canvas
          ..restore()
          ..drawCircle(
            const Offset(100, 3),
            6,
            Paint()..color = NooriPalette.pompom,
          );
      case NooriHat.crown:
        final crown = Path()
          ..moveTo(78, 40)
          ..lineTo(78, 18)
          ..lineTo(89, 28)
          ..lineTo(100, 10)
          ..lineTo(111, 28)
          ..lineTo(122, 18)
          ..lineTo(122, 40)
          ..close();
        canvas
          ..drawPath(crown, Paint()..color = NooriPalette.crownGold)
          ..drawRect(
            const Rect.fromLTWH(78, 34, 44, 6),
            Paint()..color = NooriPalette.crownShade,
          )
          ..drawCircle(
            const Offset(100, 26),
            4,
            Paint()..color = NooriPalette.gemPink,
          )
          ..drawCircle(
            const Offset(86, 32),
            3,
            Paint()..color = NooriPalette.gemBlue,
          )
          ..drawCircle(
            const Offset(114, 32),
            3,
            Paint()..color = NooriPalette.gemBlue,
          );
    }
  }

  void _head(Canvas canvas) {
    final tuft = Paint()..color = NooriPalette.bodyDark;
    canvas
      ..drawPath(
        Path()
          ..moveTo(52, 62)
          ..quadraticBezierTo(42, 38, 50, 22)
          ..quadraticBezierTo(70, 34, 82, 44)
          ..close(),
        tuft,
      )
      ..drawPath(
        Path()
          ..moveTo(148, 62)
          ..quadraticBezierTo(158, 38, 150, 22)
          ..quadraticBezierTo(130, 34, 118, 44)
          ..close(),
        tuft,
      );
    final headRect = Rect.fromCircle(center: _headC, radius: _headR);
    canvas.drawOval(headRect, _featherGradient(headRect));

    final face = Paint()..color = NooriPalette.face;
    canvas
      ..drawCircle(_leftEye, 31, face)
      ..drawCircle(_rightEye, 31, face)
      ..drawOval(
        Rect.fromCenter(center: const Offset(100, 104), width: 40, height: 30),
        face,
      );
  }

  void _eye(Canvas canvas, Offset c) {
    final ink = Paint()..color = NooriPalette.pupil;
    if (pose.happyEyes > 0.5) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - 12, c.dy + 5)
          ..quadraticBezierTo(c.dx, c.dy - 13, c.dx + 12, c.dy + 5),
        Paint()
          ..color = NooriPalette.pupil
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    final white = Paint()..color = NooriPalette.eyeWhite;
    canvas.drawCircle(c, _eyeR, white);
    final p = c + pose.pupil * 6;
    canvas
      ..drawCircle(p, 11, ink)
      ..drawCircle(p + const Offset(-4, -4), 4, white)
      ..drawCircle(p + const Offset(3.5, 4), 1.8, white);

    final open = (pose.eyeOpen * (1 - pose.blink)).clamp(0.0, 1.0);
    if (open < 0.98) {
      final lidBottom = c.dy - _eyeR + (1 - open) * _eyeR * 2;
      canvas
        ..save()
        ..clipPath(
          Path()..addOval(Rect.fromCircle(center: c, radius: _eyeR + 0.5)),
        )
        ..drawRect(
          Rect.fromLTRB(
            c.dx - _eyeR - 1,
            c.dy - _eyeR - 1,
            c.dx + _eyeR + 1,
            lidBottom,
          ),
          Paint()..color = NooriPalette.eyelid,
        );
      final half = math.sqrt(
        math.max(0, _eyeR * _eyeR - math.pow(lidBottom - c.dy, 2)),
      );
      canvas
        ..drawLine(
          Offset(c.dx - half, lidBottom),
          Offset(c.dx + half, lidBottom),
          Paint()
            ..color = NooriPalette.pupil
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        )
        ..restore();
    }
  }

  void _cheeks(Canvas canvas) {
    final paint = Paint()..color = NooriPalette.cheek;
    canvas
      ..drawCircle(const Offset(56, 112), 9, paint)
      ..drawCircle(const Offset(144, 112), 9, paint);
  }

  void _beak(Canvas canvas) {
    final open = pose.beakOpen;
    if (open > 0.02) {
      canvas.drawPath(
        Path()
          ..moveTo(94, 108)
          ..lineTo(106, 108)
          ..quadraticBezierTo(101, 110 + 10 * open, 100, 111 + 10 * open)
          ..quadraticBezierTo(99, 110 + 10 * open, 94, 108)
          ..close(),
        Paint()..color = NooriPalette.beakDark,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(91, 101)
        ..quadraticBezierTo(100, 97, 109, 101)
        ..quadraticBezierTo(104, 110, 100, 116)
        ..quadraticBezierTo(96, 110, 91, 101)
        ..close(),
      Paint()..color = NooriPalette.beak,
    );
  }

  void _thinkDots(Canvas canvas) {
    final a = pose.thinkDots;
    if (a < 0.02) return;
    const dots = [
      (Offset(154, 44), 4.0),
      (Offset(166, 28), 6.0),
      (Offset(182, 10), 8.5),
    ];
    for (var i = 0; i < dots.length; i++) {
      final pulse = math.sin(pose.time * 3 - i * 0.8) * 0.5 + 0.5;
      final (pos, r) = dots[i];
      canvas.drawCircle(
        pos,
        r * (0.85 + 0.25 * pulse),
        Paint()
          ..color = NooriPalette.thinkDot.withValues(
            alpha: a * (0.6 + 0.4 * pulse),
          ),
      );
    }
  }

  void _sparkles(Canvas canvas) {
    final a = pose.sparkle;
    if (a < 0.02) return;
    final paint = Paint()..color = NooriPalette.sparkle.withValues(alpha: a);
    const spots = [
      Offset(28, 60),
      Offset(172, 58),
      Offset(20, 140),
      Offset(180, 150),
    ];
    for (var i = 0; i < spots.length; i++) {
      final pulse = math.sin(pose.time * 6 + i * 1.7) * 0.5 + 0.5;
      _star(canvas, spots[i], 4 + 6 * pulse, paint);
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final inner = r * 0.3;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r)
        ..lineTo(c.dx + inner, c.dy - inner)
        ..lineTo(c.dx + r, c.dy)
        ..lineTo(c.dx + inner, c.dy + inner)
        ..lineTo(c.dx, c.dy + r)
        ..lineTo(c.dx - inner, c.dy + inner)
        ..lineTo(c.dx - r, c.dy)
        ..lineTo(c.dx - inner, c.dy - inner)
        ..close(),
      paint,
    );
  }

  void _zzz(Canvas canvas) {
    final a = pose.zzz;
    if (a < 0.02) return;
    for (var i = 0; i < 3; i++) {
      final phase = (pose.time * 0.35 + i / 3) % 1.0;
      final w = 8 + phase * 10;
      final origin = Offset(140 + phase * 34, 52 - phase * 52);
      canvas.drawPath(
        Path()
          ..moveTo(origin.dx, origin.dy)
          ..lineTo(origin.dx + w, origin.dy)
          ..lineTo(origin.dx, origin.dy + w)
          ..lineTo(origin.dx + w, origin.dy + w),
        Paint()
          ..color = NooriPalette.zzz.withValues(
            alpha: a * math.sin(phase * math.pi),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(NooriPainter oldDelegate) =>
      oldDelegate.pose != pose || oldDelegate.outfit != outfit;
}
