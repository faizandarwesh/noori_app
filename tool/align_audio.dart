// Karaoke timings for Noori's recorded narration. No Python needed: it uses
// whisper.cpp (https://github.com/ggerganov/whisper.cpp), a single program.
//
// For each page recording it asks Whisper when every word was spoken and
// writes the timings into the story JSON, one entry per word of the page
// text:
//
//   "words": { "en": [{ "w": "Bunty", "start": 120, "end": 480 }, ...] }
//
// The page text is the source of truth: Whisper's words are matched to it in
// order, so small mishearings don't matter, and any word Whisper missed is
// timed between its neighbours.
//
// Setup (once): download whisper.cpp (the Windows release zip contains
// whisper-cli.exe) and a model such as ggml-medium.bin or ggml-large-v3.bin
// (best for Urdu). See assets/audio/README.md.
//
//   dart run tool/align_audio.dart --check
//   dart run tool/align_audio.dart --model C:\whisper\ggml-large-v3.bin
//   dart run tool/align_audio.dart bunty_big_mango --lang ur --model ...
//
// Options:
//   --check           only list the recordings that are still missing
//   --model <file>    Whisper model (or set WHISPER_MODEL)
//   --whisper <exe>   whisper-cli program (or set WHISPER_CLI; default:
//                     whisper-cli on the PATH)
//   --lang en|ur      only this language
//   --force           re-align pages that are already done
import 'dart:convert';
import 'dart:io';

const _stories = 'assets/content/stories';
const _guideLines = 'assets/content/guide_lines.json';
const _audio = 'assets/audio';
const _langs = ['en', 'ur'];

Future<void> main(List<String> args) async {
  final opts = _Options.parse(args);
  final files = opts.stories.isEmpty
      ? (Directory(_stories)
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path)))
      : [for (final s in opts.stories) File('$_stories/$s.json')];
  for (final f in files) {
    if (!f.existsSync()) _fail('No story file ${f.path}');
  }

  if (opts.check) {
    _check(files);
    return;
  }
  final model = opts.model ?? Platform.environment['WHISPER_MODEL'];
  if (model == null || !File(model).existsSync()) {
    _fail(
      'Tell me which Whisper model to use: --model <path to ggml-*.bin> '
      '(or set WHISPER_MODEL). See assets/audio/README.md.',
    );
  }
  final whisper =
      opts.whisper ?? Platform.environment['WHISPER_CLI'] ?? 'whisper-cli';
  final langs = opts.lang == null ? _langs : [opts.lang!];
  for (final f in files) {
    await _alignStory(f, langs, whisper, model, force: opts.force);
  }
}

// ---- Paths (must match lib/core/audio/voice_clips.dart) --------------------

String pageNumber(String pageId) =>
    pageId.startsWith('p') ? pageId.substring(1) : pageId;

String _storyDir(String storyId, String lang) =>
    '$_audio/stories/$storyId/$lang';

String pageClip(String storyId, String pageId, String lang) =>
    pageId.startsWith('choice_')
    ? '${_storyDir(storyId, lang)}/$pageId.mp3'
    : '${_storyDir(storyId, lang)}/page_${pageNumber(pageId)}.mp3';

// ---- Text (must match the app's splitChunks / normaliseWord) ---------------

final _letter = RegExp(r'\p{L}', unicode: true);
final _notLetterOrMark = RegExp(r'[^\p{L}\p{M}]', unicode: true);

/// The page's words exactly as the app splits them: runs of non-space that
/// contain a letter.
List<String> textWords(String text) => [
  for (final m in RegExp(r'\S+').allMatches(text))
    if (_letter.hasMatch(m.group(0)!)) m.group(0)!,
];

String norm(String word) => word.toLowerCase().replaceAll(_notLetterOrMark, '');

// ---- Alignment -------------------------------------------------------------

typedef Heard = ({String word, int start, int end});

