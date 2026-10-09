import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/audio/audio_service.dart';
import '../../core/i18n/app_lang.dart';
import '../../core/mascot/noori_mascot.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/firefly_layer.dart';

/// Night sky; fireflies gather into "Noori", then "نوری"; Noori flies in and
/// waves. About 2.6 seconds, tap anywhere to skip. Noori is silent here: her
/// one greeting comes on the first visit to Home.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _flyCount = 180;

  // Timeline, as fractions of the controller.
  static const _gatherEnd = 0.36;
  static const _morphStart = 0.46;
  static const _morphEnd = 0.64;
  static const _flyInStart = 0.58;
  static const _flyInEnd = 0.8;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  final _random = math.Random(11);
  List<Offset> _starts = const [];
  List<Offset> _english = const [];
  List<Offset> _urdu = const [];
  List<double> _delays = const [];
  bool _left = false;
  bool _sparkled = false;
  bool _whooshed = false;

  /// Leaves even if the letter sampling never completes.
  Timer? _fallback;

  @override
  void initState() {
    super.initState();
    _c
      ..addListener(_cues)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _leave();
      });
    _fallback = Timer(const Duration(milliseconds: 4000), _leave);
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    final en = await _sampleWord(
      'Noori',
      AppTypography.style(
        AppLang.en,
        role: TextRole.display,
        weight: 700,
      ).copyWith(fontSize: AppTypeScale.splashEn, height: 1),
    );
    final ur = await _sampleWord(
      'نوری',
      AppTypography.style(
        AppLang.ur,
        role: TextRole.display,
        weight: 700,
      ).copyWith(fontSize: AppTypeScale.splashUr, height: 1.6),
    );
    if (!mounted) return;
    setState(() {
      _english = _fit(en);
      _urdu = _fit(ur);
      _starts = List.generate(
        _flyCount,
        (_) =>
            Offset(_random.nextDouble() * 2 - 1, _random.nextDouble() * 2 - 1),
      );
      _delays = List.generate(_flyCount, (_) => _random.nextDouble() * 0.35);
    });
    _c.forward();
  }

  /// Renders [text] off-screen and returns points on its letters, centred.
  static Future<List<Offset>> _sampleWord(String text, TextStyle style) async {
    final dir = RegExp(r'[؀-ۿ]').hasMatch(text)
        ? TextDirection.rtl
        : TextDirection.ltr;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(color: AppPalette.white),
      ),
      textDirection: dir,
    )..layout();
    final w = tp.width.ceil(), h = tp.height.ceil();
    final rec = ui.PictureRecorder();
    tp.paint(Canvas(rec), Offset.zero);
    final image = await rec.endRecording().toImage(w, h);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    tp.dispose();
    if (data == null) return const [];
    const step = 5;
    return [
      for (var y = 0; y < h; y += step)
        for (var x = 0; x < w; x += step)
          if (data.getUint8((y * w + x) * 4 + 3) > 140)
            Offset(x - w / 2, y - h / 2),
    ];
  }

  /// Exactly [_flyCount] points, sorted left→right so morphs flow smoothly.
  List<Offset> _fit(List<Offset> points) {
    if (points.isEmpty) return List.filled(_flyCount, Offset.zero);
    final out = [
      for (var i = 0; i < _flyCount; i++)
        points[(i * points.length / _flyCount).floor()],
    ]..sort((a, b) => a.dx.compareTo(b.dx));
    return out;
  }

  void _cues() {
    final t = _c.value;
    final audio = ref.read(audioServiceProvider);
    if (!_sparkled && t > _gatherEnd - 0.05) {
      _sparkled = true;
      audio.play(Sfx.sparkle);
    }
    if (!_whooshed && t > _flyInStart) {
      _whooshed = true;
      audio.play(Sfx.whoosh);
    }
  }

  void _leave() {
    if (_left || !mounted) return;
    _left = true;
    final chosen = ref.read(appSettingsProvider).languageChosen;
    context.go(chosen ? Routes.home : Routes.language);
  }

  @override
  void dispose() {
    _fallback?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _leave,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppPalette.navy, AppPalette.indigo],
                ),
              ),
            ),
            const FireflyLayer(count: 16, seed: 3, maxRadius: 2.5),
            if (_starts.isNotEmpty)
              RepaintBoundary(
                child: CustomPaint(
                  painter: _WordSwarmPainter(
                    _c,
                    starts: _starts,
                    english: _english,
                    urdu: _urdu,
                    delays: _delays,
                  ),
                ),
              ),
            AnimatedBuilder(
              animation: _c,
              builder: (context, child) {
                final size = MediaQuery.sizeOf(context);
                final p = Curves.easeOutCubic.transform(
                  ((_c.value - _flyInStart) / (_flyInEnd - _flyInStart)).clamp(
                    0,
                    1,
                  ),
                );
                // Swoop in from the top-left along a gentle arc.
                final x = ui.lerpDouble(-0.3, 0.5, p)! * size.width;
                final y =
                    (ui.lerpDouble(0.15, 0.7, p)! -
                        math.sin(p * math.pi) * 0.08) *
                    size.height;
                return Positioned(
                  left: x - AppSizes.mascotMd / 2,
                  top: y - AppSizes.mascotMd * 0.6,
                  child: child!,
                );
              },
              child: const NooriMascot(
                state: NooriState.happy,
                size: AppSizes.mascotMd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordSwarmPainter extends CustomPainter {
  _WordSwarmPainter(
    this.anim, {
    required this.starts,
    required this.english,
    required this.urdu,
    required this.delays,
  }) : super(repaint: anim);

  final Animation<double> anim;
  final List<Offset> starts, english, urdu;
  final List<double> delays;

  final _glow = Paint();
  final _core = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    final centre = Offset(size.width / 2, size.height * 0.36);
    for (var i = 0; i < starts.length; i++) {
      final start =
          centre +
          Offset(
            starts[i].dx * size.width * 0.6,
            starts[i].dy * size.height * 0.5,
          );
      // Each firefly arrives a little after the one before.
      final g = Curves.easeOutCubic.transform(
        ((t / _SplashScreenState._gatherEnd - delays[i]) / (1 - delays[i]))
            .clamp(0.0, 1.0),
      );
      final m = Curves.easeInOutCubic.transform(
        ((t - _SplashScreenState._morphStart) /
                (_SplashScreenState._morphEnd - _SplashScreenState._morphStart))
            .clamp(0.0, 1.0),
      );
      final word = Offset.lerp(english[i], urdu[i], m)!;
      // A little hop while morphing so fireflies visibly "fly" between words.
      final hop = Offset(0, -math.sin(m * math.pi) * 18 * ((i % 3) - 1));
      final p = Offset.lerp(start, centre + word + hop, g)!;
      final twinkle = math.sin(t * 40 + i) * 0.5 + 0.5;
      _glow.color = AppPalette.fireflyGlow.withValues(
        alpha: 0.18 + 0.15 * twinkle,
      );
      _core.color = AppPalette.firefly.withValues(alpha: 0.7 + 0.3 * twinkle);
      canvas
        ..drawCircle(p, 5.5, _glow)
        ..drawCircle(p, 2.3, _core);
    }
  }

  @override
  bool shouldRepaint(_WordSwarmPainter old) => old.starts != starts;
}
