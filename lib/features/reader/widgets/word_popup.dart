import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/i18n/app_lang.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bouncy_button.dart';

/// Shown when a child taps a word: the word, and (if the glossary knows it)
/// its meaning in the other language. A side with a recording plays it when
/// tapped.
class WordPopup extends StatelessWidget {
  const WordPopup({
    super.key,
    required this.word,
    required this.lang,
    required this.meaning,
    required this.onClose,
    this.onSpeakWord,
    this.onSpeakMeaning,
  });

  final String word;
  final AppLang lang;

  /// The word in the other language, or null if it isn't in the glossary.
  final String? meaning;
  final VoidCallback? onSpeakWord;
  final VoidCallback? onSpeakMeaning;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Flexible + scaleDown: long words shrink instead of overflowing.
    Widget side(String text, AppLang l, VoidCallback? speak) => Flexible(
      child: BouncyButton(
        semanticLabel: text,
        sfx: speak == null ? Sfx.pop : null,
        onTap: speak ?? () {},
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                textDirection: l.direction,
                style: AppTypography.style(
                  l,
                  role: TextRole.title,
                  color: c.onSurface,
                  weight: 700,
                ),
              ),
              if (speak != null)
                Icon(
                  Icons.volume_up_rounded,
                  color: c.secondary,
                  size: AppSizes.iconMd,
                ),
            ],
          ),
        ),
      ),
    );

    return GestureDetector(
          onTap: onClose,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.space5,
              vertical: AppSizes.space3,
            ),
            decoration: BoxDecoration(
              color: c.bubble,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(color: c.primary, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: AppPalette.shadow,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.ltr,
              children: [
                side(word, lang, onSpeakWord),
                if (meaning != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.space4,
                    ),
                    child: Icon(
                      Icons.sync_alt_rounded,
                      color: c.onSurfaceSoft,
                      size: AppSizes.iconMd,
                    ),
                  ),
                  side(meaning!, lang.other, onSpeakMeaning),
                ],
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 120.ms)
        .scaleXY(
          begin: 0.4,
          duration: AppMotion.bubblePop,
          curve: AppMotion.pop,
        );
  }
}
