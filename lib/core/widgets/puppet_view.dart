import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/puppets.dart';
import '../content/scenes.dart';
import '../content/story.dart';
import '../theme/app_theme.dart';
import 'illustration.dart';
import 'puppet_acts.dart';

/// A puppet from assets/content/puppets.json, alive: its parts turn into
/// [pose] and keep doing [act], its painted face blinks and shows [face]
/// (or the one [mood] gives), and it can hold a prop.
///
/// Each time [cue] goes up the puppet reacts with its own tap action and a
/// big smile (a tap, or the narration reaching its name).
class PuppetView extends ConsumerStatefulWidget {
  const PuppetView({
    super.key,
    required this.id,
    required this.height,
    this.pose,
    this.act,
    this.face,
    this.mood = CastMood.idle,
    this.look,
    this.hold,
    this.holdSize = 0.2,
    this.holdTurn = 0,
    this.holdHand = 'R',
    this.cue = 0,
    this.seed = 0,
    this.nightTint = true,
  });

  final String id;
  final double height;
  final String? pose, act, face, look;
  final CastMood mood;
  final PictureRef? hold;
  final double holdSize, holdTurn;
  final String holdHand;
  final int cue;
  final int seed;
  final bool nightTint;

  @override
  ConsumerState<PuppetView> createState() => _PuppetViewState();
}

