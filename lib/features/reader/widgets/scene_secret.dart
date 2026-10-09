import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/content/scenes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/illustration.dart';

/// A hidden surprise in a scene. It idles quietly (a frog's eyes peeking
/// over a leaf, a caterpillar snoring) and, when tapped, comes alive: the
/// butterfly flies off and back, the frog jumps, the mouse pops out.
///
/// [onFound] reports where it was found (globally), for the sparkle.
class SceneSecretView extends StatefulWidget {
  const SceneSecretView({
    super.key,
    required this.secret,
    required this.height,
    this.onFound,
  });

  final SceneSecret secret;
  final double height;
  final ValueChanged<Offset>? onFound;

  static String _art(String name) => 'assets/illustrations/secrets/$name.svg';

  /// Every picture [kind] is drawn with.
  static List<String> assetsFor(SecretKind kind) => [
    for (final name in switch (kind) {
      SecretKind.butterfly => ['butterfly'],
      SecretKind.frog => ['frog', 'frog_front'],
      SecretKind.caterpillar => ['caterpillar', 'caterpillar_awake', 'zzz'],
      SecretKind.snail => ['snail_body', 'snail_shell'],
      SecretKind.ladybird => ['ladybird', 'ladybird_back'],
      SecretKind.mouse => ['mouse', 'mouse_back'],
      SecretKind.fish => ['fish', 'fish_back', 'splash'],
    })
      _art(name),
  ];

  @override
  State<SceneSecretView> createState() => _SceneSecretViewState();
}

