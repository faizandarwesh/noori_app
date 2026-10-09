import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/voice_clips.dart';
import '../../core/i18n/app_lang.dart';
import '../../core/mascot/noori_mascot.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/firefly_layer.dart';
import '../home/widgets/dawn_sky.dart';

/// First launch only, and no buttons at all. Noori sits on a branch holding
/// two glowing lanterns, "A" and "ا". They sway, fireflies circle them, and
/// each pulses in turn with a voice sample. Tapping one bursts it into a
/// swarm of fireflies that flies at the camera, straight into Home.
class LanguagePickScreen extends ConsumerStatefulWidget {
  const LanguagePickScreen({super.key});

  @override
  ConsumerState<LanguagePickScreen> createState() => _LanguagePickScreenState();
}

class _LanguagePickScreenState extends ConsumerState<LanguagePickScreen>
    with TickerProviderStateMixin {
  static const _turn = Duration(milliseconds: 2600);

  /// Rounds of pulses that also play the voice sample; after that the
  /// lanterns keep glowing in turn, silently.
  static const _voicedTurns = 4;

  late final AnimationController _sway = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: AppMotion.lanternBurst,
  );
  late final AudioService _audio = ref.read(audioServiceProvider);

  final _lanternKeys = {AppLang.en: GlobalKey(), AppLang.ur: GlobalKey()};
  Timer? _turns;
  int _turnCount = 0;
  AppLang _pulsing = AppLang.en;
  AppLang? _chosen;
  Offset _burstFrom = Offset.zero;

  @override
  void initState() {
    super.initState();
    _turns = Timer(const Duration(milliseconds: 900), _nextTurn);
    _burst.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) context.go(Routes.home);
    });
  }

  void _nextTurn() {
    if (!mounted || _chosen != null) return;
    final lang = _turnCount.isEven ? AppLang.en : AppLang.ur;
    setState(() => _pulsing = lang);
    _pulse.forward(from: 0);
    if (_turnCount < _voicedTurns) {
      _audio.playVoice(VoiceClips.guide('lang_sample_${lang.name}', lang));
    }
    _turnCount++;
    _turns = Timer(_turn, _nextTurn);
  }

  void _choose(AppLang lang) {
    if (_chosen != null) return;
    _turns?.cancel();
    _audio
      ..stopNarration()
      ..play(Sfx.sparkle)
      ..play(Sfx.whoosh);
    HapticFeedback.mediumImpact();
    ref.read(appSettingsProvider.notifier).setLang(lang);
    final box =
        _lanternKeys[lang]!.currentContext?.findRenderObject() as RenderBox?;
    final self = context.findRenderObject() as RenderBox?;
    if (box != null && self != null) {
      _burstFrom = self.globalToLocal(
        box.localToGlobal(box.size.center(Offset.zero)),
      );
    }
    setState(() => _chosen = lang);
    _burst.forward();
  }

  @override
  void dispose() {
    _turns?.cancel();
    _sway.dispose();
    _pulse.dispose();
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        // Lanterns keep their places whichever language is active.
        textDirection: TextDirection.ltr,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth, h = box.maxHeight;
            final branchY = h * 0.3;
            final noori = Offset(w / 2, branchY);
            const m = AppSizes.branchMascot;
            final mascotH = m * 230 / 200;
            return Stack(
              fit: StackFit.expand,
              children: [
                const DawnSky(night: true),
                const FireflyLayer(count: 14, seed: 9),
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _BranchPainter(_sway, branchY: branchY),
                    ),
                  ),
                ),
                // Noori perched on the branch, watching the glowing lantern.
                Positioned(
                  left: noori.dx - m / 2,
                  top: noori.dy - mascotH * 0.93,
                  child:
                      NooriMascot(
                            size: m,
                            state: _chosen != null
                                ? NooriState.happy
                                : NooriState.idle,
                            look: _chosen != null
                                ? 0
                                : (_pulsing == AppLang.en ? -0.8 : 0.8),
                          )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .moveY(
                            begin: -30,
                            end: 0,
                            duration: 700.ms,
                            curve: Curves.easeOutBack,
                          ),
                ),
                for (final (lang, side) in const [
                  (AppLang.en, -1.0),
                  (AppLang.ur, 1.0),
                ])
                  _HangingLantern(
                    key: _lanternKeys[lang],
                    pivot: noori + Offset(side * m * 0.42, -mascotH * 0.38),
                    side: side,
                    stringLength: h * 0.17,
                    letter: lang == AppLang.en ? 'English' : 'اردو',
                    lang: lang,
                    sway: _sway,
                    pulse: _pulse,
                    pulsing: _pulsing == lang && _chosen == null,
                    gone: _chosen == lang,
                    faded: _chosen != null && _chosen != lang,
                    entranceDelay: (500 + (side > 0 ? 160 : 0)).ms,
                    onTap: () => _choose(lang),
                  ),
                if (_chosen != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _SwarmPainter(_burst, origin: _burstFrom),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A lantern on a string, swinging from a point by Noori's wing.
class _HangingLantern extends StatelessWidget {
  const _HangingLantern({
    super.key,
    required this.pivot,
    required this.side,
    required this.stringLength,
    required this.letter,
    required this.lang,
    required this.sway,
    required this.pulse,
    required this.pulsing,
    required this.gone,
    required this.faded,
    required this.entranceDelay,
    required this.onTap,
  });

  final Offset pivot;
  final double side;
  final double stringLength;
  final String letter;
  final AppLang lang;
  final Animation<double> sway;
  final Animation<double> pulse;
  final bool pulsing, gone, faded;
  final Duration entranceDelay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const w = AppSizes.langLanternW, h = AppSizes.langLanternH;
    final body = Semantics(
      button: true,
      label: lang == AppLang.en ? 'English' : 'اردو',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: RepaintBoundary(
          child: CustomPaint(
            size: const Size(w, h),
            painter: _LanternPainter(
              Listenable.merge([sway, pulse]),
              sway: sway,
              pulse: pulsing ? pulse : null,
              letter: letter,
              lang: lang,
              seed: side,
            ),
          ),
        ),
      ),
    );

    return Positioned(
      left: pivot.dx - w / 2,
      top: pivot.dy,
      child: AnimatedOpacity(
        opacity: gone ? 0 : (faded ? 0.25 : 1),
        duration: Duration(milliseconds: gone ? 160 : 500),
        child: AnimatedBuilder(
          animation: sway,
          builder: (context, child) {
            // Hangs a little outward, swinging like a pendulum.
            final t = sway.value * math.pi * 2;
            final angle = -side * 0.22 + math.sin(t + side) * 0.09;
            return Transform.rotate(
              angle: angle,
              alignment: Alignment.topCenter,
              child: child,
            );
          },
          child: SizedBox(
            width: w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 2,
                  height: stringLength,
                  color: AppPalette.trunk,
                ),
                body,
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: entranceDelay, duration: 500.ms),
    );
  }
}

