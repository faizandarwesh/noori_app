import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/app_lang.dart';

/// Reference to a picture, written in JSON as `character:rabbit`,
/// `puppet:ali` or `prop:mango`.
///
/// A puppet is a character built from separately moving parts (see
/// assets/content/puppets.json): it can strike poses, act, and change
/// expression. `character:` art is a single picture.
@immutable
class PictureRef {
  const PictureRef(this.kind, this.id);

  factory PictureRef.parse(String raw) {
    final i = raw.indexOf(':');
    if (i <= 0) throw FormatException('Picture must be kind:id, got "$raw"');
    final kind = raw.substring(0, i);
    if (kind != 'character' && kind != 'prop' && kind != 'puppet') {
      throw FormatException('Unknown picture kind "$kind"');
    }
    return PictureRef(kind, raw.substring(i + 1));
  }

  final String kind;
  final String id;

  /// Characters and puppets: someone with a name, who reacts when tapped.
  bool get isCharacter => kind != 'prop';
  bool get isPuppet => kind == 'puppet';

  /// Full art for scenes (whole body for characters; a puppet's body part).
  String get sceneAsset => switch (kind) {
    'character' => 'assets/illustrations/characters/$id.svg',
    'puppet' => 'assets/illustrations/puppets/$id/body.svg',
    _ => 'assets/illustrations/props/$id.svg',
  };

  /// Compact art for cards and quiz options (faces for characters). Puppets
  /// are drawn live by PictureView instead.
  String get cardAsset => switch (kind) {
    'character' => 'assets/illustrations/characters/${id}_face.svg',
    'puppet' => 'assets/illustrations/puppets/$id/body.svg',
    _ => 'assets/illustrations/props/$id.svg',
  };

  @override
  bool operator ==(Object other) =>
      other is PictureRef && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => '$kind:$id';
}

/// A looping bit of acting. Props use [idle], [happy], [surprised],
/// [twinkle] (pulses like a sparkle) and [float] (drifts up and down).
enum CastMood {
  idle,
  happy,
  sad,
  surprised,
  worried,
  sleepy,
  shy,
  twinkle,
  float,
}

/// How a cast member arrives: walks in from a side, drops in from the top,
/// or [grow]s up out of the ground.
enum CastEnter { none, left, right, top, grow }

/// A path a cast member keeps flying along, e.g. a bird circling a head.
/// [rx] and [ry] are fractions of the screen width and height.
@immutable
class CastOrbit {
  const CastOrbit({required this.rx, required this.ry, required this.period});

  factory CastOrbit.fromJson(Map<String, dynamic> j) => CastOrbit(
    rx: (j['rx'] as num).toDouble(),
    ry: (j['ry'] as num? ?? 0).toDouble(),
    period: Duration(milliseconds: (j['ms'] as num? ?? 3000).toInt()),
  );

  final double rx, ry;
  final Duration period;
}

/// Something placed in a page's scene. [x] and [y] are the art's
/// bottom-centre as fractions of the screen; [size] is its height as a
/// fraction of screen height.
///
/// Puppets also take a [pose] (how they stand), an [act] (what they keep
/// doing), a [face] (overriding the one their [mood] gives), where they
/// [look], and a prop to [hold].
@immutable
class CastMember {
  const CastMember({
    required this.art,
    required this.x,
    required this.y,
    required this.size,
    this.flip = false,
    this.mood = CastMood.idle,
    this.enter = CastEnter.none,
    this.pose,
    this.act,
    this.face,
    this.look,
    this.hold,
    this.holdSize = 0.2,
    this.holdTurn = 0,
    this.holdHand = 'R',
    this.turn = 0,
    this.delay = Duration.zero,
    this.until,
    this.orbit,
    this.helpStep = 0,
    this.helpHide,
  });

  factory CastMember.fromJson(Map<String, dynamic> j) => CastMember(
    art: PictureRef.parse(j['art'] as String),
    x: (j['x'] as num).toDouble(),
    y: (j['y'] as num).toDouble(),
    size: (j['size'] as num).toDouble(),
    flip: j['flip'] as bool? ?? false,
    mood: CastMood.values.byName(j['mood'] as String? ?? 'idle'),
    enter: CastEnter.values.byName(j['enter'] as String? ?? 'none'),
    pose: j['pose'] as String?,
    act: j['act'] as String?,
    face: j['face'] as String?,
    look: j['look'] as String?,
    hold: switch (j['hold']) {
      final String p => PictureRef.parse(p),
      _ => null,
    },
    holdSize: (j['holdSize'] as num? ?? 0.2).toDouble(),
    holdTurn: (j['holdTurn'] as num? ?? 0).toDouble(),
    holdHand: j['holdHand'] as String? ?? 'R',
    turn: (j['turn'] as num? ?? 0).toDouble(),
    delay: Duration(milliseconds: (j['delay'] as num? ?? 0).toInt()),
    until: switch (j['until']) {
      final num ms => Duration(milliseconds: ms.toInt()),
      _ => null,
    },
    orbit: switch (j['orbit']) {
      final Map<String, dynamic> o => CastOrbit.fromJson(o),
      _ => null,
    },
    helpStep: (j['helpStep'] as num? ?? 0).toInt(),
    helpHide: (j['helpHide'] as num?)?.toInt(),
  );

