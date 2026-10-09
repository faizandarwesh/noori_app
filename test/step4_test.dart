import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:noori/app/routes.dart';
import 'package:noori/core/audio/audio_service.dart';
import 'package:noori/core/content/story.dart';
import 'package:noori/core/progress/progress.dart';
import 'package:noori/core/storage/local_store.dart';
import 'package:noori/core/theme/app_theme.dart';
import 'package:noori/core/widgets/illustration.dart';
import 'package:noori/features/quiz/quiz_screen.dart';
import 'package:noori/features/reader/reader_screen.dart';
import 'package:noori/features/reward/reward_result.dart';
import 'package:noori/features/reward/reward_screen.dart';
import 'package:noori/features/word_jar/word_jar_screen.dart';

const _story = 'bunty_big_mango';

Future<void> _pumpFor(WidgetTester tester, Duration d) async {
  const frame = Duration(milliseconds: 50);
  for (var t = Duration.zero; t < d; t += frame) {
    await tester.pump(frame);
  }
}

/// Pumps until [done] holds, up to [max].
Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  Duration max = const Duration(seconds: 30),
}) async {
  const frame = Duration(milliseconds: 100);
  for (var t = Duration.zero; t < max && !done(); t += frame) {
    await tester.pump(frame);
  }
}

/// The quiz picture showing [file].
Finder _art(String file) =>
    find.byWidgetPredicate((w) => w is Illustration && w.asset.endsWith(file));

/// Drags the drag question's picture onto [target], one finger, slowly.
Future<void> _dragTo(WidgetTester tester, Finder target) async {
  final from = tester.getCenter(find.byType(Draggable<PictureRef>));
  final to = tester.getCenter(target);
  final g = await tester.startGesture(from);
  for (var i = 1; i <= 10; i++) {
    await g.moveTo(Offset.lerp(from, to, i / 10)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await g.up();
}

/// A small router with the story screens, starting at [start].
Future<ProviderContainer> _boot(
  WidgetTester tester,
  String start, {
  Map<String, Object?>? store,
}) async {
  await tester.binding.setSurfaceSize(const Size(412, 892));
  final container = ProviderContainer(
    overrides: [
      audioServiceProvider.overrideWithValue(AudioService(enabled: false)),
      localStoreProvider.overrideWithValue(MemoryStore(store)),
    ],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    initialLocation: start,
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (_, _) => const Scaffold(body: Text('HOME')),
      ),
      GoRoute(
        path: Routes.storyPattern,
        builder: (_, s) => ReaderScreen(storyId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.quizPattern,
        builder: (_, s) => QuizScreen(storyId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.rewardPattern,
        builder: (_, s) => RewardScreen(
          storyId: s.pathParameters['id']!,
          result: s.extra as RewardResult?,
        ),
      ),
      GoRoute(path: Routes.jar, builder: (_, _) => const WordJarScreen()),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.day(), routerConfig: router),
    ),
  );
  await _pumpFor(tester, const Duration(seconds: 2));
  return container;
}

Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 15));
}

