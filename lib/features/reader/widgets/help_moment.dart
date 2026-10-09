import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/content/story.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/guide_hint.dart';

/// The state of a page's tap-to-help moment, shared by the reader (which
/// waits on it) and the scene (where the child drags, rubs or taps).
class HelpController extends ChangeNotifier {
  /// No touch for this long brings the hint hand back.
  static const hintAfter = Duration(seconds: 3);

  HelpMoment? _moment;
  int _progress = 0;
  bool _active = false;
  bool _touching = false;
  bool _hint = false;
  Timer? _hintTimer;

  /// Each step the child completes; the reader plays a sound for it.
  VoidCallback? onStep;

  HelpMoment? get moment => _moment;

  /// Steps done so far: cast members show and hide by it.
  int get progress => _progress;

  /// True while the story waits for the child.
  bool get active => _active;
  bool get done => _moment != null && _progress >= _moment!.steps;

  /// Whether the pointing hand should show what to do.
  bool get showHint => _active && _hint && !_touching;

  /// Sets up a new page: nothing done yet, not waiting yet.
  void load(HelpMoment? moment) {
    _hintTimer?.cancel();
    _moment = moment;
    _progress = 0;
    _active = false;
    _touching = false;
    _hint = false;
    notifyListeners();
  }

  /// The story now waits for the child.
  void begin() {
    if (_moment == null || done) return;
    _active = true;
    _scheduleHint(short: true);
    notifyListeners();
  }

  /// One step done (a tap, a stretch of rubbing, the drop).
  void step() {
    final m = _moment;
    if (m == null || !_active || done) return;
    _progress++;
    HapticFeedback.mediumImpact();
    onStep?.call();
    if (done) {
      _active = false;
      _hintTimer?.cancel();
    } else {
      _scheduleHint();
    }
    notifyListeners();
  }

  /// Finishes it for the child (a grown-up skipping, or a long wait).
  void complete() {
    if (_moment == null || done) return;
    _progress = _moment!.steps;
    _active = false;
    _hintTimer?.cancel();
    notifyListeners();
  }

  set touching(bool value) {
    if (_touching == value) return;
    _touching = value;
    if (!value) _scheduleHint();
    notifyListeners();
  }

  void _scheduleHint({bool short = false}) {
    _hintTimer?.cancel();
    _hint = false;
    _hintTimer = Timer(short ? hintAfter ~/ 2 : hintAfter, () {
      _hint = true;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }
}

/// Where cast members sit in the cast layer, so help gestures can find
/// their item and target.
typedef CastBox = Rect Function(int index);

/// Wraps the help item so it can be picked up and dragged. Dropped near its
/// target it counts; dropped anywhere else it floats back home.
class HelpDragItem extends StatefulWidget {
  const HelpDragItem({
    super.key,
    required this.controller,
    required this.home,
    required this.target,
    required this.reach,
    required this.child,
  });

  final HelpController controller;

  /// The item's own centre and the target's centre, in cast-layer space.
  final Offset home, target;

  /// How close counts as on target.
  final double reach;
  final Widget child;

  @override
  State<HelpDragItem> createState() => _HelpDragItemState();
}

class _HelpDragItemState extends State<HelpDragItem>
    with SingleTickerProviderStateMixin {
  Offset _offset = Offset.zero;
  late final AnimationController _back = AnimationController(
    vsync: this,
    duration: AppMotion.entrance,
  )..addListener(() => setState(() => _offset = _from * (1 - _back.value)));
  Offset _from = Offset.zero;

  bool get _live => widget.controller.active;

  void _start(DragStartDetails _) {
    if (!_live) return;
    _back.stop();
    widget.controller.touching = true;
    HapticFeedback.selectionClick();
  }

  void _update(DragUpdateDetails d) {
    if (!_live) return;
    setState(() => _offset += d.delta);
  }

  void _end(DragEndDetails _) {
    final c = widget.controller;
    c.touching = false;
    if (!_live) return;
    final at = widget.home + _offset;
    if ((at - widget.target).distance <= widget.reach) {
      c.step();
    } else {
      _from = _offset;
      _back.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lifted = _offset != Offset.zero && _live;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _start,
      onPanUpdate: _update,
      onPanEnd: _end,
      onPanCancel: () => widget.controller.touching = false,
      child: Transform.translate(
        offset: _offset,
        child: AnimatedScale(
          scale: lifted ? 1.15 : 1,
          duration: AppMotion.pressRelease,
          curve: AppMotion.elastic,
          child: widget.child,
        ),
      ),
    );
  }
}

/// A patch over the help item that counts rubbing: every so far of finger
/// travel is one step, and the item wiggles as it's rubbed.
class HelpRubArea extends StatefulWidget {
  const HelpRubArea({
    super.key,
    required this.controller,
    required this.stepLength,
    required this.onRub,
  });

  final HelpController controller;
  final double stepLength;

  /// A little feedback while rubbing (a wiggle, a sparkle), with where the
  /// finger is globally.
  final ValueChanged<Offset> onRub;

  @override
  State<HelpRubArea> createState() => _HelpRubAreaState();
}

class _HelpRubAreaState extends State<HelpRubArea> {
  double _travel = 0;
  double _sinceFeedback = 0;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => c.touching = true,
      onPanEnd: (_) => c.touching = false,
      onPanCancel: () => c.touching = false,
      onPanUpdate: (d) {
        if (!c.active) return;
        final moved = d.delta.distance;
        _travel += moved;
        _sinceFeedback += moved;
        if (_sinceFeedback > widget.stepLength / 4) {
          _sinceFeedback = 0;
          widget.onRub(d.globalPosition);
        }
        if (_travel >= widget.stepLength) {
          _travel = 0;
          c.step();
        }
      },
    );
  }
}

