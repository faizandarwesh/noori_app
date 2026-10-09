import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A burst of confetti in the app's colours. Call [ConfettiBurstState.burst]
/// through a GlobalKey. [rain] sprinkles downward from the top instead.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.rain = false, this.particles = 16});

  final bool rain;
  final int particles;

  @override
  State<ConfettiBurst> createState() => ConfettiBurstState();
}

class ConfettiBurstState extends State<ConfettiBurst> {
  late final ConfettiController _c = ConfettiController(
    duration: Duration(milliseconds: widget.rain ? 1600 : 400),
  );

  static const colors = [
    AppPalette.sunshine,
    AppPalette.coral,
    AppPalette.mint,
    AppPalette.sky,
    AppPalette.peach,
    AppPalette.fireflyGlow,
  ];

  void burst() => _c.play();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ConfettiWidget(
        confettiController: _c,
        blastDirectionality: widget.rain
            ? BlastDirectionality.directional
            : BlastDirectionality.explosive,
        blastDirection: 1.5708, // straight down, for rain
        emissionFrequency: widget.rain ? 0.08 : 0.02,
        numberOfParticles: widget.particles,
        maxBlastForce: widget.rain ? 8 : 22,
        minBlastForce: widget.rain ? 3 : 8,
        gravity: 0.25,
        colors: colors,
        minimumSize: const Size(10, 6),
        maximumSize: const Size(18, 10),
      ),
    );
  }
}