class _LanternPainter extends CustomPainter {
  _LanternPainter(
    Listenable repaint, {
    required this.sway,
    required this.pulse,
    required this.letter,
    required this.lang,
    required this.seed,
  }) : super(repaint: repaint);

  final Animation<double> sway;
  final Animation<double>? pulse;
  final String letter;
  final AppLang lang;
  final double seed;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final t = sway.value * math.pi * 2;
    final p = pulse == null ? 0.0 : math.sin(pulse!.value * math.pi);
    final glow = 0.55 + 0.45 * p;
    final centre = Offset(w / 2, h * 0.55);

    // Halo, brighter while this lantern takes its turn.
    canvas.drawCircle(
      centre,
      w * (0.62 + 0.14 * p),
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppPalette.fireflyGlow.withValues(alpha: 0.55 * glow),
            AppPalette.fireflyGlow.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: w * 0.76)),
    );

    void fireflies(bool front) {
      for (var i = 0; i < 4; i++) {
        final a = t * (1.2 + i * 0.15) * (seed > 0 ? -1 : 1) + i * 1.57;
        final depth = math.sin(a);
        if ((depth > 0) != front) continue;
        final pos =
            centre +
            Offset(math.cos(a) * w * 0.46, depth * h * 0.12 - h * 0.04 * i);
        final r = 2.4 + depth.abs() * 1.4 * (front ? 1 : 0.5);
        canvas
          ..drawCircle(
            pos,
            r * 3,
            Paint()..color = AppPalette.fireflyGlow.withValues(alpha: 0.25),
          )
          ..drawCircle(
            pos,
            r,
            Paint()
              ..color = AppPalette.firefly.withValues(alpha: front ? 1 : 0.6),
          );
      }
    }

    fireflies(false);

    final scale = 1 + 0.06 * p;
    canvas
      ..save()
      ..translate(centre.dx, centre.dy)
      ..scale(scale)
      ..translate(-centre.dx, -centre.dy);

    final metal = Paint()..color = AppPalette.trunk;
    // Hook and cap.
    canvas
      ..drawArc(
        Rect.fromLTWH(w * 0.38, 0, w * 0.24, h * 0.14),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = AppPalette.trunk
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.22, h * 0.07, w * 0.56, h * 0.09),
          const Radius.circular(6),
        ),
        metal,
      );
    // Glowing glass.
    final glass = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.16, w * 0.68, h * 0.7),
      Radius.circular(w * 0.26),
    );
    canvas.drawRRect(
      glass,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppPalette.white,
            Color.lerp(AppPalette.firefly, AppPalette.white, 0.3 * p)!,
            AppPalette.fireflyGlow.withValues(alpha: 0.85),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(glass.outerRect),
    );
    // Frame ribs.
    final rib = Paint()
      ..color = AppPalette.trunk.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas
      ..drawRRect(glass, rib)
      ..drawLine(Offset(w * 0.5, h * 0.16), Offset(w * 0.5, h * 0.24), rib);
    // Base.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.24, h * 0.86, w * 0.52, h * 0.08),
        const Radius.circular(6),
      ),
      metal,
    );

    // The language's name inside, glowing warm, shrunk to fit the glass.
    final tp = _letter;
    final fit = math.min(1.0, glass.width * 0.86 / tp.width);
    canvas
      ..save()
      ..translate(glass.center.dx, glass.center.dy)
      ..scale(fit);
    tp.paint(
      canvas,
      Offset(-tp.width / 2, -tp.height / 2 - (lang.isRtl ? h * 0.03 : 0)),
    );
    canvas
      ..restore()
      ..restore();

    fireflies(true);
  }

  // Laid out once per painter, not every frame.
  late final TextPainter _letter = TextPainter(
    text: TextSpan(
      text: letter,
      style:
          AppTypography.style(
            lang,
            role: TextRole.title,
            color: AppPalette.coral,
            weight: 700,
          ).copyWith(
            height: 1,
            shadows: [
              Shadow(
                color: AppPalette.sunshine.withValues(alpha: 0.9),
                blurRadius: 14,
              ),
            ],
          ),
    ),
    textDirection: lang.direction,
  )..layout();

  @override
  bool shouldRepaint(_LanternPainter old) =>
      old.pulse != pulse || old.letter != letter;
}

