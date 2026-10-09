import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/audio/audio_service.dart';
import '../../core/content/story.dart';
import '../../core/i18n/app_lang.dart';
import '../../core/mascot/noori_guide.dart';
import '../../core/mascot/noori_mascot.dart';
import '../../core/progress/progress.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/confetti_burst.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/firefly_layer.dart';
import '../../core/widgets/flight.dart';
import '../../core/widgets/jar.dart';
import '../../core/widgets/lantern.dart';
import '../../core/widgets/puffy_button.dart';
import 'reward_result.dart';

enum _Act { swirl, stars, words, done }

/// Fireflies swirl into Noori's lantern, stars pop in, then the story's word
/// cards fly into the Word Jar.
class RewardScreen extends ConsumerStatefulWidget {
  const RewardScreen({super.key, required this.storyId, this.result});

  final String storyId;

  /// Null if opened without a quiz (e.g. after a restart): show saved stars.
  final RewardResult? result;

  @override
  ConsumerState<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends ConsumerState<RewardScreen>
    with TickerProviderStateMixin {
  final _guide = NooriGuideController();
  final _rain = GlobalKey<ConfettiBurstState>();
  final _jarKey = GlobalKey();
  late final AudioService _audio = ref.read(audioServiceProvider);

  late final AnimationController _swirl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..addListener(_onSwirlTick);
  late final AnimationController _rays = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  _Act _act = _Act.swirl;
  int _landed = 0;
  int _starsShown = 0;
  List<({String key, LocalizedText word})> _words = const [];
  final _flown = <String>{};
  int _jarBumps = 0;
  bool _cancelled = false;

  late final int _stars =
      widget.result?.stars ??
      ref.read(progressProvider).starsFor(widget.storyId).clamp(1, 3);
  late final int _fireflies = widget.result?.fireflies ?? 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  Future<void> _wait(int ms) async {
    await Future<void>.delayed(Duration(milliseconds: ms));
    if (!mounted) _cancelled = true;
  }

  Future<void> _play() async {
    final story = await ref.read(storyProvider(widget.storyId).future);
    if (!mounted) return;
    _words = [
      for (final id in story.vocabulary)
        if (story.entry(id) case final e?)
          (key: Progress.wordKey(story.id, id), word: e.word),
    ];

    // Act 1: fireflies swirl into the lantern.
    _rain.currentState?.burst();
    _guide
      ..setMood(NooriState.happy)
      ..say('reward_great');
    if (_fireflies > 0) await _swirl.forward();
    await _wait(300);
    if (_cancelled) return;

    // Act 2: stars, one by one.
    setState(() => _act = _Act.stars);
    for (var i = 0; i < 3; i++) {
      await _wait(420);
      if (_cancelled) return;
      setState(() => _starsShown = i + 1);
      _audio.play(i < _stars ? Sfx.chime : Sfx.pop);
    }
    await _wait(700);
    if (_cancelled) return;

    // Act 3: word cards appear, then fly into the jar.
    setState(() => _act = _Act.words);
    _guide.say('reward_word');
    await _wait(1500);
    for (final w in _words) {
      if (_cancelled || !mounted) return;
      final from = centerOf(_wordKeys[w.key]!);
      setState(() => _flown.add(w.key));
      _audio.play(Sfx.whoosh);
      if (from != null) {
        await launchFlight(
          context,
          from: from,
          to: _jarKey,
          flier: _WordCard(word: w.word),
          endScale: 0.15,
          duration: const Duration(milliseconds: 800),
        );
      }
      if (!mounted) return;
      _audio.play(Sfx.pop);
      setState(() => _jarBumps++);
    }
    await _wait(400);
    if (_cancelled) return;

    // Done: the home button breathes, and after a moment the app heads home
    // by itself.
    setState(() => _act = _Act.done);
    _guide.setMood(null);
    _autoHome = Timer(_homeAfter, _goHome);
  }

  static const _homeAfter = Duration(seconds: 6);
  Timer? _autoHome;

  void _goHome() {
    _autoHome?.cancel();
    if (mounted) context.go(Routes.home);
  }

  late final _wordKeys = <String, GlobalKey>{};

  void _onSwirlTick() {
    final arrived = _SwirlPainter.arrivedBy(_swirl.value, _fireflies);
    if (arrived > _landed) {
      setState(() => _landed = arrived);
      _audio.play(Sfx.sparkle);
    }
  }

  @override
  void dispose() {
    _autoHome?.cancel();
    _swirl.dispose();
    _rays.dispose();
    _guide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final total = ref.watch(progressProvider).fireflies;
    for (final w in _words) {
      _wordKeys.putIfAbsent(w.key, GlobalKey.new);
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, box) {
          // Where the lantern sits, shared with the swirl painter.
          final lanternAt = Offset(box.maxWidth / 2, box.maxHeight * 0.44);
          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.1),
                      radius: 1.1,
                      colors: [c.surface, c.backgroundAlt, c.background],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _RaysPainter(_rays, c.primary, lanternAt),
                  ),
                ),
              ),
              const Positioned.fill(child: FireflyLayer(count: 14)),
              // Noori with her big lantern.
              Positioned(
                left: 0,
                right: 0,
                top: lanternAt.dy - AppSizes.mascotLg * 1.05,
                child: Center(
                  child:
                      NooriGuide(
                        controller: _guide,
                        size: AppSizes.mascotLg * 0.8,
                      ).animate().fadeIn().scaleXY(
                        begin: 0.5,
                        curve: AppMotion.elastic,
                        duration: 900.ms,
                      ),
                ),
              ),
              Positioned(
                left: lanternAt.dx - AppSizes.rewardLantern,
                top: lanternAt.dy - AppSizes.rewardLantern * 0.4,
                width: AppSizes.rewardLantern * 2,
                child: Center(
                  child: Lantern(count: total, size: AppSizes.rewardLantern),
                ),
              ),
              if (_landed > 0)
                Positioned(
                  left: lanternAt.dx + AppSizes.rewardLantern * 0.35,
                  top: lanternAt.dy - AppSizes.rewardLantern * 0.6,
                  child:
                      Text(
                            '+$_landed',
                            style: AppTypography.style(
                              AppLang.en,
                              role: TextRole.title,
                              color: c.secondary,
                              weight: 700,
                            ),
                          )
                          .animate(key: ValueKey(_landed))
                          .scaleXY(
                            begin: 1.8,
                            curve: AppMotion.elastic,
                            duration: 600.ms,
                          ),
                ),
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _SwirlPainter(
                        _swirl,
                        count: _fireflies,
                        target: lanternAt,
                      ),
                    ),
                  ),
                ),
              ),
              // Stars.
              Positioned(
                left: 0,
                right: 0,
                top: lanternAt.dy + AppSizes.rewardLantern * 0.9,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.space2,
                        ),
                        child: i < _starsShown
                            ? Icon(
                                    i < _stars
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size:
                                        AppSizes.rewardStar *
                                        (i == 1 ? 1.25 : 1),
                                    color: i < _stars
                                        ? c.primary
                                        : c.onSurfaceSoft.withValues(
                                            alpha: 0.5,
                                          ),
                                    shadows: const [
                                      Shadow(
                                        color: AppPalette.shadow,
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  )
                                  .animate()
                                  .scaleXY(
                                    begin: 0,
                                    curve: AppMotion.elastic,
                                    duration: 800.ms,
                                  )
                                  .rotate(begin: -0.3, end: 0, duration: 600.ms)
                            : SizedBox.square(
                                dimension:
                                    AppSizes.rewardStar * (i == 1 ? 1.25 : 1),
                              ),
                      ),
                  ],
                ),
              ),
              // Word cards, then the jar they fly into.
              Positioned(
                left: AppSizes.space3,
                right: AppSizes.space3,
                bottom: AppSizes.bigTap * 2 + AppSizes.space5,
                child: _act.index >= _Act.words.index
                    ? Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppSizes.space2,
                        runSpacing: AppSizes.space2,
                        children: [
                          for (final (i, w) in _words.indexed)
                            Opacity(
                              opacity: _flown.contains(w.key) ? 0 : 1,
                              child: KeyedSubtree(
                                key: _wordKeys[w.key],
                                child: _WordCard(word: w.word),
                              ),
                            ).popIn(i),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: AppSizes.space4,
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // The jar only receives words here; it opens from Settings.
                      KeyedSubtree(
                            key: _jarKey,
                            child: const JarIcon(size: AppSizes.bigTap),
                          )
                          .animate(key: ValueKey(_jarBumps))
                          .scaleXY(
                            begin: _jarBumps == 0 ? 1 : 1.25,
                            end: 1,
                            curve: AppMotion.elastic,
                            duration: 600.ms,
                          ),
                      if (_act == _Act.done)
                        PuffyIconButton(
                          icon: Icons.home_rounded,
                          semanticLabel: 'Home',
                          size: AppSizes.bigTap,
                          breathe: true,
                          onTap: _goHome,
                        ).popIn(0),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiBurst(key: _rain, rain: true, particles: 10),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A Word Jar card: the word in both languages.
class _WordCard extends StatelessWidget {
  const _WordCard({required this.word});

  final LocalizedText word;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: AppSizes.wordCardWidth * 0.8,
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.space2,
          horizontal: AppSizes.space2,
        ),
        decoration: BoxDecoration(
          color: c.bubble,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(color: c.primary, width: 3),
          boxShadow: const [
            BoxShadow(
              color: AppPalette.shadow,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              child: Text(
                word.en,
                style: AppTypography.style(
                  AppLang.en,
                  role: TextRole.label,
                  color: c.onBubble,
                  weight: 700,
                ),
              ),
            ),
            FittedBox(
              child: Text(
                word.ur,
                textDirection: TextDirection.rtl,
                style: AppTypography.style(
                  AppLang.ur,
                  role: TextRole.label,
                  color: c.onBubble,
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

/// Slowly turning rays of light behind Noori.
class _RaysPainter extends CustomPainter {
  _RaysPainter(this.anim, this.color, this.center) : super(repaint: anim);

  final Animation<double> anim;
  final Color color;
  final Offset center;

  @override
  void paint(Canvas canvas, Size size) {
    const rays = 12;
    final r = size.longestSide;
    final paint = Paint()..color = color.withValues(alpha: 0.14);
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(anim.value * math.pi * 2);
    for (var i = 0; i < rays; i++) {
      final a = i * math.pi * 2 / rays;
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(math.cos(a - 0.12) * r, math.sin(a - 0.12) * r)
          ..lineTo(math.cos(a + 0.12) * r, math.sin(a + 0.12) * r)
          ..close(),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RaysPainter old) =>
      old.color != color || old.center != center;
}

/// Fireflies spiralling in from around the screen into [target].
class _SwirlPainter extends CustomPainter {
  _SwirlPainter(this.anim, {required this.count, required this.target})
    : super(repaint: anim);

  final Animation<double> anim;
  final int count;
  final Offset target;

  static const _span = 0.55;

  /// Each firefly flies during its own window of the animation.
  static (double, double) windowOf(int i, int count) {
    final gap = count <= 1 ? 0.0 : (1 - _span) / (count - 1);
    return (i * gap, i * gap + _span);
  }

  static int arrivedBy(double t, int count) {
    var n = 0;
    for (var i = 0; i < count; i++) {
      if (t >= windowOf(i, count).$2) n++;
    }
    return n;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    final radius = size.shortestSide * 0.55;
    for (var i = 0; i < count; i++) {
      final (a, b) = windowOf(i, count);
      if (t <= a || t >= b) continue;
      final p = Curves.easeInCubic.transform((t - a) / (b - a));
      final angle = i * 2.1 + p * math.pi * 3; // one and a half turns inward
      for (var k = 0; k < 6; k++) {
        final q = (p - k * 0.03).clamp(0.0, 1.0);
        final ang = i * 2.1 + q * math.pi * 3;
        final pos =
            target + Offset(math.cos(ang), math.sin(ang)) * radius * (1 - q);
        final f = 1 - k / 6;
        canvas.drawCircle(
          pos,
          k == 0 ? 7 : 5 * f,
          Paint()
            ..color = (k == 0 ? AppPalette.firefly : AppPalette.fireflyGlow)
                .withValues(alpha: 0.8 * f),
        );
      }
      final head =
          target + Offset(math.cos(angle), math.sin(angle)) * radius * (1 - p);
      canvas.drawCircle(
        head,
        14,
        Paint()..color = AppPalette.fireflyGlow.withValues(alpha: 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(_SwirlPainter old) =>
      old.count != count || old.target != target;
}
