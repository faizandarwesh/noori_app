import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_service.dart';
import '../audio/voice_clips.dart';
import '../guide/guide_lines.dart';
import '../i18n/app_lang.dart';
import '../settings/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/guide_hint.dart';
import '../widgets/speech_bubble.dart';
import 'noori_mascot.dart';

/// One line for Noori: a guide-line key, or literal [text] (e.g. a quiz
/// question) with its recording at [clip]. [lang] overrides the app language.
@immutable
class GuideLine {
  const GuideLine(this.key, {this.lang}) : text = null, clip = null;
  const GuideLine.text(LocalizedText this.text, {this.clip, this.lang})
    : key = null;

  final String? key;
  final LocalizedText? text;
  final String Function(AppLang lang)? clip;
  final AppLang? lang;

  String clipFor(AppLang lang) =>
      key != null ? VoiceClips.guide(key!, lang) : (clip?.call(lang) ?? '');
}

/// Lets a screen tell Noori what to say or how to act.
class NooriGuideController extends ChangeNotifier {
  List<GuideLine> _queue = const [];
  Completer<void>? _done;
  int _generation = 0;
  NooriState? _mood;

  NooriState? get mood => _mood;
  List<GuideLine> get queue => _queue;

  /// Increments on every request, so repeating the same line still speaks.
  int get generation => _generation;

  /// Speak the guide line [key], interrupting whatever Noori was saying.
  /// Completes when she finishes or is interrupted.
  Future<void> say(String key, {AppLang? lang}) =>
      sayAll([GuideLine(key, lang: lang)]);

  /// Speak several lines one after another.
  Future<void> sayAll(List<GuideLine> lines) {
    _finish();
    _queue = List.unmodifiable(lines);
    _generation++;
    final done = _done = Completer<void>();
    notifyListeners();
    return done.future;
  }

  void _finish() {
    final d = _done;
    _done = null;
    if (d != null && !d.isCompleted) d.complete();
  }

  /// Hold a state (e.g. happy, pointing) until cleared with null.
  void setMood(NooriState? mood) {
    if (_mood == mood) return;
    _mood = mood;
    notifyListeners();
  }

  @override
  void dispose() {
    _finish();
    super.dispose();
  }
}

/// Noori with her speech bubble. Voice-first: every line is spoken, and she
/// is in the talking state while it plays. Once she finishes, the enclosing
/// [GuideScope]'s idle clock restarts.
class NooriGuide extends ConsumerStatefulWidget {
  const NooriGuide({
    super.key,
    required this.controller,
    this.initialLine,
    this.size = AppSizes.mascotMd,
    this.bubbleAfter = true,
    this.pointLeft = false,
    this.look = 0,
    this.repeatOnTap = true,
    this.onTap,
  });

  final NooriGuideController controller;
  final String? initialLine;
  final double size;

  /// Bubble follows Noori in reading direction (right of her in English,
  /// left of her in Urdu).
  final bool bubbleAfter;
  final bool pointLeft;

  /// Where Noori looks, -1 (left) to 1 (right).
  final double look;

  /// Tapping Noori repeats her last line. Off where she must stay quiet
  /// (Home): there a tap only makes her hop.
  final bool repeatOnTap;

  /// Also called when Noori is tapped.
  final VoidCallback? onTap;

  @override
  ConsumerState<NooriGuide> createState() => _NooriGuideState();
}

class _NooriGuideState extends ConsumerState<NooriGuide> {
  static const _minTalk = Duration(milliseconds: 1400);

  int _handled = 0;
  bool _talking = false;
  GuideLine? _shown;
  int _speechId = 0;
  Timer? _hideBubble;

  /// How long the bubble stays after Noori stops talking.
  static const _bubbleLinger = Duration(seconds: 5);

  static Duration _silentTalk(String text) => Duration(
    milliseconds: (text.length * 65).clamp(_minTalk.inMilliseconds, 4000),
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onController);
    if (widget.controller.queue.isNotEmpty) {
      // Asked to speak before this widget was built: catch up.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onController();
      });
    } else if (widget.initialLine != null) {
      // After the first frame so the entrance animation starts first.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.controller.say(widget.initialLine!);
      });
    }
  }

  @override
  void didUpdateWidget(NooriGuide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onController);
      widget.controller.addListener(_onController);
    }
  }

  void _onController() {
    final c = widget.controller;
    if (c.generation != _handled) {
      _handled = c.generation;
      unawaited(_speakQueue(c.queue, c));
    }
    setState(() {});
  }

  Future<void> _speakQueue(
    List<GuideLine> queue,
    NooriGuideController c,
  ) async {
    final id = ++_speechId;
    final lines = await ref.read(guideLinesProvider.future);
    for (final line in queue) {
      if (!mounted || id != _speechId) return;
      final lang = line.lang ?? ref.read(appSettingsProvider).lang;
      final text = line.text?.of(lang) ?? lines.text(line.key!, lang);
      setState(() {
        _shown = line;
        _talking = true;
      });
      final watch = Stopwatch()..start();
      final spoke = await ref
          .read(audioServiceProvider)
          .playVoice(line.clipFor(lang));
      // No recording yet: talk silently for about as long as the line would
      // take to say, so the bubble can still be read.
      final hold = spoke ? _minTalk : _silentTalk(text);
      if (watch.elapsed < hold) {
        await Future<void>.delayed(hold - watch.elapsed);
      }
    }
    if (!mounted || id != _speechId) return;
    setState(() => _talking = false);
    if (c.generation == _handled) c._finish();
    GuideScope.maybeOf(context)?.speechEnded();
    // Let the words linger, then tidy the bubble away.
    _hideBubble?.cancel();
    _hideBubble = Timer(_bubbleLinger, () {
      if (mounted && id == _speechId) setState(() => _shown = null);
    });
  }

  @override
  void dispose() {
    _hideBubble?.cancel();
    widget.controller.removeListener(_onController);
    _speechId++;
    super.dispose();
  }

  /// The tail points back at Noori.
  BubbleTail _tailFor(TextDirection dir) {
    final nooriOnLeft = (dir == TextDirection.ltr) == widget.bubbleAfter;
    return nooriOnLeft ? BubbleTail.left : BubbleTail.right;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final lines = ref.watch(guideLinesProvider).value;
    final rest = settings.bedtime ? NooriState.sleepy : NooriState.idle;
    final state = _talking
        ? NooriState.talking
        : (widget.controller.mood ?? rest);
    final shown = _shown;
    final lang = shown?.lang ?? settings.lang;
    final text = shown == null
        ? null
        : shown.text?.of(lang) ?? lines?.text(shown.key!, lang);

    final mascot = NooriMascot(
      state: state,
      size: widget.size,
      pointLeft: widget.pointLeft,
      look: widget.look,
      onTap: () {
        widget.onTap?.call();
        if (!widget.repeatOnTap) return;
        // Tapping Noori repeats what she last said.
        final shown = _shown;
        if (shown != null) {
          widget.controller.sayAll([shown]);
        } else if (widget.initialLine != null) {
          widget.controller.say(widget.initialLine!);
        }
      },
    );
    final hasText = text != null && text.isNotEmpty;
    // The bubble pops in by itself; this just fades it out when tidied away.
    final bubble = Flexible(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: hasText
            ? Padding(
                key: ValueKey(text),
                padding: EdgeInsets.only(bottom: widget.size * 0.45),
                child: SpeechBubble(
                  text: text,
                  lang: lang,
                  tail: _tailFor(Directionality.of(context)),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: widget.bubbleAfter ? [mascot, bubble] : [bubble, mascot],
    );
  }
}
