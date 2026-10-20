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
// A whole story recorded as one file (e.g. from ElevenLabs) is cut into the
// page files first: Whisper hears the whole file once, its words are matched
// to the pages in reading order, and the MP3 is cut in the pause between
// pages, frame by frame (no re-encoding, so no quality loss). The question
// at the end of the page before a Choice Moment also becomes its
// choice clip. Pages the recording skips (often one choice branch) are
// listed and stay silent read-alongs.
//
//   dart run tool/align_audio.dart tippu_seed --lang ur --split tippu.mp3
//
// Options:
//   --check           only list the recordings that are still missing
//   --model <file>    Whisper model (or set WHISPER_MODEL)
//   --whisper <exe>   whisper-cli program (or set WHISPER_CLI; default:
//                     whisper-cli on the PATH)
//   --lang en|ur      only this language
//   --force           re-align pages that are already done
//   --split <file>    cut one whole-story recording into page files (needs
//                     one story id and --lang)
//   --listen          with --split: only run Whisper and keep what it heard,
//                     so the split itself later takes seconds
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

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
  if (opts.split case final recording?) {
    if (files.length != 1 || opts.lang == null) {
      _fail(
        '--split needs one story id and --lang, e.g. '
        'tippu_seed --lang ur --split tippu.mp3',
      );
    }
    await _splitStory(
      files.single,
      opts.lang!,
      recording,
      whisper,
      model,
      listenOnly: opts.listen,
    );
    return;
  }
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

final _marks = RegExp(r'\p{M}', unicode: true);

/// What two words are compared by: [norm] without diacritics, with the Arabic
/// letter forms Whisper sometimes writes folded into their Urdu ones.
String matchKey(String word) =>
    norm(word)
        .replaceAll(_marks, '')
        .replaceAll('ك', 'ک')
        .replaceAll(RegExp('[يى]'), 'ی')
        .replaceAll(RegExp('[هة]'), 'ہ')
        .replaceAll('ۂ', 'ہ')
        .replaceAll('أ', 'ا')
        .replaceAll('آ', 'ا');

