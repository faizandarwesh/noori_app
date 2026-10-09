import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/content/scenes.dart';
import '../../../core/content/story.dart';
import '../../../core/i18n/app_lang.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bouncy_button.dart';
import '../../../core/widgets/confetti_burst.dart';
import '../../../core/widgets/flight.dart';
import '../../../core/widgets/guide_hint.dart';
import '../../../core/widgets/puppet_view.dart';
import '../../../core/widgets/shake.dart';
import '../../reader/widgets/story_scene.dart';
import '../quiz_plan.dart';

/// Reports a right answer, with where (globally) its firefly flies from.
typedef OnSolved = void Function(Offset from);

// ---- Picture cards ----------------------------------------------------------

/// A quiz picture: pops when right, shakes softly and fades a little when
/// tried, never shows a red X.
class QuizPictureCard extends ConsumerWidget {
  const QuizPictureCard({
    super.key,
    required this.picture,
    this.label,
    required this.cardKey,
    required this.confettiKey,
    required this.shake,
    required this.tried,
    required this.solved,
    this.onTap,
    this.hovered = false,
  });

  final PictureRef picture;

  /// Words under the picture, for answers that are something said.
  final LocalizedText? label;
  final GlobalKey cardKey;
  final GlobalKey<ConfettiBurstState> confettiKey;
  final int shake;
  final bool tried, solved, hovered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final lang = ref.watch(appSettingsProvider.select((s) => s.lang));
    final words = label?.of(lang);
    final card = Stack(
      key: cardKey,
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AnimatedContainer(
          duration: AppMotion.entrance,
          height: AppSizes.quizCardHeight,
          padding: const EdgeInsets.all(AppSizes.space3),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: solved || hovered ? c.primary : c.surface,
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
          child: words == null
              ? PictureView(picture)
              : Column(
                  children: [
                    Expanded(child: PictureView(picture)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        words,
                        textDirection: lang.direction,
                        maxLines: 1,
                        style: AppTypography.style(
                          lang,
                          role: TextRole.label,
                          color: c.onSurface,
                          weight: 700,
                        ).copyWith(height: lang.isRtl ? 1.6 : 1.1),
                      ),
                    ),
                  ],
                ),
        ),
        ConfettiBurst(key: confettiKey),
      ],
    );
    return Shake(
      trigger: shake,
      child: AnimatedScale(
        scale: solved ? 1.15 : (hovered ? 1.08 : 1),
        duration: AppMotion.pressRelease,
        curve: AppMotion.elastic,
        child: AnimatedOpacity(
          opacity: tried ? 0.45 : 1,
          duration: AppMotion.entrance,
          child: onTap == null
              ? card
              : BouncyButton(
                  onTap: onTap,
                  semanticLabel: picture.id,
                  sfx: null,
                  child: card,
                ),
        ),
      ),
    );
  }
}

/// Shared bookkeeping for three-card questions.
mixin _ThreeCards<T extends StatefulWidget> on State<T> {
  final cardKeys = List.generate(3, (_) => GlobalKey());
  final confetti = List.generate(3, (_) => GlobalKey<ConfettiBurstState>());
  final wrong = <int>{};
  final shakes = [0, 0, 0];
  int? solved;

  int get firstOpen =>
      [0, 1, 2].firstWhere((i) => !wrong.contains(i), orElse: () => 0);

  void answer(List<QuizOption> options, int i, OnSolved ok, VoidCallback no) {
    if (solved != null) return;
    if (!options[i].correct) {
      setState(() {
        wrong.add(i);
        shakes[i]++;
      });
      no();
      return;
    }
    setState(() => solved = i);
    confetti[i].currentState?.burst();
    ok(centerOf(cardKeys[i]) ?? Offset.zero);
  }
}

// ---- Pick -------------------------------------------------------------------

class PickQuestion extends StatefulWidget {
  const PickQuestion({
    super.key,
    required this.item,
    required this.onSolved,
    required this.onMiss,
  });

  final PickItem item;
  final OnSolved onSolved;
  final VoidCallback onMiss;

  @override
  State<PickQuestion> createState() => _PickQuestionState();
}

class _PickQuestionState extends State<PickQuestion>
    with _ThreeCards<PickQuestion> {
  @override
  Widget build(BuildContext context) {
    final options = widget.item.question.options;
    return Row(
      children: [
        for (final (i, o) in options.indexed)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.space1),
              child: GuideHint(
                active: i == firstOpen,
                child: QuizPictureCard(
                  picture: o.picture,
                  label: o.label,
                  cardKey: cardKeys[i],
                  confettiKey: confetti[i],
                  shake: shakes[i],
                  tried: wrong.contains(i),
                  solved: solved == i,
                  onTap: () =>
                      answer(options, i, widget.onSolved, widget.onMiss),
                ),
              ),
            ).animate().fadeIn(delay: (i * 70).ms).scaleXY(begin: 0.6),
          ),
      ],
    );
  }
}

