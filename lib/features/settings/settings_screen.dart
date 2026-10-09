import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/content/catalog.dart';
import '../../core/i18n/app_lang.dart';
import '../../core/mascot/noori_mascot.dart';
import '../../core/progress/progress.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/jar.dart';
import '../../core/widgets/puffy_button.dart';

/// Settings, for grown-ups only (behind the parent gate). Everything that
/// used to live on the child's Home is here: the Word Jar, Bedtime, the
/// language, plus the Parent Corner's progress and the privacy note.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _title = LocalizedText(en: 'Settings', ur: 'سیٹنگز');
  static const _parentCorner = LocalizedText(
    en: 'Parent Corner',
    ur: 'والدین کا گوشہ',
  );
  static const _wordJar = LocalizedText(en: 'Word Jar', ur: 'لفظوں کا مرتبان');
  static const _wordJarHelp = LocalizedText(
    en: 'Words your child has collected. Open it together!',
    ur: 'بچے کے جمع کیے ہوئے الفاظ۔ مل کر کھولیں!',
  );
  static const _bedtime = LocalizedText(en: 'Bedtime mode', ur: 'سونے کا وقت');
  static const _swipe = LocalizedText(
    en: 'Swipe to skip scenes',
    ur: 'انگلی پھیر کر منظر بدلیں',
  );
  static const _swipeHelp = LocalizedText(
    en:
        'Off by default, so little hands don\'t skip by accident. When on, '
        'a long swipe moves to the next or previous scene.',
    ur:
        'شروع میں بند ہے تاکہ ننھے ہاتھ غلطی سے منظر نہ بدل دیں۔ چالو ہو تو '
        'لمبی انگلی پھیرنے سے اگلا یا پچھلا منظر آ جاتا ہے۔',
  );
  static const _bedtimeHelp = LocalizedText(
    en: 'A night sky, sleepy Noori and slower narration.',
    ur: 'رات کا آسمان، اونگھتی نوری اور دھیمی آواز۔',
  );
  static const _stories = LocalizedText(
    en: 'Stories finished',
    ur: 'مکمل کہانیاں',
  );
  static const _words = LocalizedText(
    en: 'Words learned',
    ur: 'سیکھے ہوئے الفاظ',
  );
  static const _listening = LocalizedText(
    en: 'Listening time',
    ur: 'سننے کا وقت',
  );
  static const _minutes = LocalizedText(en: 'min', ur: 'منٹ');
  static const _language = LocalizedText(en: 'Language', ur: 'زبان');
  static const _sound = LocalizedText(en: 'Sound', ur: 'آواز');
  static const _on = LocalizedText(en: 'On', ur: 'چالو');
  static const _off = LocalizedText(en: 'Off', ur: 'بند');
  static const _storyList = LocalizedText(en: 'Stories', ur: 'کہانیاں');
  static const _sleepTimer = LocalizedText(
    en: 'Bedtime sleep timer',
    ur: 'سونے کا ٹائمر',
  );
  static const _sleepHelp = LocalizedText(
    en: 'In Bedtime mode, Noori says good night and the app rests after:',
    ur: 'سونے کے وقت والے موڈ میں، اتنی دیر بعد نوری شب بخیر کہہ کر ایپ بند کر دیتی ہے:',
  );
  static const _privacyTitle = LocalizedText(en: 'Privacy', ur: 'رازداری');
  static const _privacy = LocalizedText(
    en:
        'Noori works completely offline. No data ever leaves this device: '
        'no accounts, no ads, no tracking and no internet connection. '
        "Your child's progress is stored only on this phone.",
    ur:
        'نوری مکمل طور پر آف لائن چلتی ہے۔ کوئی بھی معلومات اس فون سے باہر نہیں جاتی: '
        'نہ اکاؤنٹ، نہ اشتہار، نہ ٹریکنگ اور نہ انٹرنیٹ۔ '
        'بچے کی پیش رفت صرف اسی فون میں محفوظ رہتی ہے۔',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final progress = ref.watch(progressProvider);
    final catalog = ref.watch(catalogProvider).value;
    final lang = settings.lang;
    final total =
        catalog?.zones.fold<int>(0, (n, z) => n + z.stories.length) ?? 0;

    TextStyle style(TextRole role, {Color? color, double weight = 600}) =>
        AppTypography.style(
          lang,
          role: role,
          color: color ?? c.onSurface,
          weight: weight,
        );

    Widget section(String title, Widget child, int index) => Container(
      margin: const EdgeInsets.only(bottom: AppSizes.space4),
      padding: const EdgeInsets.all(AppSizes.space4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: style(TextRole.label, color: c.onSurfaceSoft)),
          const SizedBox(height: AppSizes.space3),
          child,
        ],
      ),
    ).popIn(index);

    Widget stat(String label, String value) => Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.style(
              AppLang.en,
              role: TextRole.title,
              color: c.secondary,
              weight: 700,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: style(TextRole.caption),
          ),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.space4),
          children: [
            Row(
              children: [
                PuffyIconButton(
                  icon: Icons.arrow_back_rounded,
                  semanticLabel: 'Back',
                  color: c.surface,
                  onTap: () => context.pop(),
                ),
                const SizedBox(width: AppSizes.space3),
                Expanded(
                  child: Text(
                    _title.of(lang),
                    style: style(TextRole.title, weight: 700),
                  ),
                ),
                NooriMascot(
                  state: settings.bedtime ? NooriState.sleepy : NooriState.idle,
                  size: AppSizes.mascotSm * 0.8,
                ),
              ],
            ).popIn(0),
            const SizedBox(height: AppSizes.space4),
            section(
              _wordJar.of(lang),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _wordJarHelp.of(lang),
                      style: style(TextRole.caption, weight: 500),
                    ),
                  ),
                  const SizedBox(width: AppSizes.space3),
                  PuffyButton(
                    semanticLabel: _wordJar.en,
                    color: c.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.space3,
                    ),
                    onTap: () => context.push(Routes.jar),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const JarIcon(),
                        const SizedBox(width: AppSizes.space2),
                        Text(
                          '${progress.words.length}',
                          style: AppTypography.style(
                            AppLang.en,
                            role: TextRole.label,
                            color: c.onPrimary,
                            weight: 700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              1,
            ),
            section(
              _bedtime.of(lang),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _bedtimeHelp.of(lang),
                      style: style(TextRole.caption, weight: 500),
                    ),
                  ),
                  const SizedBox(width: AppSizes.space3),
                  PuffyIconButton(
                    icon: settings.bedtime
                        ? Icons.bedtime_rounded
                        : Icons.wb_sunny_rounded,
                    semanticLabel: 'Bedtime',
                    color: settings.bedtime ? c.secondary : c.primary,
                    onTap: () => notifier.setBedtime(!settings.bedtime),
                  ),
                ],
              ),
              1,
            ),
            section(
              _swipe.of(lang),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _swipeHelp.of(lang),
                      style: style(TextRole.caption, weight: 500),
                    ),
                  ),
                  const SizedBox(width: AppSizes.space3),
                  PuffyButton(
                    semanticLabel: _swipe.en,
                    color: settings.swipeToSkip ? c.primary : c.backgroundAlt,
                    onTap: () => notifier.setSwipeToSkip(!settings.swipeToSkip),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swipe_rounded,
                          color: c.onPrimary,
                          size: AppSizes.iconMd,
                        ),
                        const SizedBox(width: AppSizes.space2),
                        Text(
                          (settings.swipeToSkip ? _on : _off).of(lang),
                          style: style(
                            TextRole.label,
                            color: c.onPrimary,
                            weight: 700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              1,
            ),
            section(
              _parentCorner.of(lang),
              Row(
                children: [
                  stat(_stories.of(lang), '${progress.stars.length}/$total'),
                  stat(_words.of(lang), '${progress.words.length}'),
                  stat(
                    _listening.of(lang),
                    '${progress.listeningSeconds ~/ 60} ${_minutes.of(lang)}',
                  ),
                ],
              ),
              1,
            ),
            if (catalog != null)
              section(
                _storyList.of(lang),
                Column(
                  children: [
                    for (final zone in catalog.zones)
                      for (final story in zone.stories)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.space1,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  story.title.of(lang),
                                  style: style(TextRole.caption),
                                ),
                              ),
                              for (var i = 0; i < 3; i++)
                                Icon(
                                  i < progress.starsFor(story.id)
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: c.primary,
                                  size: AppSizes.starSm,
                                ),
                            ],
                          ),
                        ),
                  ],
                ),
                2,
              ),
            section(
              _language.of(lang),
              Row(
                children: [
                  for (final (l, label) in const [
                    (AppLang.en, 'English'),
                    (AppLang.ur, 'اردو'),
                  ])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.space1,
                        ),
                        child: PuffyButton(
                          semanticLabel: label,
                          color: lang == l ? c.primary : c.backgroundAlt,
                          onTap: () => notifier.setLang(l),
                          child: Text(
                            label,
                            style: AppTypography.style(
                              l,
                              role: TextRole.label,
                              color: c.onPrimary,
                              weight: 700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              2,
            ),
            section(
              _sound.of(lang),
              PuffyButton(
                semanticLabel: _sound.en,
                color: settings.soundOn ? c.primary : c.backgroundAlt,
                onTap: () => notifier.setSound(!settings.soundOn),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      settings.soundOn
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      color: c.onPrimary,
                      size: AppSizes.iconMd,
                    ),
                    const SizedBox(width: AppSizes.space2),
                    Text(
                      (settings.soundOn ? _on : _off).of(lang),
                      style: style(
                        TextRole.label,
                        color: c.onPrimary,
                        weight: 700,
                      ),
                    ),
                  ],
                ),
              ),
              3,
            ),
            section(
              _sleepTimer.of(lang),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _sleepHelp.of(lang),
                    style: style(TextRole.caption, weight: 500),
                  ),
                  const SizedBox(height: AppSizes.space3),
                  Row(
                    children: [
                      for (final m in AppSettings.sleepChoices)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.space1,
                            ),
                            child: PuffyButton(
                              semanticLabel: '$m ${_minutes.en}',
                              color: settings.sleepMinutes == m
                                  ? c.primary
                                  : c.backgroundAlt,
                              padding: EdgeInsets.zero,
                              onTap: () => notifier.setSleepMinutes(m),
                              child: Text(
                                '$m ${_minutes.of(lang)}',
                                style: style(
                                  TextRole.label,
                                  color: c.onPrimary,
                                  weight: 700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              4,
            ),
            section(
              _privacyTitle.of(lang),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_rounded,
                    color: c.secondary,
                    size: AppSizes.iconMd,
                  ),
                  const SizedBox(width: AppSizes.space3),
                  Expanded(
                    child: Text(
                      _privacy.of(lang),
                      style: style(TextRole.caption, weight: 500),
                    ),
                  ),
                ],
              ),
              4,
            ),
          ],
        ),
      ),
    );
  }
}
