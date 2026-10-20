// Synthesises Noori's sound effects, music loops and ambient soundscapes as
// WAV files.
// Everything is generated from scratch, so there are no licensing concerns.
//
//   dart run tool/gen_audio.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const sampleRate = 22050;
final _rand = math.Random(42);

void main() {
  final sfx = Directory('assets/audio/sfx')..createSync(recursive: true);
  final music = Directory('assets/audio/music')..createSync(recursive: true);

  _write('${sfx.path}/tap.wav', _tap());
  _write('${sfx.path}/pop.wav', _pop());
  _write('${sfx.path}/sparkle.wav', _sparkle());
  _write('${sfx.path}/chime.wav', _chime());
  _write('${sfx.path}/try_again.wav', _tryAgain());
  _write('${sfx.path}/chain.wav', _chain());
  _write('${sfx.path}/whoosh.wav', _whoosh());
  _write('${sfx.path}/page.wav', _page());
  _write('${music.path}/day_loop.wav', _dayLoop());
  _write('${music.path}/bedtime_loop.wav', _bedtimeLoop());
  // Generated last so the sounds above keep their exact random sequence.
  final ambient = Directory('assets/audio/ambient')
    ..createSync(recursive: true);
  _write('${ambient.path}/birds.wav', _birds());
  _write('${ambient.path}/river.wav', _river());
  _write('${ambient.path}/wind.wav', _wind());
  // Cast reactions in the story player, also last for the same reason.
  _write('${sfx.path}/giggle.wav', _giggle());
  _write('${sfx.path}/boing.wav', _boing());
  // The beach, also last for the same reason.
  _write('${ambient.path}/waves.wav', _waves());
  stdout.writeln('Audio written to assets/audio/');
}

// ---- Building blocks --------------------------------------------------------

Float64List _buffer(double seconds) =>
    Float64List((seconds * sampleRate).round());

/// Adds a tone. [freq] may vary over the note (t = seconds into the note).
/// With [wrap], samples past the end wrap to the start (seamless loops).
void _tone(
  Float64List buf,
  double start,
  double length, {
  required double Function(double t) freq,
  double amp = 0.3,
  double attack = 0.005,
  double decay = 0.2,
  List<double> partials = const [1],
  List<double> partialAmps = const [1],
  bool wrap = false,
}) {
  final s0 = (start * sampleRate).round();
  final n = (length * sampleRate).round();
  final phases = List<double>.filled(partials.length, 0);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final env =
        (t < attack ? t / attack : 1.0) *
        math.exp(-(t - attack).clamp(0, 1e9) / decay);
    final f = freq(t);
    var v = 0.0;
    for (var p = 0; p < partials.length; p++) {
      phases[p] += 2 * math.pi * f * partials[p] / sampleRate;
      v += math.sin(phases[p]) * partialAmps[p];
    }
    var idx = s0 + i;
    if (idx >= buf.length) {
      if (!wrap) break;
      idx %= buf.length;
    }
    buf[idx] += v * env * amp;
  }
}

/// Noise shaped by [env], smoothed by a one-pole low-pass at [cutoff](t).
void _noise(
  Float64List buf,
  double start,
  double length, {
  required double Function(double t) env,
  required double Function(double t) cutoff,
  double amp = 0.3,
  double highPass = 0,
}) {
  final s0 = (start * sampleRate).round();
  final n = (length * sampleRate).round();
  var lp = 0.0, hp = 0.0;
  for (var i = 0; i < n && s0 + i < buf.length; i++) {
    final t = i / sampleRate;
    final a = 1 - math.exp(-2 * math.pi * cutoff(t) / sampleRate);
    lp += (_rand.nextDouble() * 2 - 1 - lp) * a;
    var v = lp;
    if (highPass > 0) {
      final b = 1 - math.exp(-2 * math.pi * highPass / sampleRate);
      hp += (lp - hp) * b;
      v = lp - hp;
    }
    buf[s0 + i] += v * env(t) * amp;
  }
}

double Function(double) _const(double f) =>
    (_) => f;
double _note(int midi) => 440 * math.pow(2, (midi - 69) / 12).toDouble();

// Soft bell: fundamental plus gentle inharmonic partial.
const _bell = [1.0, 2.0, 2.76, 4.07];
const _bellAmps = [1.0, 0.35, 0.22, 0.08];
// Music-box pluck.
const _box = [1.0, 3.0, 5.2];
const _boxAmps = [1.0, 0.18, 0.06];

// ---- SFX --------------------------------------------------------------------

Float64List _tap() {
  final b = _buffer(0.09);
  _tone(
    b,
    0,
    0.09,
    freq: (t) => 700 + 3500 * t,
    amp: 0.45,
    attack: 0.002,
    decay: 0.022,
  );
  return b;
}

