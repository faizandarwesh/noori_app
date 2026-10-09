import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/content/scenes.dart';
import '../../../core/content/story.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/illustration.dart';
import '../../../core/widgets/parallax_scene.dart';
import '../../../core/widgets/puppet_view.dart';
import 'help_moment.dart';
import 'scene_secret.dart';

/// A page's full-screen illustration: the scene's parallax layers with the
/// page's cast placed in the cast layer.
///
/// Characters idle, blink and act out their [mood]; [cues] holds a counter
/// per cast member, and each bump plays a one-shot action (a hop for
/// characters, a wiggle for props) as narration reaches their word.
class StoryScene extends StatelessWidget {
  const StoryScene({
    super.key,
    required this.spec,
    required this.cast,
    this.cues = const [],
    this.entrances = true,
    this.offset,
    this.onCastTap,
    this.help,
    this.secrets = false,
    this.onSecretFound,
    this.onHelpRub,
  });

  final SceneSpec spec;
  final List<CastMember> cast;
  final List<int> cues;

  /// False when the scene arrives already set (e.g. the home card growing
  /// into the story): the cast is in place instead of walking in.
  final bool entrances;
  final ValueListenable<double>? offset;

  /// A cast member (by index) was tapped. Null leaves the cast untouchable.
  final void Function(int index)? onCastTap;

  /// The page's tap-to-help moment, if it has one.
  final HelpController? help;

  /// Whether the scene's hidden surprises are out to be found (only while
  /// a story plays, not on Home's cards).
  final bool secrets;

  /// A surprise was found, at this global position.
  final ValueChanged<Offset>? onSecretFound;

  /// The child is rubbing the help item, at this global position.
  final ValueChanged<Offset>? onHelpRub;

