// Renders screens to PNGs for visual review. Skipped by default; run with:
//   flutter test test/screenshot_test.dart --dart-define=SCREENSHOTS=true
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:noori/app/noori_app.dart';
import 'package:noori/app/router.dart';
import 'package:noori/core/audio/audio_service.dart';
import 'package:noori/core/mascot/noori_mascot.dart';
import 'package:noori/core/storage/local_store.dart';
import 'package:noori/core/theme/app_theme.dart';
import 'package:noori/features/reader/reader_screen.dart';
import 'package:noori/features/reward/reward_result.dart';
import 'package:noori/core/settings/app_settings.dart';

const _enabled = bool.fromEnvironment('SCREENSHOTS');
const _out = 'build/screenshots';
const _phone = Size(412, 892);

Future<void> _loadFonts() async {
  for (final (family, file) in const [
    ('Fredoka', 'assets/fonts/Fredoka.ttf'),
    ('NotoNastaliqUrdu', 'assets/fonts/NotoNastaliqUrdu.ttf'),
    ('MaterialIcons', null),
  ]) {
    final loader = FontLoader(family);
    if (file != null) {
      loader.addFont(rootBundle.load(file));
    } else {
      final sdk = File(Platform.resolvedExecutable)
          .parent
          .parent
          .parent
          .parent
          .parent
          .parent;
      final icons = File(
        '${sdk.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      );
      if (!icons.existsSync()) continue;
      loader.addFont(
        Future.value(ByteData.sublistView(icons.readAsBytesSync())),
      );
    }
    await loader.load();
  }
}

Future<void> _capture(WidgetTester tester, Finder f, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(f);
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(_out).createSync(recursive: true);
    File('$_out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

/// Pumps frames, letting real async work (SVG parsing, image readback) run.
Future<void> _settle(WidgetTester tester, {int frames = 60}) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Boots the app with [store] contents and runs [drive] before capturing.
void _scenario(
  String name,
  Map<String, Object?> store,
  Future<void> Function(WidgetTester tester) drive,
) {
  testWidgets(name, skip: !_enabled, (tester) async {
    final key = GlobalKey();
    await tester.binding.setSurfaceSize(_phone);
    // MediaQuery follows the view, not the surface: match them.
    tester.view
      ..physicalSize = _phone
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(AudioService(enabled: false)),
          localStoreProvider.overrideWithValue(MemoryStore(store)),
        ],
        child: RepaintBoundary(key: key, child: const NooriApp()),
      ),
    );
    await drive(tester);
    await _capture(tester, find.byKey(key), name);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 15));
  });
}

Future<void> _skipSplash(WidgetTester tester) async {
  await tester.tap(find.byType(Scaffold).first);
  await _settle(tester, frames: 90);
}

const _someProgress = {
  'settings.languageChosen': true,
  'progress.fireflies': 7,
  'progress.stars': {'bunty_big_mango': 3, 'gulu_gentle_trunk': 2},
};