Float64List _pop() {
  final b = _buffer(0.16);
  _tone(
    b,
    0,
    0.16,
    freq: (t) => 300 * math.pow(5, t / 0.1).toDouble().clamp(300, 1500),
    amp: 0.45,
    attack: 0.002,
    decay: 0.04,
  );
  return b;
}

Float64List _sparkle() {
  final b = _buffer(1.1);
  const notes = [84, 88, 91, 96, 100];
  for (var i = 0; i < notes.length; i++) {
    _tone(
      b,
      i * 0.075,
      0.9,
      freq: _const(_note(notes[i])),
      amp: 0.16,
      decay: 0.28,
      partials: _bell,
      partialAmps: _bellAmps,
    );
  }
  return b;
}

Float64List _chime() {
  final b = _buffer(1.1);
  _tone(
    b,
    0,
    0.9,
    freq: _const(_note(79)),
    amp: 0.22,
    decay: 0.35,
    partials: _bell,
    partialAmps: _bellAmps,
  );
  _tone(
    b,
    0.13,
    0.95,
    freq: _const(_note(84)),
    amp: 0.24,
    decay: 0.4,
    partials: _bell,
    partialAmps: _bellAmps,
  );
  return b;
}

/// Gentle, never harsh: two soft falling notes with a little wobble.
Float64List _tryAgain() {
  final b = _buffer(0.6);
  _tone(
    b,
    0,
    0.3,
    freq: (t) => _note(76) * (1 + 0.01 * math.sin(t * 40)),
    amp: 0.22,
    attack: 0.02,
    decay: 0.12,
  );
  _tone(
    b,
    0.2,
    0.4,
    freq: (t) => _note(72) * (1 + 0.01 * math.sin(t * 40)),
    amp: 0.22,
    attack: 0.02,
    decay: 0.16,
  );
  return b;
}

Float64List _chain() {
  final b = _buffer(0.62);
  const hits = [0.0, 0.06, 0.14, 0.19, 0.28, 0.35, 0.44];
  for (final h in hits) {
    final detune = 1 + (_rand.nextDouble() - 0.5) * 0.08;
    _tone(
      b,
      h,
      0.12,
      freq: _const(2100 * detune),
      amp: 0.14,
      attack: 0.001,
      decay: 0.018,
      partials: const [1, 1.58, 2.24, 2.9],
      partialAmps: const [1, 0.8, 0.6, 0.4],
    );
    _noise(
      b,
      h,
      0.03,
      env: (t) => math.exp(-t / 0.008),
      cutoff: _const(7000),
      amp: 0.12,
      highPass: 2500,
    );
  }
  return b;
}

Float64List _whoosh() {
  final b = _buffer(0.5);
  _noise(
    b,
    0,
    0.5,
    env: (t) => math.pow(math.sin(math.pi * t / 0.5), 2).toDouble(),
    cutoff: (t) => 300 + 2500 * math.sin(math.pi * t / 0.5),
    amp: 0.5,
  );
  return b;
}

Float64List _page() {
  final b = _buffer(0.35);
  for (final (start, len) in const [(0.0, 0.12), (0.1, 0.22)]) {
    _noise(
      b,
      start,
      len,
      env: (t) => math.sin(math.pi * t / len) * math.exp(-t / 0.15),
      cutoff: _const(5000),
      amp: 0.35,
      highPass: 900,
    );
  }
  return b;
}

// ---- Music ------------------------------------------------------------------

/// Bright, soft jungle loop: C–Am–F–G, pentatonic plucked melody.
Float64List _dayLoop() {
  const bpm = 92.0;
  const beat = 60 / bpm;
  const bars = 8;
  final b = _buffer(bars * 4 * beat);

  const roots = [48, 45, 41, 43]; // C3 A2 F2 G2
  const chords = [
    [60, 64, 67],
    [57, 60, 64],
    [53, 57, 60],
    [55, 59, 62],
  ];
  // Scale degrees in C pentatonic, one per half-beat; -1 = rest.
  const melody = [
    72, -1, 76, 79, 76, -1, 74, 72, //
    69, -1, 72, 76, 74, -1, 72, -1,
    69, 72, 74, -1, 72, 69, 67, -1,
    67, -1, 71, 74, 72, -1, -1, -1,
    76, -1, 79, 81, 79, -1, 76, 74,
    72, -1, 76, 74, 72, -1, 69, -1,
    69, 72, 74, 76, 74, -1, 72, 69,
    67, -1, 74, -1, 72, -1, -1, -1,
  ];

  for (var bar = 0; bar < bars; bar++) {
    final c = bar % 4;
    final t0 = bar * 4 * beat;
    _tone(
      b,
      t0,
      4 * beat,
      freq: _const(_note(roots[c])),
      amp: 0.16,
      attack: 0.02,
      decay: 1.4,
      partials: const [1, 2],
      partialAmps: const [1, 0.25],
      wrap: true,
    );
    for (final n in chords[c]) {
      for (final off in const [1.0, 3.0]) {
        _tone(
          b,
          t0 + off * beat,
          1.6 * beat,
          freq: _const(_note(n)),
          amp: 0.045,
          attack: 0.03,
          decay: 0.5,
          wrap: true,
        );
      }
    }
    for (var i = 0; i < 8; i++) {
      final m = melody[bar * 8 + i];
      if (m < 0) continue;
      _tone(
        b,
        t0 + i * beat / 2,
        1.2,
        freq: _const(_note(m)),
        amp: 0.09,
        attack: 0.004,
        decay: 0.3,
        partials: _box,
        partialAmps: _boxAmps,
        wrap: true,
      );
    }
  }
  return _normalise(b, 0.6);
}

