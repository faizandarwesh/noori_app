import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/i18n/app_lang.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/flight.dart';

/// A glowing firefly and how many there are to spend. Bounces when the
/// number changes; give it a [pulse] bump to draw the eye (e.g. when a child
/// can't afford something yet).
class FireflyCount extends StatelessWidget {
  const FireflyCount({super.key, required this.count, this.pulse = 0});

  final int count;
  final int pulse;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'Fireflies: $count',
      child:
          Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.space2,
                  AppSizes.space1,
                  AppSizes.space4,
                  AppSizes.space1,
                ),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  boxShadow: const [
                    BoxShadow(
                      color: AppPalette.shadow,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FireflyDot(size: AppSizes.iconLg),
                    Text(
                      '$count',
                      style: AppTypography.style(
                        AppLang.en,
                        role: TextRole.title,
                        color: c.onSurface,
                        weight: 700,
                      ),
                    ),
                  ],
                ),
              )
              .animate(key: ValueKey((count, pulse)))
              .scaleXY(
                begin: 1.3,
                end: 1,
                duration: 600.ms,
                curve: Curves.elasticOut,
              ),
    );
  }
}