  final PictureRef art;
  final double x, y, size;
  final bool flip;
  final CastMood mood;
  final CastEnter enter;

  /// Puppets only: a pose name from puppets.json (`stand`, `wave`, …).
  final String? pose;

  /// Puppets only: a looping action (`walk`, `wave`, `clap`, `flap`, …).
  final String? act;

  /// Puppets only: an expression (`happy`, `laugh`, `full`, `ouch`, …).
  final String? face;

  /// Puppets only: where the eyes look (`up`, `down`, `left`, `right`).
  final String? look;

  /// Puppets only: a prop held in the hand named by [holdHand] (`R`/`L`),
  /// [holdSize] high (a fraction of the puppet's height), turned [holdTurn]
  /// degrees.
  final PictureRef? hold;
  final double holdSize, holdTurn;
  final String holdHand;

  /// Degrees the whole art is turned about its centre (180 = upside down).
  final double turn;

  /// Appears this long after the scene starts.
  final Duration delay;

  /// Fades away this long after the scene starts (for little time-lapses).
  final Duration? until;
  final CastOrbit? orbit;

  /// With a [HelpMoment] on the page: appears once the child has done
  /// this many steps of it (0 = there from the start).
  final int helpStep;

  /// With a [HelpMoment]: goes away once the child has done this many steps.
  final int? helpHide;

  /// Whether it shows after [progress] help steps.
  bool shownAt(int progress) =>
      progress >= helpStep && (helpHide == null || progress < helpHide!);
}

/// When one word is spoken in a page's narration, in milliseconds. Written
/// by tool/align_audio.dart, one entry per word of the page text, in order.
@immutable
class WordTiming {
  const WordTiming({required this.start, required this.end, this.word = ''});

  factory WordTiming.fromJson(Map<String, dynamic> j) => WordTiming(
    word: j['w'] as String? ?? '',
    start: (j['start'] as num).toInt(),
    end: (j['end'] as num).toInt(),
  );

  final String word;
  final int start, end;

  Duration get startTime => Duration(milliseconds: start);
  Duration get endTime => Duration(milliseconds: end);
}

sealed class StoryNode {
  const StoryNode(this.id);

  factory StoryNode.fromJson(Map<String, dynamic> j) =>
      switch (j['type'] as String? ?? 'page') {
        'page' => StoryPage.fromJson(j),
        'choice' => ChoiceNode.fromJson(j),
        final t => throw FormatException('Unknown node type "$t"'),
      };

  final String id;
}

class StoryPage extends StoryNode {
  const StoryPage({
    required String id,
    required this.next,
    required this.scene,
    required this.text,
    required this.cast,
    this.words = const {},
    this.help,
  }) : super(id);

  factory StoryPage.fromJson(Map<String, dynamic> j) {
    final words = j['words'] as Map<String, dynamic>? ?? const {};
    return StoryPage(
      id: j['id'] as String,
      next: j['next'] as String?,
      scene: j['scene'] as String,
      text: LocalizedText.fromJson(j['text'] as Map<String, dynamic>),
      cast: [
        for (final c in j['cast'] as List? ?? const [])
          CastMember.fromJson(c as Map<String, dynamic>),
      ],
      words: {
        for (final e in words.entries)
          AppLang.parse(e.key): [
            for (final w in e.value as List)
              WordTiming.fromJson(w as Map<String, dynamic>),
          ],
      },
      help: switch (j['help']) {
        final Map<String, dynamic> h => HelpMoment.fromJson(h),
        _ => null,
      },
    );
  }

  /// Id of the following node, or null at the end of the story.
  final String? next;
  final String scene;
  final LocalizedText text;
  final List<CastMember> cast;

  /// Karaoke timings for the page's narration in each language. Missing
  /// until the recording has been aligned; the reader then estimates.
  final Map<AppLang, List<WordTiming>> words;

  /// Something the child does to move the story on, or null.
  final HelpMoment? help;
}

class ChoiceOption {
  const ChoiceOption({
    required this.id,
    required this.label,
    required this.picture,
    required this.next,
  });