/// The branch Noori sits on, with a few leaves that stir in the breeze.
class _BranchPainter extends CustomPainter {
  _BranchPainter(this.sway, {required this.branchY}) : super(repaint: sway);

  final Animation<double> sway;
  final double branchY;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final t = sway.value * math.pi * 2;
    final bark = Paint()
      ..color = AppPalette.trunk
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(-20, branchY + 34)
      ..quadraticBezierTo(w * 0.3, branchY - 6, w * 0.62, branchY + 2)
      ..quadraticBezierTo(w * 0.85, branchY + 8, w + 20, branchY - 22);
    canvas
      ..drawPath(path, bark..strokeWidth = 16)
      ..drawPath(
        path,
        Paint()
          ..color = AppPalette.white.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );

    final leaf = Paint();
    const spots = [0.08, 0.2, 0.78, 0.9, 0.97];
    final metric = path.computeMetrics().first;
    for (final (i, f) in spots.indexed) {
      final pos = metric.getTangentForOffset(metric.length * f)!.position;
      final a = (i.isEven ? -1 : 1) * 0.9 + math.sin(t * 1.4 + i) * 0.12;
      leaf.color = i.isEven ? AppPalette.leafMid : AppPalette.leafLight;
      canvas
        ..save()
        ..translate(pos.dx, pos.dy)
        ..rotate(a)
        ..drawOval(const Rect.fromLTWH(-9, 0, 18, 40), leaf)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_BranchPainter old) => old.branchY != branchY;
}

/// The chosen lantern bursts: its fireflies fly out and rush toward the
/// camera, growing as they come, then the screen washes gold.
class _SwarmPainter extends CustomPainter {
  _SwarmPainter(this.anim, {required this.origin}) : super(repaint: anim);

  final Animation<double> anim;
  final Offset origin;

  static const _count = 90;
  static final _flies = () {
    final r = math.Random(4);
    return List.generate(
      _count,
      (_) => (
        angle: r.nextDouble() * math.pi * 2,
        speed: 0.45 + r.nextDouble() * 0.55,
        delay: r.nextDouble() * 0.25,
        size: 0.6 + r.nextDouble() * 0.8,
      ),
    );
  }();

  final _glow = Paint();
  final _core = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    final centre = size.center(Offset.zero);
    final reach = size.longestSide;
    for (final f in _flies) {
      final p = ((t - f.delay) / (1 - f.delay)).clamp(0.0, 1.0);
      if (p == 0) continue;
      // Accelerating toward the viewer: farther out and bigger each frame.
      final z = p * p;
      final dir = Offset(math.cos(f.angle), math.sin(f.angle));
      final out = origin + dir * (16 + reach * 0.75 * z * f.speed);
      final pos = Offset.lerp(out, centre + dir * reach * z, p * 0.35)!;
      final radius = (2.5 + 46 * math.pow(z, 2.2) * f.speed) * f.size;
      final alpha = p < 0.7 ? 1.0 : (1 - p) / 0.3;
      _glow.color = AppPalette.fireflyGlow.withValues(alpha: 0.35 * alpha);
      _core.color = AppPalette.firefly.withValues(alpha: alpha);
      canvas
        ..drawCircle(pos, radius * 2.4, _glow)
        ..drawCircle(pos, radius, _core);
    }
    // Golden wash into Home.
    final wash = ((t - 0.6) / 0.4).clamp(0.0, 1.0);
    if (wash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = AppPalette.glowGold.withValues(alpha: wash * wash * 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(_SwarmPainter old) => old.origin != origin;
}
