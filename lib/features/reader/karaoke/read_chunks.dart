import 'package:flutter/foundation.dart';

/// A run of non-space text, e.g. `“Yum!”` or `Let's`. Punctuation stays
/// attached to its word so a line never starts with a stray mark.
@immutable
class ReadChunk {
  const ReadChunk({required this.text, required this.start});

  final String text;

  /// Offset of the chunk in the page text.
  final int start;
  int get end => start + text.length;

  /// Chunks with no letters (a lone dash) are shown but never highlighted.
  bool get hasWord => _letter.hasMatch(text);

  static final _letter = RegExp(r'\p{L}', unicode: true);
}

/// Splits page text at whitespace.
List<ReadChunk> splitChunks(String text) => [
  for (final m in RegExp(r'\S+').allMatches(text))
    ReadChunk(text: m.group(0)!, start: m.start),
];
