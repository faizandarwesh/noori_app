import 'package:flutter/animation.dart';

/// Spacing, radii and hit-target tokens.
abstract final class AppSizes {
  static const space1 = 4.0;
  static const space2 = 8.0;
  static const space3 = 12.0;
  static const space4 = 16.0;
  static const space5 = 24.0;
  static const space6 = 32.0;
  static const space7 = 48.0;

  static const radiusSm = 24.0;
  static const radiusMd = 28.0;
  static const radiusLg = 32.0;

  /// Minimum size of any control a child presses.
  static const minTap = 72.0;
  static const bigTap = 96.0;
  static const iconMd = 36.0;
  static const iconLg = 44.0;

  /// Depth of the darker "puffy" bottom edge on 3D buttons.
  static const puffyDepth = 6.0;

  static const mascotSm = 96.0;
  static const mascotMd = 160.0;
  static const mascotLg = 240.0;

  static const bubbleMaxWidth = 300.0;
  static const hintHandSize = 64.0;

  static const storyStop = 84.0;
  static const zoneBadge = 68.0;
  static const padlock = 32.0;
  static const starSm = 22.0;
  static const iconSm = 20.0;
  static const lantern = 56.0;
  static const dialogMaxWidth = 420.0;
  static const languageCardWidth = 150.0;
  static const languageCardHeight = 190.0;
  static const textCardMinHeight = 120.0;
  static const readerMascot = 80.0;
  static const pageDot = 10.0;
  static const choiceCardHeight = 210.0;
  static const quizCardHeight = 150.0;
  static const wordCardWidth = 132.0;
  static const rewardLantern = 120.0;
  static const rewardStar = 64.0;

  // Home carousel: each card is the story's first scene scaled down.
  static const carouselCardScale = 0.6;
  static const carouselViewport = 0.66;
  static const carouselTilt = 0.5;
  static const carouselShrink = 0.2;
  static const carouselBob = 8.0;
  static const homeMascot = 104.0;
  static const homeLantern = 52.0;

  // Noori's Lantern, wardrobe and word game.
  static const bigLanternW = 170.0;
  static const bigLanternH = 230.0;
  static const doorHeight = 140.0;
  static const doorCard = 54.0;
  static const wardrobeTile = 104.0;
  static const wardrobePreview = 180.0;
  static const gameCardHeight = 160.0;
  static const settingsIcon = 30.0;
  static const settingsTap = 56.0;
  static const badgeFirefly = 44.0;

  // Language lanterns.
  static const langLanternW = 150.0;
  static const langLanternH = 190.0;
  static const branchMascot = 150.0;

  // Cinematic story player.
  static const cinemaCorner = 60.0;

  /// Smallest tap target around a hidden scene surprise.
  static const secretHitMin = 64.0;

  /// How close (a share of the screen width) a dragged help item must land
  /// to its target.
  static const helpDropReach = 0.16;

  /// How far (a share of the screen width) a finger rubs for one help step.
  static const helpRubStep = 0.6;
  static const cinemaIcon = 30.0;
  static const playButton = 128.0;
  static const subtitleMaxWidth = 640.0;
  static const progressBar = 4.0;

  // Ken Burns camera: how far the shot zooms and pans.
  static const kenBurnsZoom = 0.12;
  static const kenBurnsPan = 0.04;
}

/// Timing and curve tokens for motion.
abstract final class AppMotion {
  static const pressDown = Duration(milliseconds: 90);
  static const pressRelease = Duration(milliseconds: 520);
  static const pressDownScale = 0.9;
  static const pressOvershootScale = 1.08;

  static const breathe = Duration(milliseconds: 2200);
  static const breatheScale = 1.04;

  /// Offset between staggered entrance items (spec: 60–80ms).
  static const stagger = Duration(milliseconds: 70);
  static const entrance = Duration(milliseconds: 480);
  static const bubblePop = Duration(milliseconds: 420);

  static const blinkMin = Duration(milliseconds: 3000);
  static const blinkMax = Duration(milliseconds: 5000);
  static const blinkLength = Duration(milliseconds: 160);

  /// Idle time before the pointing hand appears.
  static const idleHint = Duration(seconds: 8);
  static const hintRepeat = Duration(seconds: 9);

  /// Pause after a page's narration before the next scene.
  static const sceneGap = Duration(milliseconds: 1200);
  static const sceneChange = Duration(milliseconds: 1100);
  static const kenBurnsMin = Duration(seconds: 6);
  static const kenBurnsMax = Duration(seconds: 10);
  static const cardFloat = Duration(milliseconds: 3200);
  static const skyCycle = Duration(seconds: 48);
  static const heroFlight = Duration(milliseconds: 750);
  static const lanternBurst = Duration(milliseconds: 1300);

  static const elastic = Curves.elasticOut;
  static const pop = Curves.easeOutBack;
  static const soft = Curves.easeInOutSine;
}
