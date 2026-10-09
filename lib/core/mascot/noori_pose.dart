import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

enum NooriState { idle, talking, happy, thinking, sleepy, pointing }

/// Every animatable part of Noori, in the painter's 200x230 design space.
/// Mutated once per frame by [NooriPoseDriver]; the painter listens to it.
class NooriPose extends ChangeNotifier {
  double time = 0;
  double bob = 0;
  double jump = 0;
  double breath = 0;
  double tilt = 0;
  double eyeOpen = 1;
  double blink = 0;
  double happyEyes = 0;
  Offset pupil = Offset.zero;
  double beakOpen = 0;
  double leftWing = 0.15;
  double rightWing = 0.15;
  double scarfSway = 0;
  double zzz = 0;
  double thinkDots = 0;
  double sparkle = 0;

  void markDirty() => notifyListeners();
}

/// Computes per-state targets and eases the pose toward them, so switching
/// state never snaps.
class NooriPoseDriver {
  NooriPoseDriver(this.pose, {math.Random? random})
    : _random = random ?? math.Random() {
    _scheduleBlink(0);
  }

  final NooriPose pose;
  final math.Random _random;

  NooriState state = NooriState.idle;
  bool pointLeft = false;

  /// Where Noori is looking, -1 (left) to 1 (right). Her eyes and head
  /// follow it, on top of whatever the state is doing.
  double look = 0;
  double _look = 0;

  double _nextBlink = 0;
  double _blinkStart = -1;
  double _last = 0;

  static const _blinkMin = 3.0;
  static const _blinkMax = 5.0;
  static const _blinkLen = 0.16;
  static const _ease = 9.0;

  void _scheduleBlink(double now) {
    _nextBlink =
        now + _blinkMin + _random.nextDouble() * (_blinkMax - _blinkMin);
  }

  void tick(double t) {
    final dt = (t - _last).clamp(0.0, 0.1);
    _last = t;
    pose.time = t;
    final k = 1 - math.exp(-dt * _ease);
    double ease(double current, double target) =>
        current + (target - current) * k;

    // Targets. Oscillations are computed directly; levels are eased.
    var bobAmp = 2.5, bobSpeed = 2.0;
    var tilt = math.sin(t * 0.8) * 0.04;
    var eyeOpen = 1.0, happyEyes = 0.0, beak = 0.0;
    var pupil = Offset(math.sin(t * 0.37) * 0.4, math.sin(t * 0.23) * 0.25);
    var lw = 0.15 + math.sin(t * 2.0) * 0.04;
    var rw = 0.15 + math.sin(t * 2.0 + 0.6) * 0.04;
    var jump = 0.0, zzz = 0.0, dots = 0.0, sparkle = 0.0;

    switch (state) {
      case NooriState.idle:
        break;
      case NooriState.talking:
        bobSpeed = 3.0;
        tilt = math.sin(t * 1.6) * 0.07;
        beak =
            (math.sin(t * 13) * 0.5 + 0.5) *
            (0.6 + 0.4 * math.sin(t * 3.1).abs());
        lw = 0.25 + math.sin(t * 3.0) * 0.18;
        rw = 0.25 + math.sin(t * 3.0 + 1.2) * 0.18;
        pupil = Offset(math.sin(t * 0.7) * 0.2, 0.1);
      case NooriState.happy:
        jump = (math.sin(t * 5.2)).abs() * 16;
        happyEyes = 1;
        beak = 0.55;
        lw = 2.35 + math.sin(t * 18) * 0.3;
        rw = 2.35 + math.sin(t * 18 + 0.4) * 0.3;
        tilt = math.sin(t * 5.2) * 0.08;
        sparkle = 1;
      case NooriState.thinking:
        tilt = 0.17 + math.sin(t * 0.9) * 0.03;
        pupil = const Offset(0.55, -0.75);
        rw = 0.9 + math.sin(t * 1.4) * 0.06;
        bobAmp = 1.5;
        bobSpeed = 1.4;
        dots = 1;
      case NooriState.sleepy:
        eyeOpen = 0.12 + (math.sin(t * 0.35) * 0.5 + 0.5) * 0.18;
        bobAmp = 3.0;
        bobSpeed = 1.0;
        tilt = 0.12 + math.sin(t * 0.5) * 0.05;
        pupil = const Offset(0, 0.5);
        lw = 0.08;
        rw = 0.08;
        zzz = 1;
      case NooriState.pointing:
        final point = 1.55 + math.sin(t * 6) * 0.08;
        if (pointLeft) {
          lw = point;
        } else {
          rw = point;
        }
        pupil = Offset(pointLeft ? -0.8 : 0.8, 0.15);
        tilt = pointLeft ? 0.08 : -0.08;
    }

    _look = ease(_look, look);
    if (_look.abs() > 0.001) {
      pupil = Offset((pupil.dx + _look * 0.9).clamp(-1.0, 1.0), pupil.dy);
      tilt -= _look * 0.14;
    }

    pose
      ..bob = math.sin(t * bobSpeed) * bobAmp
      ..breath = math.sin(t * 2.4) * 0.018
      ..jump = ease(pose.jump, jump)
      ..tilt = ease(pose.tilt, tilt)
      ..eyeOpen = ease(pose.eyeOpen, eyeOpen)
      ..happyEyes = ease(pose.happyEyes, happyEyes)
      ..pupil = Offset.lerp(pose.pupil, pupil, k)!
      ..beakOpen = ease(pose.beakOpen, beak)
      ..leftWing = ease(pose.leftWing, lw)
      ..rightWing = ease(pose.rightWing, rw)
      ..scarfSway = math.sin(t * 1.7) * 0.12 + (pose.jump / 16) * 0.2
      ..zzz = ease(pose.zzz, zzz)
      ..thinkDots = ease(pose.thinkDots, dots)
      ..sparkle = ease(pose.sparkle, sparkle);

    // Blink every 3–5 seconds.
    if (_blinkStart < 0 && t >= _nextBlink) _blinkStart = t;
    if (_blinkStart >= 0) {
      final p = (t - _blinkStart) / _blinkLen;
      if (p >= 1) {
        pose.blink = 0;
        _blinkStart = -1;
        _scheduleBlink(t);
      } else {
        pose.blink = p < 0.5 ? p * 2 : (1 - p) * 2;
      }
    }

    pose.markDirty();
  }
}
