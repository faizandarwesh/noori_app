import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../i18n/app_lang.dart';

enum Sfx {
  tap('tap'),
  pop('pop'),
  sparkle('sparkle'),
  chime('chime'),
  tryAgain('try_again'),
  chain('chain'),
  whoosh('whoosh'),
  page('page'),
  giggle('giggle'),
  boing('boing');

  const Sfx(this.file);
  final String file;
  String get asset => 'audio/sfx/$file.wav';
}

enum MusicTrack {
  day('audio/music/day_loop.wav'),
  bedtime('audio/music/bedtime_loop.wav');

  const MusicTrack(this.asset);
  final String asset;
}

/// A scene's ambient soundscape, looped under the narration.
enum Ambience {
  birds,
  river,
  wind,
  waves;

  String get asset => 'audio/ambient/$name.wav';

  static Ambience? parse(String? name) {
    for (final a in values) {
      if (a.name == name) return a;
    }
    return null;
  }
}

/// Owns every sound in the app: background music, the ambient soundscape,
/// sound effects and recorded voice (narration and Noori's lines). Music and
/// ambience duck while a voice plays.
///
/// Voices come only from bundled recordings. Text-to-speech survives solely
/// as the Word Jar's fallback for words that have no clip yet.
class AudioService {
  AudioService({this.enabled = true});

  /// False in widget tests, where no audio plugins exist.
  final bool enabled;

  static const _musicVolume = 0.3;
  static const _musicDucked = 0.07;
  static const _ambientVolume = 0.4;
  static const _ambientDucked = 0.12;
  static const _sfxVolume = 0.7;
  static const _sfxPoolSize = 4;

  /// Bedtime voices play a little slower.
  static const _bedtimeRate = 0.88;

  // Created lazily so nothing touches platform channels when disabled.
  late final _music = AudioPlayer(playerId: 'music');
  late final _ambient = AudioPlayer(playerId: 'ambient');
  late final _voice = AudioPlayer(playerId: 'voice');
  late final _sfxPool = List.generate(
    _sfxPoolSize,
    (i) => AudioPlayer(playerId: 'sfx$i'),
  );
  FlutterTts? _tts;

  int _nextSfx = 0;
  bool _soundOn = true;
  bool _musicOn = true;
  double _voiceRate = 1;
  MusicTrack? _track;
  Ambience? _ambience;
  Completer<void>? _speaking;
  bool _voicePaused = false;
  bool _initialised = false;
  Set<String> _bundled = const {};

  bool get soundOn => _soundOn;

  /// Playback rate of recorded voices (slower at bedtime).
  double get voiceRate => _voiceRate;