void main() {
  setUp(rootBundle.clear);

  test('stars count first-try answers, never zero', () {
    expect(RewardResult.starsFor(0), 1);
    expect(RewardResult.starsFor(2), 2);
    expect(RewardResult.starsFor(3), 3);
  });

  testWidgets('choice moment leads to the chosen branch', (tester) async {
    await _boot(
      tester,
      Routes.story(_story),
      store: {'settings.swipeToSkip': true},
    );
    await _pumpFor(tester, const Duration(seconds: 1));
    // Skip through the opening scenes with swipes.
    for (var i = 0; i < 4; i++) {
      await tester.fling(
        find.byType(ReaderScreen),
        const Offset(-450, 0),
        1200,
      );
      await _pumpFor(tester, const Duration(milliseconds: 1500));
    }
    // Auto-play waits here; Noori asks (the prompt card and her bubble).
    await _pumpFor(tester, const Duration(seconds: 20));
    expect(find.text('What should Bunty do with the mango?'), findsWidgets);

    await tester.tap(find.bySemanticsLabel('Share it'));
    await _pumpFor(tester, const Duration(seconds: 3));
    expect(
      find.text('smiled.'),
      findsOneWidget,
      reason: 'first page of the share branch',
    );

    // After the choice the story carries on by itself.
    await _pumpUntil(tester, () => find.text('smiled.').evaluate().isEmpty);
    expect(find.text('smiled.'), findsNothing);

    // Swiping back returns to the Choice Moment.
    const prompt = 'What should Bunty do with the mango?';
    for (var i = 0; i < 3 && find.text(prompt).evaluate().isEmpty; i++) {
      await tester.fling(find.byType(ReaderScreen), const Offset(450, 0), 1200);
      await _pumpFor(tester, const Duration(milliseconds: 1500));
    }
    expect(find.text('What should Bunty do with the mango?'), findsWidgets);
    await _teardown(tester);
  });

  testWidgets('quiz: gentle retry, fireflies, then the reward', (tester) async {
    final container = await _boot(tester, Routes.quiz(_story));
    expect(
      find.text('Who found the big mango?'),
      findsWidgets,
    ); // card + bubble

    // Wrong: a soft "try again", nothing lost.
    await tester.tap(find.bySemanticsLabel('turtle'));
    await _pumpFor(tester, const Duration(milliseconds: 800));
    expect(find.text('Try again!'), findsOneWidget);
    expect(container.read(progressProvider).fireflies, 0);

    // Right: a firefly lands in the lantern.
    await tester.tap(find.bySemanticsLabel('rabbit'));
    await _pumpFor(tester, const Duration(seconds: 3));
    expect(container.read(progressProvider).fireflies, 1);

    // Then the special question: drag the mango slice to Tolu.
    expect(find.text('Give a piece of mango to Tolu!'), findsWidgets);
    await _dragTo(tester, _art('turtle_face.svg'));
    await _pumpFor(tester, const Duration(seconds: 3));
    expect(container.read(progressProvider).fireflies, 2);

    // And one more picture question.
    await tester.tap(find.bySemanticsLabel('mango'));
    await _pumpFor(tester, const Duration(seconds: 4));

    final p = container.read(progressProvider);
    expect(p.fireflies, 3);
    expect(p.starsFor(_story), 2, reason: 'two first-try answers');
    expect(
      p.words,
      containsAll(['$_story/mango', '$_story/share', '$_story/friend']),
    );

    // The reward plays through, offers the way home, then goes there.
    await _pumpFor(tester, const Duration(seconds: 12));
    expect(find.bySemanticsLabel('Home'), findsOneWidget);
    expect(find.bySemanticsLabel('Word Jar'), findsNothing);
    await _pumpFor(tester, const Duration(seconds: 7));
    expect(find.text('HOME'), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('a replay brings a new kind of question: scenes in order', (
    tester,
  ) async {
    final container = await _boot(
      tester,
      Routes.quiz(_story),
      store: {
        'progress.plays': {_story: 1},
      },
    );
    // Second play: a picture question first (now "What fell…?").
    expect(find.text('What fell from the tree?'), findsWidgets);
    await tester.tap(find.bySemanticsLabel('mango'));
    await _pumpFor(tester, const Duration(seconds: 3));

    // Then put three scenes in story order. They're laid out last, first,
    // middle; a wrong tap just shakes.
    expect(find.bySemanticsLabel('Scene 1'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Scene 1'));
    await _pumpFor(tester, const Duration(milliseconds: 800));
    expect(find.text('Try again!'), findsOneWidget);
    for (final scene in ['Scene 2', 'Scene 3', 'Scene 1']) {
      await tester.tap(find.bySemanticsLabel(scene));
      await _pumpFor(tester, const Duration(milliseconds: 400));
    }
    await _pumpFor(tester, const Duration(seconds: 3));
    expect(container.read(progressProvider).fireflies, 2);
    await _teardown(tester);
  });

  testWidgets('word jar shows collected words', (tester) async {
    await _boot(
      tester,
      Routes.jar,
      store: {
        'progress.words': ['$_story/mango', '$_story/friend'],
      },
    );
    expect(find.text('mango'), findsOneWidget);
    expect(find.text('آم'), findsOneWidget);
    expect(find.text('دوست'), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('an empty jar says so kindly', (tester) async {
    await _boot(tester, Routes.jar);
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(
      find.text('Your jar is empty. Finish a story to find words!'),
      findsOneWidget,
    );
    await _teardown(tester);
  });
}
