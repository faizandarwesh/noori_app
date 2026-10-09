import 'package:flutter/foundation.dart';

/// What a finished quiz hands to the reward screen.
@immutable
class RewardResult {
  const RewardResult({
    required this.stars,
    required this.fireflies,
    required this.newWords,
  });

  /// 1–3, from first-try correct answers (never zero).
  final int stars;

  /// Fireflies earned in this quiz.
  final int fireflies;

  /// Word Jar keys collected for the first time.
  final List<String> newWords;

  /// Stars from first-try correct answers: every finished quiz earns at
  /// least one.
  static int starsFor(int firstTryCorrect) => firstTryCorrect.clamp(1, 3);
}
