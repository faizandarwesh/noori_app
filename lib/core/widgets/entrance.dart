import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_sizes.dart';

extension StaggeredEntrance on Widget {
  /// Pops the widget in after `index` stagger steps, so siblings arrive one
  /// after another rather than all at once.
  Widget popIn(int index, {Duration base = Duration.zero}) =>
      animate(delay: base + AppMotion.stagger * index)
          .fadeIn(duration: 200.ms)
          .scale(
            begin: const Offset(0.6, 0.6),
            duration: AppMotion.entrance,
            curve: AppMotion.pop,
          )
          .moveY(
            begin: 24,
            end: 0,
            duration: AppMotion.entrance,
            curve: AppMotion.pop,
          );
}
