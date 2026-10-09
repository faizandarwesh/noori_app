# Noori voice recordings

Noori uses only real recorded voices. Text-to-speech is used in one place:
the Word Jar, for a word that has no recording yet.

**The app works with no recordings.** A missing file is skipped: Noori's
lines show as a silent speech bubble, and story pages play as a silent
read-along with the words highlighted at a reading pace. Each recording you
add replaces its silent version automatically. You don't need to change any
code. Drop the file in the right folder with the right name and rebuild the
app.

## Get the full list

```
dart run tool/align_audio.dart --check > recordings_todo.txt
```

This writes one line per missing recording: its path, a tab, then exactly
what it should say. Open the file in VS Code to see the Urdu correctly. It's
the script for your voice artist. Run the command again at any time to see
what's still left.

## Where each file goes

```
assets/audio/
├── guide/
│   ├── en/   Noori's lines in English
│   └── ur/   Noori's lines in Urdu
└── stories/
    └── <story_id>/
        ├── en/   everything for that story in English
        └── ur/   everything for that story in Urdu
```

### Noori's lines: `assets/audio/guide/<en|ur>/<key>.mp3`

The text for each line is in `assets/content/guide_lines.json`. The file name
is the line's key.

| File | When it plays | English |
| --- | --- | --- |
| `home_first_visit.mp3` | first time Home opens, ever | Hi! I'm Noori! Swipe to see the stories, then tap one! |
| `choice_ask.mp3` | each Choice Moment | What would you do? |
| `quiz_start.mp3` | start of each quiz | Picture game time! Tap the right picture. |
| `quiz_order.mp3` | a "put in order" quiz question | Tap the pictures in story order: first, next, last! |
| `quiz_correct.mp3` | right quiz answer | Yay! You got it! |
| `quiz_try_again.mp3` | wrong quiz answer | Try again! |
| `reward_great.mp3` | reward screen | Wow! Look at all your fireflies! |
| `reward_word.mp3` | reward screen, new words | You found a new word for your Word Jar! |

The two language-screen samples are recorded only in their own language:

- `guide/en/lang_sample_en.mp3`: "Let's read!"
- `guide/ur/lang_sample_ur.mp3`: "چلو پڑھیں!"

`quiz_find` in `guide_lines.json` is a template ("Where is {name}?"); it
isn't recorded itself. Record the per-story `find_<character>.mp3` files
instead.

The `demo_*` lines are for a developer screen only. You don't need them.

### Story files: `assets/audio/stories/<story_id>/<en|ur>/`

Story ids are the file names in `assets/content/stories/`:
`bunty_big_mango`, `chunnu_crosses_river`, `gulu_gentle_trunk`,
`mithu_tells_truth`, `tolu_tiny_seed`.

| File | What it says |
| --- | --- |
| `page_<n>.mp3` | one story page's text (see page names below) |
| `choice.mp3` | the Choice Moment question, e.g. "What should Bunty do with the mango?" |
| `quiz_1.mp3` … `quiz_4.mp3` | the quiz questions in the story file, in order. `quiz_4` is the drag question, e.g. "Give a piece of mango to Tolu!" |
| `find_<character>.mp3` | the quiz's "find" question, e.g. `find_rabbit.mp3` = "Where is Bunty? Tap!" |
| `word_<id>.mp3` | one word on its own, e.g. `word_mango.mp3` = "mango" / "آم". Needed for the vocabulary words (Word Jar) and every word with a picture (the word game). Until recorded, the device voice says it |
| `name_<character>.mp3` | *(optional)* the character saying its name, e.g. `name_rabbit.mp3` = "Bunty". Plays when a child taps the character between narration; without it the character giggles |

**Page names** come from the page `id` in the story JSON, without its
leading `p`:

| Page id | File |
| --- | --- |
| `p1` | `page_1.mp3` |
| `p4` | `page_4.mp3` |
| `p5_share` | `page_5_share.mp3` |
| `p6_keep` | `page_6_keep.mp3` |
| `p7` | `page_7.mp3` |

Every branch page needs a recording, because the child might choose either
path. Run the `--check` command above for the exact, current list: about
266 files for the five stories and Noori in both languages, including the
20 optional character names.

## Recording tips

- **Format:** MP3, mono, 44.1 kHz, 128 kbps. Name files exactly as above,
  in lowercase.
- **Read the text exactly as written.** The karaoke highlight follows the
  page text word by word. Extra or skipped words still work, but the
  highlight is most accurate when the reading matches.
- **One file per page,** with about 0.3 s of silence at each end and no long
  pauses inside. The story moves on 1.2 s after the file ends.
- **Pace:** slow and warm, for ages 3–8. Bedtime mode plays voices a little
  slower by itself, so record at normal pace.
- **Urdu:** natural spoken Urdu, matching the Urdu text in the story file.
- **Never call Noori "ullu".** Always say "Noori".
- **Keep the volume even** across all files, with no background music or
  effects. The app adds its own music and nature sounds and lowers them
  while a voice plays.

## After adding story pages: align the karaoke (once per batch)

The highlight is exact only after the pages are aligned. This step listens
to each page recording and saves when every word is spoken into the story
JSON (`"words"`). It runs on your computer, not in the app, and doesn't need
Python.

**One-time setup:**

1. Download whisper.cpp from
   https://github.com/ggerganov/whisper.cpp/releases. Use a recent release
   (v1.7.4 or later reads MP3 directly). On Windows, take
   `whisper-bin-x64.zip` and unzip it, for example to `C:\whisper\`. It
   contains `whisper-cli.exe`.
2. Download a model from https://huggingface.co/ggerganov/whisper.cpp/tree/main:
   - `ggml-large-v3.bin` (about 3 GB): best for Urdu. Recommended.
   - `ggml-medium.bin` (about 1.5 GB): faster, fine for English.

   Put it next to `whisper-cli.exe`.

**Each time you add or replace page recordings:**

```
dart run tool/align_audio.dart --whisper C:\whisper\whisper-cli.exe --model C:\whisper\ggml-large-v3.bin
```

Useful options:

- Add a story id to align just that story, for example
  `dart run tool/align_audio.dart bunty_big_mango --whisper ... --model ...`.
- `--lang ur` or `--lang en`: only one language.
- `--force`: re-align pages that are already done. Pages are skipped
  automatically unless their recording is newer than the story file.

To avoid typing the paths every time, set them once in PowerShell:

```
$env:WHISPER_CLI = "C:\whisper\whisper-cli.exe"
$env:WHISPER_MODEL = "C:\whisper\ggml-large-v3.bin"
dart run tool/align_audio.dart
```

Then run `flutter test test/content_test.dart`. It checks every aligned page
has one timing per word.

**If whisper-cli can't read an MP3** (older builds), convert that file to WAV
with ffmpeg, check the timings, then keep the MP3 in the app:
`ffmpeg -i page_1.mp3 -ar 16000 -ac 1 page_1.wav`. Updating whisper.cpp is
the easier fix.

## Adding a new story later

Create its two folders, `assets/audio/stories/<new_story_id>/en/` and
`.../ur/`, and add both to the `assets:` list in `pubspec.yaml`. Flutter
doesn't include sub-folders automatically. `flutter test` tells you if you
forget one.