/// Index pairs (text, heard) of the longest common run of equal words.
List<(int, int)> matchWords(List<String> text, List<String> heard) {
  final n = text.length, m = heard.length;
  final a = [for (final w in text) matchKey(w)];
  final b = [for (final w in heard) matchKey(w)];
  final lcs = List.generate(n + 1, (_) => List.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      lcs[i][j] = a[i].isNotEmpty && a[i] == b[j]
          ? lcs[i + 1][j + 1] + 1
          : math.max(lcs[i + 1][j], lcs[i][j + 1]);
    }
  }
  final pairs = <(int, int)>[];
  for (var i = 0, j = 0; i < n && j < m;) {
    if (a[i].isNotEmpty && a[i] == b[j]) {
      pairs.add((i++, j++));
    } else if (lcs[i + 1][j] >= lcs[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  return pairs;
}

// ---- Alignment -------------------------------------------------------------

typedef Heard = ({String word, int start, int end});

/// One timing per text word. Words matched to what Whisper heard take its
/// times; the rest are paired with unmatched heard words when the counts
/// agree, otherwise spread evenly across the gap. Words after the last one
/// heard run up to [until] (default: the end of the last heard word).
List<Map<String, Object>> align(
  List<String> text,
  List<Heard> heard, {
  int? until,
}) {
  final n = text.length, m = heard.length;
  final pairs = matchWords(text, [for (final h in heard) h.word]);

  final times = List<(int, int)?>.filled(n, null);
  for (final (i, j) in pairs) {
    times[i] = (heard[j].start, heard[j].end);
  }

  // Fill each run of unmatched text words between two anchors.
  final anchors = [(-1, -1), ...pairs, (n, m)];
  final lastEnd = until ?? (heard.isEmpty ? 300 * n : heard.last.end);
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

// ---- One recording for the whole story -------------------------------------

/// Heard words [from]..[to] (inclusive) belong to one page; [matched] of the
/// page's words were recognised in them.
typedef PageSpan = ({int matched, int from, int to});

/// Shares a whole-story recording's heard words out to [pages] (each a list
/// of text words, in reading order). A page that matches fewer than
/// [minMatch] of its words isn't in the recording and gets null. Neighbouring
/// pages are split in the longest pause between them.
List<PageSpan?> planPages(
  List<List<String>> pages,
  List<Heard> heard, {
  double minMatch = 0.4,
}) {
  final spans = List<PageSpan?>.filled(pages.length, null);
  if (heard.isEmpty) return spans;
  final heardWords = [for (final h in heard) h.word];
  final order = [for (var p = 0; p < pages.length; p++) p];
  late List<int> owner;
  late List<(int, int)> pairs;
  late Map<int, int> count;
  while (true) {
    owner = [
      for (final p in order)
        for (final _ in pages[p]) p,
    ];
    pairs = matchWords([for (final p in order) ...pages[p]], heardWords);
    count = {for (final p in order) p: 0};
    for (final (i, _) in pairs) {
      count[owner[i]] = count[owner[i]]! + 1;
    }
    double share(int p) => count[p]! / pages[p].length;
    final missing = order.where((p) => share(p) < minMatch).toList();
    if (missing.isEmpty || order.length == 1) break;
    // Drop only the weakest page, then match again: words it took may
    // belong to its neighbours.
    missing.sort((x, y) => share(x).compareTo(share(y)));
    order.remove(missing.first);
  }

  final first = <int, int>{}, last = <int, int>{};
  for (final (i, j) in pairs) {
    first.putIfAbsent(owner[i], () => j);
    last[owner[i]] = j;
  }
  order.retainWhere(first.containsKey);
  if (order.isEmpty) return spans;
  int pause(int after) => heard[after + 1].start - heard[after].end;

  /// The heard word after which the longest pause in [from]..[to] falls.
  int longestPause(int from, int to) {
    var best = from;
    for (var c = from; c <= to; c++) {
      if (pause(c) > pause(best)) best = c;
    }
    return best;
  }

  // A title before the first page or a closing line after the last one is
  // left out when a clear pause separates it.
  const clearPause = 600;
  var start = 0;
  final head = first[order.first]!;
  if (head > 0) {
    final c = longestPause(0, head - 1);
    if (pause(c) >= clearPause) start = c + 1;
  }
  for (var k = 0; k < order.length; k++) {
    final p = order[k];
    var end = heard.length - 1;
    if (k + 1 < order.length) {
      end = longestPause(last[p]!, first[order[k + 1]]! - 1);
    } else if (last[p]! < end) {
      final c = longestPause(last[p]!, end - 1);
      if (pause(c) >= clearPause) end = c;
    }
    spans[p] = (matched: count[p]!, from: start, to: end);
    start = end + 1;
  }
  return spans;
}

/// The stretch of the recording to cut for heard words [from]..[to]: a
/// little silence either side, never past halfway into the next pause.
/// When Whisper missed the page's first or last words, they are still in the
/// pause, so the clip takes all of it up to the neighbouring page.
(int, int) clipBounds(
  List<Heard> heard,
  int from,
  int to,
  int totalMs, {
  bool headMissed = false,
  bool tailMissed = false,
}) {
  const lead = 300, tail = 500;
  final s = heard[from].start, e = heard[to].end;
  final prev = from > 0 ? heard[from - 1].end : 0;
  final next = to + 1 < heard.length ? heard[to + 1].start : totalMs;
  return (
    headMissed ? math.min(s, prev + 100) : math.max((prev + s) ~/ 2, s - lead),
    tailMissed
        ? math.max(e, to + 1 < heard.length ? next - lead : totalMs)
        : math.min((e + next) ~/ 2, e + tail),
  );
}

// An MP3 is a run of frames, so a clip is just the frames between two times,
// copied as they are.

typedef Mp3Frame = ({int offset, int length, double ms});

const _mp3Kbps = {
  3: [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320],
  2: [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160],
};
const _mp3Rates = {
  3: [44100, 48000, 32000],
  2: [22050, 24000, 16000],
  0: [11025, 12000, 8000],
};

/// The audio frames of an MP3 (layer III), skipping the ID3 tag and the
/// Xing/Info frame that only describes the whole file.
List<Mp3Frame> mp3Frames(Uint8List b) {
  var i = 0;
  if (b.length > 10 && b[0] == 0x49 && b[1] == 0x44 && b[2] == 0x33) {
    i = 10 + (b[6] << 21 | b[7] << 14 | b[8] << 7 | b[9]);
  }
  final frames = <Mp3Frame>[];
  while (i + 4 <= b.length) {
    final h = b[i] << 24 | b[i + 1] << 16 | b[i + 2] << 8 | b[i + 3];
    final version = h >> 19 & 3, layer = h >> 17 & 3;
    final rate = h >> 10 & 3, bits = h >> 12 & 15;
    if (h >> 21 & 0x7ff != 0x7ff ||
        version == 1 ||
        layer != 1 ||
        rate == 3 ||
        bits == 0 ||
        bits == 15) {
      i++;
      continue;
    }
    final mpeg1 = version == 3;
    final hz = _mp3Rates[version]![rate];
    final kbps = _mp3Kbps[mpeg1 ? 3 : 2]![bits];
    final length = (mpeg1 ? 144 : 72) * kbps * 1000 ~/ hz + (h >> 9 & 1);
    if (i + length > b.length) break;
    final header = String.fromCharCodes(
      b.sublist(i + 4, math.min(i + 44, b.length)),
    );
    final infoFrame =
        frames.isEmpty && (header.contains('Xing') || header.contains('Info'));
    if (!infoFrame) {
      frames.add((
        offset: i,
        length: length,
        ms: (mpeg1 ? 1152 : 576) * 1000 / hz,
      ));
    }
    i += length;
  }
  return frames;
}

/// The frames covering [fromMs]..[toMs], and the time the first one starts.
({Uint8List bytes, int startMs}) mp3Slice(
  Uint8List b,
  List<Mp3Frame> frames,
  int fromMs,
  int toMs,
) {
  final out = BytesBuilder(copy: false);
  var t = 0.0;
  int? startMs;
  for (final f in frames) {
    if (t + f.ms > fromMs && t < toMs) {
      startMs ??= t.round();
      out.add(Uint8List.sublistView(b, f.offset, f.offset + f.length));
    }
    t += f.ms;
  }
  return (bytes: out.takeBytes(), startMs: startMs ?? 0);
}

Future<void> _splitStory(
  File file,
  String lang,
  String recording,
  String whisper,
  String model, {
  bool listenOnly = false,
}) async {
  final audio = File(recording);
  if (!audio.existsSync()) _fail('No recording $recording');
  final story = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final storyId = story['id'] as String;
  final nodes = (story['nodes'] as List).cast<Map<String, dynamic>>();
  final pages = [
    for (final n in nodes)
      if ((n['type'] ?? 'page') == 'page') n,
  ];
  final texts = [
    for (final p in pages) textWords((p['text'] as Map)[lang] as String),
  ];

  final bytes = audio.readAsBytesSync();
  final frames = mp3Frames(bytes);
  if (frames.isEmpty) _fail('$recording is not an MP3');
  final totalMs = frames.fold(0.0, (t, f) => t + f.ms).round();

  stdout.writeln('Listening to $recording (${_sec(totalMs)} s)...');
  final heard = await _hear(story, lang, audio, whisper, model);
  if (listenOnly) {
    stdout.writeln('  ${heard.length} words heard and kept for --split');
    return;
  }
  final spans = planPages(texts, heard);
  // Words heard after the last page (often its last words, misheard) belong
  // to it: nothing else follows them in the recording.
  final lastHeard = spans.nonNulls.map((s) => s.to).fold(-1, math.max);

  final dir = _storyDir(storyId, lang);
  Directory(dir).createSync(recursive: true);
  final clipEnd = <String, int>{};
  final timed = <String, List<Map<String, Object>>>{};
  for (final (k, page) in pages.indexed) {
    final id = page['id'] as String;
    final span = spans[k];
    if (span == null) {
      stdout.writeln('  ${id.padRight(9)} not in the recording (stays silent)');
      continue;
    }
    final said = heard.sublist(span.from, span.to + 1);
    final pairs = matchWords(texts[k], [for (final h in said) h.word]);
    final (from, to) = clipBounds(
      heard,
      span.from,
      span.to == lastHeard ? heard.length - 1 : span.to,
      totalMs,
      headMissed: span.from > 0 && pairs.first.$1 > 0,
      tailMissed: pairs.last.$1 < texts[k].length - 1,
    );
    final clip = mp3Slice(bytes, frames, from, to);
    File(pageClip(storyId, id, lang)).writeAsBytesSync(clip.bytes);
    final words = align(
      texts[k],
      said,
      until: math.max(said.last.end, to - 300),
    );
    timed[id] = words;
    clipEnd[id] = to;
    (page['words'] ??= <String, dynamic>{})[lang] = [
      for (final w in words)
        {
          ...w,
          'start': math.max(0, (w['start']! as int) - clip.startMs),
          'end': math.max(60, (w['end']! as int) - clip.startMs),
        },
    ];
    stdout.writeln(
      '  ${id.padRight(9)} ${span.matched}/${texts[k].length} words heard, '
      '${_sec(from)}-${_sec(to)} s',
    );
  }

  // The question that ends the page before a Choice Moment is also the
  // choice's own clip.
  for (final choice in nodes.where((n) => n['type'] == 'choice')) {
    final before = pages.where((p) => p['next'] == choice['id']).firstOrNull;
    final words = timed[before?['id']];
    if (before == null || words == null) continue;
    final prompt = textWords((choice['prompt'] as Map)[lang] as String);
    final tail = words.length - prompt.length;
    if (tail <= 0) continue;
    var same = true;
    for (var i = 0; i < prompt.length; i++) {
      same &= matchKey(prompt[i]) == matchKey(words[tail + i]['w']! as String);
    }
    if (!same) continue;
    final s = words[tail]['start']! as int;
    final from = math.max(s - 250, ((words[tail - 1]['end']! as int) + s) ~/ 2);
    final to = clipEnd[before['id']]!;
    final clip = mp3Slice(bytes, frames, from, to);
    File('$dir/${choice['id']}.mp3').writeAsBytesSync(clip.bytes);
    stdout.writeln(
      '  ${'${choice['id']}'.padRight(9)} the question, '
      '${_sec(from)}-${_sec(to)} s',
    );
  }

  file.writeAsStringSync('${prettyJson(story)}\n');
  stdout.writeln('${file.path}: ${timed.length} of ${pages.length} pages');
}

/// What Whisper heard in a whole-story [audio]. It is kept, so running again
/// after a change to the story text or this tool takes seconds instead of
/// minutes.
Future<List<Heard>> _hear(
  Map<String, dynamic> story,
  String lang,
  File audio,
  String whisper,
  String model,
) async {
  final cache = File('build/align_cache/${story['id']}_$lang.json');
  if (cache.existsSync() &&
      cache.lastModifiedSync().isAfter(audio.lastModifiedSync())) {
    return [
      for (final h in jsonDecode(cache.readAsStringSync()) as List)
        (
          word: h['w'] as String,
          start: h['start'] as int,
          end: h['end'] as int,
        ),
    ];
  }
  final pages = [
    for (final n in (story['nodes'] as List).cast<Map<String, dynamic>>())
      if ((n['type'] ?? 'page') == 'page') n,
  ];
  final heard = await _transcribe(
    whisper,
    model,
    audio.path,
    lang,
    // The last page sets the script and names. Not the first: Whisper can
    // take a recording that opens with its prompt as already heard, skip
    // it, and restart its clock there.
    (pages.last['text'] as Map)[lang] as String,
  );
  cache
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(
      jsonEncode([
        for (final h in heard) {'w': h.word, 'start': h.start, 'end': h.end},
      ]),
    );
  return heard;
}

String _sec(int ms) => (ms / 1000).toStringAsFixed(1);

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
  bool check = false, force = false, listen = false;
  String? model, whisper, lang, split;
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
        case '--listen':
          o.listen = true;
        case '--model':
          o.model = value();
        case '--whisper':
          o.whisper = value();
        case '--split':
          o.split = value();
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