class _SceneSecretViewState extends State<SceneSecretView>
    with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat();
  late final AnimationController _react = AnimationController(
    vsync: this,
    duration: _reactLength(widget.secret.kind),
  );

  static Duration _reactLength(SecretKind kind) => Duration(
    milliseconds: switch (kind) {
      SecretKind.butterfly => 7000,
      SecretKind.frog => 1100,
      SecretKind.caterpillar => 3200,
      SecretKind.snail => 3400,
      SecretKind.ladybird => 2600,
      SecretKind.mouse => 2200,
      SecretKind.fish => 1500,
    },
  );

  void _tap(TapUpDetails d) {
    if (_react.isAnimating) return;
    _react.forward(from: 0);
    widget.onFound?.call(d.globalPosition);
  }

  @override
  void dispose() {
    _idle.dispose();
    _react.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height;
    // Little fingers need a bigger target than the critter itself.
    final hit = math.max(h * 1.3, AppSizes.secretHitMin);
    Widget art = SizedBox.square(
      dimension: h,
      child: AnimatedBuilder(
        animation: Listenable.merge([_idle, _react]),
        builder: (context, _) => _frame(h),
      ),
    );
    if (widget.secret.flip) art = Transform.flip(flipX: true, child: art);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: _tap,
      child: SizedBox(
        width: hit,
        height: hit,
        child: Align(alignment: Alignment.bottomCenter, child: art),
      ),
    );
  }

  Widget _frame(double h) {
    final i = _idle.value * math.pi * 2;
    final r = _react.value;
    final reacting = _react.isAnimating;
    Widget svg(String name) =>
        Illustration(SceneSecretView._art(name), fit: BoxFit.contain);

    switch (widget.secret.kind) {
      case SecretKind.butterfly:
        // Resting: wings open and close slowly. Found: flies away, stays
        // gone a while, then flutters back to its flower.
        final flap = reacting
            ? 0.35 + 0.65 * math.sin(r * 140).abs()
            : 0.65 + 0.35 * math.cos(i * 1.5).abs();
        var dx = 0.0, dy = 0.0, opacity = 1.0;
        if (reacting) {
          final out = (r / 0.25).clamp(0.0, 1.0);
          final back = ((r - 0.75) / 0.25).clamp(0.0, 1.0);
          final away = r < 0.75 ? out : 1 - back;
          dx = away * h * 4 + math.sin(away * 9) * h * 0.4;
          dy = -away * h * 5;
          opacity = 1 - Curves.easeIn.transform(away);
        }
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(flap, 1, 1),
              child: svg('butterfly'),
            ),
          ),
        );

      case SecretKind.frog:
        // Eyes peek over the leaf; found, the frog leaps up and plops back.
        final peek = reacting
            ? -math.sin(r * math.pi) * h * 1.2
            : (0.5 + 0.5 * math.sin(i)) * -h * 0.12;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              // Only the eyes clear the leaf; the rest of the frog is
              // tucked behind it (and never pokes out below).
              child: ClipRect(
                clipper: _AboveBottom(),
                child: Transform.translate(
                  offset: Offset(0, h * 0.14 + peek),
                  child: Transform.scale(
                    scale: reacting ? 1 + math.sin(r * math.pi) * 0.12 : 1,
                    child: svg('frog'),
                  ),
                ),
              ),
            ),
            Positioned.fill(child: svg('frog_front')),
          ],
        );

      case SecretKind.caterpillar:
        // Asleep and snoring; found, it wakes, wriggles, then dozes off.
        final awake = reacting && r < 0.85;
        final wiggle = awake ? math.sin(r * math.pi * 10) * 0.08 : 0.0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.diagonal3Values(
                  1 + wiggle,
                  awake ? 1 - wiggle : 1 + 0.03 * math.sin(i),
                  1,
                ),
                child: svg(awake ? 'caterpillar_awake' : 'caterpillar'),
              ),
            ),
            if (!awake)
              Positioned(
                right: -h * 0.35,
                top: -h * 0.55 - (_idle.value * h * 0.25),
                width: h * 0.7,
                height: h * 0.7,
                child: Opacity(
                  opacity: (1 - _idle.value).clamp(0.0, 1.0),
                  child: svg('zzz'),
                ),
              ),
          ],
        );

      case SecretKind.snail:
        // Tucked in its shell; found, it peeks out and slides along.
        final out = reacting
            ? math.sin((r.clamp(0.0, 1.0)) * math.pi).clamp(0.0, 1.0) * 1.4
            : 0.0;
        final slide = reacting ? r * h * 0.25 : 0.0;
        return Transform.translate(
          offset: Offset(
            slide - (reacting && r > 0.5 ? (r - 0.5) * h * 0.5 : 0),
            0,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: out.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset((out.clamp(0.0, 1.0) - 1) * h * 0.3, 0),
                    child: svg('snail_body'),
                  ),
                ),
              ),
              Positioned.fill(
                child: Transform.rotate(
                  angle: math.sin(i) * 0.04,
                  alignment: Alignment.bottomCenter,
                  child: svg('snail_shell'),
                ),
              ),
            ],
          ),
        );

      case SecretKind.ladybird:
        // Crawls a little on its leaf; found, it flies a loop and lands.
        final a = r * math.pi * 2;
        final fly = reacting
            ? Offset(math.sin(a) * h * 1.4, -math.sin(r * math.pi) * h * 1.6)
            : Offset(math.sin(i) * h * 0.12, 0);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: svg('ladybird_back')),
            Positioned(
              left: h * 0.3,
              top: h * 0.12,
              width: h * 0.42,
              height: h * 0.42,
              child: Transform.translate(
                offset: fly,
                child: Transform.rotate(
                  angle: reacting ? math.cos(a) * 0.6 : math.sin(i) * 0.15,
                  child: svg('ladybird'),
                ),
              ),
            ),
          ],
        );

      case SecretKind.mouse:
        // Ears twitch at the hole's mouth; found, it pops out and ducks.
        final peek = reacting
            ? math.sin(r * math.pi).clamp(0.0, 1.0)
            : 0.46 + 0.06 * math.sin(i * 2);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: svg('mouse_back')),
            Positioned.fill(
              child: ClipRect(
                child: Transform.translate(
                  offset: Offset(
                    reacting ? math.sin(r * math.pi * 6) * h * 0.03 : 0,
                    h * (1 - peek * 0.75),
                  ),
                  child: Transform.scale(scale: 0.62, child: svg('mouse')),
                ),
              ),
            ),
          ],
        );

      case SecretKind.fish:
        // Ripples on the water; found, a fish leaps out in an arc.
        final ripple = 0.85 + 0.15 * math.sin(i * 2);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Transform.scale(scale: ripple, child: svg('fish_back')),
            ),
            if (reacting && r < 0.92)
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(
                    (0.5 - r) * h * 1.2,
                    h * 0.5 - math.sin(r * math.pi) * h * 1.5,
                  ),
                  child: Transform.rotate(
                    angle: (r - 0.5) * 2.2,
                    child: Transform.scale(scale: 0.6, child: svg('fish')),
                  ),
                ),
              ),
            if (reacting && r > 0.82)
              Positioned.fill(
                child: Opacity(
                  opacity: ((1 - r) / 0.18).clamp(0.0, 1.0),
                  child: svg('splash'),
                ),
              ),
          ],
        );
    }
  }
}

/// Clips to the box's own bottom edge but lets things rise above its top
/// (a frog leaping out from behind its leaf).
class _AboveBottom extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-size.width, -size.height * 4, size.width * 2, size.height);

  @override
  bool shouldReclip(_AboveBottom oldClipper) => false;
}
