import 'package:flutter/widgets.dart';

enum AppLang {
  en,
  ur;

  bool get isRtl => this == AppLang.ur;
  TextDirection get direction => isRtl ? TextDirection.rtl : TextDirection.ltr;
  AppLang get other => this == AppLang.en ? AppLang.ur : AppLang.en;

  /// BCP-47 tag used for text-to-speech.
  String get ttsLocale => this == AppLang.en ? 'en-US' : 'ur-PK';

  static AppLang parse(String? code) => code == 'ur' ? AppLang.ur : AppLang.en;
}

/// A string available in both languages, as stored in the JSON content.
@immutable
class LocalizedText {
  const LocalizedText({required this.en, required this.ur});

  factory LocalizedText.fromJson(Map<String, dynamic> json) => LocalizedText(
    en: json['en'] as String? ?? '',
    ur: json['ur'] as String? ?? '',
  );

  final String en;
  final String ur;

  String of(AppLang lang) => lang == AppLang.en ? en : ur;

  Map<String, dynamic> toJson() => {'en': en, 'ur': ur};
}