  factory ChoiceOption.fromJson(Map<String, dynamic> j) => ChoiceOption(
    id: j['id'] as String,
    label: LocalizedText.fromJson(j['label'] as Map<String, dynamic>),
    picture: PictureRef.parse(j['picture'] as String),
    next: j['next'] as String,
  );

  final String id;
  final LocalizedText label;
  final PictureRef picture;
  final String next;
}

/// The story's Choice Moment: two options, each leading to its own page.
class ChoiceNode extends StoryNode {
  const ChoiceNode({
    required String id,
    required this.prompt,
    required this.options,
  }) : super(id);

  factory ChoiceNode.fromJson(Map<String, dynamic> j) => ChoiceNode(
    id: j['id'] as String,
    prompt: LocalizedText.fromJson(j['prompt'] as Map<String, dynamic>),
    options: [
      for (final o in j['options'] as List)
        ChoiceOption.fromJson(o as Map<String, dynamic>),
    ],
  );

  final LocalizedText prompt;
  final List<ChoiceOption> options;
}

/// A word a child can tap: its headword in both languages plus other forms
/// that appear in the text (plurals, verb endings).
@immutable
class GlossaryEntry {
  const GlossaryEntry({
    required this.id,
    required this.word,
    required this.forms,
    this.picture,
  });

  factory GlossaryEntry.fromJson(Map<String, dynamic> j) {
    final forms = j['forms'] as Map<String, dynamic>? ?? const {};
    final word = LocalizedText.fromJson(j['word'] as Map<String, dynamic>);
    return GlossaryEntry(
      id: j['id'] as String,
      word: word,
      forms: {
        for (final lang in AppLang.values)
          lang: {
            normaliseWord(word.of(lang)),
            for (final f in forms[lang.name] as List? ?? const [])
              normaliseWord(f as String),
          },
      },
      picture: switch (j['picture']) {
        final String p => PictureRef.parse(p),
        _ => null,
      },
    );
  }

  final String id;
  final LocalizedText word;
  final Map<AppLang, Set<String>> forms;

  /// A picture of the word, if it can be drawn (used by the word game).
  final PictureRef? picture;

  bool matches(String word, AppLang lang) =>
      forms[lang]!.contains(normaliseWord(word));
}

/// Lower-cases and strips everything that isn't a letter or mark.
String normaliseWord(String s) =>
    s.toLowerCase().replaceAll(RegExp(r"[^\p{L}\p{M}]", unicode: true), '');

@immutable
class QuizOption {
  const QuizOption({required this.picture, required this.correct, this.label});

  factory QuizOption.fromJson(Map<String, dynamic> j) => QuizOption(
    picture: PictureRef.parse(j['picture'] as String),
    correct: j['correct'] as bool? ?? false,
    label: switch (j['label']) {
      final Map<String, dynamic> l => LocalizedText.fromJson(l),
      _ => null,
    },
  );

  final PictureRef picture;
  final bool correct;

  /// Words shown under the picture, for answers that are something said
  /// ("Bismillah"). The question's recording reads the options aloud.
  final LocalizedText? label;
}

/// How a written quiz question is played.
enum QuizKind {
  /// Tap the right picture.
  pick,

  /// Drag [QuizQuestion.item] onto the right picture.
  drag,
}

@immutable
class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    this.kind = QuizKind.pick,
    this.item,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
    kind: QuizKind.values.byName(j['type'] as String? ?? 'pick'),
    item: switch (j['item']) {
      final String p => PictureRef.parse(p),
      _ => null,
    },
    question: LocalizedText.fromJson(j['question'] as Map<String, dynamic>),
    options: [
      for (final o in j['options'] as List)
        QuizOption.fromJson(o as Map<String, dynamic>),
    ],
  );

  final QuizKind kind;

  /// For [QuizKind.drag]: the picture the child drags.
  final PictureRef? item;
  final LocalizedText question;
  final List<QuizOption> options;
}

/// A whole story, from assets/content/stories/{id}.json.
class Story {
  Story({
    required this.id,
    required this.start,
    required List<StoryNode> nodes,
    required this.glossary,
    required this.vocabulary,
    required this.quiz,
    this.characters = const {},
  }) : nodes = {for (final n in nodes) n.id: n};

  static const supportedSchema = 1;
  static String assetFor(String id) => 'assets/content/stories/$id.json';

