// Validates every story file against the schema rules, so new stories can
// be added with confidence. See docs/story_schema.md.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noori/core/content/catalog.dart';
import 'package:noori/core/content/puppets.dart';
import 'package:noori/core/content/scenes.dart';
import 'package:noori/core/content/story.dart';
import 'package:noori/core/i18n/app_lang.dart';
import 'package:noori/features/quiz/quiz_plan.dart';
import 'package:noori/core/widgets/puppet_acts.dart';
import 'package:noori/features/reader/karaoke/read_chunks.dart';
import 'package:noori/features/reader/widgets/scene_secret.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

final _pubspec = File('pubspec.yaml').readAsStringSync();

void _expectAsset(String path) {
  expect(File(path).existsSync(), isTrue, reason: 'missing asset $path');
  final dir = path.substring(0, path.lastIndexOf('/') + 1);
  expect(
    _pubspec.contains('- $dir'),
    isTrue,
    reason: '$dir is not listed in pubspec.yaml',
  );
}

void main() {
  final catalog = Catalog.fromJson(_json(Catalog.asset));
  final puppets = Puppets.fromJson(_json(Puppets.asset));
  final scenes = Scenes.fromJson(_json(Scenes.asset), puppets: puppets);
  final written = [
    for (final z in catalog.zones)
      for (final s in z.stories)
        if (File(Story.assetFor(s.id)).existsSync()) s,
  ];

  test('at least one story is written', () => expect(written, isNotEmpty));

  test('every scene hides a surprise, placed on screen', () {
    for (final id in scenes.ids) {
      final spec = scenes[id]!;
      expect(spec.secrets, isNotEmpty, reason: '$id has nothing to find');
      for (final s in spec.secrets) {
        expect(s.x, inInclusiveRange(0, 1), reason: '$id ${s.kind}');
        // Above the subtitle strip, so a finger can reach it.
        expect(s.y, inInclusiveRange(0.1, 0.8), reason: '$id ${s.kind}');
        SceneSecretView.assetsFor(s.kind).forEach(_expectAsset);
      }
    }
  });

  test('scene layers exist', () {
    for (final id in scenes.ids) {
      final spec = scenes[id]!;
      expect(
        spec.layers.where((l) => l.isCast),
        hasLength(1),
        reason: '$id needs one cast layer',
      );
      for (final l in spec.layers.where((l) => !l.isCast)) {
        _expectAsset(l.asset);
      }
    }
  });

  test('every puppet part is drawn', () {
    expect(puppets.ids, isNotEmpty);
    for (final id in puppets.ids) {
      final p = puppets[id]!;
      expect(p.part('body'), isNotNull, reason: '$id needs a body part');
      expect(p.part(p.face.part), isNotNull, reason: '$id face part');
      for (final part in p.parts) {
        _expectAsset(p.asset(part.id));
        if (part.parent case final parent?) {
          expect(p.part(parent), isNotNull, reason: '$id.${part.id} parent');
        }
      }
      for (final hand in p.hands.values) {
        expect(p.part(hand.part), isNotNull, reason: '$id hand');
      }
    }
  });

  for (final entry in written) {
    group(entry.id, () {
      late Story story;
      setUpAll(() => story = Story.fromJson(_json(Story.assetFor(entry.id))));

      test('id matches catalog and character art exists', () {
        expect(story.id, entry.id);
        if (puppets[entry.character] == null) {
          _expectAsset(
            'assets/illustrations/characters/${entry.character}_face.svg',
          );
        }
      });

      test('every link resolves and every node is reachable', () {
        final reached = <String>{};
        void walk(String id) {
          if (!reached.add(id)) return;
          final n = story.node(id);
          switch (n) {
            case StoryPage(:final next):
              if (next != null) walk(next);
            case ChoiceNode(:final options):
              for (final o in options) {
                walk(o.next);
              }
          }
        }

        walk(story.start);
        expect(reached, story.nodes.keys.toSet(), reason: 'unreachable nodes');
      });

      test('pages have text, a known scene and existing art', () {
        for (final p in story.nodes.values.whereType<StoryPage>()) {
          for (final lang in AppLang.values) {
            expect(
              p.text.of(lang).trim(),
              isNotEmpty,
              reason: '${p.id} ${lang.name} text',
            );
            final words = splitChunks(p.text.of(lang))
                .where((c) => c.hasWord)
                .length;
            expect(
              words,
              inInclusiveRange(3, 45),
              reason: '${p.id}: keep pages short',
            );
          }
          expect(
            scenes[p.scene],
            isNotNull,
            reason: '${p.id} scene ${p.scene}',
          );
          for (final c in p.cast) {
            _expectAsset(c.art.sceneAsset);
            expect(c.x, inInclusiveRange(0, 1));
            expect(c.y, inInclusiveRange(0, 1));
          }
          for (final MapEntry(key: lang, value: timings) in p.words.entries) {
            final words = splitChunks(p.text.of(lang))
                .where((c) => c.hasWord)
                .length;
            expect(
              timings,
              hasLength(words),
              reason: '${p.id} ${lang.name}: one timing per word',
            );
            for (var i = 1; i < timings.length; i++) {
              expect(
                timings[i].start,
                greaterThanOrEqualTo(timings[i - 1].start),
                reason: '${p.id} ${lang.name}: timings in order',
              );
            }
          }
        }
      });

      test('every character in the cast has a name', () {
        for (final p in story.nodes.values.whereType<StoryPage>()) {
          for (final c in p.cast.where((c) => c.art.isCharacter)) {
            expect(
              story.characters[c.art.id],
              isNotNull,
              reason: '${p.id}: name ${c.art.id} under "characters"',
            );
          }
        }
      });

      test('puppets, poses, actions and held props exist', () {
        for (final p in story.nodes.values.whereType<StoryPage>()) {
          for (final c in p.cast) {
            if (c.hold case final held?) _expectAsset(held.sceneAsset);
            if (!c.art.isPuppet) continue;
            final spec = puppets[c.art.id];
            expect(spec, isNotNull, reason: '${p.id}: puppet ${c.art.id}');
            if (c.pose case final pose?) {
              expect(
                spec!.poses.containsKey(pose),
                isTrue,
                reason: '${p.id}: ${c.art.id} has no pose "$pose"',
              );
            }
            for (final act in c.act?.split('+') ?? const <String>[]) {
              expect(
                PuppetActs.names,
                contains(act.trim()),
                reason: '${p.id}: unknown act "$act"',
              );
            }
          }
        }
      });

      test('help moments point at real cast and can be finished', () {
        for (final p in story.nodes.values.whereType<StoryPage>()) {
          final help = p.help;
          if (help == null) {
            expect(
              p.cast.where((c) => c.helpStep > 0 || c.helpHide != null),
              isEmpty,
              reason: '${p.id}: helpStep/helpHide need a "help" moment',
            );
            continue;
          }
          expect(help.item, inInclusiveRange(0, p.cast.length - 1));
          expect(
            p.cast[help.item].helpStep,
            0,
            reason: '${p.id}: the help item must be there from the start',
          );
          expect(help.steps, greaterThanOrEqualTo(1));
          if (help.kind == HelpKind.drag) {
            expect(help.to, isNotNull, reason: '${p.id}: a drag needs "to"');
            expect(help.to, inInclusiveRange(0, p.cast.length - 1));
            expect(help.steps, 1, reason: '${p.id}: a drag is one step');
          }
          for (final c in p.cast) {
            expect(c.helpStep, lessThanOrEqualTo(help.steps));
            if (c.helpHide case final hide?) {
              expect(hide, inInclusiveRange(1, help.steps));
              expect(hide, greaterThan(c.helpStep));
            }
          }
          // Something visibly changes when the child is done.
          expect(
            p.cast.where((c) => c.helpStep > 0),
            isNotEmpty,
            reason: '${p.id}: nothing appears when the child helps',
          );
        }
      });

      test('narration folders are bundled', () {
        for (final lang in AppLang.values) {
          expect(
            _pubspec.contains(
              '- assets/audio/stories/${story.id}/${lang.name}/',
            ),
            isTrue,
            reason:
                'add assets/audio/stories/${story.id}/${lang.name}/ '
                'to pubspec.yaml',
          );
        }
      });

      test('exactly one choice moment with two options', () {
        final choices = story.nodes.values.whereType<ChoiceNode>().toList();
        expect(choices, hasLength(1));
        expect(choices.single.options, hasLength(2));
        for (final o in choices.single.options) {
          _expectAsset(o.picture.cardAsset);
        }
      });

      test('both branches are the same length (6–9 pages)', () {
        int lengthVia(int option) {
          var count = 0;
          String? id = story.start;
          while (id != null) {
            final n = story.node(id);
            switch (n) {
              case StoryPage():
                count++;
                id = n.next;
              case ChoiceNode():
                id = n.options[option].next;
            }
          }
          return count;
        }

        expect(lengthVia(0), lengthVia(1));
        // Up to 8 scenes plus the page showing the choice's outcome.
        expect(lengthVia(0), inInclusiveRange(6, 9));
      });

      test('quiz: 3 picture questions, 3 pictures each, one correct', () {
        expect(story.quiz.where((q) => q.kind == QuizKind.pick), hasLength(3));
        for (final q in story.quiz) {
          expect(q.options, hasLength(3));
          expect(q.options.where((o) => o.correct), hasLength(1));
          for (final o in q.options) {
            _expectAsset(o.picture.cardAsset);
          }
          if (q.kind == QuizKind.drag) {
            expect(q.item, isNotNull, reason: 'a drag question needs an item');
            _expectAsset(q.item!.cardAsset);
          }
        }
      });

      test('every quiz round has three questions, rotating each replay', () {
        final rounds = [
          for (var play = 0; play < 6; play++) planQuiz(story, play),
        ];
        for (final r in rounds) {
          expect(r, hasLength(3));
        }
        // The special question changes kind across replays.
        final kinds = {for (final r in rounds) r[1].runtimeType};
        expect(kinds.length, greaterThanOrEqualTo(2));
      });

      test('glossary pictures exist', () {
        for (final g in story.glossary) {
          if (g.picture case final p?) _expectAsset(p.cardAsset);
        }
      });

      test('3 vocabulary words, all in the glossary', () {
        expect(story.vocabulary, hasLength(3));
        for (final v in story.vocabulary) {
          expect(story.entry(v), isNotNull, reason: 'vocabulary "$v"');
        }
        final ids = story.glossary.map((g) => g.id).toList();
        expect(
          ids.toSet(),
          hasLength(ids.length),
          reason: 'duplicate glossary ids',
        );
      });
    });
  }
}
