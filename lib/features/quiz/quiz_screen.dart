import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/voice_clips.dart';
import '../../core/content/scenes.dart';
import '../../core/content/story.dart';
import '../../core/guide/guide_lines.dart';
import '../../core/i18n/app_lang.dart';
import '../../core/mascot/noori_guide.dart';
import '../../core/mascot/noori_mascot.dart';
import '../../core/progress/progress.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/firefly_layer.dart';
import '../../core/widgets/flight.dart';
import '../../core/widgets/guide_hint.dart';
import '../../core/widgets/lantern.dart';
import '../../core/widgets/puffy_button.dart';
import '../reward/reward_result.dart';
import 'quiz_plan.dart';
import 'widgets/quiz_questions.dart';

/// Three questions after a story: two picture questions plus one special
/// (drag a picture to its place, put scenes in order, or find a character),
/// rotating each replay. Right answers send a firefly into the lantern;
/// wrong ones get a soft shake and "Try again!". There is no way to fail.
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.storyId});

  final String storyId;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  final _guide = NooriGuideController();
  final _lanternKey = GlobalKey();
  late final AudioService _audio = ref.read(audioServiceProvider);

  Story? _story;
  Scenes? _scenes;
  GuideLines? _lines;
  List<QuizItem> _items = const [];
  int _index = 0;
  bool _solved = false;
  bool _missedThis = false;
  int _firstTry = 0;
  int _earned = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final story = await ref.read(storyProvider(widget.storyId).future);
    final scenes = await ref.read(scenesProvider.future);
    final lines = await ref.read(guideLinesProvider.future);
    if (!mounted) return;
    final play = ref.read(progressProvider).playsFor(story.id);
    setState(() {
      _story = story;
      _scenes = scenes;
      _lines = lines;
      _items = planQuiz(story, play);
    });
    _ask(intro: true);
  }

  QuizItem get _item => _items[_index];

  /// What the current question says, in both languages.
  LocalizedText _questionText() => switch (_item) {
    PickItem(:final question) || DragItem(:final question) => question.question,
    OrderItem() => _lines?['quiz_order'] ?? const LocalizedText(en: '', ur: ''),
    FindItem(:final characterId) => _findText(characterId),
  };

  LocalizedText _findText(String characterId) {
    final name = _story!.characters[characterId]!;
    final template = _lines?['quiz_find'];
    String fill(AppLang l) =>
        (template?.of(l) ?? '{name}?').replaceAll('{name}', name.of(l));
    return LocalizedText(en: fill(AppLang.en), ur: fill(AppLang.ur));
  }

  void _ask({bool intro = false}) {
    final storyId = widget.storyId;
    final item = _item;
    _guide.sayAll([
      if (intro) const GuideLine('quiz_start'),
      switch (item) {
        PickItem(:final question, :final index) ||
        DragItem(:final question, :final index) => GuideLine.text(
          question.question,
          clip: (lang) => VoiceClips.quiz(storyId, index, lang),
        ),
        OrderItem() => const GuideLine('quiz_order'),
        FindItem(:final characterId) => GuideLine.text(
          _findText(characterId),
          clip: (lang) => VoiceClips.find(storyId, characterId, lang),
        ),
      },
    ]);
  }

  void _miss() {
    _missedThis = true;
    _audio.play(Sfx.tryAgain);
    _guide
      ..setMood(NooriState.thinking)
      ..say('quiz_try_again');
  }

  Future<void> _solve(Offset from) async {
    if (_solved) return;
    if (!_missedThis) _firstTry++;
    setState(() => _solved = true);
    _audio.play(Sfx.chime);
    _guide
      ..setMood(NooriState.happy)
      ..say('quiz_correct');

    // A firefly flies from the answer into the lantern.
    if (from != Offset.zero) {
      await launchFlight(
        context,
        from: from,
        to: _lanternKey,
        flier: const FireflyDot(),
        trail: true,
        endScale: 0.6,
      );
    }
    if (!mounted) return;
    _audio.play(Sfx.sparkle);
    ref.read(progressProvider.notifier).addFireflies(1);
    _earned++;

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    _guide.setMood(null);
    if (_index + 1 < _items.length) {
      setState(() {
        _index++;
        _solved = false;
        _missedThis = false;
      });
      _ask();
    } else {
      _finish();
    }
  }

  void _finish() {
    final story = _story!;
    final stars = RewardResult.starsFor(_firstTry);
    final progress = ref.read(progressProvider.notifier)
      ..completeStory(story.id, stars);
    final words = progress.collectStoryWords(story.id, story.vocabulary);
    context.pushReplacement(
      Routes.reward(story.id),
      extra: RewardResult(stars: stars, fireflies: _earned, newWords: words),
    );
  }

  @override
  void dispose() {
    _guide.dispose();
    super.dispose();
  }

  Widget _question(QuizItem item) {
    final key = ValueKey(_index);
    final scenes = _scenes!;
    return switch (item) {
      PickItem() => PickQuestion(
        key: key,
        item: item,
        onSolved: _solve,
        onMiss: _miss,
      ),
      DragItem() => DragQuestion(
        key: key,
        item: item,
        onSolved: _solve,
        onMiss: _miss,
      ),
      OrderItem() => OrderQuestion(
        key: key,
        item: item,
        scenes: scenes,
        onSolved: _solve,
        onMiss: _miss,
      ),
      FindItem() => FindQuestion(
        key: key,
        item: item,
        scenes: scenes,
        onSolved: _solve,
        onMiss: _miss,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lang = ref.watch(appSettingsProvider).lang;
    final fireflies = ref.watch(progressProvider).fireflies;
    final ready = _story != null && _items.isNotEmpty;

    return Scaffold(
      body: GuideScope(
        // After 8 quiet seconds a hand points the way. No voice.
        enabled: ready && !_solved,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [c.skyTop, c.backgroundAlt, c.background],
                  ),
                ),
              ),
            ),
            const Positioned.fill(child: FireflyLayer(count: 10)),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.space4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        PuffyIconButton(
                          icon: Icons.home_rounded,
                          semanticLabel: 'Home',
                          color: c.surface,
                          iconColor: c.onSurface,
                          onTap: () => context.go(Routes.home),
                        ).popIn(0),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < _items.length; i++)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.space1,
                                  ),
                                  child: Icon(
                                    i < _index || (i == _index && _solved)
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: c.primary,
                                    size: AppSizes.iconMd,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        KeyedSubtree(
                          key: _lanternKey,
                          child: Lantern(count: fireflies),
                        ).popIn(1),
                      ],
                    ),
                    const SizedBox(height: AppSizes.space2),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: NooriGuide(
                        controller: _guide,
                        size: AppSizes.mascotSm * 0.85,
                      ).popIn(2),
                    ),
                    if (ready) ...[
                      const SizedBox(height: AppSizes.space2),
                      _QuestionCard(
                        key: ValueKey(_index),
                        text: _questionText().of(lang),
                        lang: lang,
                        onTap: _ask,
                      ),
                      const SizedBox(height: AppSizes.space4),
                      Expanded(child: Center(child: _question(_item))),
                    ] else
                      const Spacer(),
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

/// The question, written out; tap it to hear it again.
class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    super.key,
    required this.text,
    required this.lang,
    required this.onTap,
  });

  final String text;
  final AppLang lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BouncyButton(
      semanticLabel: 'Hear the question',
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.space3),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: const [
            BoxShadow(
              color: AppPalette.shadow,
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.volume_up_rounded,
              color: c.secondary,
              size: AppSizes.iconLg,
            ),
            const SizedBox(width: AppSizes.space3),
            Expanded(
              child: Text(
                text,
                textDirection: lang.direction,
                style: AppTypography.style(
                  lang,
                  role: TextRole.title,
                  color: c.onSurface,
                  weight: 700,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scaleXY(begin: 0.8, curve: AppMotion.pop);
  }
}
