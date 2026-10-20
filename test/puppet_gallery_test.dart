// Renders every puppet in its poses and expressions to PNGs, for checking
// the art. Skipped by default; run with:
//   flutter test test/puppet_gallery_test.dart --dart-define=SCREENSHOTS=true
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
import 'package:noori/core/theme/app_theme.dart';
import 'package:noori/core/widgets/puppet_view.dart';

const _enabled = bool.fromEnvironment('SCREENSHOTS');
const _out = 'build/screenshots/puppets';

Future<void> _shoot(
  WidgetTester tester,
  String name,
  Size size,
  Widget Function(Puppets puppets) build,
) async {
  final key = GlobalKey();
  await tester.binding.setSurfaceSize(size);
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final raw = await tester.runAsync(() => File(Puppets.asset).readAsString());
  final puppets = Puppets.fromJson(jsonDecode(raw!) as Map<String, dynamic>);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        scenesProvider.overrideWith(
          (ref) => Scenes(const {}, puppets: puppets),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.day(),
        home: RepaintBoundary(
          key: key,
          child: ColoredBox(color: AppPalette.mint, child: build(puppets)),
        ),
      ),
    ),
  );
  for (var i = 0; i < 40; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 4)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(_out).createSync(recursive: true);
    File('$_out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 6));
}

Widget _cell(String id, {String? pose, String? face, String? label}) =>
    SizedBox(
      width: 120,
      height: 170,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: PuppetView(id: id, height: 140, pose: pose, face: face),
            ),
          ),
          Text(
            label ?? pose ?? face ?? id,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );

const _bipedPoses = [
  'stand', 'wave', 'cheer', 'hold_hand', 'hold', 'drink', 'think', 'clap', //
  'dua', 'hug', 'give', 'shocked', 'tummy', 'shy', 'cover_eyes', 'dig',
  'pour', 'thumbs_up', 'tuck', 'sit', 'kneel', 'hand_on_shoulder',
];

const _faces = [
  'idle', 'happy', 'laugh', 'sad', 'surprised', 'worried', 'sleep', 'full', //
  'ouch', 'shy', 'think', 'open', 'tired',
];

void main() {
  setUp(rootBundle.clear);

  testWidgets('puppets standing', skip: !_enabled, (tester) async {
    await _shoot(tester, 'all', const Size(1000, 720), (p) {
      return Wrap(children: [for (final id in p.ids) _cell(id, label: id)]);
    });
  });

  for (final id in [
    'ali',
    'baba',
    'ayesha',
    'nani',
    'bunty',
    'bhalu',
    'tippu',
    'kaku',
    'dada',
  ]) {
    testWidgets('poses $id', skip: !_enabled, (tester) async {
      await _shoot(tester, 'poses_$id', const Size(1000, 540), (p) {
        return Wrap(
          children: [for (final pose in _bipedPoses) _cell(id, pose: pose)],
        );
      });
    });
  }

  testWidgets('animals', skip: !_enabled, (tester) async {
    await _shoot(tester, 'animals', const Size(1000, 540), (p) {
      return Wrap(
        children: [
          for (final pose in [
            'stand',
            'kick',
            'spray',
            'trunk_up',
            'worried',
            'hide',
          ])
            _cell('dodo', pose: pose),
          for (final id in ['sparrow', 'mithu'])
            for (final pose in [
              'stand',
              'spread',
              'fly',
              'tired',
              'drink',
              'sleep',
            ])
              _cell(id, pose: pose, label: '$id $pose'),
        ],
      );
    });
  });

  testWidgets('faces', skip: !_enabled, (tester) async {
    await _shoot(tester, 'faces', const Size(1600, 540), (p) {
      return Wrap(
        children: [
          for (final id in ['hamza', 'bhalu', 'sparrow'])
            for (final f in _faces) _cell(id, face: f, label: '$id $f'),
        ],
      );
    });
  });
}