class _PuppetViewState extends ConsumerState<PuppetView>
    with TickerProviderStateMixin {
  final _time = ValueNotifier<double>(0);
  late final Ticker _ticker = createTicker(
    (elapsed) => _time.value = elapsed.inMicroseconds / 1e6,
  )..start();
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: AppMotion.blinkLength,
  );
  late final AnimationController _react = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  late final _random = math.Random(widget.seed * 31 + widget.id.hashCode);
  late final double _phase = _random.nextDouble();
  Timer? _nextBlink;

  @override
  void initState() {
    super.initState();
    _scheduleBlink();
  }

  @override
  void didUpdateWidget(PuppetView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cue > oldWidget.cue) _react.forward(from: 0);
  }

  void _scheduleBlink() {
    final span = AppMotion.blinkMax - AppMotion.blinkMin;
    _nextBlink = Timer(
      AppMotion.blinkMin + span * _random.nextDouble(),
      () async {
        if (!mounted) return;
        await _blink.forward(from: 0);
        if (!mounted) return;
        await _blink.reverse();
        if (mounted) _scheduleBlink();
      },
    );
  }

  @override
  void dispose() {
    _nextBlink?.cancel();
    _ticker.dispose();
    _time.dispose();
    _blink.dispose();
    _react.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = ref.watch(
      scenesProvider.select((s) => s.value?.puppets[widget.id]),
    );
    if (spec == null) {
      return SizedBox(height: widget.height, width: widget.height * 0.6);
    }
    final s = widget.height / spec.size.height;
    final night =
        widget.nightTint && Theme.of(context).brightness == Brightness.dark;
    // Built once per build: the SVGs themselves never repaint as parts move.
    final art = {
      for (final p in spec.parts)
        p.id: RepaintBoundary(
          child: Illustration(
            spec.asset(p.id),
            fit: BoxFit.fill,
            nightTint: widget.nightTint,
          ),
        ),
    };
    final held = widget.hold;
    final heldArt = held == null
        ? null
        : SizedBox.square(
            dimension: widget.holdSize * widget.height,
            child: held.isPuppet
                ? null
                : Illustration(held.sceneAsset, nightTint: widget.nightTint),
          );

    // Shrinks to fit if its slot is narrower, so parts and face stay
    // in register.
    return FittedBox(
      child: SizedBox(
        width: spec.size.width * s,
        height: spec.size.height * s,
        child: AnimatedBuilder(
          animation: Listenable.merge([_time, _blink, _react]),
          builder: (context, _) => _frame(spec, s, art, heldArt, night: night),
        ),
      ),
    );
  }

  Widget _frame(
    PuppetSpec spec,
    double s,
    Map<String, Widget> art,
    Widget? heldArt, {
    required bool night,
  }) {
    final pose = spec.pose(widget.pose);
    var act = PuppetActs.frame(widget.act, _time.value, seed: _phase);
    final r = _react.value;
    final reacting = r > 0 && r < 1;
    if (reacting) {
      act =
          act +
          PuppetActs.frame(
            spec.tap,
            r * 1.3,
          ).scaled(math.sin(r * math.pi).clamp(0, 1));
    }

    // Each part's transform, parents first.
    final matrices = <String, Matrix4>{};
    Matrix4 matrixOf(PuppetPart p) {
      final known = matrices[p.id];
      if (known != null) return known;
      var deg = (pose.turns[p.id] ?? 0) + (act.turns[p.id] ?? 0);
      if (p.mirror) deg = -deg;
      final shift = (pose.shifts[p.id] ?? Offset.zero) * s;
      final pivot = p.pivot * s;
      final parent = p.parent == null ? null : spec.part(p.parent!);
      final m = (parent == null ? Matrix4.identity() : matrixOf(parent).clone())
        ..translateByDouble(pivot.dx + shift.dx, pivot.dy + shift.dy, 0, 1)
        ..rotateZ(deg * math.pi / 180)
        ..translateByDouble(-pivot.dx, -pivot.dy, 0, 1);
      return matrices[p.id] = m;
    }

    final face = spec.face;
    final expression = reacting && widget.mood != CastMood.sleepy
        ? 'happy'
        : widget.face ?? pose.face ?? _moodFace(widget.mood);
    final hand = spec.hands[widget.holdHand];

    final layers = <Widget>[];
    for (final p in spec.parts) {
      final m = matrixOf(p);
      layers.add(
        Positioned.fill(
          child: Transform(transform: m, child: art[p.id]),
        ),
      );
      if (p.id == face.part) {
        layers.add(
          Positioned.fill(
            child: Transform(
              transform: m,
              child: CustomPaint(
                painter: _FacePainter(
                  face: face,
                  scale: s,
                  expression: expression,
                  blink: _blink.value,
                  look: _lookOffset(widget.look ?? pose.look),
                  talk: act.talk,
                  night: night,
                ),
              ),
            ),
          ),
        );
      }
      if (heldArt != null && hand != null && hand.part == p.id) {
        final at = hand.at * s;
        final d = widget.holdSize * widget.height;
        layers.add(
          Positioned.fill(
            child: Transform(
              transform: m,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: at.dx - d / 2,
                    top: at.dy - d / 2,
                    child: Transform.rotate(
                      angle: widget.holdTurn * math.pi / 180,
                      child: heldArt,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    final w = spec.size.width * s, h = spec.size.height * s;
    final body = Matrix4.identity()
      ..translateByDouble(act.dx * s, (act.dy + pose.drop) * s, 0, 1)
      ..translateByDouble(w / 2, h, 0, 1)
      ..rotateZ(act.rot * math.pi / 180)
      ..scaleByDouble(act.sx, act.sy, 1, 1)
      ..translateByDouble(-w / 2, -h, 0, 1);
    return Transform(
      transform: body,
      child: Stack(clipBehavior: Clip.none, children: layers),
    );
  }

  static String _moodFace(CastMood mood) => switch (mood) {
    CastMood.happy => 'happy',
    CastMood.sad => 'sad',
    CastMood.surprised => 'surprised',
    CastMood.worried => 'worried',
    CastMood.sleepy => 'sleep',
    CastMood.shy => 'shy',
    _ => 'idle',
  };

  static Offset _lookOffset(String? look) => switch (look) {
    'up' => const Offset(0, -1),
    'down' => const Offset(0, 1),
    'left' => const Offset(-1, 0),
    'right' => const Offset(1, 0),
    'upLeft' => const Offset(-0.7, -0.7),
    'upRight' => const Offset(0.7, -0.7),
    'downLeft' => const Offset(-0.7, 0.7),
    'downRight' => const Offset(0.7, 0.7),
    _ => Offset.zero,
  };
}

/// Paints a puppet's eyes, brows, cheeks and mouth (or beak) in the style
/// of the SVG art: dark round eyes with a shine, soft pink cheeks.
class _FacePainter extends CustomPainter {
  _FacePainter({
    required this.face,
    required this.scale,
    required this.expression,
    required this.blink,
    required this.look,
    required this.talk,
    required this.night,
  });

  final PuppetFace face;
  final double scale;
  final String expression;
  final double blink;
  final Offset look;
  final double talk;
  final bool night;

  static const _ink = Color(0xFF2D2433);
  static const _shine = Color(0xFFFFFFFF);
  static const _blush = Color(0x80F7A3BA);
  static const _tongue = Color(0xFFF27C8F);
  static const _tear = Color(0xFF8FD3FF);

  Color _t(Color c) =>
      night ? Color.alphaBlend(AppPalette.navy.withValues(alpha: 0.55), c) : c;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(scale);
    final ink = Paint()..color = _t(face.ink ?? _ink);
    final line = Paint()
      ..color = _t(face.ink ?? _ink)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final e = expression;
    final eyeR = face.eyes.isEmpty ? 4.0 : face.eyes.first.$2;

    // Cheeks: puffed with food, or a blush.
    for (final (c, r) in face.cheeks) {
      if (e == 'full') {
        canvas
          ..drawCircle(c, r * 2.1, Paint()..color = _t(face.skin))
          ..drawCircle(
            c + Offset(-r * 0.5, -r * 0.6),
            r * 0.6,
            Paint()..color = _t(_shine.withValues(alpha: 0.35)),
          );
      }
      final big = e == 'shy' || e == 'happy' || e == 'laugh' || e == 'full';
      canvas.drawCircle(
        c,
        r * (big ? 1.25 : 1),
        Paint()..color = _t(big ? _blush.withValues(alpha: 0.75) : _blush),
      );
    }

    // The middle of the face, so brows know which end is "inner".
    final mid = face.eyes.length > 1
        ? (face.eyes.first.$1.dx + face.eyes.last.$1.dx) / 2
        : face.mouth?.$1.dx ?? face.eyes.first.$1.dx - eyeR * 3;

    for (final (c, r) in face.eyes) {
      final closed = switch (e) {
        'sleep' => _Closed.down,
        'laugh' || 'full' => _Closed.up,
        'ouch' => _Closed.squeeze,
        _ => blink > 0.55 ? _Closed.down : null,
      };
      line.strokeWidth = r * 0.42;
      switch (closed) {
        case _Closed.down:
          canvas.drawArc(
            Rect.fromCenter(center: c, width: r * 1.9, height: r * 1.3),
            math.pi * 0.1,
            math.pi * 0.8,
            false,
            line,
          );
        case _Closed.up:
          canvas.drawArc(
            Rect.fromCenter(
              center: c + Offset(0, r * 0.4),
              width: r * 1.9,
              height: r * 1.6,
            ),
            math.pi * 1.1,
            math.pi * 0.8,
            false,
            line,
          );
        case _Closed.squeeze:
          final inner = c.dx < mid ? 1.0 : -1.0;
          canvas.drawPath(
            Path()
              ..moveTo(c.dx - inner * r * 0.9, c.dy - r * 0.7)
              ..lineTo(c.dx + inner * r * 0.7, c.dy)
              ..lineTo(c.dx - inner * r * 0.9, c.dy + r * 0.7),
            line,
          );
        case null:
          final grow = switch (e) {
            'surprised' || 'open' => 1.22,
            'sad' => 0.92,
            _ => 1.0,
          };
          final p = c + look * r * 0.32;
          final eye = Rect.fromCenter(
            center: p,
            width: r * 1.9 * grow,
            height: r * 2.15 * grow,
          );
          canvas
            ..drawOval(eye, ink)
            ..drawCircle(
              p + Offset(-r * 0.32, -r * 0.42) * grow,
              r * 0.36 * grow,
              Paint()..color = _t(_shine),
            )
            ..drawCircle(
              p + Offset(r * 0.32, r * 0.38) * grow,
              r * 0.15 * grow,
              Paint()..color = _t(_shine),
            );
          // Half-closed lids: a blink on its way, or a sad droop.
          final lid = e == 'sad' || e == 'worried'
              ? math.max(blink, 0.28)
              : blink;
          if (lid > 0) {
            canvas
              ..save()
              ..clipPath(Path()..addOval(eye.inflate(r * 0.08)));
            if (e == 'sad' || e == 'worried') {
              // A lid that slopes down to the outside.
              final out = c.dx < mid ? -1.0 : 1.0;
              final top = eye.top - r * 0.1;
              canvas.drawPath(
                Path()
                  ..moveTo(eye.left - r, top)
                  ..lineTo(eye.right + r, top)
                  ..lineTo(
                    c.dx + out * eye.width,
                    top + eye.height * (lid + 0.35),
                  )
                  ..lineTo(c.dx - out * eye.width, top + eye.height * lid * 0.5)
                  ..close(),
                Paint()..color = _t(face.skin),
              );
            } else {
              canvas.drawRect(
                Rect.fromLTRB(
                  eye.left - 1,
                  eye.top - 1,
                  eye.right + 1,
                  eye.top + eye.height * lid,
                ),
                Paint()..color = _t(face.skin),
              );
            }
            canvas.restore();
          }
      }

      // Brows.
      final browColor = face.brows;
      if (browColor != null) {
        final inner = c.dx < mid ? 1.0 : -1.0;
        final lift = switch (e) {
          'surprised' || 'open' => r * 0.7,
          'happy' || 'laugh' => r * 0.25,
          _ => 0.0,
        };
        final tilt = switch (e) {
          'sad' || 'worried' || 'ouch' => r * 0.55,
          'think' => c.dx < mid ? r * 0.4 : -r * 0.2,
          _ => 0.0,
        };
        final y = c.dy - r * 1.75 - lift;
        final brow = Paint()
          ..color = _t(browColor)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = r * 0.42;
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - inner * r * 0.95, y + tilt * 0.2)
            ..quadraticBezierTo(
              c.dx,
              y - r * 0.35 - tilt * 0.3,
              c.dx + inner * r * 0.95,
              y - tilt,
            ),
          brow,
        );
      }
    }

    if (e == 'sad' && face.eyes.isNotEmpty) {
      final (c, r) = face.eyes.first;
      canvas.drawPath(
        _drop(c + Offset(-r * 0.2, r * 1.9), r * 0.55),
        Paint()..color = _t(_tear),
      );
    }
    if (e == 'worried' && face.eyes.isNotEmpty) {
      final (c, r) = face.eyes.last;
      canvas.drawPath(
        _drop(c + Offset(r * 2.4, -r * 1.6), r * 0.6),
        Paint()..color = _t(_tear),
      );
    }

    final mouth = face.mouth;
    if (mouth != null) _paintMouth(canvas, mouth.$1, mouth.$2, ink, line);
    final beak = face.beak;
    if (beak != null) _paintBeak(canvas, beak.$1, beak.$2, ink);
    canvas.restore();
  }

  void _paintMouth(Canvas canvas, Offset c, double w, Paint ink, Paint line) {
    final e = expression;
    line.strokeWidth = math.max(1.4, w * 0.2);
    final l = c.dx - w / 2, r = c.dx + w / 2;
    // Talking opens whatever mouth the face has.
    final open = switch (e) {
      'happy' || 'laugh' => 0.75 + talk * 0.25,
      'surprised' || 'open' => 1.0,
      _ => talk,
    };
    if (e == 'sad') {
      canvas.drawPath(
        Path()
          ..moveTo(l + w * 0.1, c.dy + w * 0.25)
          ..quadraticBezierTo(
            c.dx,
            c.dy - w * 0.25,
            r - w * 0.1,
            c.dy + w * 0.25,
          ),
        line,
      );
      return;
    }
    if (e == 'worried' || e == 'ouch') {
      final p = Path()..moveTo(l, c.dy);
      const waves = 3;
      for (var i = 0; i < waves; i++) {
        final x0 = l + w * i / waves;
        p.quadraticBezierTo(
          x0 + w / waves / 2,
          c.dy + (i.isEven ? -1 : 1) * w * 0.16,
          x0 + w / waves,
          c.dy,
        );
      }
      canvas.drawPath(p, line);
      return;
    }
    if (e == 'full') {
      canvas.drawLine(
        Offset(l + w * 0.25, c.dy),
        Offset(r - w * 0.25, c.dy),
        line,
      );
      return;
    }
    if (e == 'sleep') {
      canvas.drawOval(
        Rect.fromCenter(center: c, width: w * 0.3, height: w * 0.22),
        ink,
      );
      return;
    }
    if (e == 'surprised' || e == 'open') {
      final o = Rect.fromCenter(
        center: c + Offset(0, w * 0.1),
        width: w * 0.5,
        height: w * 0.6,
      );
      canvas
        ..drawOval(o, ink)
        ..save()
        ..clipPath(Path()..addOval(o))
        ..drawCircle(o.bottomCenter, w * 0.22, Paint()..color = _t(_tongue))
        ..restore();
      return;
    }
    if (open > 0.05) {
      // An open smile: a "D" with a tongue.
      final depth = w * (0.25 + 0.5 * open);
      final d = Path()
        ..moveTo(l, c.dy)
        ..quadraticBezierTo(c.dx, c.dy + depth * 1.6, r, c.dy)
        ..close();
      canvas
        ..drawPath(d, ink)
        ..save()
        ..clipPath(d)
        ..drawCircle(
          Offset(c.dx, c.dy + depth * 0.95),
          w * 0.26,
          Paint()..color = _t(_tongue),
        )
        ..restore();
      return;
    }
    final small = e == 'shy' || e == 'think';
    final mw = small ? w * 0.6 : w;
    final shift = e == 'think' ? w * 0.2 : 0.0;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - mw / 2 + shift, c.dy)
        ..quadraticBezierTo(
          c.dx + shift,
          c.dy + mw * (e == 'think' ? 0.1 : 0.45),
          c.dx + mw / 2 + shift,
          c.dy,
        ),
      line,
    );
  }

  void _paintBeak(Canvas canvas, Offset base, double len, Paint ink) {
    final color = Paint()
      ..color = _t(face.beakColor ?? const Color(0xFFFFB703));
    final shade = Paint()
      ..color = _t(
        Color.lerp(face.beakColor ?? const Color(0xFFFFB703), _ink, 0.25)!,
      );
    final open = switch (expression) {
      'surprised' || 'open' || 'happy' || 'laugh' => 0.8,
      _ => talk,
    };
    final l = len.abs();
    final h = l * 0.8;
    if (len > 0) {
      // Side view, pointing right.
      final gap = h * 0.45 * open;
      if (gap > 0.2) {
        canvas.drawPath(
          Path()
            ..moveTo(base.dx, base.dy - h * 0.3)
            ..lineTo(base.dx + l * 0.75, base.dy)
            ..lineTo(base.dx, base.dy + h * 0.3 + gap)
            ..close(),
          ink,
        );
      }
      canvas
        ..drawPath(
          Path()
            ..moveTo(base.dx, base.dy + gap * 0.5)
            ..lineTo(base.dx + l * 0.8, base.dy + h * 0.25 + gap)
            ..lineTo(base.dx, base.dy + h * 0.45 + gap)
            ..close(),
          shade,
        )
        ..drawPath(
          Path()
            ..moveTo(base.dx, base.dy - h * 0.5)
            ..quadraticBezierTo(
              base.dx + l * 0.7,
              base.dy - h * 0.4,
              base.dx + l,
              base.dy + h * 0.15 - gap * 0.3,
            )
            ..lineTo(base.dx, base.dy + h * 0.1)
            ..close(),
          color,
        );
    } else {
      // Front view, pointing down: a hooked parrot beak.
      final gap = h * 0.4 * open;
      if (gap > 0.2) {
        canvas.drawOval(
          Rect.fromCenter(
            center: base + Offset(0, l * 0.55 + gap * 0.3),
            width: h * 0.7,
            height: gap * 1.6 + h * 0.2,
          ),
          ink,
        );
      }
      canvas
        ..drawPath(
          Path()
            ..moveTo(base.dx - h * 0.3, base.dy + l * 0.45 + gap)
            ..quadraticBezierTo(
              base.dx,
              base.dy + l * 0.95 + gap,
              base.dx + h * 0.3,
              base.dy + l * 0.45 + gap,
            )
            ..close(),
          shade,
        )
        ..drawPath(
          Path()
            ..moveTo(base.dx - h * 0.5, base.dy)
            ..quadraticBezierTo(
              base.dx - h * 0.45,
              base.dy + l * 0.7,
              base.dx,
              base.dy + l,
            )
            ..quadraticBezierTo(
              base.dx + h * 0.45,
              base.dy + l * 0.7,
              base.dx + h * 0.5,
              base.dy,
            )
            ..close(),
          color,
        );
    }
  }

  static Path _drop(Offset tip, double r) => Path()
    ..moveTo(tip.dx, tip.dy - r * 1.6)
    ..quadraticBezierTo(
      tip.dx + r * 1.1,
      tip.dy - r * 0.2,
      tip.dx,
      tip.dy + r * 0.6,
    )
    ..quadraticBezierTo(
      tip.dx - r * 1.1,
      tip.dy - r * 0.2,
      tip.dx,
      tip.dy - r * 1.6,
    )
    ..close();

  @override
  bool shouldRepaint(_FacePainter old) =>
      old.expression != expression ||
      old.blink != blink ||
      old.look != look ||
      old.talk != talk ||
      old.night != night ||
      old.scale != scale ||
      old.face != face;
}

