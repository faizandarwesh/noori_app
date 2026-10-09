import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/content/scenes.dart';
import '../../../core/content/story.dart';
import '../../../core/i18n/app_lang.dart';
import '../../../core/theme/app_theme.dart';
import '../../reader/widgets/story_hero.dart';
import '../../reader/widgets/story_scene.dart';

/// One story in the Home carousel: its opening scene, alive and in
/// miniature (characters idle and blink, leaves sway, layers parallax with
/// [swipe]), the title, and a golden firefly once the story is finished.
///
/// The scene is laid out at full [screen] size and scaled down, so tapping
/// it can grow it seamlessly into the story through [StoryHero].
class StoryCard extends StatelessWidget {
  const StoryCard({
    super.key,
    required this.storyId,
    required this.title,
    required this.lang,
    required this.screen,
    required this.scene,
    required this.page,
    required this.completed,
    required this.swipe,
  });

  final String storyId;
  final String title;
  final AppLang lang;
  final Size screen;
  final SceneSpec? scene;
  final StoryPage? page;
  final bool completed;

  /// How far this card is from the centre while swiping, -1 to 1.
  final ValueListenable<double> swipe;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final spec = scene, first = page;
    final art = spec == null || first == null
        ? ColoredBox(color: c.backgroundAlt)
        : FittedBox(
            fit: BoxFit.fill,
            child: SizedBox.fromSize(
              size: screen,
              child: StoryScene(
                spec: spec,
                cast: first.cast,
                entrances: false,
                offset: swipe,
              ),
            ),
          );

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: StoryHero(storyId: storyId, child: art),
        ),
        // A soft inner frame so the card reads as a window into the story.
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(color: CinemaPalette.glassBorder, width: 3),
            ),
          ),
        ),
        PositionedDirectional(
          start: AppSizes.space3,
          end: AppSizes.space3,
          bottom: AppSizes.space3,
          child: _TitlePill(text: title, lang: lang),
        ),
        if (completed)
          const PositionedDirectional(
            top: AppSizes.space3,
            end: AppSizes.space3,
            child: GoldenFirefly(),
          ),
      ],
    );
  }
}

class _TitlePill extends StatelessWidget {
  const _TitlePill({required this.text, required this.lang});

  final String text;
  final AppLang lang;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space4,
        vertical: AppSizes.space2,
      ),
      decoration: BoxDecoration(
        color: CinemaPalette.subtitleShade,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          textDirection: lang.direction,
          maxLines: 1,
          style: AppTypography.style(
            lang,
            role: TextRole.label,
            color: CinemaPalette.subtitleText,
            weight: 700,
          ).copyWith(height: lang.isRtl ? 1.7 : 1.2),
        ),
      ),
    );
  }
}

/// The "finished" badge: a small golden firefly, softly pulsing.
class GoldenFirefly extends StatelessWidget {
  const GoldenFirefly({super.key, this.size = AppSizes.badgeFirefly});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Finished',
      child: RepaintBoundary(
        child:
            CustomPaint(
                  size: Size.square(size),
                  painter: const _FireflyBadgePainter(),
                )
                .animate(onPlay: (a) => a.repeat(reverse: true))
                .scaleXY(
                  begin: 0.9,
                  end: 1.08,
                  duration: 1400.ms,
                  curve: AppMotion.soft,
                ),
      ),
    );
  }
}

class _FireflyBadgePainter extends CustomPainter {
  const _FireflyBadgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppPalette.fireflyGlow.withValues(alpha: 0.75),
            AppPalette.fireflyGlow.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // Wings.
    final wing = Paint()..color = AppPalette.white.withValues(alpha: 0.85);
    for (final side in [-1.0, 1.0]) {
      canvas
        ..save()
        ..translate(c.dx + side * r * 0.22, c.dy - r * 0.18)
        ..rotate(side * math.pi / 5)
        ..drawOval(
          Rect.fromCenter(
            center: Offset(side * r * 0.12, -r * 0.08),
            width: r * 0.42,
            height: r * 0.62,
          ),
          wing,
        )
        ..restore();
    }
    // Glowing body.
    canvas
      ..drawCircle(
        c + Offset(0, r * 0.08),
        r * 0.3,
        Paint()..color = AppPalette.sunshine,
      )
      ..drawCircle(
        c + Offset(0, r * 0.12),
        r * 0.2,
        Paint()..color = AppPalette.firefly,
      )
      ..drawCircle(
        c - Offset(0, r * 0.22),
        r * 0.14,
        Paint()..color = AppPalette.ink,
      );
  }

  @override
  bool shouldRepaint(_FireflyBadgePainter old) => false;
}
