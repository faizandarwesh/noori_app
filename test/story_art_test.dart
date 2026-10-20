// Renders every page of the batch 1-3 stories to PNGs, for checking how each
// scene is staged. Skipped by default; run with:
//   flutter test test/story_art_test.dart --dart-define=SCREENSHOTS=true
// Optionally limit to one story: --dart-define=STORY=ali_thirsty_sparrow
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noori/core/content/puppets.dart';
import 'package:noori/core/content/scenes.dart';
import 'package:noori/core/content/story.dart';
import 'package:noori/core/theme/app_theme.dart';
import 'package:noori/features/reader/widgets/help_moment.dart';
import 'package:noori/features/reader/widgets/story_scene.dart';

const _enabled = bool.fromEnvironment('SCREENSHOTS');
const _only = String.fromEnvironment('STORY');
const _out = 'build/screenshots/stories';
const _phone = Size(412, 892);

const _stories = [
  'ali_thirsty_sparrow',
  'bunty_bismillah',
  'dodo_tells_truth',
  'tippu_seed',
  'hamza_salam',
  'zoya_messy_room',
  'ahmed_dada_glasses',
  'sara_iftar_helper',
  'usman_asks_first',
  'fatima_not_afraid',
  'hassan_moti_fish',
  'kaku_crab_walk',
  'zain_nana_boat',
  'maryam_seashell',
  'hamid_holds_hand',
];

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  setUp(rootBundle.clear);

  for (final id in _stories) {
    if (_only.isNotEmpty && _only != id) continue;
    if (!File(Story.assetFor(id)).existsSync()) continue;
    final story = Story.fromJson(_json(Story.assetFor(id)));
    final scenes = Scenes.fromJson(
      _json(Scenes.asset),
      puppets: Puppets.fromJson(_json(Puppets.asset)),
    );
    for (final page in story.nodes.values.whereType<StoryPage>()) {
      // A help page is shown waiting for the child, then once helped.
      for (final state in page.help == null ? [''] : ['_waiting', '_helped']) {
        testWidgets('$id ${page.id}$state', skip: !_enabled, (tester) async {
          final help = HelpController()..load(page.help);
          addTearDown(help.dispose);
          if (state == '_waiting') help.begin();
          if (state == '_helped') help.complete();
          final key = GlobalKey();
          await tester.binding.setSurfaceSize(_phone);
          tester.view
            ..physicalSize = _phone
            ..devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [scenesProvider.overrideWith((ref) => scenes)],
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.day(),
                home: RepaintBoundary(
                  key: key,
                  child: StoryScene(
                    spec: scenes[page.scene]!,
                    cast: page.cast,
                    help: page.help == null ? null : help,
                    secrets: true,
                  ),
                ),
              ),
            ),
          );
          // Let SVGs load, then run the scene past its time-lapses.
          for (var i = 0; i < 30; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 4)),
            );
            await tester.pump(const Duration(milliseconds: 16));
          }
          for (var i = 0; i < 80; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          for (var i = 0; i < 10; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 4)),
            );
            await tester.pump(const Duration(milliseconds: 16));
          }
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(key),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 0.6);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            Directory(_out).createSync(recursive: true);
            File('$_out/${id}_${page.id}$state.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
          });
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 10));
        });
      }
    }
  }
}