/// One timing per text word. Words matched to what Whisper heard take its
/// times; the rest are paired with unmatched heard words when the counts
/// agree, otherwise spread evenly across the gap.
List<Map<String, Object>> align(List<String> text, List<Heard> heard) {
  final n = text.length, m = heard.length;
  final a = [for (final w in text) norm(w)];
  final b = [for (final h in heard) norm(h.word)];

  // Longest common subsequence of normalised words.
  final lcs = List.generate(n + 1, (_) => List.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      lcs[i][j] = a[i] == b[j]
          ? lcs[i + 1][j + 1] + 1
          : (lcs[i + 1][j] > lcs[i][j + 1] ? lcs[i + 1][j] : lcs[i][j + 1]);
    }
  }
  final pairs = <(int, int)>[];
  for (var i = 0, j = 0; i < n && j < m;) {
    if (a[i] == b[j]) {
      pairs.add((i++, j++));
    } else if (lcs[i + 1][j] >= lcs[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }

  final times = List<(int, int)?>.filled(n, null);
  for (final (i, j) in pairs) {
    times[i] = (heard[j].start, heard[j].end);
  }

  // Fill each run of unmatched text words between two anchors.
  final anchors = [(-1, -1), ...pairs, (n, m)];
  final lastEnd = heard.isEmpty ? 300 * n : heard.last.end;
  for (var k = 0; k + 1 < anchors.length; k++) {
    final (i0, j0) = anchors[k];
    final (i1, j1) = anchors[k + 1];
    final gapText = i1 - i0 - 1, gapHeard = j1 - j0 - 1;
    if (gapText <= 0) continue;
    if (gapText == gapHeard) {
      for (var g = 0; g < gapText; g++) {
        final h = heard[j0 + 1 + g];
        times[i0 + 1 + g] = (h.start, h.end);
      }
      continue;
    }
    final left = gapHeard > 0
        ? heard[j0 + 1].start
        : (i0 >= 0 ? times[i0]!.$2 : (heard.isEmpty ? 0 : heard.first.start));
    var right = gapHeard > 0
        ? heard[j1 - 1].end
        : (i1 < n ? times[i1]!.$1 : lastEnd);
    if (right <= left) right = left + 250 * gapText;
    final step = (right - left) / gapText;
    for (var g = 0; g < gapText; g++) {
      times[i0 + 1 + g] = (
        (left + g * step).round(),
        (left + (g + 1) * step).round(),
      );
    }
  }

  // Starts never go backwards, so the highlight only moves forward.
  var last = 0;
  return [
    for (var i = 0; i < n; i++)
      () {
        final (s0, e0) = times[i]!;
        final s = s0 < last ? last : s0;
        final e = e0 < s + 60 ? s + 60 : e0;
        last = s;
        return <String, Object>{'w': text[i], 'start': s, 'end': e};
      }(),
  ];
}

// ---- Whisper ---------------------------------------------------------------

Future<List<Heard>> _transcribe(
  String whisper,
  String model,
  String clip,
  String lang,
  String prompt,
) async {
  final tmp = await Directory.systemTemp.createTemp('noori_align');
  try {
    final out = '${tmp.path}${Platform.pathSeparator}words';
    final result = await Process.run(whisper, [
      '-m', model,
      '-f', clip,
      '-l', lang,
      '--prompt', prompt,
      // One segment per word, split at word boundaries.
      '-ml', '1',
      '-sow',
      '-oj',
      '-of', out,
      '-np',
    ]);
    if (result.exitCode != 0) {
      _fail(
        'whisper-cli failed on $clip:\n${result.stderr}\n'
        'If it cannot read MP3 here, convert to 16 kHz WAV with ffmpeg and '
        'see assets/audio/README.md.',
      );
    }
    final bytes = await File('$out.json').readAsBytes();
    final json = jsonDecode(
      utf8.decode(bytes, allowMalformed: true),
    ) as Map<String, dynamic>;
    return [
      for (final seg in json['transcription'] as List)
        if (seg case {
          'text': final String text,
          'offsets': {'from': final num from, 'to': final num to},
        })
          if (norm(text).isNotEmpty && !text.trim().startsWith('['))
            (word: text.trim(), start: from.toInt(), end: to.toInt()),
    ];
  } on ProcessException {
    _fail(
      'Could not run "$whisper". Install whisper.cpp and pass --whisper '
      '<path to whisper-cli> (or set WHISPER_CLI). See assets/audio/README.md.',
    );
  } finally {
    await tmp.delete(recursive: true);
  }
}

Future<void> _alignStory(
  File file,
  List<String> langs,
  String whisper,
  String model, {
  required bool force,
}) async {
  final story = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final storyId = story['id'] as String;
  final storyTime = file.lastModifiedSync();
  var changed = 0;
  for (final node in (story['nodes'] as List).cast<Map<String, dynamic>>()) {
    if ((node['type'] ?? 'page') != 'page') continue;
    for (final lang in langs) {
      final clip = File(pageClip(storyId, node['id'] as String, lang));
      if (!clip.existsSync()) continue;
      final words = (node['words'] as Map<String, dynamic>?)?[lang];
      final done = words is List && words.isNotEmpty;
      if (!force && done && !clip.lastModifiedSync().isAfter(storyTime)) {
        continue; // Already aligned, and the recording hasn't changed.
      }
      final text = (node['text'] as Map<String, dynamic>)[lang] as String;
      final heard = await _transcribe(whisper, model, clip.path, lang, text);
      final wordsOut = align(textWords(text), heard);
      (node['words'] ??= <String, dynamic>{})[lang] = wordsOut;
      changed++;
      stdout.writeln(
        '  $storyId/${node['id']}/$lang: '
        '${heard.length} heard -> ${wordsOut.length} words',
      );
    }
  }
  if (changed > 0) {
    file.writeAsStringSync('${prettyJson(story)}\n');
    stdout.writeln('${file.path}: $changed page(s) aligned');
  } else {
    stdout.writeln('${file.path}: nothing new to align');
  }
}

// ---- Missing recordings ----------------------------------------------------

void _check(List<File> files) {
  var missing = 0;
  void need(String path, String says) {
    if (File(path).existsSync()) return;
    missing++;
    stdout.writeln('$path\t$says');
  }

  final guide =
      jsonDecode(File(_guideLines).readAsStringSync()) as Map<String, dynamic>;
  for (final MapEntry(:key, :value) in guide.entries) {
    if (key.startsWith('demo_')) continue;
    // Templates like "Where is {name}?" are recorded per story (find_*).
    if ((value as Map).values.any((t) => '$t'.contains('{'))) continue;
    for (final lang in _langs) {
      // Each language sample is recorded only in its own language.
      if (key.startsWith('lang_sample_') && !key.endsWith(lang)) continue;
      need('$_audio/guide/$lang/$key.mp3', value[lang] as String);
    }
  }

  for (final f in files) {
    final story = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    final id = story['id'] as String;
    final vocabulary = (story['vocabulary'] as List? ?? const []).toSet();
    for (final lang in _langs) {
      final dir = _storyDir(id, lang);
      for (final node in (story['nodes'] as List).cast<Map>()) {
        if ((node['type'] ?? 'page') == 'page') {
          need(pageClip(id, node['id'] as String, lang), node['text'][lang]);
        } else if (node['type'] == 'choice') {
          need('$dir/${node['id']}.mp3', node['prompt'][lang] as String);
        }
      }
      for (final (i, q) in (story['quiz'] as List? ?? const []).indexed) {
        need('$dir/quiz_${i + 1}.mp3', q['question'][lang] as String);
      }
      // A character saying its name when tapped (if missing: a giggle).
      for (final MapEntry(:key, :value)
          in (story['characters'] as Map? ?? const {}).entries) {
        need('$dir/name_$key.mp3', (value as Map)[lang] as String);
      }
      // The quiz's "Where is Bunty?" question for each character.
      final findLine = (guide['quiz_find'] as Map?)?[lang] as String?;
      for (final MapEntry(:key, :value)
          in (story['characters'] as Map? ?? const {}).entries) {
        final name = (value as Map)[lang] as String;
        need(
          '$dir/find_$key.mp3',
          findLine?.replaceAll('{name}', name) ?? name,
        );
      }
      // Vocabulary words (Word Jar) and every picture word (word game).
      for (final g in (story['glossary'] as List? ?? const []).cast<Map>()) {
        if (vocabulary.contains(g['id']) || g['picture'] != null) {
          need('$dir/word_${g['id']}.mp3', g['word'][lang] as String);
        }
      }
    }
  }
  stderr.writeln('\n$missing recording(s) missing.');
}

// ---- JSON that keeps the stories readable ----------------------------------

/// JSON with small objects and arrays kept on one line, like the
/// hand-written story files.
String prettyJson(Object? value, [int indent = 0, int width = 100]) {
  final flat = _flat(value);
  if (value is! Map && value is! List || flat.length + indent <= width) {
    return flat;
  }
  final pad = ' ' * (indent + 2);
  if (value is Map) {
    final items = [
      for (final e in value.entries)
        '$pad${jsonEncode(e.key)}: ${prettyJson(e.value, indent + 2, width)}',
    ];
    return '{\n${items.join(',\n')}\n${' ' * indent}}';
  }
  final items = [
    for (final v in value as List) '$pad${prettyJson(v, indent + 2, width)}',
  ];
  return '[\n${items.join(',\n')}\n${' ' * indent}]';
}

/// One-line JSON in the stories' style: `{ "a": 1, "b": [1, 2] }`.
String _flat(Object? value) => switch (value) {
  final Map m when m.isEmpty => '{}',
  final Map m =>
    '{ ${[for (final e in m.entries) '${jsonEncode(e.key)}: ${_flat(e.value)}'].join(', ')} }',
  final List l => '[${[for (final v in l) _flat(v)].join(', ')}]',
  _ => jsonEncode(value),
};

// ---- Options ---------------------------------------------------------------

class _Options {
  bool check = false, force = false;
  String? model, whisper, lang;
  final stories = <String>[];

  static _Options parse(List<String> args) {
    final o = _Options();
    for (var i = 0; i < args.length; i++) {
      String value() =>
          i + 1 < args.length ? args[++i] : _fail('${args[i]} needs a value');
      switch (args[i]) {
        case '--check':
          o.check = true;
        case '--force':
          o.force = true;
        case '--model':
          o.model = value();
        case '--whisper':
          o.whisper = value();
        case '--lang':
          o.lang = value();
          if (!_langs.contains(o.lang)) _fail('--lang must be en or ur');
        case final a when a.startsWith('-'):
          _fail('Unknown option $a');
        case final story:
          o.stories.add(story);
      }
    }
    return o;
  }
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
