import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_service.dart';
import '../../core/i18n/app_lang.dart';
import '../../core/mascot/noori_guide.dart';
import '../../core/mascot/noori_mascot.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/firefly_layer.dart';
import '../../core/widgets/guide_hint.dart';
import '../../core/widgets/parallax_scene.dart';
import '../../core/widgets/puffy_button.dart';
import 'demo_backdrop.dart';

/// Build step 1 showcase: theme, core widgets and every Noori state.
class MascotDemoScreen extends ConsumerStatefulWidget {
  const MascotDemoScreen({super.key});

  @override
  ConsumerState<MascotDemoScreen> createState() => _MascotDemoScreenState();
}

class _MascotDemoScreenState extends ConsumerState<MascotDemoScreen> {
  final _guide = NooriGuideController();
  NooriState _state = NooriState.idle;

  static const _labels = {
    NooriState.idle: LocalizedText(en: 'Idle', ur: 'آرام'),
    NooriState.talking: LocalizedText(en: 'Talking', ur: 'باتیں'),
    NooriState.happy: LocalizedText(en: 'Happy', ur: 'خوش'),
    NooriState.thinking: LocalizedText(en: 'Thinking', ur: 'سوچ'),
    NooriState.sleepy: LocalizedText(en: 'Sleepy', ur: 'نیند'),
    NooriState.pointing: LocalizedText(en: 'Pointing', ur: 'اشارہ'),
  };
  static const _cheer = LocalizedText(
    en: 'Make Noori happy!',
    ur: 'نوری کو خوش کرو!',
  );

  @override
  void dispose() {
    _guide.dispose();
    super.dispose();
  }

  void _celebrate() {
    ref.read(audioServiceProvider).play(Sfx.sparkle);
    setState(() => _state = NooriState.happy);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final lang = settings.lang;
    final c = context.colors;

    return Scaffold(
      body: GuideScope(
        onIdle: () => _guide.say('demo_hint'),
        child: Stack(
          children: [
            Positioned.fill(
              child: ParallaxScene(
                layers: demoJungleLayers(context, night: settings.bedtime),
              ),
            ),
            Positioned.fill(
              child: FireflyLayer(count: settings.bedtime ? 22 : 12),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.space4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        PuffyIconButton(
                          icon: Icons.translate_rounded,
                          semanticLabel: 'Switch language',
                          sfx: Sfx.whoosh,
                          onTap: () {
                            notifier.toggleLang();
                            _guide.say('demo_hello');
                          },
                        ).popIn(0),
                        const Spacer(),
                        PuffyIconButton(
                          icon: settings.bedtime
                              ? Icons.wb_sunny_rounded
                              : Icons.bedtime_rounded,
                          semanticLabel: 'Bedtime',
                          color: c.secondary,
                          onTap: () {
                            notifier.setBedtime(!settings.bedtime);
                            _guide.say(
                              settings.bedtime ? 'demo_hello' : 'bedtime_on',
                            );
                          },
                        ).popIn(1),
                      ],
                    ),
                    const SizedBox(height: AppSizes.space3),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: NooriGuide(
                        controller: _guide,
                        initialLine: 'demo_hello',
                        size: AppSizes.mascotSm,
                      ).popIn(2),
                    ),
                    Expanded(
                      child: Center(
                        child: NooriMascot(
                          state: _state,
                          size: AppSizes.mascotLg,
                          onTap: () =>
                              ref.read(audioServiceProvider).play(Sfx.pop),
                        ).popIn(3),
                      ),
                    ),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSizes.space2,
                      runSpacing: AppSizes.space2,
                      children: [
                        for (final (i, s) in NooriState.values.indexed)
                          PuffyButton(
                            minSize: AppSizes.minTap,
                            color: s == _state ? c.primary : c.surface,
                            semanticLabel: _labels[s]!.en,
                            onTap: () => setState(() => _state = s),
                            child: Text(
                              _labels[s]!.of(lang),
                              textDirection: lang.direction,
                              style: AppTypography.style(
                                lang,
                                role: TextRole.label,
                                color: s == _state ? c.onPrimary : c.onSurface,
                                weight: 600,
                              ),
                            ),
                          ).popIn(4 + i),
                      ],
                    ),
                    const SizedBox(height: AppSizes.space4),
                    GuideHint(
                      child: PuffyButton(
                        breathe: true,
                        sfx: null,
                        minSize: AppSizes.bigTap,
                        semanticLabel: _cheer.en,
                        onTap: _celebrate,
                        child: Text(
                          _cheer.of(lang),
                          textDirection: lang.direction,
                          style: AppTypography.style(
                            lang,
                            role: TextRole.title,
                            color: c.onPrimary,
                            weight: 700,
                          ),
                        ),
                      ),
                    ).popIn(10),
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
