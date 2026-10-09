// Tap-to-help moments and hidden scene surprises.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noori/core/audio/audio_service.dart';
import 'package:noori/core/content/scenes.dart';
import 'package:noori/core/content/story.dart';
import 'package:noori/core/i18n/app_lang.dart';
import 'package:noori/core/storage/local_store.dart';
import 'package:noori/core/theme/app_theme.dart';
import 'package:noori/features/reader/reader_screen.dart';
import 'package:noori/features/reader/widgets/help_moment.dart';
import 'package:noori/features/reader/widgets/scene_secret.dart';
import 'package:noori/features/reader/widgets/story_scene.dart';

const _phone = Size(412, 892);

Future<void> _pumpFor(WidgetTester tester, Duration d) async {
  const frame = Duration(milliseconds: 50);
  for (var t = Duration.zero; t < d; t += frame) {
    await tester.pump(frame);
  }
}

/// Pumps until [finder] shows up (or [max] passes); true if it did.
Future<bool> _pumpUntil(
  WidgetTester tester,
  Finder finder,
  Duration max,
) async {
  const frame = Duration(milliseconds: 50);
  for (var t = Duration.zero; t < max; t += frame) {
    await tester.pump(frame);
    if (finder.evaluate().isNotEmpty) return true;
  }
  return false;
}

/// Lets SVGs finish loading, so the cast has a size to touch.
Future<void> _settleArt(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 4)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void _usePhone(WidgetTester tester) {
  tester.view
    ..physicalSize = _phone
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Just the cast layer, no scenery to load.
const _castOnly = SceneSpec([SceneLayerSpec(art: null, depth: 0.6)]);

CastMember _prop(
  String id,
  double x, {
  int helpStep = 0,
  int? helpHide,
  double size = 0.08,
}) => CastMember(
  art: PictureRef('prop', id),
  x: x,
  y: 0.6,
  size: size,
  helpStep: helpStep,
  helpHide: helpHide,
);

/// Where a cast member's middle is on screen.
Offset _centre(CastMember m) =>
    Offset(m.x * _phone.width, (m.y - m.size / 2) * _phone.height);

Future<HelpController> _scene(
  WidgetTester tester,
  List<CastMember> cast,
  HelpMoment moment, {
  List<SceneSecret> secrets = const [],
  ValueChanged<Offset>? onSecretFound,
}) async {
  _usePhone(tester);
  final help = HelpController()
    ..load(moment)
    ..begin();
  addTearDown(help.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.day(),
        home: StoryScene(
          spec: SceneSpec(_castOnly.layers, secrets: secrets),
          cast: cast,
          help: help,
          secrets: secrets.isNotEmpty,
          onSecretFound: onSecretFound,
          onCastTap: (_) {},
        ),
      ),
    ),
  );
  await _settleArt(tester);
  return help;
}

Future<void> _done(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 5));
}