void main() {
  readerScreenshots();
  step4Screenshots();
  // rootBundle caches asset futures; one created in a previous test's fake
  // zone never completes in the next, so start each test with a clean cache.
  setUp(rootBundle.clear);

  setUpAll(_loadFonts);

  testWidgets('noori states', skip: !_enabled, (tester) async {
    final key = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(1000, 360));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.day(),
          home: RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: AppPalette.mint,
              child: Wrap(
                children: [
                  for (final s in NooriState.values)
                    NooriMascot(state: s, size: 160),
                  const NooriMascot(
                    state: NooriState.pointing,
                    pointLeft: true,
                    size: 160,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await _capture(tester, find.byKey(key), 'noori_states');
  });

  _scenario('splash_english', {}, (t) => _settle(t, frames: 68));
  _scenario('splash_urdu', {}, (t) => _settle(t, frames: 105));
  _scenario('language_lanterns', {}, (t) async {
    await _skipSplash(t);
    await _settle(t, frames: 90);
  });
  _scenario('language_burst', {}, (t) async {
    await _skipSplash(t);
    await t.tap(find.bySemanticsLabel('اردو'));
    await _settle(t, frames: 40);
  });
  _scenario('home_first_visit', {'settings.languageChosen': true}, (t) async {
    await _skipSplash(t);
    await _settle(t, frames: 60);
  });
  _scenario('home_day_en', {..._someProgress, 'settings.homeGreeted': true}, (
    t,
  ) async {
    await _skipSplash(t);
    await _settle(t, frames: 60);
  });
  _scenario(
    'home_night_ur',
    {
      ..._someProgress,
      'settings.homeGreeted': true,
      'settings.lang': 'ur',
      'settings.bedtime': true,
    },
    (t) async {
      await _skipSplash(t);
      await _settle(t, frames: 60);
    },
  );
  _scenario(
    'home_mid_swipe',
    {..._someProgress, 'settings.homeGreeted': true},
    (t) async {
      await _skipSplash(t);
      final gesture = await t.startGesture(const Offset(300, 450));
      await gesture.moveBy(const Offset(-120, 0));
      await _settle(t, frames: 10);
    },
  );
  _scenario('settings_gate', _someProgress, (t) async {
    await _skipSplash(t);
    await t.tap(find.bySemanticsLabel('Settings'));
    await _settle(t, frames: 40);
  });
  _scenario('settings_ur', {..._someProgress, 'settings.lang': 'ur'}, (
    t,
  ) async {
    await _skipSplash(t);
    final router = GoRouter.of(t.element(find.byType(Scaffold).first));
    router.push(Routes.settings);
    await _settle(t, frames: 60);
  });
}

/// Swipes the story player on to its next scene.
Future<void> _next(WidgetTester t) =>
    t.fling(find.byType(ReaderScreen), const Offset(-300, 0), 1200);

/// Reader scenarios, rendered straight into the reader screen.
void _readerScenario(
  String name,
  Map<String, Object?> store,
  Future<void> Function(WidgetTester tester) drive,
) {
  testWidgets(name, skip: !_enabled, (tester) async {
    final key = GlobalKey();
    await tester.binding.setSurfaceSize(_phone);
    // MediaQuery follows the view, not the surface: match them.
    tester.view
      ..physicalSize = _phone
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(AudioService(enabled: false)),
          localStoreProvider.overrideWithValue(MemoryStore(store)),
        ],
        child: RepaintBoundary(
          key: key,
          child: Consumer(
            builder: (context, ref, _) {
              final s = ref.watch(appSettingsProvider);
              return MaterialApp(
                theme: s.bedtime ? AppTheme.bedtime() : AppTheme.day(),
                home: const ReaderScreen(storyId: 'bunty_big_mango'),
              );
            },
          ),
        ),
      ),
    );
    await _settle(tester, frames: 80);
    await drive(tester);
    await _capture(tester, find.byKey(key), name);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 15));
  });
}

void readerScreenshots() {
  _readerScenario('reader_p1_karaoke', {}, (t) => _settle(t, frames: 90));
  _readerScenario('reader_word_popup', {}, (t) async {
    await t.tap(find.text('mango'));
    await _settle(t, frames: 30);
  });
  _readerScenario('reader_scene_cut', {}, (t) async {
    await _next(t);
    await _settle(t, frames: 30);
  });
  _readerScenario('reader_paused', {}, (t) async {
    await t.tapAt(const Offset(206, 300));
    await _settle(t, frames: 30);
  });
  _readerScenario('reader_flip_mid', {}, (t) async {
    await t.tap(find.bySemanticsLabel('Switch language'));
    await _settle(t, frames: 12);
  });
  _readerScenario(
    'reader_p4_ur_night',
    {'settings.lang': 'ur', 'settings.bedtime': true},
    (t) async {
      for (var i = 0; i < 3; i++) {
        await _next(t);
        await _settle(t, frames: 60);
      }
      await _settle(t, frames: 60);
    },
  );
  _readerScenario('reader_p5_share', {}, (t) async {
    for (var i = 0; i < 4; i++) {
      await _next(t);
      await _settle(t, frames: 60);
    }
  });
}

/// Step 4 screens, via the real app router at [location].
void _routeScenario(
  String name,
  String location,
  Map<String, Object?> store,
  Future<void> Function(WidgetTester tester) drive, {
  Object? extra,
}) {
  testWidgets(name, skip: !_enabled, (tester) async {
    final key = GlobalKey();
    await tester.binding.setSurfaceSize(_phone);
    // MediaQuery follows the view, not the surface: match them.
    tester.view
      ..physicalSize = _phone
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = buildRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(AudioService(enabled: false)),
          localStoreProvider.overrideWithValue(MemoryStore(store)),
        ],
        child: RepaintBoundary(
          key: key,
          child: Consumer(
            builder: (context, ref, _) {
              final s = ref.watch(appSettingsProvider);
              return MaterialApp.router(
                theme: s.bedtime ? AppTheme.bedtime() : AppTheme.day(),
                routerConfig: router,
              );
            },
          ),
        ),
      ),
    );
    router.go(location, extra: extra);
    await _settle(tester, frames: 80);
    await drive(tester);
    await _capture(tester, find.byKey(key), name);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 20));
  });
}