/// A soft pulsing ring that says "this one" while the story waits.
class HelpGlow extends StatefulWidget {
  const HelpGlow({super.key, required this.size});

  final double size;

  @override
  State<HelpGlow> createState() => _HelpGlowState();
}

class _HelpGlowState extends State<HelpGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = context.colors.primary;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final t = AppMotion.soft.transform(_pulse.value);
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  glow.withValues(alpha: 0.45 + 0.2 * t),
                  glow.withValues(alpha: 0),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The silent pointing hand acting out the help: dragging from item to
/// target, rubbing back and forth, or tapping.
class HelpHintHand extends StatefulWidget {
  const HelpHintHand({
    super.key,
    required this.kind,
    required this.from,
    required this.to,
    required this.span,
  });

  final HelpKind kind;

  /// Where the fingertip starts and (for a drag) ends, in cast-layer space.
  final Offset from, to;

  /// For rubbing: how far the hand sweeps either side.
  final double span;

  @override
  State<HelpHintHand> createState() => _HelpHintHandState();
}

class _HelpHintHandState extends State<HelpHintHand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const hand = AppSizes.hintHandSize;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          top: 0,
          child: AnimatedBuilder(
            animation: _loop,
            builder: (context, child) {
              final t = _loop.value;
              final at = switch (widget.kind) {
                // Hold, carry it over, let go, start again.
                HelpKind.drag => Offset.lerp(
                  widget.from,
                  widget.to,
                  Curves.easeInOut.transform(
                    ((t - 0.15) / 0.6).clamp(0.0, 1.0),
                  ),
                )!,
                HelpKind.rub =>
                  widget.from +
                      Offset(math.sin(t * math.pi * 4) * widget.span, 0),
                HelpKind.tap => widget.from,
              };
              final press = widget.kind == HelpKind.tap
                  ? 1 - 0.18 * math.sin(t * math.pi * 4).abs()
                  : 1.0;
              // Put the fingertip, not the hand's centre, on the spot (as
              // GuideHint does).
              return Transform.translate(
                offset: at - const Offset(hand * 0.2, hand * 0.05),
                child: Transform.scale(scale: press, child: child),
              );
            },
            child: const IgnorePointer(child: PointingHand()),
          ),
        ),
      ],
    );
  }
}