void main() {
  setUp(rootBundle.clear);

  group('help controller', () {
    test('counts steps to done, and stops waiting', () {
      final help = HelpController()
        ..load(const HelpMoment(kind: HelpKind.tap, item: 0, steps: 2));
      expect(help.active, isFalse);
      help.step();
      expect(help.progress, 0, reason: 'not waiting yet: taps do nothing');
      help
        ..begin()
        ..step();
      expect(help.progress, 1);
      expect(help.done, isFalse);
      help.step();
      expect(help.done, isTrue);
      expect(help.active, isFalse);
      help.dispose();
    });

    testWidgets('the hint hand comes after a pause, and hides under a finger', (
      tester,
    ) async {
      final help = HelpController()
        ..load(const HelpMoment(kind: HelpKind.drag, item: 0, to: 1))
        ..begin();
      expect(help.showHint, isFalse);
      await tester.pump(HelpController.hintAfter);
      expect(help.showHint, isTrue);
      help.touching = true;
      expect(help.showHint, isFalse);
      help.dispose();
    });
  });

  group('helping in the scene', () {
    final bottle = _prop('bottle_low', 0.3, helpHide: 1);
    final cap = _prop('bottle_cap_empty', 0.7, helpHide: 1);
    final full = _prop('bottle_cap', 0.7, helpStep: 1);
    const pour = HelpMoment(kind: HelpKind.drag, item: 0, to: 1);

    testWidgets('dragging the item onto its target finishes it', (
      tester,
    ) async {
      final help = await _scene(tester, [bottle, cap, full], pour);
      expect(find.byType(HelpGlow), findsNWidgets(2));
      expect(find.byType(HelpDragItem), findsOneWidget);
      await tester.dragFrom(_centre(bottle), _centre(cap) - _centre(bottle));
      await tester.pump();
      expect(help.done, isTrue);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(HelpGlow), findsNothing);
      await _done(tester);
    });

    testWidgets('a drop anywhere else floats back and still waits', (
      tester,
    ) async {
      final help = await _scene(tester, [bottle, cap, full], pour);
      await tester.dragFrom(_centre(bottle), const Offset(0, -250));
      await tester.pump(const Duration(seconds: 1));
      expect(help.done, isFalse);
      expect(help.active, isTrue);
      await _done(tester);
    });

    testWidgets('a revealed cast member is only there once helped', (
      tester,
    ) async {
      final help = await _scene(tester, [bottle, cap, full], pour);
      // Index 2 (the full cap) isn't built until the child pours.
      final before = find.byType(FractionalTranslation).evaluate().length;
      help.complete();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(FractionalTranslation).evaluate().length, before + 1);
      await _done(tester);
    });

    testWidgets('tapping counts one step per tap', (tester) async {
      final mango = _prop('mango', 0.5, helpHide: 3);
      final help = await _scene(tester, [
        mango,
        _prop('mango_slice', 0.8, helpStep: 1),
      ], const HelpMoment(kind: HelpKind.tap, item: 0, steps: 3));
      for (var i = 1; i <= 3; i++) {
        await tester.tapAt(_centre(mango));
        await tester.pump(const Duration(milliseconds: 300));
        expect(help.progress, i);
      }
      expect(help.done, isTrue);
      await _done(tester);
    });

    testWidgets('rubbing back and forth counts steps', (tester) async {
      final soil = _prop('soil', 0.5);
      final help = await _scene(tester, [
        soil,
        _prop('sprout', 0.5, helpStep: 3),
      ], const HelpMoment(kind: HelpKind.rub, item: 0, steps: 3));
      final gesture = await tester.startGesture(_centre(soil));
      for (var i = 0; i < 24 && !help.done; i++) {
        await gesture.moveBy(Offset(i.isEven ? 60 : -60, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      expect(help.done, isTrue);
      await _done(tester);
    });
  });

  group('hidden surprises', () {
    testWidgets('a tap on a secret reports the find', (tester) async {
      Offset? found;
      await _scene(
        tester,
        [_prop('rock', 0.2)],
        const HelpMoment(kind: HelpKind.tap, item: 0),
        secrets: const [
          SceneSecret(kind: SecretKind.frog, x: 0.8, y: 0.75, size: 0.05),
        ],
        onSecretFound: (at) => found = at,
      );
      expect(find.byType(SceneSecretView), findsOneWidget);
      await tester.tap(find.byType(SceneSecretView));
      await tester.pump(const Duration(milliseconds: 100));
      expect(found, isNotNull);
      await _pumpFor(tester, const Duration(seconds: 2));
      await _done(tester);
    });

    testWidgets('Home cards leave secrets hidden', (tester) async {
      _usePhone(tester);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: StoryScene(
              spec: SceneSpec(
                [SceneLayerSpec(art: null, depth: 0.6)],
                secrets: [
                  SceneSecret(
                    kind: SecretKind.snail,
                    x: 0.5,
                    y: 0.7,
                    size: 0.04,
                  ),
                ],
              ),
              cast: [],
            ),
          ),
        ),
      );
      expect(find.byType(SceneSecretView), findsNothing);
      await _done(tester);
    });
  });

  group('the reader waits for help', () {
    const id = 'help_demo';
    final mango = _prop('mango', 0.5, helpHide: 1);

    Story story({required bool before}) => Story(
      id: id,
      start: 'p1',
      nodes: [
        StoryPage(
          id: 'p1',
          next: 'p2',
          scene: 'mango_grove',
          text: const LocalizedText(
            en: 'Tap the big mango.',
            ur: 'بڑے آم کو چھوؤ۔',
          ),
          cast: [mango, _prop('mango_slice', 0.7, helpStep: 1)],
          help: HelpMoment(
            kind: HelpKind.tap,
            item: 0,
            beforeNarration: before,
          ),
        ),
        const StoryPage(
          id: 'p2',
          next: null,
          scene: 'mango_grove',
          text: LocalizedText(en: 'Yum yum yum!', ur: 'مزے دار!'),
          cast: [],
        ),
      ],
      glossary: const [],
      vocabulary: const [],
      quiz: const [],
    );

    Future<void> open(WidgetTester tester, Story s) async {
      await tester.binding.setSurfaceSize(_phone);
      _usePhone(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioServiceProvider.overrideWithValue(
              AudioService(enabled: false),
            ),
            localStoreProvider.overrideWithValue(MemoryStore(null)),
            storyProvider(id).overrideWith((ref) async => s),
          ],
          child: MaterialApp(
            theme: AppTheme.day(),
            home: const ReaderScreen(storyId: id),
          ),
        ),
      );
      await _settleArt(tester);
      await _pumpFor(tester, const Duration(seconds: 1));
    }

    Future<void> close(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 15));
    }

    testWidgets('help first: the story never moves on by itself', (
      tester,
    ) async {
      await open(tester, story(before: true));
      await _pumpFor(tester, const Duration(seconds: 15));
      expect(find.text('Yum'), findsNothing);
      expect(find.byType(HelpGlow), findsOneWidget);

      await tester.tapAt(_centre(mango));
      await tester.pump();
      // A celebration, the page's narration, then the next scene.
      expect(
        await _pumpUntil(tester, find.text('Yum'), const Duration(seconds: 12)),
        isTrue,
      );
      await close(tester);
    });

    testWidgets('help after: the narration plays, then the story waits', (
      tester,
    ) async {
      await open(tester, story(before: false));
      expect(find.byType(HelpGlow), findsNothing, reason: 'narrating first');
      await _pumpFor(tester, const Duration(seconds: 15));
      expect(find.byType(HelpGlow), findsOneWidget);
      expect(find.text('Yum'), findsNothing);

      await tester.tapAt(_centre(mango));
      expect(
        await _pumpUntil(tester, find.text('Yum'), const Duration(seconds: 6)),
        isTrue,
      );
      await close(tester);
    });

    testWidgets('a child who never manages it is not stuck', (tester) async {
      await open(tester, story(before: true));
      await _pumpFor(tester, const Duration(seconds: 40));
      expect(find.text('Yum'), findsNothing);
      expect(
        await _pumpUntil(tester, find.text('Yum'), const Duration(seconds: 20)),
        isTrue,
      );
      await close(tester);
    });
  });
}
