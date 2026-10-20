# Noori story format

Stories and zones are plain JSON. Adding a story or a zone needs no code
changes; `flutter test test/content_test.dart` checks your files.

## 1. List the story: `assets/content/zones.json`

```json
{
  "id": "bunty_big_mango",
  "title": { "en": "Bunty and the Big Mango", "ur": "بنٹی اور بڑا آم" },
  "value": "sharing",
  "character": "rabbit"
}
```

- Home shows every story of every open zone as a card in the carousel, in
  this order. The card is the story's first scene, alive and in miniature.
- `character`: the story's lead (`characters/<character>_face.svg`).
- A zone opens when the zone named in its `unlockAfter` is fully complete
  and it has at least one story. Locked or empty zones never appear in the
  child's screens.

## 2. Write the story: `assets/content/stories/<id>.json`

```json
{
  "schemaVersion": 1,
  "id": "bunty_big_mango",
  "start": "p1",
  "characters": { "rabbit": { "en": "Bunty", "ur": "بنٹی" } },
  "nodes": [ ... ],
  "glossary": [ ... ],
  "vocabulary": ["mango", "share", "friend"],
  "quiz": [ ... ]
}
```

`characters` names each character in the story's cast. When the narration
reaches a name, that character hops in the scene; when it reaches a prop's
glossary word, the prop wiggles.

### Nodes

The story is a small graph. Each node has an `id`, and pages point to the
next node with `next` (`null` ends the story).

**Page**

```json
{
  "id": "p2",
  "type": "page",
  "next": "p3",
  "scene": "mango_grove",
  "text": { "en": "Plop! A big yellow mango fell down.", "ur": "دھپ! ایک بڑا سا پیلا آم نیچے گرا۔" },
  "cast": [
    { "art": "character:rabbit", "x": 0.62, "y": 0.6, "size": 0.17, "mood": "surprised" },
    { "art": "prop:mango", "x": 0.44, "y": 0.6, "size": 0.06, "enter": "top" }
  ],
  "words": {
    "en": [{ "w": "Plop!", "start": 140, "end": 520 }, { "w": "A", "start": 610, "end": 680 }, "…"],
    "ur": ["…"]
  }
}
```

- 1–3 short sentences per page, 6–9 pages on every path.
- Write the Urdu as natural spoken Urdu for children, not a word-for-word
  translation.
- `cast`: `art` is `character:<id>` (`characters/<id>.svg`) or `prop:<id>`
  (`props/<id>.svg`). `x`, `y` place the art's bottom-centre as fractions of
  the screen. Keep feet around `y: 0.6`, above the subtitles. `size` is the
  height as a fraction of the screen.
  - `mood`: `idle`, `happy`, `sad`, `surprised`.
  - `enter`: `none`, `left`, `right`, `top` (drops or flies in), `grow` (rises out of the ground).
  - `flip`: `true` to face the other way.
  - `mood` also takes `worried`, `sleepy`, `shy`, and for props `twinkle` (pulses like a sparkle) and `float` (drifts up and down).
  - `turn`: degrees the art is turned about its centre (`180` hangs upside down, `-90` lies down).
  - `delay` / `until`: milliseconds after the scene starts when the art appears / fades away. Use them for little time-lapses (seed → plant → tree) or for "first this, then that" on one page.
  - `orbit`: `{ "rx": 0.2, "ry": 0.04, "ms": 3200 }` keeps the art flying round an ellipse (fractions of the screen), turning to face the way it goes.
- `words` is written by `tool/align_audio.dart`; don't edit it by hand. It
  holds one entry per word of the page text (punctuation-only chunks don't
  count) with its start and end in milliseconds. See "Narration" below.

**Puppets** (`"art": "puppet:<id>"`) are characters built from separately moving parts, listed in `assets/content/puppets.json` and drawn by `dart run tool/gen_puppets.dart`. Besides the fields above they take:

