import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/audio/voice_clips.dart';
import '../../../core/content/story.dart';
import '../../../core/i18n/app_lang.dart';
import 'read_chunks.dart';

/// Plays a page's recorded narration and tracks which chunk to highlight.
///
/// Timing comes from the page's Whisper word timestamps. Between the
/// player's position reports (every ~200ms on Android) the position is
/// extrapolated, so the highlight moves exactly on each word. A page with no
/// recording yet plays as a silent read-along on estimated timings, so the
/// story still flows while audio is being produced.
class Narrator extends ChangeNotifier {
  Narrator(this._audio);

  final AudioService _audio;

  static const _tick = Duration(milliseconds: 30);

  /// Silence after the last word before a silent read-along counts as done.
  static const _silentTail = 400;

  List<ReadChunk> _chunks = const [];
  List<WordTiming> _timings = const [];

  /// Index into [_chunks] of each timed word.
  List<int> _wordChunks = const [];
  int? _active;
  bool _playing = false;
  bool _paused = false;
  int _session = 0;

  // Playback clock: last reported position plus time since, at [_rate].
  // clock.stopwatch() so widget tests' fake time drives it too.
  final _sinceAnchor = clock.stopwatch();
  int _anchorMs = 0;
  double _rate = 1;
  Timer? _ticker;
  Completer<bool>? _silentDone;
  final _listened = clock.stopwatch();

  List<ReadChunk> get chunks => _chunks;
  int? get active => _active;
  bool get playing => _playing && !_paused;
  bool get paused => _paused;

  /// Time spent actually narrating since the last call; resets it.
  Duration takeListened() {
    final d = _listened.elapsed;
    _listened.reset();
    return d;
  }

  /// The timing of chunk [i], if it is a timed word.
  WordTiming? timingOf(int i) {
    final k = _wordChunks.indexOf(i);
    return k < 0 || k >= _timings.length ? null : _timings[k];
  }

  /// Shows [text] without reading it.
  void load(String text) {
    stop();
    _chunks = splitChunks(text);
    _active = null;
    notifyListeners();
  }

  /// Reads [page] in [lang], starting [from] into the narration. Completes
  /// with true if the page was read to the end, false if it was stopped.
  Future<bool> play(
    String storyId,
    StoryPage page,
    AppLang lang, {
    bool slow = false,
    Duration from = Duration.zero,
  }) async {
    stop();
    final session = ++_session;
    _chunks = splitChunks(page.text.of(lang));
    _wordChunks = [
      for (var i = 0; i < _chunks.length; i++)
        if (_chunks[i].hasWord) i,
    ];
    final recorded = page.words[lang];
    _timings = recorded != null && recorded.isNotEmpty
        ? recorded
        : estimateTimings(_chunks, lang, slow: slow);
    if (_chunks.isEmpty) return true;

    _playing = true;
    _paused = false;
    _active = null;
    _anchorMs = from.inMilliseconds;
    _sinceAnchor
      ..reset()
      ..start();
    _listened.start();
    _ticker = Timer.periodic(_tick, (_) => _onTick(session));
    notifyListeners();

    final clip = VoiceClips.page(storyId, page.id, lang);
    bool finished;
    if (_audio.hasClip(clip)) {
      _rate = _audio.voiceRate;
      await _audio.playVoice(
        clip,
        from: from,
        onPosition: (pos) {
          if (session != _session) return;
          _anchorMs = pos.inMilliseconds;
          _sinceAnchor.reset();
        },
      );
      finished = session == _session;
    } else {
      // Silent read-along: the estimate already includes bedtime slowness.
      _rate = 1;
      final done = _silentDone = Completer<bool>();
      finished = await done.future;
    }

    if (session == _session) {
      _end();
      notifyListeners();
    }
    return finished;
  }

  int get _positionMs =>
      _anchorMs + (_sinceAnchor.elapsedMilliseconds * _rate).round();

  void _onTick(int session) {
    if (session != _session || _paused) return;
    final pos = _positionMs;
    var k = -1;
    for (var i = 0; i < _timings.length; i++) {
      if (_timings[i].start <= pos) k = i;
    }
    if (k >= 0 && k < _wordChunks.length) _highlight(_wordChunks[k]);

    final done = _silentDone;
    if (done != null &&
        !done.isCompleted &&
        (_timings.isEmpty || pos >= _timings.last.end + _silentTail)) {
      done.complete(true);
    }
  }

  void pause() {
    if (!_playing || _paused) return;
    _paused = true;
    _sinceAnchor.stop();
    _listened.stop();
    unawaited(_audio.pauseVoice());
    notifyListeners();
  }

  void resume() {
    if (!_playing || !_paused) return;
    _paused = false;
    _sinceAnchor.start();
    _listened.start();
    unawaited(_audio.resumeVoice());
    notifyListeners();
  }

  /// Lights up one chunk without reading, e.g. a word the child tapped.
  void spotlight(int i) => _highlight(i);

  void _highlight(int i) {
    if (_active == i) return;
    _active = i;
    notifyListeners();
  }

  void _end() {
    _ticker?.cancel();
    _ticker = null;
    _sinceAnchor.stop();
    _listened.stop();
    _playing = false;
    _paused = false;
    _active = null;
  }

  /// Stops reading.
  void stop() {
    _session++;
    final done = _silentDone;
    _silentDone = null;
    if (done != null && !done.isCompleted) done.complete(false);
    if (_playing) {
      _end();
      unawaited(_audio.stopNarration());
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  /// Timings for a page with no recording, paced by word length.
  @visibleForTesting
  static List<WordTiming> estimateTimings(
    List<ReadChunk> chunks,
    AppLang lang, {
    required bool slow,
  }) {
    var t = 300;
    return [
      for (final c in chunks)
        if (c.hasWord)
          () {
            final d = estimateFor(c, lang, slow: slow).inMilliseconds;
            final w = WordTiming(word: c.text, start: t, end: t + d);
            t += d;
            return w;
          }(),
    ];
  }

  /// How long a chunk takes to say at a child-friendly pace.
  @visibleForTesting
  static Duration estimateFor(ReadChunk c, AppLang lang, {required bool slow}) {
    final letters = c.text
        .replaceAll(RegExp(r'[^\p{L}]', unicode: true), '')
        .length;
    final pause = RegExp(r'[.!?۔؟]').hasMatch(c.text) ? 280 : 0;
    final base = lang == AppLang.en ? 200 + 55 * letters : 240 + 65 * letters;
    return Duration(milliseconds: ((base + pause) * (slow ? 1.35 : 1)).round());
  }
}
