import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/audio_service.dart';
import '../../core/audio/voice_clips.dart';
import '../../core/content/catalog.dart';
import '../../core/content/story.dart';
import '../../core/mascot/noori_mascot.dart';
import '../../core/progress/progress.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/confetti_burst.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/firefly_layer.dart';
import '../../core/widgets/guide_hint.dart';
import '../../core/widgets/puppet_view.dart';
import '../../core/widgets/puffy_button.dart';
import '../../core/widgets/shake.dart';
import '../lantern/widgets/firefly_count.dart';

/// A word the game can ask for: it has a picture to tap.
typedef GameWord = ({String storyId, GlossaryEntry entry, bool heard});

/// Every picture word in the open stories, one per picture. Words from
/// stories the child has finished are marked [GameWord.heard] and asked
/// for first.
final wordGamePoolProvider = FutureProvider<List<GameWord>>((ref) async {
  final catalog = await ref.watch(catalogProvider.future);
  final progress = ref.read(progressProvider);
  final byPicture = <String, GameWord>{};
  for (final entry in catalog.playable(progress)) {
    final Story story;
    try {
      story = await ref.watch(storyProvider(entry.id).future);
    } catch (_) {
      continue;
    }
    final heard = progress.isCompleted(story.id);
    for (final g in story.glossary) {
      final pic = g.picture;
      if (pic == null) continue;
      final key = '$pic';
      final had = byPicture[key];
      if (had == null || (heard && !had.heard)) {
        byPicture[key] = (storyId: story.id, entry: g, heard: heard);
      }
    }
  }
  return byPicture.values.toList();
});

/// "Tap the mango!": a word is spoken, and the child taps its picture.
/// Five rounds; finishing them earns a firefly. The Word Jar for children.
class WordGameScreen extends ConsumerStatefulWidget {
  const WordGameScreen({super.key});

  static const rounds = 5;

  @override
  ConsumerState<WordGameScreen> createState() => _WordGameScreenState();
}

class _WordGameScreenState extends ConsumerState<WordGameScreen> {
  final _random = math.Random();
  final _confetti = List.generate(3, (_) => GlobalKey<ConfettiBurstState>());
  late final AudioService _audio = ref.read(audioServiceProvider);

