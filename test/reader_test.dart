import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noori/core/audio/audio_service.dart';
import 'package:noori/core/audio/voice_clips.dart';
import 'package:noori/core/content/story.dart';
import 'package:noori/core/i18n/app_lang.dart';
import 'package:noori/core/storage/local_store.dart';
import 'package:noori/core/theme/app_theme.dart';
import 'package:noori/features/reader/karaoke/narrator.dart';
import 'package:noori/features/reader/karaoke/read_chunks.dart';
import 'package:noori/features/reader/reader_screen.dart';
import 'package:noori/features/reader/widgets/subtitle_strip.dart';
import 'package:noori/features/reader/widgets/tap_sparkle.dart';
import 'package:noori/features/reader/widgets/word_popup.dart';

Future<void> _pumpFor(WidgetTester tester, Duration d) async {
  const frame = Duration(milliseconds: 50);
  for (var t = Duration.zero; t < d; t += frame) {
    await tester.pump(frame);
  }
}

void main() {
  setUp(rootBundle.clear);

  group('read chunks', () {
    test('keep punctuation on words and track offsets', () {
      final c = splitChunks('Plop! A big “Yum!” said Bunty.');
      expect(c.map((x) => x.text), [
        'Plop!',
        'A',
        'big',
        '“Yum!”',
        'said',
        'Bunty.',
      ]);
      expect(c[3].start, 'Plop! A big '.length);
    });

    test('Urdu splits on spaces too', () {
      final c = splitChunks('بنٹی بولا، “واہ، مزے دار!”');
      expect(c, hasLength(5));
      expect(c.every((x) => x.hasWord), isTrue);
    });
  });

  group('timings', () {
    test('estimates grow with word length and slow down at bedtime', () {
      const short = ReadChunk(text: 'a', start: 0);
      const long = ReadChunk(text: 'mangoes', start: 0);
      Duration e(ReadChunk c, {bool slow = false}) =>
          Narrator.estimateFor(c, AppLang.en, slow: slow);
      expect(e(long), greaterThan(e(short)));
      expect(e(long, slow: true), greaterThan(e(long)));
    });

    test('estimated timings run in order, one per word', () {
      final chunks = splitChunks('Bunty — hopped to the tree.');
      final t = Narrator.estimateTimings(chunks, AppLang.en, slow: false);
      expect(t, hasLength(5), reason: 'the dash is not a word');
      for (var i = 1; i < t.length; i++) {
        expect(t[i].start, t[i - 1].end);
      }
    });

    test('page JSON carries word timings per language', () {
      final page = StoryPage.fromJson({
        'id': 'p1',
        'next': null,
        'scene': 'mango_grove',
        'text': {'en': 'Hi Bunty', 'ur': 'ہائے بنٹی'},
        'words': {
          'en': [
            {'w': 'Hi', 'start': 100, 'end': 300},
            {'w': 'Bunty', 'start': 320, 'end': 800},
          ],
        },
      });
      expect(page.words[AppLang.en]!.map((w) => w.start), [100, 320]);
      expect(page.words[AppLang.ur], isNull);
    });

    test('voice clip paths follow the recording layout', () {
      expect(
        VoiceClips.page('bunty_big_mango', 'p5_share', AppLang.ur),
        'audio/stories/bunty_big_mango/ur/page_5_share.mp3',
      );
      expect(
        VoiceClips.quiz('bunty_big_mango', 0, AppLang.en),
        'audio/stories/bunty_big_mango/en/quiz_1.mp3',
      );
      expect(
        VoiceClips.guide('choice_ask', AppLang.en),
        'audio/guide/en/choice_ask.mp3',
      );
    });
  });

  group('glossary', () {
    test('matches forms, ignoring case and punctuation', () {
      final g = GlossaryEntry.fromJson({
        'id': 'mango',
        'word': {'en': 'mango', 'ur': 'آم'},
        'forms': {
          'en': ['mangoes'],
          'ur': ['آموں'],
        },
      });
      expect(g.matches('Mangoes!', AppLang.en), isTrue);
      expect(g.matches('آموں', AppLang.ur), isTrue);
      expect(g.matches('آم۔', AppLang.ur), isTrue);
      expect(g.matches('man', AppLang.en), isFalse);
    });

    test('names and prop words cue the cast', () {
      final story = Story.fromJson({
        'id': 's',
        'start': 'p1',
        'characters': {
          'rabbit': {'en': 'Bunty', 'ur': 'بنٹی'},
        },
        'nodes': <Object>[],
        'glossary': [
          {
            'id': 'mango',
            'word': {'en': 'mango', 'ur': 'آم'},
          },
        ],
      });
      const rabbit = PictureRef('character', 'rabbit');
      const mango = PictureRef('prop', 'mango');
      expect(story.cues(rabbit, 'Bunty.', AppLang.en), isTrue);
      expect(story.cues(rabbit, "Bunty's", AppLang.en), isTrue);
      expect(story.cues(rabbit, 'بنٹی', AppLang.ur), isTrue);
      expect(story.cues(rabbit, 'Tolu', AppLang.en), isFalse);
      expect(story.cues(mango, 'آم', AppLang.ur), isTrue);
      expect(story.cues(mango, 'tree', AppLang.en), isFalse);
    });
  });

  group('subtitles', () {
    Future<void> show(WidgetTester tester, String text, AppLang lang) async {
      tester.view
        ..physicalSize = const Size(412, 400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.day(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SubtitleStrip(
                chunks: splitChunks(text),
                lang: lang,
                active: null,
                onWordTap: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('Urdu reads right to left', (tester) async {
      await show(tester, 'اگلے دن وہ واپس آیا', AppLang.ur);
      final first = tester.getCenter(find.text('اگلے'));
      final second = tester.getCenter(find.text('دن'));
      expect(first.dy, second.dy, reason: 'same line');
      expect(
        first.dx,
        greaterThan(second.dx),
        reason: 'first word on the right',
      );
    });

    testWidgets('English reads left to right', (tester) async {
      await show(tester, 'The next day he came back', AppLang.en);
      expect(
        tester.getCenter(find.text('The')).dx,
        lessThan(tester.getCenter(find.text('next')).dx),
      );
    });
  });

  group('cinematic reader', () {
    Future<void> openReader(
      WidgetTester tester, {
      Map<String, Object?>? store,
    }) async {
      await tester.binding.setSurfaceSize(const Size(412, 892));
      tester.view
        ..physicalSize = const Size(412, 892)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioServiceProvider.overrideWithValue(
              AudioService(enabled: false),
            ),
            localStoreProvider.overrideWithValue(MemoryStore(store)),
          ],
          child: MaterialApp(
            theme: AppTheme.day(),
            home: const ReaderScreen(storyId: 'bunty_big_mango'),
          ),
        ),
      );
      await _pumpFor(tester, const Duration(seconds: 1));
    }

    Future<void> teardown(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 15));
    }

    testWidgets('plays on by itself, with no taps', (tester) async {
      await openReader(tester);
      expect(find.text('Bunty'), findsOneWidget);
      expect(find.bySemanticsLabel('Next page'), findsNothing);

      // No recordings in tests: the page reads as a silent read-along, then
      // the camera moves on after the pause.
      await _pumpFor(tester, const Duration(seconds: 10));
      expect(find.text('Plop!'), findsOneWidget);
      expect(find.text('Bunty'), findsNothing);
      await teardown(tester);
    });

    testWidgets('tapping scenery or a character never pauses the story', (
      tester,
    ) async {
      await openReader(tester);
      // Let Bunty finish walking in.
      await _pumpFor(tester, const Duration(seconds: 1));
      // The sky: a sparkle, not a pause.
      await tester.tapAt(const Offset(300, 200));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(TapSparkle), findsOneWidget);
      // Bunty himself (feet at 56% across, 60% down): he hops and giggles,
      // and the tap goes to him, not to the scenery behind.
      await tester.tapAt(const Offset(230, 480));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(TapSparkle), findsOneWidget);
      await _pumpFor(tester, const Duration(milliseconds: 300));
      expect(find.bySemanticsLabel('Play'), findsNothing);
      await _pumpFor(tester, const Duration(seconds: 10));
      expect(find.text('Plop!'), findsOneWidget, reason: 'it kept playing');
      await teardown(tester);
    });

    testWidgets('the pause button pauses; the big play button resumes', (
      tester,
    ) async {
      await openReader(tester);
      await tester.tap(find.bySemanticsLabel('Pause'));
      await _pumpFor(tester, const Duration(milliseconds: 500));
      expect(find.bySemanticsLabel('Play'), findsOneWidget);

      // Paused: it stays on the first scene however long we wait.
      await _pumpFor(tester, const Duration(seconds: 12));
      expect(find.text('Bunty'), findsOneWidget);
      expect(find.text('Plop!'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Play'));
      await _pumpFor(tester, const Duration(seconds: 10));
      expect(find.text('Plop!'), findsOneWidget);
      await teardown(tester);
    });

    testWidgets('a two-finger tap pauses too', (tester) async {
      await openReader(tester);
      final a = await tester.startGesture(const Offset(120, 250));
      final b = await tester.startGesture(const Offset(300, 250));
      await a.up();
      await b.up();
      await _pumpFor(tester, const Duration(milliseconds: 500));
      expect(find.bySemanticsLabel('Play'), findsOneWidget);
      await teardown(tester);
    });

    testWidgets('swipes do nothing unless a grown-up turns them on', (
      tester,
    ) async {
      await openReader(tester);
      await tester.fling(
        find.byType(ReaderScreen),
        const Offset(-300, 0),
        1200,
      );
      await _pumpFor(tester, const Duration(seconds: 2));
      expect(find.text('Bunty'), findsOneWidget);
      expect(find.text('Plop!'), findsNothing);
      await teardown(tester);
    });

    testWidgets('with swiping on, a short swipe is still ignored', (
      tester,
    ) async {
      await openReader(tester, store: {'settings.swipeToSkip': true});
      await tester.fling(find.byType(ReaderScreen), const Offset(-80, 0), 1200);
      await _pumpFor(tester, const Duration(seconds: 2));
      expect(find.text('Bunty'), findsOneWidget);
      await teardown(tester);
    });

    testWidgets('long swipes skip, the corner flips language, words explain', (
      tester,
    ) async {
      await openReader(tester, store: {'settings.swipeToSkip': true});

      // Swipe left: next scene.
      await tester.fling(
        find.byType(ReaderScreen),
        const Offset(-300, 0),
        1200,
      );
      await _pumpFor(tester, const Duration(seconds: 2));
      expect(find.text('Plop!'), findsOneWidget);

      // Flip to Urdu.
      await tester.tap(find.bySemanticsLabel('Switch language'));
      await _pumpFor(tester, const Duration(seconds: 1));
      expect(find.text('دھپ!'), findsOneWidget);
      expect(find.text('Plop!'), findsNothing);

      // In Urdu, swiping right moves on and left goes back.
      await tester.fling(
        find.byType(ReaderScreen),
        const Offset(-300, 0),
        1200,
      );
      await _pumpFor(tester, const Duration(seconds: 2));
      expect(find.text('بنٹی'), findsOneWidget);

      // Tap-a-word: خرگوش ↔ rabbit.
      await tester.tap(find.text('خرگوش'));
      await _pumpFor(tester, const Duration(milliseconds: 600));
      expect(find.byType(WordPopup), findsOneWidget);
      expect(find.text('rabbit'), findsOneWidget);
      await teardown(tester);
    });

    testWidgets('a missing story shows a thinking Noori, not a crash', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioServiceProvider.overrideWithValue(
              AudioService(enabled: false),
            ),
            localStoreProvider.overrideWithValue(MemoryStore()),
          ],
          child: MaterialApp(
            theme: AppTheme.day(),
            home: const ReaderScreen(storyId: 'nope'),
          ),
        ),
      );
      await _pumpFor(tester, const Duration(seconds: 2));
      expect(find.bySemanticsLabel('Home'), findsOneWidget);
      await teardown(tester);
    });
  });
}
