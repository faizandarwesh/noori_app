import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Watches for child interaction on a screen. After [idleAfter] with no
/// touches it turns "idle": every [GuideHint] marked active shows its
/// pointing hand and [onIdle] fires so Noori can repeat the hint. It keeps
/// repeating every [repeatEvery] (up to [maxRepeats]) until the child touches
/// the screen.
class GuideScope extends StatefulWidget {
  const GuideScope({
    super.key,
    required this.child,
    this.onIdle,
    this.idleAfter = AppMotion.idleHint,
    this.repeatEvery = AppMotion.hintRepeat,
    this.maxRepeats = 3,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onIdle;
  final Duration idleAfter;
  final Duration repeatEvery;
  final int maxRepeats;
  final bool enabled;

  static GuideScopeState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<GuideScopeState>();

  @override
  State<GuideScope> createState() => GuideScopeState();
}

class GuideScopeState extends State<GuideScope> {
  final _idle = ValueNotifier<bool>(false);
  Timer? _timer;
  int _repeats = 0;

  @override
  void initState() {
    super.initState();
    restart();
  }

  @override
  void didUpdateWidget(GuideScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) restart();
  }

  /// Noori finished a line. Start counting idle time from now, unless the
  /// hint is already showing (then keep the hand up).
  void speechEnded() {
    if (!_idle.value) restart();
  }

  /// Reset the idle clock and hide any hint.
  void restart() {
    _timer?.cancel();
    _idle.value = false;
    _repeats = 0;
    if (widget.enabled) _timer = Timer(widget.idleAfter, _becomeIdle);
  }

  void _becomeIdle() {
    if (!mounted) return;
    _idle.value = true;
    widget.onIdle?.call();
    if (_repeats < widget.maxRepeats) {
      _repeats++;
      _timer = Timer(widget.repeatEvery, _becomeIdle);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => restart(),
      child: _GuideIdle(notifier: _idle, child: widget.child),
    );
  }
}

class _GuideIdle extends InheritedNotifier<ValueNotifier<bool>> {
  const _GuideIdle({required super.notifier, required super.child});
}

/// Marks the next expected action. When the surrounding [GuideScope] goes
/// idle and [active] is true, a pulsing hand taps on this widget.
class GuideHint extends StatelessWidget {
  const GuideHint({
    super.key,
    required this.child,
    this.active = true,
    this.handOffset = const Offset(0.35, 0.35),
  });

  final Widget child;
  final bool active;

  /// Where the fingertip lands, as a fraction of the child's size from centre.
  final Offset handOffset;

  @override
  Widget build(BuildContext context) {
    final idle =
        context
            .dependOnInheritedWidgetOfExactType<_GuideIdle>()
            ?.notifier
            ?.value ??
        false;
    final show = active && idle;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: Alignment(handOffset.dx * 2, handOffset.dy * 2),
              child: FractionalTranslation(
                // Put the fingertip, not the hand's centre, on the target.
                translation: const Offset(-0.2, -0.05),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (c, a) =>
                      ScaleTransition(scale: a, child: c),
                  child: show
                      ? const PointingHand(key: ValueKey('hand'))
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A cartoon hand that taps repeatedly, with a ripple at the fingertip.
class PointingHand extends StatefulWidget {
  const PointingHand({super.key, this.size = AppSizes.hintHandSize});

  final double size;

  @override
  State<PointingHand> createState() => _PointingHandState();
}

class _PointingHandState extends State<PointingHand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size * 1.4),
        painter: _HandPainter(_c, context.colors.primary),
      ),
    );
  }
}

class _HandPainter extends CustomPainter {
  _HandPainter(this.anim, this.ripple) : super(repaint: anim);

  final Animation<double> anim;
  final Color ripple;

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    // Press in during the first 35%, then lift.
    final press = t < 0.35
        ? Curves.easeIn.transform(t / 0.35)
        : 1 - Curves.easeOut.transform(((t - 0.35) / 0.65).clamp(0, 1));
    final s = size.width / 90;
    final tip = Offset(size.width * 0.3, size.height * 0.18);

    // Ripple rings at the fingertip once pressed.
    if (t > 0.3) {
      final rt = (t - 0.3) / 0.7;
      canvas.drawCircle(
        tip,
        (8 + 26 * rt) * s,
        Paint()
          ..color = ripple.withValues(alpha: (1 - rt) * 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * s,
      );
    }

    canvas
      ..save()
      ..translate(0, (1 - press) * 10 * s)
      ..translate(tip.dx, tip.dy)
      ..rotate(-math.pi / 10)
      ..scale(s * (1 - press * 0.06));

    final fill = Paint()..color = AppPalette.white;
    final outline = Paint()
      ..color = AppPalette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;
    // Hand shape drawn with the fingertip at (0, 0).
    final hand = Path()
      ..moveTo(-7, 6)
      ..lineTo(-7, 30)
      ..quadraticBezierTo(-18, 26, -22, 34)
      ..quadraticBezierTo(-24, 40, -16, 46)
      ..lineTo(-4, 62)
      ..quadraticBezierTo(4, 72, 18, 72)
      ..lineTo(30, 72)
      ..quadraticBezierTo(44, 72, 44, 56)
      ..lineTo(44, 40)
      ..quadraticBezierTo(44, 32, 36, 32)
      ..quadraticBezierTo(34, 26, 26, 27)
      ..quadraticBezierTo(22, 22, 15, 24)
      ..quadraticBezierTo(12, 20, 7, 22)
      ..lineTo(7, 6)
      ..arcToPoint(
        const Offset(-7, 6),
        radius: const Radius.circular(7),
        clockwise: false,
      )
      ..close();
    canvas
      ..drawShadow(hand, AppPalette.shadow, 4, false)
      ..drawPath(hand, fill)
      ..drawPath(hand, outline)
      ..restore();
  }

  @override
  bool shouldRepaint(_HandPainter old) => old.ripple != ripple;
}
