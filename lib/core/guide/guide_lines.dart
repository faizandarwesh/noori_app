import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/app_lang.dart';

/// Noori's spoken instructions, from assets/content/guide_lines.json.
class GuideLines {
  const GuideLines(this._lines);

  static const asset = 'assets/content/guide_lines.json';

  factory GuideLines.fromJson(Map<String, dynamic> json) => GuideLines({
    for (final e in json.entries)
      if (e.value is Map<String, dynamic>)
        e.key: LocalizedText.fromJson(e.value as Map<String, dynamic>),
  });

  final Map<String, LocalizedText> _lines;

  LocalizedText? operator [](String key) => _lines[key];

  String text(String key, AppLang lang) => _lines[key]?.of(lang) ?? '';
}

final guideLinesProvider = FutureProvider<GuideLines>((ref) async {
  final raw = await rootBundle.loadString(GuideLines.asset);
  return GuideLines.fromJson(jsonDecode(raw) as Map<String, dynamic>);
});
