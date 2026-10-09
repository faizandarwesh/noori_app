import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/local_store.dart';

/// Everything the child has earned. Stored locally only.
@immutable
class Progress {
  const Progress({
    this.fireflies = 0,
    this.stars = const {},
    this.words = const [],
    this.listeningSeconds = 0,
    this.spent = 0,
    this.plays = const {},
  });

  /// Every firefly ever earned. Noori's lantern glows by this, so spending
  /// never makes it dimmer.
  final int fireflies;

  /// Fireflies spent in Noori's wardrobe.
  final int spent;

  /// Fireflies left to spend.
  int get balance => fireflies - spent;

  /// Story id → times its quiz has been finished; rotates the question
  /// types on each replay.
  final Map<String, int> plays;
  int playsFor(String storyId) => plays[storyId] ?? 0;

  /// Story id → best stars earned (1–3). Present means completed.
  final Map<String, int> stars;

  /// Collected Word Jar word ids, in the order found.
  final List<String> words;
  final int listeningSeconds;

  /// Word Jar key: glossary ids are only unique within one story.
  static String wordKey(String storyId, String wordId) => '$storyId/$wordId';

  bool isCompleted(String storyId) => stars.containsKey(storyId);
  int starsFor(String storyId) => stars[storyId] ?? 0;

  Progress copyWith({
    int? fireflies,
    Map<String, int>? stars,
    List<String>? words,
    int? listeningSeconds,
    int? spent,
    Map<String, int>? plays,
  }) => Progress(
    fireflies: fireflies ?? this.fireflies,
    stars: stars ?? this.stars,
    words: words ?? this.words,
    listeningSeconds: listeningSeconds ?? this.listeningSeconds,
    spent: spent ?? this.spent,
    plays: plays ?? this.plays,
  );
}

class ProgressNotifier extends Notifier<Progress> {
  static const _fireflies = 'progress.fireflies';
  static const _stars = 'progress.stars';
  static const _words = 'progress.words';
  static const _listening = 'progress.listeningSeconds';
  static const _spent = 'progress.spent';
  static const _plays = 'progress.plays';

  LocalStore get _store => ref.read(localStoreProvider);

  @override
  Progress build() {
    final s = ref.watch(localStoreProvider);
    // Hive hands collections back as dynamic maps/lists.
    final rawStars = s.read(_stars) as Map? ?? const {};
    final rawWords = s.read(_words) as List? ?? const [];
    final rawPlays = s.read(_plays) as Map? ?? const {};
    return Progress(
      fireflies: s.read(_fireflies) as int? ?? 0,
      stars: {
        for (final e in rawStars.entries) '${e.key}': (e.value as num).toInt(),
      },
      words: [for (final w in rawWords) '$w'],
      listeningSeconds: s.read(_listening) as int? ?? 0,
      spent: s.read(_spent) as int? ?? 0,
      plays: {
        for (final e in rawPlays.entries) '${e.key}': (e.value as num).toInt(),
      },
    );
  }

  void addFireflies(int n) {
    state = state.copyWith(fireflies: state.fireflies + n);
    _store.write(_fireflies, state.fireflies);
  }

  /// Spends [n] fireflies if there are enough. Returns whether it did.
  bool spendFireflies(int n) {
    if (n > state.balance) return false;
    state = state.copyWith(spent: state.spent + n);
    _store.write(_spent, state.spent);
    return true;
  }

  /// Records a finished story, keeping the best star count.
  void completeStory(String storyId, int stars) {
    final best = math.max(state.starsFor(storyId), stars.clamp(1, 3));
    state = state.copyWith(
      stars: {...state.stars, storyId: best},
      plays: {...state.plays, storyId: state.playsFor(storyId) + 1},
    );
    _store
      ..write(_stars, state.stars)
      ..write(_plays, state.plays);
  }

  /// Returns false if the word was already in the jar.
  bool collectWord(String wordId) {
    if (state.words.contains(wordId)) return false;
    state = state.copyWith(words: [...state.words, wordId]);
    _store.write(_words, state.words);
    return true;
  }

  /// Adds a finished story's vocabulary to the Word Jar. Returns the keys
  /// that were new.
  List<String> collectStoryWords(String storyId, List<String> wordIds) => [
    for (final id in wordIds)
      if (collectWord(Progress.wordKey(storyId, id)))
        Progress.wordKey(storyId, id),
  ];

  void addListening(Duration d) {
    if (d.inSeconds <= 0) return;
    state = state.copyWith(
      listeningSeconds: state.listeningSeconds + d.inSeconds,
    );
    _store.write(_listening, state.listeningSeconds);
  }
}

final progressProvider = NotifierProvider<ProgressNotifier, Progress>(
  ProgressNotifier.new,
);
