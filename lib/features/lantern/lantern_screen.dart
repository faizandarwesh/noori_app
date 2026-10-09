import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/i18n/app_lang.dart';
import '../../core/mascot/noori_mascot.dart';
import '../../core/progress/progress.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/firefly_layer.dart';
import '../../core/widgets/illustration.dart';
import '../../core/widgets/lantern.dart';
import '../../core/widgets/puffy_button.dart';
import '../home/widgets/dawn_sky.dart';
import 'widgets/firefly_count.dart';

/// Noori's Lantern: the child's own corner, reached by tapping Noori on
/// Home. Every firefly they have earned flies inside the big lantern, and
/// two big doors lead to Noori's wardrobe and the word game.
class LanternScreen extends ConsumerWidget {
  const LanternScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final progress = ref.watch(progressProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DawnSky(night: true),
          const FireflyLayer(count: 18, seed: 13),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.space4),
              child: Column(
                children: [
                  Row(
                    children: [
                      PuffyIconButton(
                        icon: Icons.arrow_back_rounded,
                        semanticLabel: 'Back',
                        color: c.surface,
                        iconColor: c.onSurface,
                        onTap: () => context.pop(),
                      ).popIn(0),
                      const Spacer(),
                      FireflyCount(count: progress.balance).popIn(1),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const NooriMascot(
                          state: NooriState.happy,
                          size: AppSizes.mascotSm * 1.2,
                        ).popIn(2),
                        BigLantern(fireflies: progress.fireflies).popIn(3),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.space5),
                  Row(
                    children: [
                      Expanded(
                        child: _Door(
                          label: const LocalizedText(
                            en: 'Wardrobe',
                            ur: 'کپڑوں کی الماری',
                          ),
                          color: c.secondary,
                          onTap: () => context.push(Routes.wardrobe),
                          picture: const _WardrobePicture(),
                        ).popIn(4),
                      ),
                      const SizedBox(width: AppSizes.space4),
                      Expanded(
                        child: _Door(
                          label: const LocalizedText(
                            en: 'Word game',
                            ur: 'لفظوں کا کھیل',
                          ),
                          color: c.primary,
                          onTap: () => context.push(Routes.wordGame),
                          picture: const _WordGamePicture(),
                        ).popIn(5),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.space4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A big puffy button with a picture, for children who can't read yet.
class _Door extends ConsumerWidget {
  const _Door({
    required this.label,
    required this.color,
    required this.onTap,
    required this.picture,
  });

  final LocalizedText label;
  final Color color;
  final VoidCallback onTap;
  final Widget picture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final lang = ref.watch(appSettingsProvider).lang;
    return PuffyButton(
      semanticLabel: label.en,
      color: color,
      breathe: true,
      padding: const EdgeInsets.all(AppSizes.space3),
      onTap: onTap,
      child: SizedBox(
        height: AppSizes.doorHeight,
        child: Column(
          children: [
            Expanded(child: picture),
            const SizedBox(height: AppSizes.space2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label.of(lang),
                textDirection: lang.direction,
                style: AppTypography.style(
                  lang,
                  role: TextRole.label,
                  color: c.onPrimary,
                  weight: 700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WardrobePicture extends StatelessWidget {
  const _WardrobePicture();

  @override
  Widget build(BuildContext context) {
    // Just a picture: the door takes the tap, not Noori.
    return const IgnorePointer(
      child: FittedBox(
        child: NooriMascot(state: NooriState.happy, size: AppSizes.mascotSm),
      ),
    );
  }
}

class _WordGamePicture extends StatelessWidget {
  const _WordGamePicture();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget card(String art, double angle) => Transform.rotate(
      angle: angle,
      child: Container(
        width: AppSizes.doorCard,
        height: AppSizes.doorCard,
        padding: const EdgeInsets.all(AppSizes.space1),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppSizes.space3),
        ),
        child: Illustration(art, nightTint: false),
      ),
    );
    return FittedBox(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          card('assets/illustrations/props/mango.svg', -0.15),
          card('assets/illustrations/props/ball.svg', 0.05),
          card('assets/illustrations/props/flower.svg', 0.18),
        ],
      ),
    );
  }
}

/// A big lantern with every earned firefly flying around inside it (up to
/// 40 drawn). It glows brighter the more there are.
class BigLantern extends StatefulWidget {
  const BigLantern({super.key, required this.fireflies});

  final int fireflies;

  @override
  State<BigLantern> createState() => _BigLanternState();
}

class _BigLanternState extends State<BigLantern>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Fireflies: ${widget.fireflies}',
      child: RepaintBoundary(
        child: CustomPaint(
          size: const Size(AppSizes.bigLanternW, AppSizes.bigLanternH),
          painter: _BigLanternPainter(_t, widget.fireflies),
        ),
      ),
    );
  }
}

class _BigLanternPainter extends CustomPainter {
  _BigLanternPainter(this.t, this.count) : super(repaint: t);

  final Animation<double> t;
  final int count;

  static final _flies = () {
    final r = math.Random(8);
    return List.generate(
      40,
      (_) => (
        x: r.nextDouble(),
        y: r.nextDouble(),
        speed: 1 + r.nextDouble() * 2,
        phase: r.nextDouble() * math.pi * 2,
      ),
    );
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final glow = glowFor(count);
    final time = t.value * math.pi * 2 * 6;
    final glass = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.2, w * 0.72, h * 0.66),
      Radius.circular(w * 0.24),
    );

    // Halo.
    canvas.drawCircle(
      glass.center,
      w * (0.7 + 0.05 * math.sin(time * 0.5)),
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppPalette.fireflyGlow.withValues(alpha: 0.6 * glow),
            AppPalette.fireflyGlow.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: glass.center, radius: w * 0.8)),
    );

    final metal = Paint()..color = AppPalette.trunk;
    canvas
      ..drawArc(
        Rect.fromLTWH(w * 0.36, 0, w * 0.28, h * 0.16),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = AppPalette.trunk
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.2, h * 0.1, w * 0.6, h * 0.1),
          const Radius.circular(8),
        ),
        metal,
      )
      ..drawRRect(
        glass,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Color.lerp(AppPalette.cream, AppPalette.white, glow)!,
              Color.lerp(AppPalette.cream, AppPalette.firefly, glow)!,
              Color.lerp(
                AppPalette.cream,
                AppPalette.fireflyGlow,
                glow,
              )!.withValues(alpha: 0.9),
            ],
            stops: const [0, 0.5, 1],
          ).createShader(glass.outerRect),
      );

    // The fireflies, drifting inside the glass.
    canvas
      ..save()
      ..clipRRect(glass);
    final inner = glass.outerRect.deflate(w * 0.06);
    final shown = math.min(count, _flies.length);
    for (var i = 0; i < shown; i++) {
      final f = _flies[i];
      final a = time * f.speed * 0.1 + f.phase;
      final p = Offset(
        inner.left + inner.width * (0.5 + 0.42 * math.sin(a + f.x * 6)),
        inner.top + inner.height * (0.5 + 0.42 * math.cos(a * 0.8 + f.y * 6)),
      );
      final twinkle = math.sin(time * f.speed + f.phase) * 0.5 + 0.5;
      canvas
        ..drawCircle(
          p,
          9,
          Paint()..color = AppPalette.white.withValues(alpha: 0.35 * twinkle),
        )
        ..drawCircle(p, 4, Paint()..color = AppPalette.coral);
    }
    canvas.restore();

    final rib = Paint()
      ..color = AppPalette.trunk.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas
      ..drawRRect(glass, rib)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.22, h * 0.86, w * 0.56, h * 0.09),
          const Radius.circular(8),
        ),
        metal,
      );
  }

  @override
  bool shouldRepaint(_BigLanternPainter old) => old.count != count;
}