/// Slow music-box lullaby for bedtime.
Float64List _bedtimeLoop() {
  const bpm = 62.0;
  const beat = 60 / bpm;
  const bars = 4;
  final b = _buffer(bars * 4 * beat);

  const roots = [48, 45, 41, 43];
  const melody = [
    [79, 76, 72, 76],
    [74, 72, 69, 72],
    [72, 69, 65, 69],
    [71, 74, 72, -1],
  ];
  for (var bar = 0; bar < bars; bar++) {
    final t0 = bar * 4 * beat;
    _tone(
      b,
      t0,
      4 * beat,
      freq: _const(_note(roots[bar])),
      amp: 0.12,
      attack: 0.3,
      decay: 2.5,
      wrap: true,
    );
    _tone(
      b,
      t0 + 2 * beat,
      2 * beat,
      freq: _const(_note(roots[bar] + 7)),
      amp: 0.06,
      attack: 0.3,
      decay: 1.5,
      wrap: true,
    );
    for (var i = 0; i < 4; i++) {
      final m = melody[bar][i];
      if (m < 0) continue;
      _tone(
        b,
        t0 + i * beat,
        2.0,
        freq: _const(_note(m)),
        amp: 0.1,
        attack: 0.004,
        decay: 0.7,
        partials: _box,
        partialAmps: _boxAmps,
        wrap: true,
      );
    }
  }
  return _normalise(b, 0.5);
}

// ---- Ambient soundscapes ----------------------------------------------------
// Each is built a little longer than the loop, then the tail is crossfaded
// into the head so the loop point is inaudible. Slow modulations use periods
// that divide the loop length.

const _ambientLoop = 12.0;
const _ambientFade = 1.5;

Float64List _loopify(Float64List b) {
  final n = (_ambientLoop * sampleRate).round();
  final f = (_ambientFade * sampleRate).round();
  final out = Float64List(n);
  for (var i = 0; i < n; i++) {
    out[i] = b[i];
  }
  for (var i = 0; i < f; i++) {
    final x = i / f;
    // Equal-power crossfade of the overhang into the start.
    out[i] =
        b[i] * math.sin(x * math.pi / 2) + b[n + i] * math.cos(x * math.pi / 2);
  }
  return out;
}

Float64List _ambientBuffer() => _buffer(_ambientLoop + _ambientFade);

double _wave(double t, double period, [double phase = 0]) =>
    math.sin(2 * math.pi * t / period + phase) * 0.5 + 0.5;

/// Leaves rustling under scattered little bird calls.
Float64List _birds() {
  final b = _ambientBuffer();
  _noise(
    b,
    0,
    _ambientLoop + _ambientFade,
    env: (t) => 0.5 + 0.5 * _wave(t, 6),
    cutoff: (t) => 2600,
    highPass: 900,
    amp: 0.05,
  );
  final loop = _buffer(_ambientLoop);
  var t = 0.4;
  while (t < _ambientLoop - 0.3) {
    final base = 2300 + _rand.nextDouble() * 1600;
    final notes = 2 + _rand.nextInt(4);
    final rise = _rand.nextBool();
    for (var i = 0; i < notes; i++) {
      final f0 = base * (1 + (rise ? 0.06 : -0.05) * i);
      _tone(
        loop,
        t + i * 0.11,
        0.09,
        freq: (x) => f0 + 900 * math.sin(x / 0.09 * math.pi),
        amp: 0.11,
        attack: 0.006,
        decay: 0.035,
        wrap: true,
      );
    }
    t += 0.7 + _rand.nextDouble() * 1.6;
  }
  final out = _loopify(b);
  for (var i = 0; i < out.length; i++) {
    out[i] += loop[i];
  }
  return _normalise(out, 0.45);
}

