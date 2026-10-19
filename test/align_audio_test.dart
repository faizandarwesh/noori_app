import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

  group('whole-story recording', () {
    // Heard words 400 ms apart, with longer pauses where [gaps] says.
    List<Heard> heardOf(List<String> words, {Map<int, int> gaps = const {}}) {
      var t = 0;
      return [
        for (final (i, w) in words.indexed)
          () {
            t += gaps[i] ?? 100;
            final h = (word: w, start: t, end: t + 300);
            t += 300;
            return h;
          }(),
      ];
    }

    test('pages split in the pause between them', () {
      final heard = heardOf(
        ['one', 'two', 'three', 'four', 'fiv', 'six'],
        gaps: {2: 900, 4: 200},
      );
      final spans = planPages([
        ['one', 'two'],
        ['three', 'four', 'five', 'six'],
      ], heard);
      expect(spans[0], (matched: 2, from: 0, to: 1));
      expect(spans[1], (matched: 3, from: 2, to: 5));
    });

    test('a branch that was not read is left out', () {
      final heard = heardOf(['a', 'b', 'c', 'x', 'y', 'g', 'h']);
      final spans = planPages([
        ['a', 'b', 'c'],
        ['x', 'y'],
        ['p', 'q', 'r', 'c'],
        ['g', 'h'],
      ], heard);
      expect(spans[2], isNull);
      expect([spans[0], spans[1], spans[3]], everyElement(isNotNull));
    });

    test('a title before the first page is skipped', () {
      final heard = heardOf(['title', 'one', 'two'], gaps: {1: 1200});
      expect(
        planPages([
          ['one', 'two'],
        ], heard).single?.from,
        1,
      );
    });

    test('a clip keeps the pause when Whisper missed its last words', () {
      final heard = heardOf(['one', 'two', 'three'], gaps: {2: 3000});
      // 'two' ends at 800, 'three' starts at 3800.
      expect(clipBounds(heard, 0, 1, 5000), (50, 1300));
      expect(clipBounds(heard, 0, 1, 5000, tailMissed: true), (50, 3500));
      expect(clipBounds(heard, 0, 2, 4500, tailMissed: true).$2, 4500);
      final unheardEnd = align(
        textWords('one two three four'),
        heard.sublist(0, 2),
        until: 3000,
      );
      expect(unheardEnd.last['start'], greaterThan(1500));
    });

    test('Arabic letter forms match their Urdu ones', () {
      expect(matchKey('كيا'), matchKey('کیا'));
      expect(matchKey('چاہیے؟'), matchKey('چاهیے'));
    });

    test('MP3 frames are cut without the header frame', () {
      // MPEG-1 layer III, 128 kbps, 44.1 kHz, mono: 417-byte frames.
      Uint8List frame([String fill = '']) {
        final f = Uint8List(417)..setAll(0, [0xFF, 0xFB, 0x90, 0xC0]);
        f.setAll(4 + 17, fill.codeUnits);
        return f;
      }

      final file = Uint8List.fromList([
        ...frame('Info'),
        for (var i = 0; i < 100; i++) ...frame(),
      ]);
      final frames = mp3Frames(file);
      expect(frames, hasLength(100));
      expect(frames.first.ms, closeTo(26.12, 0.01));
      final clip = mp3Slice(file, frames, 1000, 2000);
      expect(clip.startMs, closeTo(992, 1)); // frame 38 holds 1000 ms
      expect(clip.bytes.length % 417, 0);
      expect(mp3Frames(clip.bytes).length, clip.bytes.length ~/ 417);
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
