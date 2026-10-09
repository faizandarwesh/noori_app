import 'package:flutter/material.dart';

import '../../../core/i18n/app_lang.dart';
import '../../../core/theme/app_theme.dart';
import '../karaoke/read_chunks.dart';

/// Film-style subtitles over a soft fade at the bottom of the scene. The
/// word being narrated lights up; any word can be tapped.
class SubtitleStrip extends StatelessWidget {
  const SubtitleStrip({
    super.key,
    required this.chunks,
    required this.lang,
    required this.active,
    required this.onWordTap,
  });

  final List<ReadChunk> chunks;
  final AppLang lang;
  final int? active;
  final void Function(int index) onWordTap;

  @override
  Widget build(BuildContext context) {
    final style =
        AppTypography.style(
          lang,
          color: CinemaPalette.subtitleText,
          weight: 600,
        ).copyWith(
          shadows: const [
            Shadow(color: CinemaPalette.subtitleShadow, blurRadius: 8),
          ],
        );
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [CinemaPalette.subtitleClear, CinemaPalette.subtitleShade],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.space5,
            AppSizes.space7,
            AppSizes.space5,
            AppSizes.space5,
          ),
          // heightFactor: 1 keeps the strip as tall as its text, not the screen.
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.subtitleMaxWidth,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position:
                        Tween(
                          begin: const Offset(0, 0.25),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(parent: anim, curve: AppMotion.pop),
                        ),
                    child: child,
                  ),
                ),
                child: Directionality(
                  key: ValueKey((
                    lang,
                    chunks.length,
                    chunks.firstOrNull?.text,
                  )),
                  textDirection: lang.direction,
                  // A Wrap, not a paragraph of WidgetSpans: a paragraph made only
                  // of placeholders has no letters to tell it which way to run,
                  // so Urdu came out left to right. Wrap follows the
                  // Directionality above, so Urdu reads right to left.
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: style.fontSize! * 0.28,
                    children: [
                      for (var i = 0; i < chunks.length; i++)
                        _Word(
                          text: chunks[i].text,
                          style: style,
                          lit: i == active,
                          onTap: chunks[i].hasWord ? () => onWordTap(i) : null,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Word extends StatelessWidget {
  const _Word({
    required this.text,
    required this.style,
    required this.lit,
    required this.onTap,
  });

  final String text;
  final TextStyle style;
  final bool lit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedScale(
        scale: lit ? 1.12 : 1,
        duration: const Duration(milliseconds: 200),
        curve: AppMotion.pop,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.space1),
          decoration: BoxDecoration(
            color: lit ? c.highlight : c.highlight.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(AppSizes.space3),
          ),
          child: Text(
            text,
            style: lit
                ? style.copyWith(color: c.onPrimary, shadows: const [])
                : style,
          ),
        ),
      ),
    );
  }
}
