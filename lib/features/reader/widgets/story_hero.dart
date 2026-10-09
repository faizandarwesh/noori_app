import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// The hero that carries a story's opening scene from its Home card into
/// the reader. Both ends show the scene laid out at full screen size, so the
/// flight is a pure scale: no relayout per frame, and the card's rounded
/// corners ease to square as it lands.
class StoryHero extends StatelessWidget {
  const StoryHero({super.key, required this.storyId, required this.child});

  final String storyId;

  /// The scene, laid out at screen size.
  final Widget child;

  static Object tag(String storyId) => 'story-scene-$storyId';

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag(storyId),
      flightShuttleBuilder: _shuttle,
      child: child,
    );
  }

  static Widget _shuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromContext,
    BuildContext toContext,
  ) {
    final hero =
        (direction == HeroFlightDirection.push ? toContext : fromContext).widget
            as Hero;
    final screen = MediaQuery.sizeOf(flightContext);
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => ClipRRect(
        borderRadius: BorderRadius.circular(
          lerpDouble(AppSizes.radiusLg, 0, curved.value)!,
        ),
        child: child,
      ),
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox.fromSize(size: screen, child: hero.child),
      ),
    );
  }
}