  factory Story.fromJson(Map<String, dynamic> j) {
    final version = j['schemaVersion'] as int? ?? 1;
    if (version > supportedSchema) {
      throw FormatException('Story schema $version is newer than this app');
    }
    return Story(
      id: j['id'] as String,
      start: j['start'] as String,
      nodes: [
        for (final n in j['nodes'] as List)
          StoryNode.fromJson(n as Map<String, dynamic>),
      ],
      glossary: [
        for (final g in j['glossary'] as List? ?? const [])
          GlossaryEntry.fromJson(g as Map<String, dynamic>),
      ],
      vocabulary: [
        for (final v in j['vocabulary'] as List? ?? const []) v as String,
      ],
      quiz: [
        for (final q in j['quiz'] as List? ?? const [])
          QuizQuestion.fromJson(q as Map<String, dynamic>),
      ],
      characters: {
        for (final e
            in (j['characters'] as Map<String, dynamic>? ?? const {}).entries)
          e.key: LocalizedText.fromJson(e.value as Map<String, dynamic>),
      },
    );
  }

  final String id;
  final String start;
  final Map<String, StoryNode> nodes;
  final List<GlossaryEntry> glossary;

  /// Character art id → the character's name, e.g. `rabbit` → Bunty. When
  /// narration reaches a name, that character acts in the scene.
  final Map<String, LocalizedText> characters;

  StoryPage? get firstPage => switch (nodes[start]) {
    final StoryPage p => p,
    _ => null,
  };

  /// The cast member that [word] (a word of page text) brings to life: a
  /// character's name, or a prop's glossary word.
  bool cues(PictureRef art, String word, AppLang lang) {
    final w = normaliseWord(word);
    if (w.isEmpty) return false;
    if (art.isCharacter) {
      final name = characters[art.id];
      return name != null && w.startsWith(normaliseWord(name.of(lang)));
    }
    final entry = lookup(word, lang);
    return entry?.id == art.id || (lang == AppLang.en && w == art.id);
  }

  /// Glossary ids collected into the Word Jar when the story is finished.
  final List<String> vocabulary;
  final List<QuizQuestion> quiz;

  StoryNode node(String id) =>
      nodes[id] ?? (throw StateError('Story $this has no node "$id"'));

  GlossaryEntry? lookup(String word, AppLang lang) {
    for (final g in glossary) {
      if (g.matches(word, lang)) return g;
    }
    return null;
  }

  GlossaryEntry? entry(String id) {
    for (final g in glossary) {
      if (g.id == id) return g;
    }
    return null;
  }

  /// Pages along the default path (first option at each choice). Every path
  /// through a story should be this long, so it sizes the progress dots.
  int get pathLength => pathPages.length;

  /// The pages along the default path, in order.
  List<StoryPage> get pathPages {
    final pages = <StoryPage>[];
    String? id = start;
    final seen = <String>{};
    while (id != null && seen.add(id)) {
      final n = node(id);
      switch (n) {
        case StoryPage():
          pages.add(n);
          id = n.next;
        case ChoiceNode():
          id = n.options.first.next;
      }
    }
    return pages;
  }

  @override
  String toString() => id;
}

final storyProvider = FutureProvider.family<Story, String>((ref, id) async {
  final raw = await rootBundle.loadString(Story.assetFor(id));
  return Story.fromJson(jsonDecode(raw) as Map<String, dynamic>);
});

/// What the child does in a [HelpMoment].
enum HelpKind {
  /// Drag the cast member [HelpMoment.item] onto [HelpMoment.to].
  drag,

  /// Rub back and forth over [HelpMoment.item].
  rub,

  /// Tap [HelpMoment.item], once per step.
  tap,
}

/// A tap-to-help moment: the story waits while the child does the page's
/// key action themselves (pour the water, cut the mango). Cast members with
/// `helpStep` / `helpHide` appear and go as the child makes progress.
@immutable
class HelpMoment {
  const HelpMoment({
    required this.kind,
    required this.item,
    this.to,
    this.steps = 1,
    this.beforeNarration = true,
  });

  factory HelpMoment.fromJson(Map<String, dynamic> j) {
    final kind = HelpKind.values.byName(j['kind'] as String);
    return HelpMoment(
      kind: kind,
      item: (j['item'] as num).toInt(),
      to: (j['to'] as num?)?.toInt(),
      steps: (j['steps'] as num? ?? (kind == HelpKind.drag ? 1 : 3)).toInt(),
      beforeNarration: switch (j['when'] as String? ?? 'before') {
        'before' => true,
        'after' => false,
        final w => throw FormatException(
          'help "when" must be before or after, got "$w"',
        ),
      },
    );
  }

  final HelpKind kind;

  /// Cast index of what the child drags, rubs or taps.
  final int item;

  /// Drag only: cast index of where it goes.
  final int? to;

  /// How many steps until it's done (always 1 for a drag).
  final int steps;

  /// True: the child helps first and the narration follows. False: the
  /// narration plays first and the story waits for the child after it.
  final bool beforeNarration;
}
