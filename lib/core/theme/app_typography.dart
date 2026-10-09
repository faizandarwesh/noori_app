import 'package:flutter/widgets.dart';

import '../i18n/app_lang.dart';

/// Fonts are bundled in assets/fonts (variable TTFs), so the app never
/// fetches anything at runtime. Weight is set through the `wght` axis.
abstract final class AppFonts {
  static const english = 'Fredoka';
  static const urdu = 'NotoNastaliqUrdu';
}

abstract final class AppTypeScale {
  static const bodyEn = 22.0;
  static const bodyUr = 26.0;
  static const titleEn = 34.0;
  static const titleUr = 34.0;
  static const displayEn = 52.0;
  static const displayUr = 48.0;
  static const splashEn = 96.0;
  static const splashUr = 88.0;
  static const labelEn = 20.0;
  static const labelUr = 22.0;
  static const captionEn = 16.0;
  static const captionUr = 17.0;

  /// Tighter Nastaliq height for short one-line captions.
  static const urduCaptionHeight = 1.6;

  /// Nastaliq needs generous line height for its tall ascenders/descenders.
  static const urduHeight = 2.1;
  static const englishHeight = 1.3;
}

enum TextRole { body, title, display, label, caption }

abstract final class AppTypography {
  static TextStyle style(
    AppLang lang, {
    TextRole role = TextRole.body,
    Color? color,
    double weight = 500,
  }) {
    final isUr = lang == AppLang.ur;
    final size = switch (role) {
      TextRole.body => isUr ? AppTypeScale.bodyUr : AppTypeScale.bodyEn,
      TextRole.title => isUr ? AppTypeScale.titleUr : AppTypeScale.titleEn,
      TextRole.display =>
        isUr ? AppTypeScale.displayUr : AppTypeScale.displayEn,
      TextRole.label => isUr ? AppTypeScale.labelUr : AppTypeScale.labelEn,
      TextRole.caption =>
        isUr ? AppTypeScale.captionUr : AppTypeScale.captionEn,
    };
    return TextStyle(
      fontFamily: isUr ? AppFonts.urdu : AppFonts.english,
      // Each font covers the other script, e.g. digits in Urdu text or an
      // Urdu unit after an English number.
      fontFamilyFallback: isUr
          ? const [AppFonts.english]
          : const [AppFonts.urdu],
      fontSize: size,
      height: isUr
          ? (role == TextRole.caption
                ? AppTypeScale.urduCaptionHeight
                : AppTypeScale.urduHeight)
          : AppTypeScale.englishHeight,
      color: color,
      fontVariations: [FontVariation.weight(weight)],
      fontWeight: _nearestWeight(weight),
    );
  }

  static FontWeight _nearestWeight(double w) {
    final i = ((w / 100).round() - 1).clamp(0, 8);
    return FontWeight.values[i];
  }
}