  List<GameWord> _pool = const [];
  final _asked = <String>{};
  int _round = 0;
  GameWord? _target;
  List<GameWord> _cards = const [];
  final _wrong = <int>{};
  final _shakes = [0, 0, 0];
  int? _solved;
  bool _done = false;
  NooriState _mood = NooriState.idle;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pool = await ref.read(wordGamePoolProvider.future);
    if (!mounted || pool.length < 3) return;
    setState(() => _pool = pool);
    _deal();
  }

  /// Picks the next word (heard ones first) and two other pictures.
  void _deal() {
    final fresh = _pool.where((w) => !_asked.contains('${w.entry.picture}'));
    final heard = fresh.where((w) => w.heard).toList();
    final fromFresh = heard.isNotEmpty ? heard : fresh.toList();
    final choices = fromFresh.isNotEmpty ? fromFresh : _pool;
    final target = choices[_random.nextInt(choices.length)];
    _asked.add('${target.entry.picture}');
    final others = [
      for (final w in _pool)
        if ('${w.entry.picture}' != '${target.entry.picture}') w,
    ]..shuffle(_random);
    setState(() {
      _target = target;
      _cards = [target, ...others.take(2)]..shuffle(_random);
      _wrong.clear();
      _solved = null;
      _mood = NooriState.idle;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _say());
  }

  /// Says the word in the narrator's voice (or the device voice until it's
  /// recorded).
  Future<void> _say() async {
    final target = _target;
    if (target == null || !mounted) return;
    final lang = ref.read(appSettingsProvider).lang;
    final played = await _audio.playVoice(
      VoiceClips.word(target.storyId, target.entry.id, lang),
    );
    if (!played) {
      await _audio.speakWordFallback(target.entry.word.of(lang), lang);
    }
  }

  Future<void> _tap(int i) async {
    if (_solved != null || _done) return;
    if (_cards[i] != _target) {
      _audio.play(Sfx.tryAgain);
      setState(() {
        _wrong.add(i);
        _shakes[i]++;
        _mood = NooriState.thinking;
      });
      return;
    }
    _audio.play(Sfx.chime);
    _confetti[i].currentState?.burst();
    setState(() {
      _solved = i;
      _mood = NooriState.happy;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    if (_round + 1 < WordGameScreen.rounds) {
      _round++;
      _deal();
    } else {
      _finish();
    }
  }

  void _finish() {
    ref.read(progressProvider.notifier).addFireflies(1);
    _audio.play(Sfx.sparkle);
    setState(() {
      _done = true;
      _mood = NooriState.happy;
    });
  }

  void _again() {
    _asked.clear();
    setState(() {
      _round = 0;
      _done = false;
    });
    _deal();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lang = ref.watch(appSettingsProvider).lang;
    final balance = ref.watch(progressProvider).balance;
    final target = _target;

    return Scaffold(
      body: GuideScope(
        // A silent pointing hand after 8 quiet seconds.
        enabled: target != null && _solved == null && !_done,
        child: Stack(
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
            const FireflyLayer(count: 10, seed: 23),
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
                        Expanded(
                          child: _RoundDots(round: _round, done: _done),
                        ),
                        FireflyCount(count: balance).popIn(1),
                      ],
                    ),
                    const Spacer(),
                    if (_done)
                      _Finished(onAgain: _again, onBack: () => context.pop())
                    else if (target != null) ...[
                      BouncyButton(
                            semanticLabel: 'Hear the word again',
                            onTap: _say,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.space5,
                                vertical: AppSizes.space3,
                              ),
                              decoration: BoxDecoration(
                                color: c.surface,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusLg,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: c.backgroundAlt,
                                    offset: const Offset(
                                      0,
                                      AppSizes.puffyDepth,
                                    ),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.volume_up_rounded,
                                    color: c.secondary,
                                    size: AppSizes.iconLg,
                                  ),
                                  const SizedBox(width: AppSizes.space3),
                                  // Long words ("flower pot") shrink to fit.
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        target.entry.word.of(lang),
                                        textDirection: lang.direction,
                                        style: AppTypography.style(
                                          lang,
                                          role: TextRole.display,
                                          color: c.onSurface,
                                          weight: 700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .animate(key: ValueKey(_round))
                          .fadeIn()
                          .scaleXY(begin: 0.7, curve: AppMotion.pop),
                      const SizedBox(height: AppSizes.space6),
                      Row(
                        children: [
                          for (final (i, w) in _cards.indexed)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.space1,
                                ),
                                child: GuideHint(
                                  active: w == target,
                                  child: _PictureCard(
                                    key: ValueKey('$_round-$i'),
                                    word: w,
                                    confettiKey: _confetti[i],
                                    shake: _shakes[i],
                                    tried: _wrong.contains(i),
                                    solved: _solved == i,
                                    onTap: () => _tap(i),
                                  ),
                                ),
                              ).popIn(i, base: 150.ms),
                            ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    Align(
                      alignment: AlignmentDirectional.bottomStart,
                      child: NooriMascot(
                        state: _mood,
                        size: AppSizes.mascotSm,
                      ).popIn(4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundDots extends StatelessWidget {
  const _RoundDots({required this.round, required this.done});

  final int round;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < WordGameScreen.rounds; i++)
          Icon(
            done || i < round ? Icons.star_rounded : Icons.star_outline_rounded,
            color: c.primary,
            size: AppSizes.iconMd * 0.8,
          ),
      ],
    );
  }
}

class _PictureCard extends StatelessWidget {
  const _PictureCard({
    super.key,
    required this.word,
    required this.confettiKey,
    required this.shake,
    required this.tried,
    required this.solved,
    required this.onTap,
  });

  final GameWord word;
  final GlobalKey<ConfettiBurstState> confettiKey;
  final int shake;
  final bool tried, solved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Shake(
      trigger: shake,
      child: AnimatedScale(
        scale: solved ? 1.15 : 1,
        duration: AppMotion.pressRelease,
        curve: AppMotion.elastic,
        child: AnimatedOpacity(
          // A tried card fades a little: a hint, never a red X.
          opacity: tried ? 0.45 : 1,
          duration: AppMotion.entrance,
          child: BouncyButton(
            onTap: onTap,
            semanticLabel: word.entry.word.en,
            sfx: null,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: AppMotion.entrance,
                  height: AppSizes.gameCardHeight,
                  padding: const EdgeInsets.all(AppSizes.space3),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(
                      color: solved ? c.primary : c.surface,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: c.backgroundAlt,
                        offset: const Offset(0, AppSizes.puffyDepth),
                      ),
                      if (solved)
                        BoxShadow(
                          color: c.primary.withValues(alpha: 0.7),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                    ],
                  ),
                  child: PictureView(word.entry.picture!),
                ),
                ConfettiBurst(key: confettiKey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// All five found: a firefly for the lantern, and play again or go back.
class _Finished extends StatelessWidget {
  const _Finished({required this.onAgain, required this.onBack});

  final VoidCallback onAgain;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Icon(
                    Icons.star_rounded,
                    color: c.primary,
                    size: AppSizes.rewardStar,
                  )
                  .animate(delay: (i * 160).ms)
                  .scaleXY(
                    begin: 0,
                    curve: AppMotion.elastic,
                    duration: 700.ms,
                  ),
          ],
        ),
        const SizedBox(height: AppSizes.space4),
        const FireflyCount(count: 1)
            .animate(delay: 500.ms)
            .fadeIn()
            .moveY(begin: 30, end: 0, curve: AppMotion.pop),
        const SizedBox(height: AppSizes.space6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PuffyIconButton(
              icon: Icons.arrow_back_rounded,
              semanticLabel: 'Back',
              color: c.surface,
              iconColor: c.onSurface,
              onTap: onBack,
            ),
            const SizedBox(width: AppSizes.space5),
            PuffyIconButton(
              icon: Icons.replay_rounded,
              semanticLabel: 'Play again',
              size: AppSizes.bigTap,
              breathe: true,
              onTap: onAgain,
            ),
          ],
        ).popIn(2, base: 700.ms),
      ],
    );
  }
}
