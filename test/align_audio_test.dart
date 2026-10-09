import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/align_audio.dart';

void main() {
  group('align', () {
    test('matched words take Whisper times, punctuation ignored', () {
      final t = align(textWords('Plop! A big mango.'), [
        (word: 'plop', start: 100, end: 400),
        (word: 'a', start: 450, end: 500),
        (word: 'big', start: 520, end: 800),
        (word: 'Mango', start: 820, end: 1300),
      ]);
      expect(t.map((w) => w['w']), ['Plop!', 'A', 'big', 'mango.']);
      expect(t.map((w) => w['start']), [100, 450, 520, 820]);
    });

    test('a misheard word is paired in place', () {
      final t = align(textWords('Bunty hopped home'), [
        (word: 'Bunty', start: 0, end: 300),
        (word: 'hoped', start: 320, end: 600),
        (word: 'home', start: 620, end: 900),
      ]);
      expect(t[1]['start'], 320);
    });

    test('missed words are spread between neighbours, in order', () {
      final t = align(textWords('one two three four'), [
        (word: 'one', start: 0, end: 200),
        (word: 'four', start: 1000, end: 1200),
      ]);
      final starts = [for (final w in t) w['start']! as int];
      expect(starts.first, 0);
      expect(starts.last, 1000);
      expect(starts[1], greaterThanOrEqualTo(200));
      expect(starts[2], greaterThan(starts[1]));
      expect(starts[2], lessThan(1000));
    });

    test('works for Urdu and with nothing heard', () {
      final ur = align(textWords('بنٹی خرگوش آیا۔'), [
        (word: 'بنٹی', start: 0, end: 300),
        (word: 'خرگوش', start: 320, end: 700),
        (word: 'آیا', start: 720, end: 1000),
      ]);
      expect(ur.map((w) => w['start']), [0, 320, 720]);
      expect(align(textWords('a b c'), const []), hasLength(3));
    });
  });

  test('page clip names match the app', () {
    expect(
      pageClip('bunty_big_mango', 'p5_share', 'ur'),
      'assets/audio/stories/bunty_big_mango/ur/page_5_share.mp3',
    );
  });

  test('rewriting a story keeps its content and its one-line style', () {
    final raw = File('assets/content/stories/bunty_big_mango.json')
        .readAsStringSync();
    final story = jsonDecode(raw);
    final out = prettyJson(story);
    expect(jsonDecode(out), story);
    expect(
      out,
      contains('{ "art": "character:rabbit", "x": 0.56'),
      reason: 'small objects stay on one line',
    );
  });
}
