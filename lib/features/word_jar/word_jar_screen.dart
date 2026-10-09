import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/audio_service.dart';
import '../../core/content/story.dart';
import '../../core/i18n/app_lang.dart';
import '../../core/audio/voice_clips.dart';
import '../../core/mascot/noori_mascot.dart';
import '../../core/settings/app_settings.dart';
import '../../core/progress/progress.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/firefly_layer.dart';
import '../../core/widgets/jar.dart';
import '../../core/widgets/puffy_button.dart';

typedef JarWord = ({String key, LocalizedText word});

/// The collected words, resolved from each story's glossary, newest last.
final jarWordsProvider = FutureProvider<List<JarWord>>((ref) async {
  final keys = ref.watch(progressProvider.select((p) => p.words));
  final out = <JarWord>[];
  for (final key in keys) {
    final slash = key.indexOf('/');
    if (slash <= 0) continue;
    try {
      final story = await ref.watch(
        storyProvider(key.substring(0, slash)).future,
      );
      final entry = story.entry(key.substring(slash + 1));
      if (entry != null) out.add((key: key, word: entry.word));
    } catch (_) {
      // A story that's gone missing just leaves its words out.
    }
  }
  return out;
});

class WordJarScreen extends ConsumerStatefulWidget {
  const WordJarScreen({super.key});

  @override
  ConsumerState<WordJarScreen> createState() => _WordJarScreenState();
}

class _WordJarScreenState extends ConsumerState<WordJarScreen> {
  static const _empty = LocalizedText(
    en: 'Your jar is empty. Finish a story to find words!',
    ur: 'مرتبان ابھی خالی ہے۔ کہانی پوری کرو اور لفظ جمع کرو!',
  );

  String? _speaking;

  /// Says the word in English, then Urdu: its recording if there is one,
  /// otherwise the device voice (the only place text-to-speech remains).
  Future<void> _hear(JarWord w) async {
    final audio = ref.read(audioServiceProvider);
    final slash = w.key.indexOf('/');
    final storyId = w.key.substring(0, slash);
    final wordId = w.key.substring(slash + 1);
    setState(() => _speaking = w.key);
    for (final lang in AppLang.values) {
      if (!mounted || _speaking != w.key) return;
      final played = await audio.playVoice(
        VoiceClips.word(storyId, wordId, lang),
      );
      if (!played) await audio.speakWordFallback(w.word.of(lang), lang);
    }
    if (mounted && _speaking == w.key) setState(() => _speaking = null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final words = ref.watch(jarWordsProvider).value;
    final settings = ref.watch(appSettingsProvider);
    final bedtime = settings.bedtime;
    final lang = settings.lang;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [c.skyTop, c.background],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: FireflyLayer(count: 8)),
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
                      const SizedBox(width: AppSizes.space3),
                      NooriMascot(
                        state: _speaking != null
                            ? NooriState.happy
                            : (bedtime ? NooriState.sleepy : NooriState.idle),
                        size: AppSizes.mascotSm,
                      ).popIn(1),
                      if (words != null && words.isEmpty)
                        Expanded(
                          child: Text(
                            _empty.of(lang),
                            textDirection: lang.direction,
                            style: AppTypography.style(
                              lang,
                              role: TextRole.label,
                              color: c.onSurface,
                              weight: 600,
                            ),
                          ).popIn(2),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.space3),
                  Expanded(
                    child: _Jar(
                      words: words ?? const [],
                      speaking: _speaking,
                      onTap: _hear,
                    ).popIn(2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Jar extends StatelessWidget {
  const _Jar({
    required this.words,
    required this.speaking,
    required this.onTap,
  });

  final List<JarWord> words;
  final String? speaking;
  final void Function(JarWord) onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // Keep the jar's shape whatever the screen.
        var w = box.maxWidth;
        var h = w * 1.3;
        if (h > box.maxHeight) {
          h = box.maxHeight;
          w = h / 1.3;
        }
        final size = Size(w, h);
        final inside = JarPainter.interiorOf(size);
        return Center(
          child: SizedBox.fromSize(
            size: size,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: JarPainter(
                      glow: (words.length / 9).clamp(0.2, 1.0),
                    ),
                  ),
                ),
                Positioned.fromRect(
                  rect: inside,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(inside.width * 0.12),
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: FireflyLayer(count: 6, seed: 21, maxRadius: 3),
                        ),
                        // Cards settle at the bottom of the jar, and scroll once it's full.
                        SingleChildScrollView(
                          reverse: true,
                          padding: const EdgeInsets.all(AppSizes.space2),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: inside.height - AppSizes.space2 * 2,
                            ),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                runAlignment: WrapAlignment.end,
                                spacing: AppSizes.space2,
                                runSpacing: AppSizes.space2,
                                children: [
                                  for (final (i, word) in words.indexed)
                                    _JarCard(
                                      word: word,
                                      index: i,
                                      speaking: speaking == word.key,
                                      onTap: () => onTap(word),
                                    ).popIn(i),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _JarCard extends StatelessWidget {
  const _JarCard({
    required this.word,
    required this.index,
    required this.speaking,
    required this.onTap,
  });

  final JarWord word;
  final int index;
  final bool speaking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Each card tilts a little differently, like cards tossed in a jar.
    final tilt = ((index * 37) % 7 - 3) * 0.02;
    return BouncyButton(
      semanticLabel: '${word.word.en} ${word.word.ur}',
      sfx: Sfx.pop,
      onTap: onTap,
      child:
          Transform.rotate(
                angle: tilt,
                child: AnimatedContainer(
                  duration: AppMotion.entrance,
                  width: AppSizes.wordCardWidth,
                  padding: const EdgeInsets.all(AppSizes.space2),
                  decoration: BoxDecoration(
                    color: c.bubble,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    border: Border.all(
                      color: speaking ? c.primary : c.backgroundAlt,
                      width: 3,
                    ),
                    boxShadow: [
                      const BoxShadow(
                        color: AppPalette.shadow,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                      if (speaking)
                        BoxShadow(
                          color: c.primary.withValues(alpha: 0.7),
                          blurRadius: 18,
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        child: Text(
                          word.word.en,
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
                          word.word.ur,
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
              )
              .animate(
                delay: (index * 230).ms,
                onPlay: (a) => a.repeat(reverse: true),
              )
              .moveY(
                begin: 0,
                end: -4,
                duration: 1600.ms,
                curve: AppMotion.soft,
              ),
    );
  }
}
