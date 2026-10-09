import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/voice_clips.dart';
import '../../core/content/scenes.dart';
import '../../core/content/story.dart';
import '../../core/i18n/app_lang.dart';
import '../../core/mascot/noori_guide.dart';
import '../../core/mascot/noori_mascot.dart';
import '../../core/progress/progress.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/firefly_layer.dart';
import '../../core/widgets/guide_hint.dart';
import '../../core/widgets/puffy_button.dart';
import 'karaoke/narrator.dart';
import 'widgets/camera.dart';
import 'widgets/choice_view.dart';
import 'widgets/help_moment.dart';
import 'widgets/story_hero.dart';
import 'widgets/story_scene.dart';
import 'widgets/subtitle_strip.dart';
import 'widgets/tap_sparkle.dart';
import 'widgets/word_popup.dart';

/// Plays a story like a cartoon. Each page is a scene with a slow camera
/// move; its narration plays with karaoke subtitles, and ~1.2s after it ends
/// the camera cuts to the next scene. Nothing needs a tap: the story only
/// waits at the Choice Moment and at a page's tap-to-help moment (the
/// child pours the water, cuts the mango), then carries on by itself.
///
/// Children tap everything, so taps never stop the cartoon: characters and
/// props react, empty scenery sparkles, and hidden surprises (a frog under
/// a leaf) come alive. Pausing is the small pause button (or a two-finger
/// tap), and a big play button resumes. Swiping to skip is off unless a
/// grown-up enables it in Settings. The corner button flips the language.
/// Noori stays silent until the Choice Moment.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.storyId});

  final String storyId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  static const _theEnd = LocalizedText(en: 'The End', ur: 'ختم شد');
  static const _swipeVelocity = 280.0;

  /// A skip swipe must travel this share of the screen width.
  static const _swipeDistance = 0.35;
  static const _castReaction = Duration(milliseconds: 450);

  final _guide = NooriGuideController();
  late final AudioService _audio;
  late final Narrator _narrator;
  late final AppLifecycleListener _lifecycle;

  Story? _story;
  Scenes? _scenes;
  bool _missing = false;
  String? _nodeId;
  final _history = <String>[];
  late AppLang _lang;

  /// The opening scene arrived from its Home card: it stays put (no
  /// walk-ins) and its narration waits for the flight to land.
  bool _heroArrival = true;
  SceneMove _move = SceneMove.dissolve;
  int _shot = 0;

  bool _paused = false;

  /// The page's narration was cut off while paused; resuming starts it over.
  bool _replayOnResume = false;

  /// Narration finished during a pause; resuming moves on.
  bool _advanceOnResume = false;
  Timer? _gap;
  Timer? _startNarration;

  String? _chosen;
  bool _ending = false;

  /// Bumped per cast member as narration reaches their word.
  final _cues = ValueNotifier<List<int>>(const []);
  int? _cuedChunk;

  ({int chunk, String word, String? meaning, GlossaryEntry? entry})? _popup;
  Timer? _popupTimer;
  bool _resumeAfterPopup = false;

  /// Sparkles from taps on empty scenery, by id.
  final _sparkles = <int, Offset>{};
  int _sparkleId = 0;

  /// Cast members still mid-reaction to a tap.
  final _castBusy = <int>{};

  /// The page's tap-to-help moment. It is set up once per page, so a
  /// language flip keeps what the child has already done.
  final _help = HelpController();
  String? _helpPageId;
  bool _helpWaiting = false;
  bool _helpCelebrated = false;
  Timer? _helpGiveUp;
  Timer? _afterHelp;

  /// A child who never manages it isn't stuck: the story helps itself.
  static const _helpPatience = Duration(seconds: 45);
  final _stackKey = GlobalKey();
  final _pointers = <int>{};
  bool _twoFingerUsed = false;
  double _dragDx = 0;

  @override
  void initState() {
    super.initState();
    // Eager, so dispose() never has to touch ref.
    _audio = ref.read(audioServiceProvider);
    _narrator = Narrator(_audio)..addListener(_onWord);
    _lang = ref.read(appSettingsProvider).lang;
    _lifecycle = AppLifecycleListener(onHide: _onHide);
    _help
      ..onStep = _onHelpStep
      ..addListener(_onHelpChanged);
    // Home preloads the story so the hero has its scene on the first frame.
    final story = ref.read(storyProvider(widget.storyId)).value;
    final scenes = ref.read(scenesProvider).value;
    if (story != null && scenes != null) {
      _begin(story, scenes);
    } else {
      _heroArrival = false;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final story = await ref.read(storyProvider(widget.storyId).future);
      final scenes = await ref.read(scenesProvider.future);
      if (mounted) setState(() => _begin(story, scenes));
    } catch (_) {
      if (mounted) setState(() => _missing = true);
    }
  }

  void _begin(Story story, Scenes scenes) {
    _story = story;
    _scenes = scenes;
    _nodeId = story.start;
    _enterNode(
      delay: _heroArrival
          ? AppMotion.heroFlight + const Duration(milliseconds: 250)
          : AppMotion.entrance,
    );
  }

  // ---- Where we are --------------------------------------------------------

  StoryNode? get _node {
    final id = _nodeId, story = _story;
    if (id == null || story == null) return null;
    return story.node(id);
  }

  StoryPage? get _page => switch (_node) {
    final StoryPage p => p,
    _ => null,
  };

  ChoiceNode? get _choice => switch (_node) {
    final ChoiceNode c => c,
    _ => null,
  };

  /// The scene behind the Choice Moment: the last page shown.
  StoryPage? get _backdropPage {
    for (final id in _history.reversed) {
      final n = _story!.node(id);
      if (n is StoryPage) return n;
    }
    return null;
  }

  int get _pagesRead =>
      _history.where((id) => _story!.node(id) is StoryPage).length;

  // ---- Flow ----------------------------------------------------------------

  /// Sets up the current node: its soundscape, subtitles and, after
  /// [delay] (so the camera cut lands first), its narration or question.
  void _enterNode({Duration delay = Duration.zero}) {
    _gap?.cancel();
    _startNarration?.cancel();
    _afterHelp?.cancel();
    _helpGiveUp?.cancel();
    _narrator.stop();
    _replayOnResume = false;
    _advanceOnResume = false;
    _cuedChunk = null;
    final page = _page;
    final scenePage = page ?? _backdropPage;
    if (page?.id != _helpPageId) {
      _helpPageId = page?.id;
      _helpCelebrated = false;
      _help.load(page?.help);
    }
    _cues.value = List.filled(scenePage?.cast.length ?? 0, 0);
    _narrator.load(page?.text.of(_lang) ?? '');
    final scene = scenePage == null ? null : _scenes?[scenePage.scene];
    _audio.playAmbient(Ambience.parse(scene?.ambient));

    _startNarration = Timer(delay, () {
      if (!mounted) return;
      if (_page != null) {
        if (_helpFirst) {
          _beginHelp();
        } else if (_paused) {
          _replayOnResume = true;
        } else {
          _narrate();
        }
      } else if (_choice != null) {
        _askChoice();
      }
    });
  }

  Future<void> _narrate({Duration from = Duration.zero}) async {
    final page = _page;
    if (page == null || !mounted) return;
    final nodeId = _nodeId;
    final finished = await _narrator.play(
      widget.storyId,
      page,
      _lang,
      slow: ref.read(appSettingsProvider).bedtime,
      from: from,
    );
    if (!mounted) return;
    ref.read(progressProvider.notifier).addListening(_narrator.takeListened());
    if (!finished || _nodeId != nodeId) return;
    if (_paused) {
      // The app went to the background mid-page; start it over on resume.
      _replayOnResume = true;
      return;
    }
    if (_help.moment != null && !_help.done) {
      // Now the child does what the narration just told.
      _beginHelp();
      return;
    }
    _gap = Timer(AppMotion.sceneGap, _autoAdvance);
  }

  // ---- Tap-to-help ---------------------------------------------------------

  /// The child helps before this page's narration (and hasn't yet).
  bool get _helpFirst {
    final m = _help.moment;
    return m != null && m.beforeNarration && !_help.done;
  }

  void _beginHelp() {
    if (_help.done || _ending) return;
    _help.begin();
    _helpGiveUp?.cancel();
    _helpGiveUp = Timer(_helpPatience, _help.complete);
  }

  void _onHelpStep() {
    _audio.play(Sfx.pop);
    _helpGiveUp?.cancel();
    _helpGiveUp = Timer(_helpPatience, _help.complete);
  }

  void _onHelpChanged() {
    if (!mounted) return;
    if (_help.active != _helpWaiting) {
      setState(() => _helpWaiting = _help.active);
    }
    if (!_help.done || _helpCelebrated) return;
    _helpCelebrated = true;
    _helpGiveUp?.cancel();
    _audio
      ..play(Sfx.sparkle)
      ..play(Sfx.chime);
    final page = _page;
    _afterHelp = Timer(_helpCelebration, () {
      if (!mounted || _page != page) return;
      final before = page?.help?.beforeNarration ?? false;
      if (_paused) {
        before ? _replayOnResume = true : _advanceOnResume = true;
      } else if (before) {
        _narrate();
      } else {
        _autoAdvance();
      }
    });
  }

  static const _helpCelebration = Duration(milliseconds: 1600);

  void _autoAdvance() {
    if (!mounted) return;
    if (_paused) {
      _advanceOnResume = true;
      return;
    }
    final next = _page?.next;
    if (next == null) {
      _finish();
    } else {
      _goTo(next, _shot.isEven ? SceneMove.panForward : SceneMove.dissolve);
    }
  }

  void _goTo(String id, SceneMove move) {
    setState(() {
      _history.add(_nodeId!);
      _nodeId = id;
      _move = move;
      _shot++;
      _heroArrival = false;
      _paused = false;
    });
    _enterNode(delay: AppMotion.sceneChange * 0.6);
  }

  void _skipForward() {
    final page = _page;
    if (page == null || _ending || _chosen != null) return;
    _audio.play(Sfx.whoosh);
    final next = page.next;
    if (next == null) {
      _narrator.stop();
      _finish();
    } else {
      _goTo(next, SceneMove.panForward);
    }
  }

  void _skipBack() {
    if (_history.isEmpty || _ending || _chosen != null) return;
    _audio.play(Sfx.whoosh);
    setState(() {
      _nodeId = _history.removeLast();
      _move = SceneMove.panBack;
      _shot++;
      _heroArrival = false;
      _paused = false;
    });
    _enterNode(delay: AppMotion.sceneChange * 0.6);
  }

  void _onDragStart(DragStartDetails _) => _dragDx = 0;

  void _onDragUpdate(DragUpdateDetails d) => _dragDx += d.primaryDelta ?? 0;

  /// Only a long, deliberate swipe skips a scene; a stray drag by a little
  /// hand does nothing. (Grown-ups switch swiping on in Settings.)
  void _onSwipe(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    final width = MediaQuery.sizeOf(context).width;
    if (_dragDx.abs() < width * _swipeDistance || v.abs() < _swipeVelocity) {
      return;
    }
    // Swiping towards the reading direction's start moves on.
    final forward = _lang.isRtl ? _dragDx > 0 : _dragDx < 0;
    forward ? _skipForward() : _skipBack();
  }

  // ---- Touching the scene --------------------------------------------------

  /// A tap on a cast member makes it act, and the story keeps playing:
  /// characters hop with a giggle (or say hello, once recorded), props
  /// wiggle with a boing.
  void _tapCast(int index) {
    final page = _page;
    if (page == null || index >= page.cast.length || _ending) return;
    if (!_castBusy.add(index)) return; // Let each reaction finish first.
    Timer(_castReaction, () => _castBusy.remove(index));
    final cues = [..._cues.value];
    if (index < cues.length) {
      cues[index]++;
      _cues.value = cues;
    }
    HapticFeedback.lightImpact();
    final art = page.cast[index].art;
    if (!art.isCharacter) {
      _audio.play(Sfx.boing);
      return;
    }
    // A recorded hello, but never over the narration.
    final hello = VoiceClips.name(widget.storyId, art.id, _lang);
    if (!_narrator.playing && _audio.hasClip(hello)) {
      _audio.playVoice(hello);
    } else {
      _audio.play(Sfx.giggle);
    }
  }

  /// A tap on empty scenery answers with a sparkle (and closes an open word
  /// card). It never pauses: that's the pause button's job.
  void _tapScenery(TapUpDetails d) {
    if (_popup != null) {
      _closePopup();
      return;
    }
    if (_ending) return;
    final id = _sparkleId++;
    setState(() => _sparkles[id] = d.localPosition);
    _audio.play(Sfx.tap);
  }

  /// A hidden surprise was found: a little shower of sparkles there.
  void _foundSecret(Offset global) {
    _audio.play(Sfx.sparkle);
    HapticFeedback.lightImpact();
    _sparkleAt(global, burst: 3);
  }

  /// Rubbing the help item twinkles under the finger.
  void _helpRub(Offset global) {
    _audio.play(Sfx.tap);
    _sparkleAt(global);
  }

  void _sparkleAt(Offset global, {int burst = 1}) {
    final box = _stackKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !mounted) return;
    final at = box.globalToLocal(global);
    setState(() {
      for (var k = 0; k < burst; k++) {
        _sparkles[_sparkleId++] = at + Offset((k - 1) * 22.0, (k % 2) * -18.0);
      }
    });
  }

  /// Two fingers down at once pauses or resumes, a grown-up shortcut.
  void _onPointerDown(PointerDownEvent e) {
    _pointers.add(e.pointer);
    if (_pointers.length == 2 && !_twoFingerUsed) {
      _twoFingerUsed = true;
      _togglePause();
    }
  }

  void _onPointerUp(PointerEvent e) {
    _pointers.remove(e.pointer);
    if (_pointers.isEmpty) _twoFingerUsed = false;
  }

  /// The Choice Moment: one of the few times Noori speaks.
  void _askChoice() {
    final choice = _choice;
    if (choice == null) return;
    final storyId = widget.storyId;
    _guide.sayAll([
      GuideLine('choice_ask', lang: _lang),
      GuideLine.text(
        choice.prompt,
        lang: _lang,
        clip: (l) => VoiceClips.choice(storyId, choice.id, l),
      ),
    ]);
  }

  /// The child picked a card: celebrate, then the story carries on.
  Future<void> _pick(ChoiceOption option) async {
    if (_chosen != null) return;
    _audio
      ..stopNarration()
      ..play(Sfx.sparkle);
    setState(() => _chosen = option.id);
    _guide.setMood(NooriState.happy);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    _guide.setMood(null);
    _goTo(option.next, SceneMove.dissolve);
    _chosen = null;
  }

  Future<void> _finish() async {
    if (_ending) return;
    setState(() => _ending = true);
    _audio
      ..play(Sfx.sparkle)
      ..playAmbient(null);
    await Future<void>.delayed(const Duration(milliseconds: 2400));
    if (mounted) context.pushReplacement(Routes.quiz(widget.storyId));
  }

  // ---- Pause ---------------------------------------------------------------

  void _togglePause() {
    if (_popup != null) {
      _closePopup();
      return;
    }
    if (_ending || _page == null) return;
    _paused ? _resume() : _pause();
  }

  void _pause() {
    if (_paused) return;
    setState(() => _paused = true);
    _narrator.pause();
    if (_gap?.isActive ?? false) {
      _gap!.cancel();
      _advanceOnResume = true;
    }
  }

  void _resume() {
    if (!_paused) return;
    setState(() => _paused = false);
    _audio.play(Sfx.pop);
    // The story is waiting for the child's help: nothing to resume yet.
    if (_help.active) return;
    if (_advanceOnResume) {
      _advanceOnResume = false;
      _gap = Timer(AppMotion.sceneGap * 0.5, _autoAdvance);
    } else if (_replayOnResume) {
      _replayOnResume = false;
      _narrate();
    } else if (_narrator.paused) {
      _narrator.resume();
    } else if (!_narrator.playing && !(_startNarration?.isActive ?? false)) {
      _narrate();
    }
  }

  void _onHide() {
    if (_page != null && !_ending) _pause();
  }

  // ---- Language flip -------------------------------------------------------

  void _flipLanguage() {
    if (_node == null || _ending || _chosen != null) return;
    _closePopup(resume: false);
    _audio.play(Sfx.whoosh);
    setState(() => _lang = _lang.other);
    _enterNode(delay: const Duration(milliseconds: 350));
  }

  // ---- Tap-a-word ----------------------------------------------------------

  void _tapWord(int index) {
    final story = _story;
    final page = _page;
    if (story == null || page == null) return;
    _resumeAfterPopup = !_paused;
    final timing = _narrator.timingOf(index);
    _narrator
      ..stop()
      ..spotlight(index);
    _gap?.cancel();
    final raw = _narrator.chunks[index].text;
    final word = raw.replaceAll(RegExp(r"[^\p{L}\p{M}'’]", unicode: true), '');
    final entry = story.lookup(word, _lang);
    _audio.play(Sfx.pop);
    setState(
      () => _popup = (
        chunk: index,
        word: word,
        meaning: entry?.word.of(_lang.other),
        entry: entry,
      ),
    );
    _speakWord(index, timing, entry, _lang);
    _popupTimer?.cancel();
    _popupTimer = Timer(const Duration(seconds: 5), _closePopup);
  }

  /// Plays a tapped word in the narrator's own voice: its slice of the
  /// page recording, or else its recorded glossary clip.
  void _speakWord(
    int index,
    WordTiming? timing,
    GlossaryEntry? entry,
    AppLang lang,
  ) {
    final page = _page;
    if (page == null) return;
    final pageClip = VoiceClips.page(widget.storyId, page.id, lang);
    final timed = page.words[lang]?.isNotEmpty ?? false;
    if (timing != null && timed && _audio.hasClip(pageClip)) {
      _audio.playVoiceSlice(pageClip, timing.startTime, timing.endTime);
    } else if (entry != null) {
      _audio.playVoice(VoiceClips.word(widget.storyId, entry.id, lang));
    }
  }

  VoidCallback? _wordClip(GlossaryEntry? entry, AppLang lang) {
    if (entry == null) return null;
    final clip = VoiceClips.word(widget.storyId, entry.id, lang);
    return _audio.hasClip(clip) ? () => _audio.playVoice(clip) : null;
  }

  void _closePopup({bool resume = true}) {
    _popupTimer?.cancel();
    final popup = _popup;
    if (popup == null || !mounted) return;
    setState(() => _popup = null);
    if (resume && _resumeAfterPopup && _page != null) {
      // Carry on from the word the child tapped.
      final from = _narrator.timingOf(popup.chunk)?.startTime ?? Duration.zero;
      _narrate(from: from);
    }
  }

  // ---- Text-tied acting ----------------------------------------------------

  /// As narration reaches a character's name (or a prop's word), that cast
  /// member acts it out.
  void _onWord() {
    final i = _narrator.active;
    final story = _story;
    final page = _page;
    if (i == null || i == _cuedChunk || story == null || page == null) return;
    if (_popup != null) return;
    _cuedChunk = i;
    final word = _narrator.chunks[i].text;
    var bumped = false;
    final cues = [..._cues.value];
    for (final (k, m) in page.cast.indexed) {
      if (k < cues.length && story.cues(m.art, word, _lang)) {
        cues[k]++;
        bumped = true;
      }
    }
    if (bumped) _cues.value = cues;
  }

  void _goHome() {
    _narrator.stop();
    _audio.playAmbient(null);
    context.pop();
  }

  @override
  void dispose() {
    _gap?.cancel();
    _helpGiveUp?.cancel();
    _afterHelp?.cancel();
    _help
      ..removeListener(_onHelpChanged)
      ..dispose();
    _startNarration?.cancel();
    _popupTimer?.cancel();
    _lifecycle.dispose();
    _narrator
      ..removeListener(_onWord)
      ..dispose();
    _audio.playAmbient(null);
    _cues.dispose();
    _guide.dispose();
    super.dispose();
  }

  // ---- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_missing) return _ComingSoon(onHome: _goHome);
    final c = context.colors;
    final node = _node;
    final page = _page;
    final choice = _choice;
    final story = _story;
    final popup = _popup;
    // No skip-swipes while the child is dragging or rubbing to help.
    final swipe =
        ref.watch(appSettingsProvider.select((s) => s.swipeToSkip)) &&
        !_helpWaiting;

    return Scaffold(
      backgroundColor: c.skyTop,
      body: GuideScope(
        // The pointing hand only helps at the Choice Moment, and silently.
        enabled: choice != null && _chosen == null,
        child: Listener(
          onPointerDown: _onPointerDown,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerUp,
          child: Stack(
            key: _stackKey,
            fit: StackFit.expand,
            children: [
              if (node != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: _tapScenery,
                  onHorizontalDragStart: swipe ? _onDragStart : null,
                  onHorizontalDragUpdate: swipe ? _onDragUpdate : null,
                  onHorizontalDragEnd: swipe ? _onSwipe : null,
                  child: SceneCut(
                    sceneKey: ValueKey(node.id),
                    move: _move,
                    rtl: _lang.isRtl,
                    child: page != null ? _scene(page) : _choiceView(choice!),
                  ),
                ),
              const IgnorePointer(child: FireflyLayer(count: 5)),
              for (final MapEntry(key: id, value: at) in _sparkles.entries)
                TapSparkle(
                  key: ValueKey(id),
                  at: at,
                  onDone: () {
                    if (mounted) setState(() => _sparkles.remove(id));
                  },
                ),
              if (page != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  // Taps between words only close an open word card.
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _closePopup,
                    child: ListenableBuilder(
                      listenable: _narrator,
                      builder: (context, _) => SubtitleStrip(
                        chunks: _narrator.chunks,
                        lang: _lang,
                        active: _narrator.active,
                        onWordTap: _tapWord,
                      ),
                    ),
                  ),
                ),
              if (choice != null)
                PositionedDirectional(
                  start: AppSizes.space3,
                  end: AppSizes.space3,
                  top: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: AppSizes.cinemaCorner + AppSizes.space4,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: NooriGuide(
                          controller: _guide,
                          size: AppSizes.readerMascot,
                        ).popIn(0, base: 300.ms),
                      ),
                    ),
                  ),
                ),
              if (popup != null)
                Align(
                  alignment: const Alignment(0, 0.25),
                  child: WordPopup(
                    key: ValueKey(popup),
                    word: popup.word,
                    lang: _lang,
                    meaning: popup.meaning,
                    onSpeakWord: () => _speakWord(
                      popup.chunk,
                      _narrator.timingOf(popup.chunk),
                      popup.entry,
                      _lang,
                    ),
                    onSpeakMeaning: _wordClip(popup.entry, _lang.other),
                    onClose: _closePopup,
                  ),
                ),
              _PauseOverlay(visible: _paused && popup == null, onPlay: _resume),
              if (story != null) _topBar(story),
              if (_ending) _TheEnd(text: _theEnd.of(_lang), lang: _lang),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scene(StoryPage page) {
    final spec = _scenes?[page.scene];
    if (spec == null) return ColoredBox(color: context.colors.skyTop);
    final hero = _heroArrival && page.id == _story?.start;
    Widget scene = KenBurns(
      shot: _shot,
      paused: _paused,
      child: ValueListenableBuilder<List<int>>(
        valueListenable: _cues,
        builder: (context, cues, _) => StoryScene(
          spec: spec,
          cast: page.cast,
          cues: cues,
          entrances: !hero,
          onCastTap: _tapCast,
          help: _help,
          secrets: true,
          onSecretFound: _foundSecret,
          onHelpRub: _helpRub,
        ),
      ),
    );
    if (hero) scene = StoryHero(storyId: widget.storyId, child: scene);
    return scene;
  }

  Widget _choiceView(ChoiceNode choice) {
    final backdrop = _backdropPage;
    return ChoiceView(
      choice: choice,
      scene: backdrop == null ? null : _scenes?[backdrop.scene],
      cast: backdrop?.cast ?? const [],
      lang: _lang,
      chosen: _chosen,
      hint: _chosen == null,
      bottomInset: AppSizes.space4,
      onPick: _pick,
    );
  }

  Widget _topBar(Story story) {
    final total = story.pathLength;
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.space3),
          child: Row(
            children: [
              _GlassButton(
                icon: Icons.home_rounded,
                semanticLabel: 'Home',
                onTap: _goHome,
              ).popIn(0, base: 400.ms),
              const SizedBox(width: AppSizes.space4),
              Expanded(
                child: _StoryProgress(
                  value: total == 0 ? 0 : (_pagesRead + 1) / total,
                ),
              ),
              const SizedBox(width: AppSizes.space4),
              // The one way to pause (besides a two-finger tap).
              if (_page != null && !_ending) ...[
                _GlassButton(
                  icon: _paused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  semanticLabel: _paused ? 'Resume' : 'Pause',
                  onTap: _togglePause,
                ).popIn(1, base: 400.ms),
                const SizedBox(width: AppSizes.space3),
              ],
              _GlassButton(
                icon: Icons.translate_rounded,
                label: _lang.other == AppLang.ur ? 'اردو' : 'EN',
                labelLang: _lang.other,
                semanticLabel: 'Switch language',
                onTap: _flipLanguage,
              ).popIn(1, base: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small frosted round button for the corners of the story player.
class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.label,
    this.labelLang = AppLang.en,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;
  final String? label;
  final AppLang labelLang;

  @override
  Widget build(BuildContext context) {
    final text = label;
    return BouncyButton(
      semanticLabel: semanticLabel,
      minSize: AppSizes.cinemaCorner,
      onTap: onTap,
      child: Container(
        width: AppSizes.cinemaCorner,
        height: AppSizes.cinemaCorner,
        decoration: BoxDecoration(
          color: CinemaPalette.glass,
          shape: BoxShape.circle,
          border: Border.all(color: CinemaPalette.glassBorder, width: 2),
        ),
        child: text == null
            ? Icon(
                icon,
                color: CinemaPalette.subtitleText,
                size: AppSizes.cinemaIcon,
              )
            : Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.space1),
                    child: Text(
                      text,
                      textDirection: labelLang.direction,
                      style: AppTypography.style(
                        labelLang,
                        role: TextRole.label,
                        color: CinemaPalette.subtitleText,
                        weight: 700,
                      ).copyWith(height: 1.2),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// A thin glowing line showing how far through the story we are.
class _StoryProgress extends StatelessWidget {
  const _StoryProgress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.progressBar),
      child: SizedBox(
        height: AppSizes.progressBar,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: CinemaPalette.glass),
            TweenAnimationBuilder<double>(
              tween: Tween(end: value.clamp(0, 1)),
              duration: AppMotion.entrance,
              curve: AppMotion.soft,
              builder: (context, v, _) => FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: v,
                child: ColoredBox(color: c.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dims the frozen scene and offers one big, breathing play button.
class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.visible, required this.onPlay});

  final bool visible;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        // Tapping anywhere resumes, just as tapping anywhere paused.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPlay,
          child: ColoredBox(
            color: CinemaPalette.pauseVeil,
            child: Center(
              child: AnimatedScale(
                scale: visible ? 1 : 0.6,
                duration: AppMotion.entrance,
                curve: AppMotion.pop,
                child: BouncyButton(
                  semanticLabel: 'Play',
                  breathe: true,
                  sfx: null,
                  minSize: AppSizes.playButton,
                  onTap: onPlay,
                  child: Container(
                    width: AppSizes.playButton,
                    height: AppSizes.playButton,
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: c.primaryDeep,
                          offset: const Offset(0, AppSizes.puffyDepth),
                        ),
                        BoxShadow(
                          color: c.primary.withValues(alpha: 0.6),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: c.onPrimary,
                      size: AppSizes.playButton * 0.6,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A warm "The End" title card before the quiz.
class _TheEnd extends StatelessWidget {
  const _TheEnd({required this.text, required this.lang});

  final String text;
  final AppLang lang;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ColoredBox(
      color: CinemaPalette.pauseVeil,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const FireflyLayer(count: 24, seed: 5, maxRadius: 5),
          Center(
            child:
                Text(
                      text,
                      textDirection: lang.direction,
                      style:
                          AppTypography.style(
                            lang,
                            role: TextRole.display,
                            color: c.primary,
                            weight: 700,
                          ).copyWith(
                            shadows: const [
                              Shadow(
                                color: CinemaPalette.subtitleShadow,
                                blurRadius: 16,
                              ),
                            ],
                          ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scaleXY(
                      begin: 0.6,
                      duration: 900.ms,
                      curve: AppMotion.elastic,
                    ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

/// Shown if a story's file can't be loaded.
class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.onHome});

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: c.backgroundAlt)),
          const Positioned.fill(child: FireflyLayer()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.space4),
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: PuffyIconButton(
                      icon: Icons.home_rounded,
                      semanticLabel: 'Home',
                      onTap: onHome,
                    ),
                  ),
                  const Spacer(),
                  const NooriMascot(
                    state: NooriState.thinking,
                    size: AppSizes.mascotLg * 0.7,
                  ).animate().fadeIn().scaleXY(
                    begin: 0.7,
                    curve: AppMotion.pop,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