enum _Closed { down, up, squeeze }

/// Any picture on a card (quiz options, choices, the word game): plain art,
/// or a puppet standing idle, cropped to its card slice.
class PictureView extends ConsumerWidget {
  const PictureView(this.picture, {super.key, this.nightTint = false});

  final PictureRef picture;
  final bool nightTint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!picture.isPuppet) {
      return Illustration(picture.cardAsset, nightTint: nightTint);
    }
    final spec = ref.watch(
      scenesProvider.select((s) => s.value?.puppets[picture.id]),
    );
    if (spec == null) return const SizedBox.expand();
    final (top, bottom) = spec.card;
    return LayoutBuilder(
      builder: (context, box) {
        final slice = bottom - top;
        // Fit the slice into the box.
        final aspect = spec.size.width / (spec.size.height * slice);
        var h = box.maxHeight;
        if (h * aspect > box.maxWidth) h = box.maxWidth / aspect;
        final full = h / slice;
        return Center(
          child: SizedBox(
            width: h * aspect,
            height: h,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minHeight: full,
                maxHeight: full,
                child: Transform.translate(
                  offset: Offset(0, -top * full),
                  child: PuppetView(
                    id: picture.id,
                    height: full,
                    nightTint: nightTint,
                    mood: CastMood.happy,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
