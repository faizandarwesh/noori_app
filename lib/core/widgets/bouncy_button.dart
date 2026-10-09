import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_service.dart';
import '../theme/app_theme.dart';

/// Wraps any tappable thing with squash-and-stretch press feedback,
/// a tap sound and a light haptic. Primary buttons can also [breathe].
class BouncyButton extends ConsumerStatefulWidget {
  const BouncyButton({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
    this.breathe = false,
    this.sfx = Sfx.tap,
    this.minSize = AppSizes.minTap,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool breathe;
  final Sfx? sfx;

  /// Hit area is never smaller than this (spec: 72dp).
  final double minSize;

  @override
  ConsumerState<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends ConsumerState<BouncyButton>
    with TickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: AppMotion.pressRelease,
    value: 1,
  );
  late final AnimationController _pressDown = AnimationController(
    vsync: this,
    duration: AppMotion.pressDown,
  );
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: AppMotion.breathe,
  );

  // 0 → pressed (0.9), then overshoot to 1.08 and settle at 1.0.
  static final _release = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: AppMotion.pressDownScale,
        end: AppMotion.pressOvershootScale,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: AppMotion.pressOvershootScale,
        end: 1.0,
      ).chain(CurveTween(curve: AppMotion.elastic)),
      weight: 70,
    ),
  ]);

  bool _down = false;

  @override
  void initState() {
    super.initState();
    _syncBreath();
  }

  @override
  void didUpdateWidget(BouncyButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.breathe != widget.breathe) _syncBreath();
  }

  void _syncBreath() {
    if (widget.breathe) {
      _breath.repeat(reverse: true);
    } else {
      _breath
        ..stop()
        ..value = 0;
    }
  }

  bool get _enabled => widget.onTap != null;

  void _onDown(TapDownDetails _) {
    if (!_enabled) return;
    _press.value = 1;
    setState(() => _down = true);
    _pressDown.forward(from: 0);
  }

  void _onUp() {
    if (!_down) return;
    setState(() => _down = false);
    _pressDown.value = 0;
    _press.forward(from: 0);
  }

  void _onTap() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
    final sfx = widget.sfx;
    if (sfx != null) ref.read(audioServiceProvider).play(sfx);
    widget.onTap!();
  }

  @override
  void dispose() {
    _press.dispose();
    _pressDown.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      // A given label describes the whole button; don't append child text.
      excludeSemantics: widget.semanticLabel != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onDown,
        onTapUp: (_) => _onUp(),
        onTapCancel: _onUp,
        onTap: _onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.minSize,
            minHeight: widget.minSize,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: AnimatedBuilder(
              animation: Listenable.merge([_press, _pressDown, _breath]),
              builder: (context, child) {
                final press = _down
                    ? 1 -
                          (1 - AppMotion.pressDownScale) *
                              Curves.easeOut.transform(_pressDown.value)
                    : (_press.value < 1
                          ? _release.transform(_press.value)
                          : 1.0);
                final breath =
                    1 +
                    (AppMotion.breatheScale - 1) *
                        Curves.easeInOutSine.transform(_breath.value);
                return Transform.scale(scale: press * breath, child: child);
              },
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