  @override
  Widget build(BuildContext context) {
    return ParallaxScene(
      period: const Duration(seconds: 14),
      offsetListenable: offset,
      layers: [
        for (final layer in spec.layers)
          ParallaxLayer(
            depth: layer.depth,
            drift: layer.drift,
            bob: layer.bob,
            fitViewport: layer.isCast,
            child: layer.isCast
                ? _CastLayer(
                    cast: cast,
                    cues: cues,
                    entrances: entrances,
                    onTap: onCastTap,
                    help: help,
                    secrets: secrets ? spec.secrets : const [],
                    onSecretFound: onSecretFound,
                    onHelpRub: onHelpRub,
                  )
                // Scenery never takes a touch, so taps reach the cast beneath
                // the foreground leaves.
                : IgnorePointer(
                    child: Illustration(
                      layer.asset,
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
          ),
      ],
    );
  }
}

class _CastLayer extends StatelessWidget {
  const _CastLayer({
    required this.cast,
    required this.cues,
    required this.entrances,
    required this.onTap,
    required this.help,
    required this.secrets,
    required this.onSecretFound,
    required this.onHelpRub,
  });

  final List<CastMember> cast;
  final List<int> cues;
  final bool entrances;
  final void Function(int index)? onTap;
  final HelpController? help;
  final List<SceneSecret> secrets;
  final ValueChanged<Offset>? onSecretFound;
  final ValueChanged<Offset>? onHelpRub;

  @override
  Widget build(BuildContext context) {
    final help = this.help;
    if (help == null) return _layout(context, null);
    return ListenableBuilder(
      listenable: help,
      builder: (context, _) => _layout(context, help),
    );
  }

  Widget _layout(BuildContext context, HelpController? help) {
    final progress = help?.progress ?? 0;
    final moment = help?.moment;
    final waiting = help != null && help.active && moment != null;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        Offset centre(int i) {
          final m = cast[i];
          return Offset(m.x * w, (m.y - m.size / 2) * h);
        }

        final item = waiting && moment.item < cast.length ? moment.item : null;
        final to = waiting && moment.to != null && moment.to! < cast.length
            ? moment.to
            : null;
        final glowSize = item == null
            ? 0.0
            : math.max(cast[item].size * h * 1.6, AppSizes.secretHitMin * 1.5);
        final rubSize = item == null
            ? 0.0
            : math.max(cast[item].size * h * 1.8, w * 0.36);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Hidden surprises sit behind the cast, waiting to be found.
            for (final (i, s) in secrets.indexed)
              Positioned(
                key: ValueKey('secret$i'),
                left: s.x * w,
                top: s.y * h,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -1),
                  child: SceneSecretView(
                    secret: s,
                    height: s.size * h,
                    onFound: onSecretFound,
                  ),
                ),
              ),
            // A glow on what to touch (and where a drag goes).
            for (final g in {?item, ?to})
              Positioned(
                key: ValueKey('helpGlow$g'),
                left: centre(g).dx - glowSize / 2,
                top: centre(g).dy - glowSize / 2,
                child: HelpGlow(size: glowSize),
              ),
            for (final (i, m) in cast.indexed)
              // Not yet earned by the child's help: not there at all, so
              // its entrance plays the moment it is revealed.
              if (progress >= m.helpStep)
                Positioned(
                  key: ValueKey('cast$i'),
                  left: m.x * w,
                  top: m.y * h,
                  // Anchor the art's bottom-centre on (x, y).
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -1),
                    child: _helpGone(
                      gone: !m.shownAt(progress),
                      child: _interactive(
                        i,
                        help,
                        item: item,
                        home: centre(i),
                        target: to == null ? null : centre(to),
                        width: w,
                        child: _CastMemberView(
                          member: m,
                          screen: Size(w, h),
                          index: i,
                          cue: i < cues.length ? cues[i] : 0,
                          entrance: entrances,
                          revealed: m.helpStep > 0,
                        ),
                      ),
                    ),
                  ),
                ),
            if (item != null && moment!.kind == HelpKind.rub)
              Positioned(
                key: const ValueKey('helpRub'),
                left: centre(item).dx - rubSize / 2,
                top: centre(item).dy - rubSize / 2,
                width: rubSize,
                height: rubSize,
                child: HelpRubArea(
                  controller: help!,
                  stepLength: w * AppSizes.helpRubStep,
                  onRub: (at) {
                    onTap?.call(item);
                    onHelpRub?.call(at);
                  },
                ),
              ),
            if (item != null && help!.showHint)
              Positioned.fill(
                key: const ValueKey('helpHand'),
                child: IgnorePointer(
                  child: HelpHintHand(
                    kind: moment!.kind,
                    from: centre(item),
                    to: to == null ? centre(item) : centre(to),
                    span: rubSize * 0.3,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// The help item takes the child's drag or taps; everyone else just
  /// reacts to a tap.
  Widget _interactive(
    int i,
    HelpController? help, {
    required int? item,
    required Offset home,
    required Offset? target,
    required double width,
    required Widget child,
  }) {
    if (help != null && i == item) {
      final moment = help.moment!;
      if (moment.kind == HelpKind.drag && target != null) {
        return HelpDragItem(
          controller: help,
          home: home,
          target: target,
          reach: width * AppSizes.helpDropReach,
          child: child,
        );
      }
      if (moment.kind == HelpKind.tap) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            onTap?.call(i);
            help.step();
          },
          child: child,
        );
      }
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap == null ? null : () => onTap!(i),
      child: child,
    );
  }

  /// Fades out a cast member the child's help has done away with.
  static Widget _helpGone({required bool gone, required Widget child}) =>
      IgnorePointer(
        ignoring: gone,
        child: AnimatedOpacity(
          opacity: gone ? 0 : 1,
          duration: AppMotion.pressRelease,
          child: child,
        ),
      );
}

class _CastMemberView extends StatelessWidget {
  const _CastMemberView({
    required this.member,
    required this.screen,
    required this.index,
    required this.cue,
    required this.entrance,
    this.revealed = false,
  });

  final CastMember member;
  final Size screen;
  final int index;
  final int cue;
  final bool entrance;