// ---- Drag -------------------------------------------------------------------

/// Drag the picture at the bottom onto the right one of three. A wrong drop
/// shakes that card and the picture floats back.
class DragQuestion extends ConsumerStatefulWidget {
  const DragQuestion({
    super.key,
    required this.item,
    required this.onSolved,
    required this.onMiss,
  });

  final DragItem item;
  final OnSolved onSolved;
  final VoidCallback onMiss;

  @override
  ConsumerState<DragQuestion> createState() => _DragQuestionState();
}

class _DragQuestionState extends ConsumerState<DragQuestion>
    with _ThreeCards<DragQuestion> {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final q = widget.item.question;
    final options = q.options;
    final itemCard = Container(
      width: AppSizes.quizCardHeight,
      height: AppSizes.quizCardHeight,
      padding: const EdgeInsets.all(AppSizes.space3),
      decoration: BoxDecoration(
        color: c.surface,
        shape: BoxShape.circle,
        border: Border.all(color: c.secondary, width: 4),
        boxShadow: [
          BoxShadow(color: c.secondary.withValues(alpha: 0.5), blurRadius: 18),
        ],
      ),
      child: PictureView(q.item!),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            for (final (i, o) in options.indexed)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.space1,
                  ),
                  child: DragTarget<PictureRef>(
                    onAcceptWithDetails: (_) =>
                        answer(options, i, widget.onSolved, widget.onMiss),
                    builder: (context, hovering, _) => QuizPictureCard(
                      picture: o.picture,
                      label: o.label,
                      cardKey: cardKeys[i],
                      confettiKey: confetti[i],
                      shake: shakes[i],
                      tried: wrong.contains(i),
                      solved: solved == i,
                      hovered: hovering.isNotEmpty,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSizes.space6),
        SizedBox(
          height: AppSizes.quizCardHeight,
          child: solved != null
              ? null
              : GuideHint(
                  handOffset: const Offset(0.2, 0.2),
                  child: Draggable<PictureRef>(
                    data: q.item,
                    feedback: Transform.scale(scale: 1.1, child: itemCard),
                    childWhenDragging: Opacity(opacity: 0.25, child: itemCard),
                    onDragStarted: () =>
                        ref.read(audioServiceProvider).play(Sfx.pop),
                    child: itemCard
                        .animate(onPlay: (a) => a.repeat(reverse: true))
                        .moveY(
                          begin: 0,
                          end: -10,
                          duration: 900.ms,
                          curve: AppMotion.soft,
                        ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ---- Scene thumbnails -------------------------------------------------------

/// A story scene laid out at screen size and scaled into [size], frozen
/// still so three of them cost almost nothing.
class _SceneShot extends StatelessWidget {
  const _SceneShot({
    required this.spec,
    required this.page,
    required this.size,
    this.live = false,
    this.cues = const [],
    this.onCastTap,
  });

  final SceneSpec spec;
  final StoryPage page;
  final Size size;
  final bool live;
  final List<int> cues;
  final void Function(int)? onCastTap;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: SizedBox.fromSize(
        size: size,
        child: TickerMode(
          enabled: live,
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox.fromSize(
              size: screen,
              child: StoryScene(
                spec: spec,
                cast: page.cast,
                cues: cues,
                entrances: false,
                onCastTap: onCastTap,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The largest screen-shaped box that fits [max] (scaled by [fill]).
Size _screenShaped(BuildContext context, Size max, {double fill = 1}) {
  final screen = MediaQuery.sizeOf(context);
  final aspect = screen.width / screen.height;
  var w = max.width * fill;
  var h = w / aspect;
  if (h > max.height * fill) {
    h = max.height * fill;
    w = h * aspect;
  }
  return Size(w, h);
}

// ---- Order ------------------------------------------------------------------

/// Tap three scenes in story order. Each right tap gets a number badge; a
/// wrong one shakes.
class OrderQuestion extends ConsumerStatefulWidget {
  const OrderQuestion({
    super.key,
    required this.item,
    required this.scenes,
    required this.onSolved,
    required this.onMiss,
  });

  final OrderItem item;
  final Scenes scenes;
  final OnSolved onSolved;
  final VoidCallback onMiss;

  @override
  ConsumerState<OrderQuestion> createState() => _OrderQuestionState();
}

class _OrderQuestionState extends ConsumerState<OrderQuestion> {
  final _keys = List.generate(3, (_) => GlobalKey());
  final _confetti = GlobalKey<ConfettiBurstState>();

  /// Card positions tapped so far, in order.
  final _picked = <int>[];
  final _shakes = [0, 0, 0];

  void _tap(int slot) {
    if (_picked.length == 3 || _picked.contains(slot)) return;
    if (widget.item.shown[slot] != _picked.length) {
      setState(() => _shakes[slot]++);
      widget.onMiss();
      return;
    }
    setState(() => _picked.add(slot));
    ref.read(audioServiceProvider).play(Sfx.pop);
    if (_picked.length == 3) {
      _confetti.currentState?.burst();
      widget.onSolved(centerOf(_keys[slot]) ?? Offset.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // The next scene to find gets the (silent) pointing hand.
    final next = widget.item.shown.indexOf(_picked.length);
    return LayoutBuilder(
      builder: (context, box) {
        final size = _screenShaped(
          context,
          Size((box.maxWidth - AppSizes.space2 * 4) / 3, box.maxHeight),
          fill: 0.95,
        );
        return Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var slot = 0; slot < 3; slot++)
                  Shake(
                    trigger: _shakes[slot],
                    child: GuideHint(
                      active: slot == next,
                      child: BouncyButton(
                        semanticLabel: 'Scene ${slot + 1}',
                        sfx: null,
                        minSize: 0,
                        onTap: () => _tap(slot),
                        child: Stack(
                          key: _keys[slot],
                          clipBehavior: Clip.none,
                          children: [
                            _SceneShot(
                              spec:
                                  widget.scenes[widget
                                      .item
                                      .pages[widget.item.shown[slot]]
                                      .scene]!,
                              page: widget.item.pages[widget.item.shown[slot]],
                              size: size,
                            ),
                            Positioned.fill(
                              child: AnimatedContainer(
                                duration: AppMotion.entrance,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusMd,
                                  ),
                                  border: Border.all(
                                    color: _picked.contains(slot)
                                        ? c.primary
                                        : c.surface,
                                    width: 4,
                                  ),
                                ),
                              ),
                            ),
                            if (_picked.contains(slot))
                              Positioned(
                                top: -AppSizes.space3,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: _NumberBadge(
                                    number: _picked.indexOf(slot) + 1,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: (slot * 90).ms).scaleXY(begin: 0.7),
              ],
            ),
            ConfettiBurst(key: _confetti, particles: 24),
          ],
        );
      },
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: AppSizes.iconLg,
      height: AppSizes.iconLg,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: c.primaryDeep, offset: const Offset(0, 3)),
        ],
      ),
      child: Text(
        '$number',
        style: TextStyle(
          fontFamily: AppFonts.english,
          fontSize: AppTypeScale.labelEn,
          fontVariations: const [FontVariation.weight(700)],
          color: c.onPrimary,
        ),
      ),
    ).animate().scaleXY(begin: 0, duration: 500.ms, curve: AppMotion.elastic);
  }
}

// ---- Find -------------------------------------------------------------------

/// Find a character in a scene and tap them. Anyone else tapped wiggles
/// ("not me!"), and the child tries again.
class FindQuestion extends ConsumerStatefulWidget {
  const FindQuestion({
    super.key,
    required this.item,
    required this.scenes,
    required this.onSolved,
    required this.onMiss,
  });

  final FindItem item;
  final Scenes scenes;
  final OnSolved onSolved;
  final VoidCallback onMiss;

  @override
  ConsumerState<FindQuestion> createState() => _FindQuestionState();
}

class _FindQuestionState extends ConsumerState<FindQuestion> {
  final _card = GlobalKey();
  final _confetti = GlobalKey<ConfettiBurstState>();
  late List<int> _cues = List.filled(widget.item.page.cast.length, 0);
  bool _found = false;

  void _tap(int i) {
    if (_found) return;
    setState(() => _cues = [..._cues]..[i] += 1);
    if (i != widget.item.castIndex) {
      widget.onMiss();
      return;
    }
    _found = true;
    _confetti.currentState?.burst();
    ref.read(audioServiceProvider).play(Sfx.giggle);
    widget.onSolved(centerOf(_card) ?? Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final page = widget.item.page;
    return LayoutBuilder(
      builder: (context, box) {
        final size = _screenShaped(context, box.biggest, fill: 0.98);
        return Center(
          child: Stack(
            key: _card,
            alignment: Alignment.center,
            children: [
              _SceneShot(
                spec: widget.scenes[page.scene]!,
                page: page,
                size: size,
                live: true,
                cues: _cues,
                onCastTap: _tap,
              ),
              IgnorePointer(
                child: Container(
                  width: size.width,
                  height: size.height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(
                      color: _found ? c.primary : c.surface,
                      width: math.max(4, size.width * 0.012),
                    ),
                  ),
                ),
              ),
              ConfettiBurst(key: _confetti, particles: 24),
            ],
          ),
        ).animate().fadeIn().scaleXY(begin: 0.85, curve: AppMotion.pop);
      },
    );
  }
}