  Future<void> init() async {
    if (!enabled || _initialised) return;
    _initialised = true;
    await _guard(() async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _bundled = {
        for (final a in manifest.listAssets())
          if (a.startsWith('assets/audio/')) a.substring('assets/'.length),
      };
    });
    await _guard(() async {
      // Let music, ambience, SFX and voice mix instead of stealing focus.
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers)
            .build(),
      );
      // By default every player asks the platform for its position on every
      // frame while it plays. SFX players (SoundPool) never report that they
      // finished, so theirs never stopped, and each play added another
      // per-frame poll: the app slowed down story by story. Only the voice
      // needs positions (for karaoke), and the narrator fills in between
      // reports, so it polls on a timer.
      _music.positionUpdater = null;
      _ambient.positionUpdater = null;
      _voice.positionUpdater = TimerPositionUpdater(
        getPosition: _voice.getCurrentPosition,
        interval: const Duration(milliseconds: 200),
      );
      await _music.setReleaseMode(ReleaseMode.loop);
      await _ambient.setReleaseMode(ReleaseMode.loop);
      for (final p in _sfxPool) {
        p.positionUpdater = null;
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setReleaseMode(ReleaseMode.stop);
      }
    });
  }

  /// Whether a recording is bundled at [clip] (a path under assets/).
  bool hasClip(String clip) => enabled && _bundled.contains(clip);

  // ---- Settings ------------------------------------------------------------

  Future<void> setSoundOn(bool on) async {
    _soundOn = on;
    if (!on) {
      await stopNarration();
      await _guard(_music.pause);
      await _guard(_ambient.pause);
    } else {
      if (_track != null && _musicOn) await _guard(_music.resume);
      if (_ambience != null) await _guard(_ambient.resume);
    }
  }

  void setSlowNarration(bool slow) => _voiceRate = slow ? _bedtimeRate : 1;

  // ---- SFX -----------------------------------------------------------------

  Future<void> play(Sfx sfx) async {
    if (!enabled || !_soundOn) return;
    final player = _sfxPool[_nextSfx];
    _nextSfx = (_nextSfx + 1) % _sfxPoolSize;
    await _guard(() => player.play(AssetSource(sfx.asset), volume: _sfxVolume));
  }

  // ---- Music & ambience ----------------------------------------------------

  Future<void> playMusic(MusicTrack track) async {
    if (!enabled) return;
    _musicOn = true;
    if (_track == track) return;
    _track = track;
    if (!_soundOn) return;
    await _guard(() async {
      await _music.stop();
      await _music.play(
        AssetSource(track.asset),
        volume: _speaking == null ? _musicVolume : _musicDucked,
      );
    });
  }

  Future<void> stopMusic() async {
    _musicOn = false;
    _track = null;
    await _guard(_music.stop);
  }

  /// Loops [ambience] under everything; null fades it out.
  Future<void> playAmbient(Ambience? ambience) async {
    if (!enabled || _ambience == ambience) return;
    _ambience = ambience;
    await _guard(() async {
      await _ambient.stop();
      if (ambience == null || !_soundOn) return;
      await _ambient.play(
        AssetSource(ambience.asset),
        volume: _isDucked ? _ambientDucked : _ambientVolume,
      );
    });
  }

  bool get _isDucked => _speaking != null && !_voicePaused;

  Future<void> _applyDuck() async {
    final ducked = _isDucked;
    await _guard(() => _music.setVolume(ducked ? _musicDucked : _musicVolume));
    if (_ambience != null) {
      await _guard(
        () => _ambient.setVolume(ducked ? _ambientDucked : _ambientVolume),
      );
    }
  }

  // ---- Voice ---------------------------------------------------------------

  /// Plays the recording at [clip]. Returns false straight away if it isn't
  /// bundled (or sound is off); otherwise completes with true when it ends or
  /// is stopped. Playback starts at [from]; [onPosition] reports the
  /// position as it plays.
  Future<bool> playVoice(
    String clip, {
    Duration from = Duration.zero,
    void Function(Duration position)? onPosition,
  }) async {
    if (!enabled || !_soundOn || !hasClip(clip)) return false;
    await stopNarration();
    final done = _speaking = Completer<void>();
    _voicePaused = false;
    unawaited(_applyDuck());
    StreamSubscription<Duration>? pos;
    StreamSubscription<void>? end;
    await _guard(() async {
      pos = _voice.onPositionChanged.listen(onPosition);
      end = _voice.onPlayerComplete.listen((_) {
        if (identical(_speaking, done)) _finishSpeaking();
      });
      await _voice.setPlaybackRate(_voiceRate);
      if (from > Duration.zero) {
        await _voice.setSource(AssetSource(clip));
        await _voice.seek(from);
        await _voice.resume();
      } else {
        await _voice.play(AssetSource(clip));
      }
    });
    await done.future;
    await pos?.cancel();
    await end?.cancel();
    return true;
  }

  /// Plays [start]–[end] of [clip], e.g. one word of a page's narration.
  Future<bool> playVoiceSlice(String clip, Duration start, Duration end) async {
    if (!enabled || !_soundOn || !hasClip(clip) || end <= start) return false;
    await stopNarration();
    final done = _speaking = Completer<void>();
    _voicePaused = false;
    unawaited(_applyDuck());
    await _guard(() async {
      await _voice.setPlaybackRate(1);
      await _voice.setSource(AssetSource(clip));
      await _voice.seek(start);
      await _voice.resume();
    });
    // A little tail so the word's last sound isn't clipped.
    final stop = Timer(end - start + const Duration(milliseconds: 120), () {
      if (identical(_speaking, done)) unawaited(stopNarration());
    });
    await done.future;
    stop.cancel();
    return true;
  }

  /// Holds the current voice where it is (the reader's pause).
  Future<void> pauseVoice() async {
    if (_speaking == null || _voicePaused) return;
    _voicePaused = true;
    await _guard(_voice.pause);
    await _applyDuck();
  }

  Future<void> resumeVoice() async {
    if (_speaking == null || !_voicePaused) return;
    _voicePaused = false;
    await _applyDuck();
    await _guard(_voice.resume);
  }

  /// Word Jar only: says [text] with the device voice when a word has no
  /// recording yet.
  Future<void> speakWordFallback(String text, AppLang lang) async {
    if (!enabled || !_soundOn || text.trim().isEmpty) return;
    await stopNarration();
    final done = _speaking = Completer<void>();
    unawaited(_applyDuck());
    await _guard(() async {
      final tts = _tts ??= FlutterTts();
      await tts.awaitSpeakCompletion(true);
      await tts.setLanguage(lang.ttsLocale);
      await tts.setSpeechRate(0.42);
      await tts.setPitch(lang == AppLang.en ? 1.15 : 1.05);
      await tts.speak(text);
    });
    if (identical(_speaking, done)) _finishSpeaking();
    return done.future;
  }

  Future<void> stopNarration() async {
    if (_speaking == null) return;
    final tts = _tts;
    if (tts != null) await _guard(tts.stop);
    await _guard(_voice.stop);
    _finishSpeaking();
  }

  bool get isSpeaking => _speaking != null;

  void _finishSpeaking() {
    final c = _speaking;
    if (c == null) return;
    _speaking = null;
    _voicePaused = false;
    unawaited(_applyDuck());
    if (!c.isCompleted) c.complete();
  }

  // ---- Lifecycle -----------------------------------------------------------

  Future<void> pauseAll() async {
    await stopNarration();
    await _guard(_music.pause);
    await _guard(_ambient.pause);
  }

  Future<void> resumeMusic() async {
    if (!_soundOn) return;
    if (_track != null && _musicOn) await _guard(_music.resume);
    if (_ambience != null) await _guard(_ambient.resume);
  }

  Future<void> dispose() async {
    if (!enabled) return;
    final tts = _tts;
    if (tts != null) await _guard(tts.stop);
    for (final p in [_music, _ambient, _voice, ..._sfxPool]) {
      await _guard(p.dispose);
    }
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (!enabled) return;
    try {
      await action();
    } catch (e) {
      // Audio must never crash the app; a missing file is not fatal.
      debugPrint('AudioService: $e');
    }
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});