  /// Brought on by the child's help: it swaps in quickly (a character
  /// changing pose) or pops in (a prop), rather than making an entrance.
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final m = member;
    final height = m.size * screen.height;
    final rig = CharacterRig.of(m.art);
    Widget art = m.art.isPuppet
        ? PuppetView(
            id: m.art.id,
            height: height,
            pose: m.pose,
            act: m.act,
            face: m.face,
            mood: m.mood,
            look: m.look,
            hold: m.hold,
            holdSize: m.holdSize,
            holdTurn: m.holdTurn,
            holdHand: m.holdHand,
            cue: cue,
            seed: index,
          )
        : rig == null
        ? SizedBox(height: height, child: Illustration(m.art.sceneAsset))
        : _BlinkingCharacter(rig: rig, art: m.art, height: height, seed: index);
    if (m.flip) art = Transform.flip(flipX: true, child: art);
    if (m.turn != 0) {
      art = Transform.rotate(angle: m.turn * math.pi / 180, child: art);
    }
    art = _CueAction(cue: cue, prop: !m.art.isCharacter, child: art);

    // Mood: a looping bit of acting.
    art = switch (m.mood) {
      CastMood.idle || CastMood.shy || CastMood.sleepy =>
        art
            .animate(
              delay: (index * 180).ms,
              onPlay: (a) => a.repeat(reverse: true),
            )
            .moveY(begin: 0, end: -4, duration: 1500.ms, curve: AppMotion.soft),
      CastMood.worried =>
        art
            .animate(onPlay: (a) => a.repeat(reverse: true))
            .moveX(begin: -1.5, end: 1.5, duration: 260.ms),
      CastMood.twinkle =>
        art
            .animate(
              delay: (index * 230).ms,
              onPlay: (a) => a.repeat(reverse: true),
            )
            .scaleXY(
              begin: 0.7,
              end: 1.1,
              duration: 700.ms,
              curve: AppMotion.soft,
            )
            .fade(begin: 0.45, end: 1, duration: 700.ms),
      CastMood.float =>
        art
            .animate(
              delay: (index * 200).ms,
              onPlay: (a) => a.repeat(reverse: true),
            )
            .moveY(begin: 0, end: -10, duration: 1800.ms, curve: AppMotion.soft)
            .rotate(begin: -0.02, end: 0.02, duration: 1800.ms),
      CastMood.happy =>
        art
            .animate(
              delay: (index * 140).ms,
              onPlay: (a) => a.repeat(reverse: true),
            )
            .moveY(begin: 0, end: -14, duration: 380.ms, curve: Curves.easeOut)
            .scaleXY(begin: 1, end: 1.03, duration: 380.ms),
      CastMood.sad =>
        art
            .animate(onPlay: (a) => a.repeat(reverse: true))
            .rotate(
              begin: -0.01,
              end: -0.035,
              alignment: Alignment.bottomCenter,
              duration: 2200.ms,
              curve: AppMotion.soft,
            )
            .scaleY(
              begin: 1,
              end: 0.97,
              alignment: Alignment.bottomCenter,
              duration: 2200.ms,
            ),
      CastMood.surprised =>
        art
            .animate(onPlay: (a) => a.repeat(reverse: true))
            .moveY(begin: 0, end: -3, duration: 1200.ms, curve: AppMotion.soft)
            .animate()
            .moveY(begin: 0, end: -22, duration: 220.ms, curve: Curves.easeOut)
            .then()
            .moveY(
              begin: 0,
              end: 22,
              duration: 420.ms,
              curve: Curves.bounceOut,
            ),
    };

    if (m.orbit case final o?) {
      art = _Orbit(orbit: o, screen: screen, flipped: m.flip, child: art);
    }
    if (m.until case final until?) {
      art = art
          .animate(delay: until)
          .fadeOut(duration: 500.ms)
          .scaleXY(
            end: 0.6,
            duration: 500.ms,
            alignment: Alignment.bottomCenter,
          );
    }

    if (!entrance) {
      if (m.delay == Duration.zero) return art;
      return art.animate(delay: m.delay).fadeIn(duration: 400.ms);
    }

    if (revealed && m.enter == CastEnter.none) {
      return m.art.isCharacter
          ? art.animate(delay: m.delay).fadeIn(duration: 220.ms)
          : art
                .animate(delay: m.delay)
                .fadeIn(duration: 150.ms)
                .scaleXY(
                  begin: 0.3,
                  end: 1,
                  duration: 700.ms,
                  alignment: Alignment.bottomCenter,
                  curve: Curves.elasticOut,
                );
    }
    if (revealed) {
      return _entrance(art, m.delay);
    }