void step4Screenshots() {
  const rich = {
    'progress.fireflies': 24,
    'progress.stars': {'bunty_big_mango': 3, 'gulu_gentle_trunk': 2},
    'wardrobe.owned': ['scarf.rainbow', 'hat.crown', 'hat.party'],
    'wardrobe.hat': 'crown',
    'wardrobe.scarf': 'rainbow',
  };
  _routeScenario(
    'lantern_hub',
    Routes.lantern,
    rich,
    (t) => _settle(t, frames: 40),
  );
  _routeScenario(
    'wardrobe',
    Routes.wardrobe,
    rich,
    (t) => _settle(t, frames: 40),
  );
  _routeScenario(
    'word_game',
    Routes.wordGame,
    rich,
    (t) => _settle(t, frames: 40),
  );
  _routeScenario('quiz_drag', Routes.quiz('bunty_big_mango'), {}, (t) async {
    await t.tap(find.bySemanticsLabel('rabbit'));
    await _settle(t, frames: 200);
  });
  _routeScenario(
    'quiz_order',
    Routes.quiz('bunty_big_mango'),
    {
      'progress.plays': {'bunty_big_mango': 1},
    },
    (t) async {
      await t.tap(find.bySemanticsLabel('mango'));
      await _settle(t, frames: 200);
    },
  );
  _routeScenario(
    'quiz_find',
    Routes.quiz('bunty_big_mango'),
    {
      'progress.plays': {'bunty_big_mango': 2},
    },
    (t) async {
      await t.tap(find.bySemanticsLabel('turtle'));
      await _settle(t, frames: 200);
    },
  );
  _routeScenario('choice', Routes.story('bunty_big_mango'), {}, (t) async {
    for (var i = 0; i < 4; i++) {
      await _next(t);
      await _settle(t, frames: 70);
    }
  });
  _routeScenario('choice_picked', Routes.story('bunty_big_mango'), {}, (
    t,
  ) async {
    for (var i = 0; i < 4; i++) {
      await _next(t);
      await _settle(t, frames: 70);
    }
    await t.tap(find.bySemanticsLabel('Share it'));
    await _settle(t, frames: 30);
  });
  _routeScenario(
    'quiz_try_again',
    Routes.quiz('bunty_big_mango'),
    {'progress.fireflies': 4},
    (t) async {
      await t.tap(find.bySemanticsLabel('turtle'));
      await _settle(t, frames: 30);
    },
  );
  _routeScenario(
    'quiz_correct_flight',
    Routes.quiz('bunty_big_mango'),
    {'progress.fireflies': 4},
    (t) async {
      await t.tap(find.bySemanticsLabel('rabbit'));
      await _settle(t, frames: 28);
    },
  );
  _routeScenario(
    'reward_swirl',
    Routes.reward('bunty_big_mango'),
    {'progress.fireflies': 7},
    (t) => _settle(t, frames: 60),
    extra: const RewardResult(stars: 2, fireflies: 3, newWords: []),
  );
  _routeScenario(
    'reward_words',
    Routes.reward('bunty_big_mango'),
    {
      'progress.fireflies': 7,
      'progress.stars': {'bunty_big_mango': 2},
    },
    (t) => _settle(t, frames: 330),
    extra: const RewardResult(stars: 2, fireflies: 3, newWords: []),
  );
  _routeScenario(
    'reward_done_night',
    Routes.reward('bunty_big_mango'),
    {'progress.fireflies': 7, 'settings.bedtime': true},
    (t) => _settle(t, frames: 560),
    extra: const RewardResult(stars: 3, fireflies: 3, newWords: []),
  );
  _routeScenario(
    'word_jar',
    Routes.jar,
    {
      'progress.words': [
        for (final w in ['mango', 'share', 'friend', 'tree', 'sweet', 'rabbit'])
          'bunty_big_mango/$w',
      ],
    },
    (t) async {
      await t.tap(find.text('share'));
      await _settle(t, frames: 20);
    },
  );
}