/// A gentle stream: filtered rushing water with soft bubbles.
Float64List _river() {
  final b = _ambientBuffer();
  _noise(
    b,
    0,
    _ambientLoop + _ambientFade,
    env: (t) => 0.75 + 0.25 * _wave(t, 4) * _wave(t, 3, 1),
    cutoff: (t) => 900 + 500 * _wave(t, 6),
    highPass: 180,
    amp: 0.35,
  );
  final bubbles = _buffer(_ambientLoop);
  var t = 0.2;
  while (t < _ambientLoop) {
    final f0 = 380 + _rand.nextDouble() * 520;
    _tone(
      bubbles,
      t,
      0.07,
      freq: (x) => f0 * (1 + x * 9),
      amp: 0.05 + _rand.nextDouble() * 0.05,
      attack: 0.004,
      decay: 0.025,
      wrap: true,
    );
    t += 0.12 + _rand.nextDouble() * 0.45;
  }
  final out = _loopify(b);
  for (var i = 0; i < out.length; i++) {
    out[i] += bubbles[i];
  }
  return _normalise(out, 0.4);
}

/// Soft wind through grass, swelling and settling.
Float64List _wind() {
  final b = _ambientBuffer();
  _noise(
    b,
    0,
    _ambientLoop + _ambientFade,
    env: (t) => 0.35 + 0.65 * _wave(t, 12) * (0.7 + 0.3 * _wave(t, 4, 2)),
    cutoff: (t) => 240 + 420 * _wave(t, 6, 1),
    highPass: 60,
    amp: 0.6,
  );
  return _normalise(_loopify(b), 0.4);
}

/// Waves rolling onto a beach: a surge and a long hiss every four seconds,
/// over a soft steady sea.
Float64List _waves() {
  final b = _ambientBuffer();
  // Each wave swells, breaks, then drains back down the sand.
  double surge(double t) {
    final x = (t % 4) / 4;
    return x < 0.3
        ? math.pow(x / 0.3, 2).toDouble()
        : math.pow(1 - (x - 0.3) / 0.7, 1.6).toDouble();
  }

  _noise(
    b,
    0,
    _ambientLoop + _ambientFade,
    env: (t) => 0.18 + 0.82 * surge(t) * (0.8 + 0.2 * _wave(t, 12)),
    cutoff: (t) => 500 + 1700 * surge(t),
    highPass: 90,
    amp: 0.55,
  );
  return _normalise(_loopify(b), 0.4);
}

// ---- Cast reactions ---------------------------------------------------------

/// A tiny "hee-hee-hee": quick bright chirps that wobble up then down.
Float64List _giggle() {
  final b = _buffer(0.62);
  const notes = [1180.0, 1320.0, 1260.0, 1120.0];
  for (var i = 0; i < notes.length; i++) {
    final f0 = notes[i];
    _tone(
      b,
      0.02 + i * 0.13,
      0.12,
      freq: (t) => f0 * (1 + 0.08 * math.sin(t * 2 * math.pi * 28)) + 900 * t,
      amp: 0.32,
      attack: 0.006,
      decay: 0.05,
      partials: const [1, 2, 3],
      partialAmps: const [1, 0.3, 0.1],
    );
  }
  return _normalise(b, 0.6);
}

/// A springy "boing": a low note that swoops up with a fading wobble.
Float64List _boing() {
  final b = _buffer(0.5);
  _tone(
    b,
    0,
    0.5,
    freq: (t) =>
        (190 + 260 * (1 - math.exp(-t * 14))) *
        (1 + 0.06 * math.sin(t * 2 * math.pi * 16) * math.exp(-t * 4)),
    amp: 0.5,
    attack: 0.004,
    decay: 0.16,
    partials: const [1, 2],
    partialAmps: const [1, 0.25],
  );
  return _normalise(b, 0.6);
}

Float64List _normalise(Float64List b, double peak) {
  var max = 0.0;
  for (final v in b) {
    max = math.max(max, v.abs());
  }
  if (max == 0) return b;
  for (var i = 0; i < b.length; i++) {
    b[i] = b[i] / max * peak;
  }
  return b;
}

// ---- WAV --------------------------------------------------------------------

void _write(String path, Float64List samples) {
  final data = ByteData(44 + samples.length * 2);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  data
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little) // PCM
    ..setUint16(22, 1, Endian.little) // mono
    ..setUint32(24, sampleRate, Endian.little)
    ..setUint32(28, sampleRate * 2, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little);
  str(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final v = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    data.setInt16(44 + i * 2, v, Endian.little);
  }
  File(path).writeAsBytesSync(data.buffer.asUint8List());
}