- `pose`: how they stand, e.g. `stand`, `walk`, `wave`, `cheer`, `hold`, `hold_both`, `carry`, `drink`, `eat`, `think`, `clap`, `dua`, `hug`, `give`, `point`, `shocked`, `tummy`, `rub`, `shy`, `cover_eyes`, `dig`, `pour`, `thumbs_up`, `tuck`, `sit`, `kneel`, `kneel_pat`, `hand_on_shoulder`, `hold_hand` / `hold_hand_l`, `lie`. Birds: `spread`, `fly`, `tired`, `drink`, `sleep`. The elephant: `kick`, `spray`, `trunk_up`, `worried`, `hide`.
- `act`: what they keep doing: `walk`, `run`, `wave`, `clap`, `nod`, `talk`, `chirp`, `flap`, `fly`, `hop`, `laugh`, `dig`, `pour`, `eat`, `rub`, `kick`, `spray`, `trunk`, `ears`, `tail`, `sway`, `shy`, `fidget`, `tuck`, `dua`, `hug`, `sleep`, `drink`, `look`, `cheer`, `bounce`, `give`. Combine with `+`: `"walk+talk"`.
- `face`: an expression overriding the mood's: `idle`, `happy`, `laugh`, `sad`, `surprised`, `worried`, `sleep`, `full` (cheeks stuffed), `ouch`, `shy`, `think`, `open`, `tired`.
- `look`: `up`, `down`, `left`, `right`, `upLeft`, `upRight`, `downLeft`, `downRight`.
- `hold`: a prop in the hand (`"prop:bottle"`), with `holdSize` (fraction of the puppet's height), `holdTurn` (degrees) and `holdHand` (`R` or `L`).

A tap on a puppet, or the narration reaching its name, makes it react with its own action and a big smile.

**Choice** (exactly one per story, two options)

```json
{
  "id": "choice",
  "type": "choice",
  "prompt": { "en": "What should Bunty do with the mango?", "ur": "بنٹی آم کا کیا کرے؟" },
  "options": [
    { "id": "share", "label": { "en": "Share it", "ur": "بانٹ لے" }, "picture": "prop:mango_slice", "next": "p5_share" },
    { "id": "keep", "label": { "en": "Keep it all", "ur": "سارا خود رکھ لے" }, "picture": "prop:mango", "next": "p5_keep" }
  ]
}
```

Both branches must be the same number of pages, and may join back together.

**Tap-to-help** (optional, once per story): the story waits while the
child does the page's key action themselves.

```json
"help": { "kind": "drag", "item": 1, "to": 2, "when": "before" },
"cast": [
  { "art": "puppet:ali", "x": 0.4, "y": 0.63, "size": 0.24, "pose": "hold", "helpHide": 1 },
  { "art": "prop:bottle_low", "x": 0.43, "y": 0.575, "size": 0.075, "helpHide": 1 },
  { "art": "prop:bottle_cap_empty", "x": 0.64, "y": 0.645, "size": 0.06, "helpHide": 1 },
  { "art": "puppet:ali", "x": 0.4, "y": 0.63, "size": 0.24, "pose": "pour", "helpStep": 1 },
  { "art": "prop:bottle_cap", "x": 0.64, "y": 0.645, "size": 0.075, "helpStep": 1 }
]
```

- `kind`: `drag` (drag cast member `item` onto cast member `to`), `rub`
  (rub back and forth over `item`) or `tap` (tap `item`). Indexes count
  from 0 in `cast`.
- `steps`: rubs and taps take several steps (default 3); a drag is one.
- `when`: `before` (default) the child helps, then the page is narrated;
  `after` the narration plays, then the story waits for the child.
- On the cast: `helpStep: n` appears once the child has done n steps (and
  makes its entrance then); `helpHide: n` goes away at n steps. Use a pair
  to swap a character into a new pose, and `helpStep` 1, 2, 3 to show
  progress step by step (a mango piece for each friend).
- While it waits, what to touch glows and, after a few quiet seconds, a
  silent hand shows what to do. Each step pops; finishing sparkles and
  chimes. A child who never manages it isn't stuck: after 45 seconds the
  story does it for them.

Name the branch pages `choice_a` and `choice_b`: their recordings are then simply `choice_a.mp3` and `choice_b.mp3` (other pages are `page_<n>.mp3`).

### Glossary (tap-a-word)

```json
{ "id": "mango", "picture": "prop:mango", "word": { "en": "mango", "ur": "آم" }, "forms": { "en": ["mangoes"], "ur": ["آموں"] } }
```

Add `picture` when there's art for the word: it puts the word into the
children's word game ("Tap the mango!").

When a child taps a word, it is matched against each entry's headword and
`forms`, ignoring case and punctuation. The popup shows the meaning in the
other language. The tapped word plays in the narrator's voice, cut from
the page recording by its timings.

### Vocabulary

Three glossary ids. They go into the Word Jar when the story is finished.

### Quiz

Three picture questions, three picture options each, exactly one
`"correct": true`. Pictures use the same `character:`/`prop:` references.
Characters show their face art; puppets show themselves, alive. For an
answer that is something said ("Bismillah"), add a `label` with `en`/`ur`
words to show under the picture.

Add one **drag** question too: the child drags `item` onto the right picture.

```json
{
  "type": "drag",
  "question": { "en": "Give a piece of mango to Tolu!", "ur": "ٹولو کو آم کا ٹکڑا دو!" },
  "item": "prop:mango_slice",
  "options": [
    { "picture": "character:parrot" },
    { "picture": "character:turtle", "correct": true },
    { "picture": "character:elephant" }
  ]
}
```

Each play of the quiz asks three questions: two picture questions plus one
special question that rotates on every replay. The specials are the drag
question and two the app builds from the story itself, so you write
nothing for them:

- **put in order:** the first, middle and last scenes, to tap in order;
- **find:** "Where is Bunty?" in a scene with company (a character listed
  under `characters`).

## 2b. Narration: recorded voices only

Stories play like a cartoon, so every line is a human-quality recording
bundled with the app. Nothing is spoken by text-to-speech (the Word Jar
keeps it only as a fallback for words with no recording).

For each story and language, put MP3s in
`assets/audio/stories/<story_id>/<en|ur>/`:

| File | Says |
| --- | --- |
| `page_<n>.mp3` | the page text; page `p5_share` → `page_5_share.mp3` |
| `<choice id>.mp3` | the Choice Moment's `prompt`, e.g. `choice.mp3` |
| `quiz_1.mp3` … `quiz_3.mp3` | the quiz questions |
| `word_<glossary id>.mp3` | a vocabulary word on its own (Word Jar) |

Noori's lines go in `assets/audio/guide/<en|ur>/<key>.mp3`, one per key
in `guide_lines.json`.

Then align the pages for karaoke with whisper.cpp (no Python needed):

```
dart run tool/align_audio.dart --check   # lists every clip still missing
dart run tool/align_audio.dart --whisper <whisper-cli> --model <ggml-*.bin>
```

Full step-by-step instructions, file names and recording tips are in
[assets/audio/README.md](../assets/audio/README.md).

Until a page has its recording, the player still runs: it reads the page
as a silent read-along, highlighting words on estimated timings.

## 3. Scenes: `assets/content/scenes.json`

```json
"mango_grove": {
  "ambient": "birds",
  "layers": [
    { "art": "scenes/mango_grove/sky.svg", "depth": 0, "drift": 0 },
    { "art": "scenes/mango_grove/near.svg", "depth": 0.6, "drift": 8 },
    { "cast": true, "depth": 0.6, "drift": 8 },
    { "art": "scenes/mango_grove/fg.svg", "depth": 1, "drift": 12, "bob": 3 }
  ]
}
```

Layers are drawn back to front. `depth` 0 moves least and 1 moves most.
`drift` and `bob` set the idle motion in pixels. Give the `cast` layer the
same depth and drift as the ground it stands on.

`ambient` loops a soundscape under the narration: `birds`, `river`,
`wind` or `waves` (`assets/audio/ambient/`). Music and ambience duck while a voice
plays.

`secrets` are little surprises hidden in the scene, for children who tap
around while the story plays (not on Home's cards):

```json
"secrets": [
  { "kind": "frog", "x": 0.88, "y": 0.76, "size": 0.05 },
  { "kind": "caterpillar", "x": 0.13, "y": 0.36, "size": 0.04 }
]
```

Kinds: `butterfly` (flies away and comes back), `frog` (peeks over a leaf,
leaps), `caterpillar` (asleep, wakes and wriggles), `snail` (peeks out of
its shell), `ladybird` (flies a loop), `mouse` (pops out of its hole),
`fish` (leaps out of the ripples). Finding one gives a sparkle. Place them
at the edges, in the trees or in the grass in front of the cast, above
the subtitles (`y` at most 0.8), and not behind the cast.

Scene SVGs use a 400 × 860 view box with the ground line near y = 500. The
subtitles cover the bottom fifth of the screen, and the camera slowly zooms
(up to 12%), so keep the action away from the very edges.

## Art

Flat vector SVG in the house style: simple shapes, soft gradients, no
outlines thicker than 3px. Characters are original animals.

**One manual step:** Flutter does not include asset folders recursively. A
*new folder* (for example a new scene's folder) must be added under
`flutter: assets:` in `pubspec.yaml`. The content test tells you when you
forget.
