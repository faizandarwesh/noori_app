import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noori/app/noori_app.dart';
import 'package:noori/core/audio/audio_service.dart';
import 'package:noori/core/content/catalog.dart';
import 'package:noori/core/mascot/noori_pose.dart';
import 'package:noori/core/progress/progress.dart';
import 'package:noori/core/settings/app_settings.dart';
import 'package:noori/core/storage/local_store.dart';
import 'package:noori/features/home/home_screen.dart';
import 'package:noori/features/home/widgets/story_card.dart';
import 'package:noori/features/reader/reader_screen.dart';

ProviderContainer _container([MemoryStore? store]) => ProviderContainer(
  overrides: [
    audioServiceProvider.overrideWithValue(AudioService(enabled: false)),
    localStoreProvider.overrideWithValue(store ?? MemoryStore()),
  ],
);

Future<void> _pumpFrames(WidgetTester tester, Duration total) async {
  const frame = Duration(milliseconds: 50);
  for (var t = Duration.zero; t < total; t += frame) {
    await tester.pump(frame);
  }
}

/// Unmount and let pending timers (idle hints, speech minimums) finish.
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 15));
}

void main() {
  // rootBundle caches asset futures; one created in a previous test's fake
  // zone never completes in the next, so start each test with a clean cache.
  setUp(rootBundle.clear);

  testWidgets('first launch: splash → lanterns → straight into Home', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    final container = _container();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const NooriApp()),
    );

    // The splash hands over to Noori and her two lanterns. No buttons.
    await _pumpFrames(tester, const Duration(seconds: 5));
    expect(find.bySemanticsLabel('English'), findsOneWidget);
    expect(find.bySemanticsLabel('اردو'), findsOneWidget);
    expect(find.bySemanticsLabel('Go'), findsNothing);

    // One tap: the lantern bursts and the app goes home by itself.
    await tester.tap(find.bySemanticsLabel('اردو'));
    await _pumpFrames(tester, const Duration(seconds: 3));
    expect(container.read(appSettingsProvider).lang.name, 'ur');
    expect(container.read(appSettingsProvider).languageChosen, isTrue);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(StoryCard), findsWidgets);
    await _teardown(tester);
  });

  testWidgets('Home shows only stories; Noori greets once, ever', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    final store = MemoryStore({'settings.languageChosen': true});
    final container = _container(store);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const NooriApp()),
    );
    await tester.tap(find.byType(Scaffold)); // skip splash
    await _pumpFrames(tester, const Duration(seconds: 2));

    expect(find.text('Bunty and the Big Mango'), findsOneWidget);
    expect(find.textContaining('Swipe'), findsOneWidget);
    // No map, no locked zones, no clutter.
    expect(find.text('Sea'), findsNothing);
    expect(find.bySemanticsLabel('Word Jar'), findsNothing);
    expect(find.bySemanticsLabel('Bedtime'), findsNothing);
    expect(container.read(appSettingsProvider).homeGreeted, isTrue);
    await _teardown(tester);

    // Next launch: Home is quiet.
    final again = _container(store);
    addTearDown(again.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: again, child: const NooriApp()),
    );
    await tester.tap(find.byType(Scaffold));
    await _pumpFrames(tester, const Duration(seconds: 2));
    expect(find.textContaining('Swipe'), findsNothing);
    await _teardown(tester);
  });

  testWidgets('tapping the middle card opens its story', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    final container = _container(
      MemoryStore({
        'settings.languageChosen': true,
        'settings.homeGreeted': true,
      }),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const NooriApp()),
    );
    await tester.tap(find.byType(Scaffold));
    await _pumpFrames(tester, const Duration(seconds: 2));

    await tester.tap(find.text('Bunty and the Big Mango'));
    await _pumpFrames(tester, const Duration(seconds: 2));
    expect(find.byType(ReaderScreen), findsOneWidget);
    expect(find.text('Bunty'), findsWidgets);
    await _teardown(tester);
  });

  testWidgets('parent gate stays shut on a wrong answer', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    final container = _container(
      MemoryStore({'settings.languageChosen': true}),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const NooriApp()),
    );
    await tester.tap(find.byType(Scaffold));
    await _pumpFrames(tester, const Duration(seconds: 3));

    await tester.tap(find.bySemanticsLabel('Settings'));
    await _pumpFrames(tester, const Duration(seconds: 1));
    final question = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .firstWhere((s) => s.contains(' plus '));
    const words = [
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'seven',
      'eight',
      'nine',
    ];
    final parts = question.toLowerCase().replaceAll('?', '').split(' plus ');
    final answer = words.indexOf(parts[0]) + 1 + words.indexOf(parts[1]) + 1;

    final wrong = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => int.tryParse(t.data ?? ''))
        .whereType<int>()
        .firstWhere((n) => n != answer);
    await tester.tap(find.text('$wrong'));
    await _pumpFrames(tester, const Duration(seconds: 1));
    expect(find.text('Settings'), findsNothing);
    await _teardown(tester);
  });

  test('progress persists and keeps the best stars', () {
    final store = MemoryStore();
    final c1 = _container(store);
    c1.read(progressProvider.notifier)
      ..completeStory('bunty_big_mango', 3)
      ..completeStory('bunty_big_mango', 1)
      ..addFireflies(2);
    expect(c1.read(progressProvider.notifier).collectWord('aam'), isTrue);
    expect(c1.read(progressProvider.notifier).collectWord('aam'), isFalse);
    c1.dispose();

    final c2 = _container(store);
    final p = c2.read(progressProvider);
    expect(p.starsFor('bunty_big_mango'), 3);
    expect(p.fireflies, 2);
    expect(p.words, ['aam']);
    c2.dispose();
  });

  test('a zone unlocks only after the zone before it is complete', () {
    Map<String, Object?> story(String id) => {
      'id': id,
      'title': {'en': id, 'ur': id},
      'character': 'rabbit',
    };
    Map<String, Object?> zone(String id, String? after, List<String> ids) => {
      'id': id,
      'name': {'en': id, 'ur': id},
      'badge': id,
      'unlockAfter': after,
      'stories': [for (final s in ids) story(s)],
    };
    final catalog = Catalog.fromJson({
      'zones': [
        zone('jungle', null, ['a', 'b']),
        zone('samandar', 'jungle', ['c']),
        zone('space', 'jungle', []),
      ],
    });
    final jungle = catalog.zone('jungle')!;
    final sea = catalog.zone('samandar')!;
    final space = catalog.zone('space')!;
    expect(catalog.isZoneUnlocked(jungle, const Progress()), isTrue);
    expect(catalog.isZoneUnlocked(sea, const Progress()), isFalse);
    expect(catalog.playable(const Progress()), hasLength(2));

    final allDone = Progress(stars: {for (final s in jungle.stories) s.id: 2});
    expect(catalog.isZoneComplete(jungle, allDone), isTrue);
    expect(catalog.isZoneUnlocked(sea, allDone), isTrue);
    // Still locked: it has no stories yet.
    expect(catalog.isZoneUnlocked(space, allDone), isFalse);
    // Home only ever lists playable stories.
    expect(catalog.playable(allDone), hasLength(3));
  });

  test('every written story is on Home from the first launch', () {
    final json = jsonDecode(
      File('assets/content/zones.json').readAsStringSync(),
    );
    final catalog = Catalog.fromJson(json as Map<String, dynamic>);
    final all = [for (final z in catalog.zones) ...z.stories];
    expect(catalog.playable(const Progress()), hasLength(all.length));
  });

  test('pose driver eases between states without snapping', () {
    final pose = NooriPose();
    final driver = NooriPoseDriver(pose)..state = NooriState.happy;
    driver.tick(0.016);
    final firstStep = pose.leftWing;
    for (var t = 0.032; t < 2; t += 0.016) {
      driver.tick(t);
    }
    expect(
      firstStep,
      lessThan(0.6),
      reason: 'wings should not jump up instantly',
    );
    expect(pose.happyEyes, greaterThan(0.9));
  });

  test('Noori looks where she is told, easing there', () {
    final pose = NooriPose();
    final driver = NooriPoseDriver(pose)..look = 1;
    for (var t = 0.016; t < 1.5; t += 0.016) {
      driver.tick(t);
    }
    expect(pose.pupil.dx, greaterThan(0.5));
  });
}