    // Entrance: walk in, drop in, grow up, or pop in.
    return _entrance(art, 250.ms + (index * 120).ms + m.delay);
  }

  Widget _entrance(Widget art, Duration base) {
    final m = member;
    return switch (m.enter) {
      CastEnter.none =>
        art
            .animate(delay: base)
            .fadeIn(duration: 300.ms)
            .scaleXY(begin: 0.85, curve: AppMotion.pop),
      CastEnter.left => _walkIn(art, base, -1),
      CastEnter.right => _walkIn(art, base, 1),
      CastEnter.top =>
        art
            .animate(delay: base)
            .moveY(
              begin: -screen.height * 0.45,
              end: 0,
              duration: 900.ms,
              curve: Curves.bounceOut,
            ),
      CastEnter.grow =>
        art
            .animate(delay: base)
            .fadeIn(duration: 200.ms)
            .scaleXY(
              begin: 0,
              end: 1,
              duration: 1100.ms,
              alignment: Alignment.bottomCenter,
              curve: Curves.elasticOut,
            ),
    };
  }

  /// Slides in from the side with a stepping bounce, like walking.
  Widget _walkIn(Widget art, Duration delay, double side) {
    const steps = 4;
    return art
        .animate(delay: delay)
        .moveX(
          begin: side * screen.width * 0.7,
          end: 0,
          duration: 1100.ms,
          curve: Curves.easeOutCubic,
        )
        .custom(
          duration: 1100.ms,
          builder: (context, t, child) => Transform.translate(
            offset: Offset(
              0,
              -(math.sin(t * math.pi * steps)).abs() * 8 * (1 - t),
            ),
            child: child,
          ),
        );
  }
}

/// Keeps its child flying round an ellipse, turning to face the way it
/// goes (art faces right unless [flipped]).
class _Orbit extends StatefulWidget {
  const _Orbit({
    required this.orbit,
    required this.screen,
    required this.flipped,
    required this.child,
  });

  final CastOrbit orbit;
  final Size screen;
  final bool flipped;
  final Widget child;

  @override
  State<_Orbit> createState() => _OrbitState();
}

class _OrbitState extends State<_Orbit> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.orbit.period,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rx = widget.orbit.rx * widget.screen.width;
    final ry = widget.orbit.ry * widget.screen.height;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final a = _c.value * math.pi * 2;
        // Moving right on the near half of the loop: no turn needed.
        final goingRight = -math.sin(a) * rx > 0;
        return Transform.translate(
          offset: Offset(math.cos(a) * rx, math.sin(a) * ry),
          child: Transform.flip(
            flipX: goingRight == widget.flipped,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Where a character's eyes sit in its SVG, so Noori's cast can blink.
@immutable
class CharacterRig {
  const CharacterRig({
    required this.viewBox,
    required this.eyes,
    required this.lid,
  });

  /// SVG viewBox size.
  final Size viewBox;

  /// Eye centre and the radius the lid must cover, in viewBox units.
  final List<(Offset, double)> eyes;
  final Color lid;

  static CharacterRig? of(PictureRef art) =>
      art.isCharacter ? _rigs[art.id] : null;

  static const _rigs = {
    'rabbit': CharacterRig(
      viewBox: Size(120, 150),
      eyes: [(Offset(50, 60), 6), (Offset(70, 60), 6)],
      lid: CastPalette.rabbitLid,
    ),
    'monkey': CharacterRig(
      viewBox: Size(120, 150),
      eyes: [(Offset(52, 48), 5.6), (Offset(68, 48), 5.6)],
      lid: CastPalette.monkeyLid,
    ),
    'parrot': CharacterRig(
      viewBox: Size(110, 150),
      eyes: [(Offset(46, 44), 5.6), (Offset(64, 44), 5.6)],
      lid: CastPalette.parrotLid,
    ),
    'elephant': CharacterRig(
      viewBox: Size(160, 150),
      eyes: [(Offset(132, 52), 6)],
      lid: CastPalette.elephantLid,
    ),
    'turtle': CharacterRig(
      viewBox: Size(160, 120),
      eyes: [(Offset(142.5, 66.5), 5)],
      lid: CastPalette.turtleLid,
    ),
  };
}

/// A character's art with eyelids that close every few seconds.
class _BlinkingCharacter extends StatefulWidget {
  const _BlinkingCharacter({
    required this.rig,
    required this.art,
    required this.height,
    required this.seed,
  });

  final CharacterRig rig;
  final PictureRef art;
  final double height;
  final int seed;

  @override
  State<_BlinkingCharacter> createState() => _BlinkingCharacterState();
}

class _BlinkingCharacterState extends State<_BlinkingCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: AppMotion.blinkLength,
  );
  late final _random = math.Random(widget.seed * 31 + widget.art.id.hashCode);
  Timer? _next;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    final span = AppMotion.blinkMax - AppMotion.blinkMin;
    _next = Timer(AppMotion.blinkMin + span * _random.nextDouble(), () async {
      if (!mounted) return;
      await _blink.forward(from: 0);
      if (!mounted) return;
      await _blink.reverse();
      if (mounted) _schedule();
    });
  }

  @override
  void dispose() {
    _next?.cancel();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vb = widget.rig.viewBox;
    final night = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: widget.height,
      width: widget.height * vb.width / vb.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(child: Illustration(widget.art.sceneAsset)),
          CustomPaint(painter: _LidPainter(_blink, widget.rig, night: night)),
        ],
      ),
    );
  }
}

