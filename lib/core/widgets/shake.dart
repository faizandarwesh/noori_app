import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Gives its child a soft side-to-side shake each time [trigger] changes.
class Shake extends StatefulWidget {
  const Shake({
    super.key,
    required this.trigger,
    required this.child,
    this.distance = 8,
    this.rotation = 0.08,
  });

  final int trigger;
  final Widget child;
  final double distance;
  final double rotation;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void didUpdateWidget(Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) _c.forward(from: 0);
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
        // Three wobbles that fade out.
        final t = _c.value;
        final wave = math.sin(t * math.pi * 6) * (1 - t);
        return Transform.translate(
          offset: Offset(wave * widget.distance, 0),
          child: Transform.rotate(angle: wave * widget.rotation, child: child),
        );
      },
      child: widget.child,
    );
  }
}
