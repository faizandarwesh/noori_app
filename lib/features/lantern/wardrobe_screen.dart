import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/audio_service.dart';
import '../../core/i18n/app_lang.dart';
import '../../core/mascot/noori_mascot.dart';
import '../../core/mascot/noori_outfit.dart';
import '../../core/mascot/noori_painter.dart';
import '../../core/progress/progress.dart';
import '../../core/progress/wardrobe.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/confetti_burst.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/firefly_layer.dart';
import '../../core/widgets/flight.dart';
import '../../core/widgets/puffy_button.dart';
import '../../core/widgets/shake.dart';
import 'widgets/firefly_count.dart';

/// Noori's wardrobe: spend fireflies on scarves and hats. Owned things go
/// straight on; a locked one is bought with a sparkle if there are enough
/// fireflies, or gives a soft shake (and the firefly count bounces) if not.
/// Only earned fireflies are spent: no ads, no real money.
class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  static const _scarves = LocalizedText(en: 'Scarves', ur: 'مفلر');
  static const _hats = LocalizedText(en: 'Hats', ur: 'ٹوپیاں');

  final _confetti = GlobalKey<ConfettiBurstState>();
  final _shakes = <String, int>{};
  int _pulse = 0;
  bool _cheering = false;
  Timer? _cheer;

  void _tap(WardrobeItem item) {
    final audio = ref.read(audioServiceProvider);
    final wardrobe = ref.read(wardrobeProvider.notifier);
    if (ref.read(wardrobeProvider).owns(item)) {
      wardrobe.wear(item);
      audio.play(Sfx.pop);
      _celebrate(big: false);
      return;
    }
    switch (wardrobe.buy(item)) {
      case BuyResult.bought:
        audio.play(Sfx.sparkle);
        HapticFeedback.mediumImpact();
        _confetti.currentState?.burst();
        _celebrate(big: true);
      case BuyResult.notEnough:
        // Not yet: a gentle shake and a nudge at the firefly count.
        audio.play(Sfx.tryAgain);
        setState(() {
          _shakes[item.id] = (_shakes[item.id] ?? 0) + 1;
          _pulse++;
        });
      case BuyResult.alreadyOwned:
        break;
    }
  }

  void _celebrate({required bool big}) {
    _cheer?.cancel();
    setState(() => _cheering = true);
    _cheer = Timer(Duration(milliseconds: big ? 1800 : 900), () {
      if (mounted) setState(() => _cheering = false);
    });
  }

  @override
  void dispose() {
    _cheer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lang = ref.watch(appSettingsProvider).lang;
    final balance = ref.watch(progressProvider).balance;
    final wardrobe = ref.watch(wardrobeProvider);

    Widget shelf(LocalizedText title, Iterable<WardrobeItem> items, int at) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title.of(lang),
              textAlign: TextAlign.center,
              textDirection: lang.direction,
              style: AppTypography.style(
                lang,
                role: TextRole.label,
                color: c.onSurfaceSoft,
                weight: 700,
              ),
            ),
            const SizedBox(height: AppSizes.space2),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSizes.space3,
              runSpacing: AppSizes.space3,
              children: [
                for (final (i, item) in items.indexed)
                  Shake(
                    trigger: _shakes[item.id] ?? 0,
                    child: _Tile(
                      item: item,
                      owned: wardrobe.owns(item),
                      wearing: wardrobe.isWearing(item),
                      affordable: balance >= item.price,
                      onTap: () => _tap(item),
                    ),
                  ).popIn(at + i),
              ],
            ),
          ],
        );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [c.skyTop, c.backgroundAlt, c.background],
              ),
            ),
          ),
          const FireflyLayer(count: 10, seed: 17),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.space4),
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
                    FireflyCount(count: balance, pulse: _pulse).popIn(1),
                  ],
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    NooriMascot(
                      state: _cheering ? NooriState.happy : NooriState.idle,
                      size: AppSizes.wardrobePreview,
                    ).popIn(2),
                    ConfettiBurst(key: _confetti, particles: 24),
                  ],
                ),
                const SizedBox(height: AppSizes.space4),
                shelf(
                  _scarves,
                  WardrobeItem.all.where((i) => i.scarf != null),
                  3,
                ),
                const SizedBox(height: AppSizes.space5),
                shelf(_hats, WardrobeItem.all.where((i) => i.hat != null), 9),
                const SizedBox(height: AppSizes.space5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One scarf or hat: its picture, and its price until it's bought.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.item,
    required this.owned,
    required this.wearing,
    required this.affordable,
    required this.onTap,
  });

  final WardrobeItem item;
  final bool owned, wearing, affordable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = item.scarf != null
        ? '${item.scarf!.name} scarf'
        : '${item.hat!.name} hat';
    return BouncyButton(
      semanticLabel: owned ? label : '$label, ${item.price} fireflies',
      sfx: null,
      onTap: onTap,
      child: AnimatedOpacity(
        // Too dear for now: a little faded, never hidden.
        opacity: owned || affordable ? 1 : 0.6,
        duration: AppMotion.entrance,
        child: AnimatedContainer(
          duration: AppMotion.entrance,
          width: AppSizes.wardrobeTile,
          height: AppSizes.wardrobeTile,
          padding: const EdgeInsets.all(AppSizes.space2),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: wearing ? c.primary : c.surface,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: c.backgroundAlt,
                offset: const Offset(0, AppSizes.puffyDepth),
              ),
              if (wearing)
                BoxShadow(
                  color: c.primary.withValues(alpha: 0.6),
                  blurRadius: 18,
                ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: item.scarf != null
                      ? _ScarfPainter(item.scarf!)
                      : _HatPainter(item.hat!, empty: c.onSurfaceSoft),
                ),
              ),
              if (!owned)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FireflyDot(size: AppSizes.iconSm),
                    Text(
                      '${item.price}',
                      style: AppTypography.style(
                        AppLang.en,
                        role: TextRole.label,
                        color: c.onSurface,
                        weight: 700,
                      ),
                    ),
                  ],
                )
              else if (wearing)
                Icon(
                  Icons.check_circle_rounded,
                  color: c.primary,
                  size: AppSizes.iconSm * 1.2,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A little scarf: a curved band with a stripe and a hanging tail.
class _ScarfPainter extends CustomPainter {
  const _ScarfPainter(this.scarf);

  final NooriScarf scarf;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    final paint = Paint()..color = scarf.color;
    if (scarf.isRainbow) {
      paint.shader = const LinearGradient(colors: NooriPalette.rainbow)
          .createShader(rect);
    }
    final band = Path()
      ..moveTo(w * 0.08, h * 0.3)
      ..quadraticBezierTo(w * 0.5, h * 0.55, w * 0.92, h * 0.3)
      ..lineTo(w * 0.92, h * 0.5)
      ..quadraticBezierTo(w * 0.5, h * 0.78, w * 0.08, h * 0.5)
      ..close();
    canvas
      ..drawPath(band, paint)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.62, h * 0.48, w * 0.18, h * 0.48),
          Radius.circular(w * 0.06),
        ),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(w * 0.12, h * 0.41)
          ..quadraticBezierTo(w * 0.5, h * 0.64, w * 0.88, h * 0.41),
        Paint()
          ..color = scarf.stripe
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
  }

  @override
  bool shouldRepaint(_ScarfPainter old) => old.scarf != scarf;
}

/// One of Noori's hats on its own, cut from her design space. "No hat" is a
/// soft crossed circle.
class _HatPainter extends CustomPainter {
  const _HatPainter(this.hat, {required this.empty});

  final NooriHat hat;
  final Color empty;

  // The part of Noori's 200x230 design where hats are drawn.
  static const _area = Rect.fromLTWH(66, -2, 72, 52);

  @override
  void paint(Canvas canvas, Size size) {
    if (hat == NooriHat.none) {
      final r = size.shortestSide * 0.32;
      final c = size.center(Offset.zero);
      final p = Paint()
        ..color = empty
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas
        ..drawCircle(c, r, p)
        ..drawLine(c + Offset(-r, r) * 0.7, c + Offset(r, -r) * 0.7, p);
      return;
    }
    final s = (size.width / _area.width) < (size.height / _area.height)
        ? size.width / _area.width
        : size.height / _area.height;
    canvas
      ..save()
      ..translate(
        (size.width - _area.width * s) / 2,
        (size.height - _area.height * s) / 2,
      )
      ..scale(s)
      ..translate(-_area.left, -_area.top);
    NooriPainter.paintHat(canvas, hat);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HatPainter old) => old.hat != hat || old.empty != empty;
}
