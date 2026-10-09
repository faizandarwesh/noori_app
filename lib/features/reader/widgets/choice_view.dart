import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/content/scenes.dart';
import '../../../core/content/story.dart';
import '../../../core/i18n/app_lang.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bouncy_button.dart';
import '../../../core/widgets/entrance.dart';
import '../../../core/widgets/guide_hint.dart';
import '../../../core/widgets/puppet_view.dart';
import 'story_scene.dart';

/// The Choice Moment: the last page's scene, softly dimmed, with two big
/// wobbling picture cards. The chosen card grows and glows; the other fades.
class ChoiceView extends StatelessWidget {
  const ChoiceView({
    super.key,
    required this.choice,
    required this.scene,
    required this.cast,
    required this.lang,
    required this.chosen,
    required this.hint,
    required this.bottomInset,
    required this.onPick,
  });

  final ChoiceNode choice;
  final SceneSpec? scene;
  final List<CastMember> cast;
  final AppLang lang;
  final String? chosen;
  final bool hint;
  final double bottomInset;
  final void Function(ChoiceOption) onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final spec = scene;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (spec != null)
          StoryScene(spec: spec, cast: cast, entrances: false)
        else
          ColoredBox(color: c.skyTop),
        ColoredBox(color: c.background.withValues(alpha: 0.45)),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSizes.space3,
              0,
              AppSizes.space3,
              bottomInset + AppSizes.space3,
            ),
            child: AnimatedSwitcher(
              duration: AppMotion.entrance,
              child: Column(
                key: ValueKey(lang),
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.space4),
                    decoration: BoxDecoration(
                      color: c.surface.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      boxShadow: const [
                        BoxShadow(
                          color: AppPalette.shadow,
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      choice.prompt.of(lang),
                      textAlign: TextAlign.center,
                      textDirection: lang.direction,
                      style: AppTypography.style(
                        lang,
                        role: TextRole.title,
                        color: c.onSurface,
                        weight: 700,
                      ),
                    ),
                  ).popIn(0),
                  const SizedBox(height: AppSizes.space5),
                  Row(
                    textDirection: lang.direction,
                    children: [
                      for (final (i, o) in choice.options.indexed)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.space2,
                            ),
                            child: GuideHint(
                              active: hint && i == 0,
                              child: _ChoiceCard(
                                option: o,
                                lang: lang,
                                state: chosen == null
                                    ? _CardState.waiting
                                    : (chosen == o.id
                                          ? _CardState.chosen
                                          : _CardState.dropped),
                                wobbleDelay: (i * 700).ms,
                                onTap: () => onPick(o),
                              ),
                            ),
                          ).popIn(1 + i),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _CardState { waiting, chosen, dropped }

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.option,
    required this.lang,
    required this.state,
    required this.wobbleDelay,
    required this.onTap,
  });

  final ChoiceOption option;
  final AppLang lang;
  final _CardState state;
  final Duration wobbleDelay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final chosen = state == _CardState.chosen;
    Widget card = AnimatedContainer(
      duration: AppMotion.entrance,
      curve: AppMotion.pop,
      height: AppSizes.choiceCardHeight,
      padding: const EdgeInsets.all(AppSizes.space3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: chosen ? c.primary : c.surface, width: 4),
        boxShadow: [
          BoxShadow(
            color: chosen ? c.primaryDeep : c.backgroundAlt,
            offset: const Offset(0, AppSizes.puffyDepth),
          ),
          if (chosen)
            BoxShadow(
              color: c.primary.withValues(alpha: 0.7),
              blurRadius: 28,
              spreadRadius: 4,
            ),
        ],
      ),
      child: Column(
        children: [
          Expanded(child: PictureView(option.picture)),
          const SizedBox(height: AppSizes.space2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              option.label.of(lang),
              textDirection: lang.direction,
              style: AppTypography.style(
                lang,
                role: TextRole.label,
                color: c.onSurface,
                weight: 700,
              ),
            ),
          ),
        ],
      ),
    );

    // Gentle wiggle while waiting.
    if (state == _CardState.waiting) {
      card = card
          .animate(delay: wobbleDelay, onPlay: (a) => a.repeat(reverse: true))
          .rotate(
            begin: -0.02,
            end: 0.02,
            duration: 1100.ms,
            curve: AppMotion.soft,
          )
          .moveY(begin: 0, end: -6, duration: 1100.ms, curve: AppMotion.soft);
    }

    return AnimatedOpacity(
      duration: AppMotion.entrance,
      opacity: state == _CardState.dropped ? 0.25 : 1,
      child: AnimatedScale(
        duration: AppMotion.pressRelease,
        curve: AppMotion.elastic,
        scale: switch (state) {
          _CardState.waiting => 1,
          _CardState.chosen => 1.12,
          _CardState.dropped => 0.85,
        },
        child: BouncyButton(
          onTap: state == _CardState.waiting ? onTap : null,
          semanticLabel: option.label.of(lang),
          sfx: Sfx.pop,
          child: card,
        ),
      ),
    );
  }
}