class _LidPainter extends CustomPainter {
  _LidPainter(this.blink, this.rig, {required this.night})
    : super(repaint: blink);

  final Animation<double> blink;
  final CharacterRig rig;

  /// Matches the moonlit tint [Illustration] gives the art at bedtime.
  final bool night;

  Color _tint(Color c) =>
      night ? Color.alphaBlend(AppPalette.navy.withValues(alpha: 0.55), c) : c;

  @override
  void paint(Canvas canvas, Size size) {
    final b = blink.value;
    if (b <= 0) return;
    final s = size.width / rig.viewBox.width;
    final lid = Paint()..color = _tint(rig.lid);
    final lash = Paint()
      ..color = _tint(CastPalette.lash)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.6 * s;
    for (final (c, r) in rig.eyes) {
      final centre = c * s;
      final radius = r * s;
      final eye = Rect.fromCircle(center: centre, radius: radius);
      final edge = eye.top + eye.height * b;
      canvas
        ..save()
        ..clipPath(Path()..addOval(eye))
        ..drawRect(Rect.fromLTRB(eye.left, eye.top, eye.right, edge), lid)
        ..restore();
      if (b > 0.55) {
        // The closed eye: a soft downward curve.
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(centre.dx, edge - radius * 0.55),
            width: radius * 1.5,
            height: radius,
          ),
          math.pi * 0.15,
          math.pi * 0.7,
          false,
          lash,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LidPainter old) => old.rig != rig || old.night != night;
}

/// Plays a short action each time [cue] goes up: characters hop with a
/// squash, props wiggle.
class _CueAction extends StatefulWidget {
  const _CueAction({
    required this.cue,
    required this.prop,
    required this.child,
  });

  final int cue;
  final bool prop;
  final Widget child;

  @override
  State<_CueAction> createState() => _CueActionState();
}

class _CueActionState extends State<_CueAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );

  @override
  void didUpdateWidget(_CueAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cue > oldWidget.cue) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        if (t == 0 || t == 1) return child!;
        if (widget.prop) {
          return Transform.rotate(
            angle: math.sin(t * math.pi * 4) * 0.22 * (1 - t),
            alignment: Alignment.bottomCenter,
            child: Transform.scale(
              scale: 1 + math.sin(t * math.pi) * 0.12,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          );
        }
        // Crouch, spring up, land with a squash.
        final lift = math.sin(((t - 0.15) / 0.7).clamp(0.0, 1.0) * math.pi);
        final squash = t < 0.15 ? t / 0.15 : (t > 0.85 ? (1 - t) / 0.15 : 0.0);
        return Transform.translate(
          offset: Offset(0, -lift * 26),
          child: Transform.scale(
            scaleX: 1 + squash * 0.08 - lift * 0.03,
            scaleY: 1 - squash * 0.1 + lift * 0.05,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
