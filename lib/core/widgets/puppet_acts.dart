import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// One moment of a puppet's looping action: extra turns per part (degrees,
/// positive = towards the body's middle on paired parts), and a move of the
/// whole puppet in viewBox units.
@immutable
class ActFrame {
  const ActFrame({
    this.turns = const {},
    this.dx = 0,
    this.dy = 0,
    this.rot = 0,
    this.sx = 1,
    this.sy = 1,
    this.talk = 0,
  });

  final Map<String, double> turns;
  final double dx, dy;

  /// Whole-body lean in degrees, about the feet.
  final double rot;
  final double sx, sy;

  /// How open the mouth (or beak) is, 0–1.
  final double talk;

  static const rest = ActFrame();

  ActFrame operator +(ActFrame o) => ActFrame(
    turns: {
      ...turns,
      for (final e in o.turns.entries) e.key: (turns[e.key] ?? 0) + e.value,
    },
    dx: dx + o.dx,
    dy: dy + o.dy,
    rot: rot + o.rot,
    sx: sx * o.sx,
    sy: sy * o.sy,
    talk: math.max(talk, o.talk),
  );

  /// This frame faded towards rest by [k] (0 = rest, 1 = full).
  ActFrame scaled(double k) => ActFrame(
    turns: {for (final e in turns.entries) e.key: e.value * k},
    dx: dx * k,
    dy: dy * k,
    rot: rot * k,
    sx: 1 + (sx - 1) * k,
    sy: 1 + (sy - 1) * k,
    talk: talk * k,
  );
}

/// The actions a cast member's `act` can name. Several can be combined
/// with `+` (`walk+talk`). Parts a puppet doesn't have are simply ignored,
/// so one action serves people, animals and birds alike.
abstract final class PuppetActs {
  static const names = {
    'breathe', 'walk', 'run', 'wave', 'clap', 'nod', 'talk', 'chirp', //
    'flap', 'fly', 'hop', 'laugh', 'dig', 'pour', 'eat', 'rub', 'kick',
    'spray', 'trunk', 'ears', 'tail', 'sway', 'shy', 'fidget', 'tuck',
    'dua', 'hug', 'sleep', 'drink', 'look', 'cheer', 'bounce', 'give',
  };

  /// The frame of [act] at [seconds]; [seed] offsets the phase so a crowd
  /// doesn't move in lockstep.
  static ActFrame frame(String? act, double seconds, {double seed = 0}) {
    if (act == null || act.isEmpty) return _one('breathe', seconds, seed);
    if (!act.contains('+')) return _one(act, seconds, seed);
    return act
        .split('+')
        .map((a) => _one(a.trim(), seconds, seed))
        .fold(ActFrame.rest, (a, b) => a + b);
  }

  static ActFrame _one(String act, double t, double seed) {
    double phase(double period) => (t / period + seed) % 1;
    double sin(double period) => math.sin(phase(period) * math.pi * 2);
    double up(double period) => math.sin(phase(period) * math.pi).abs();

    switch (act) {
      case 'breathe':
        final s = sin(3.2);
        return ActFrame(turns: {'head': 1.2 * s}, sy: 1 + 0.012 * s);
      case 'walk':
        final s = sin(0.9);
        return ActFrame(
          turns: {
            'legL': 14 * s, 'legR': -14 * s, //
            'upperL': -12 * s, 'upperR': 12 * s,
            'legF2': 14 * s, 'legB1': 14 * s, 'legF1': -14 * s,
            'legB2': -14 * s, 'tail': 8 * s, 'head': 1.5 * s,
          },
          dy: -up(0.45) * 2.5,
        );
      case 'run':
        final s = sin(0.5);
        return ActFrame(
          turns: {
            'legL': 24 * s, 'legR': -24 * s, //
            'upperL': -26 * s, 'upperR': 26 * s,
            'foreL': -20, 'foreR': -20, 'tail': 14 * s,
          },
          dy: -up(0.25) * 5,
        );
      case 'wave':
        final s = sin(0.7);
        return ActFrame(turns: {'foreR': 24 * s, 'upperR': 5 * s});
      case 'clap':
        final s = sin(0.5);
        return ActFrame(turns: {'foreL': 12 * s, 'foreR': 12 * s});
      case 'nod':
        return ActFrame(turns: {'head': 4 * sin(1.6)});
      case 'talk':
        final s = sin(0.42);
        return ActFrame(turns: {'head': 2 * s}, talk: 0.5 + 0.5 * s);
      case 'chirp':
        final s = sin(0.5);
        return ActFrame(turns: {'head': 6 * s}, talk: math.max(0, s));
      case 'flap':
        final s = sin(0.36);
        return ActFrame(
          turns: {'wingL': -30 * s, 'wingR': -30 * s, 'wing': -30 * s},
          dy: -up(0.36) * 2,
        );
      case 'fly':
        final s = sin(0.26);
        return ActFrame(
          turns: {'wingL': -45 * s, 'wingR': -45 * s, 'wing': -45 * s},
          dy: -4 * sin(1.1),
        );
      case 'hop':
        final h = math.max(0.0, sin(0.8));
        return ActFrame(dy: -h * 12, sy: 1 + h * 0.04);
      case 'laugh':
        final s = sin(0.32);
        return ActFrame(
          turns: {'head': 3 * s},
          dy: -up(0.32) * 2.5,
          rot: 1.2 * s,
          talk: 0.6 + 0.4 * s.abs(),
        );
      case 'dig':
        final s = sin(1.0);
        return ActFrame(
          turns: {
            'upperL': 10 * s, 'upperR': 10 * s, //
            'foreL': 20 * s, 'foreR': 20 * s, 'head': 3 * s,
          },
          dy: -up(1.0) * 1.5,
        );
      case 'pour':
        return ActFrame(turns: {'foreR': 8 * sin(2.4)});
      case 'eat':
        final s = sin(0.45);
        return ActFrame(
          turns: {'foreR': 22 * s, 'upperR': 6 * s, 'head': 2 * s},
          talk: s.abs(),
        );
      case 'rub':
        final s = sin(0.5);
        return ActFrame(turns: {'foreR': 16 * s, 'foreL': -10 * s});
      case 'kick':
        final p = phase(1.4);
        final k = p < 0.3 ? math.sin(p / 0.3 * math.pi) : 0.0;
        return ActFrame(turns: {'legR': -40 * k, 'legF2': -45 * k});
      case 'spray':
        final s = sin(1.4);
        return ActFrame(turns: {'trunk': -8 * s, 'trunkTip': 16 * s});
      case 'trunk':
        final s = sin(2.6);
        return ActFrame(turns: {'trunk': 6 * s, 'trunkTip': 12 * s});
      case 'ears':
        final s = sin(1.0);
        return ActFrame(turns: {'earL': 12 * s, 'earR': 12 * s, 'ear': 12 * s});
      case 'tail':
        return ActFrame(turns: {'tail': 16 * sin(0.8)});
      case 'sway':
        return ActFrame(rot: 3 * sin(2.8));
      case 'shy':
        final s = sin(3.0);
        return ActFrame(turns: {'head': 3 * s}, rot: 1.5 * s);
      case 'fidget':
        final s = sin(0.5);
        return ActFrame(turns: {'head': 2 * s}, dx: 0.8 * s);
      case 'tuck':
        final s = sin(2.4);
        return ActFrame(turns: {'foreR': 10 * s, 'upperR': 5 * s});
      case 'dua':
        final s = sin(3.2);
        return ActFrame(turns: {'head': 2 * s, 'foreL': 3 * s, 'foreR': 3 * s});
      case 'hug':
        final s = sin(1.8);
        return ActFrame(
          turns: {'upperL': 4 * s, 'upperR': 4 * s, 'head': 2 * s},
          sx: 1 + 0.015 * s,
        );
      case 'sleep':
        final s = sin(3.6);
        return ActFrame(turns: {'head': 1.5 * s}, sy: 1 + 0.025 * s);
      case 'drink':
        final s = sin(2.4);
        return ActFrame(
          turns: {'head': -3 + 3 * s, 'foreR': 4 * s},
          talk: 0.3 + 0.3 * s,
        );
      case 'look':
        return ActFrame(turns: {'head': 7 * sin(3.0)});
      case 'cheer':
        final s = sin(0.5);
        return ActFrame(
          turns: {
            'upperL': -40 - 30 * s, 'upperR': -40 - 30 * s, //
            'wingL': -40 * s, 'wingR': -40 * s, 'wing': -40 * s,
            'ear': 14 * s, 'earL': 14 * s, 'earR': 14 * s,
            'tail': 20 * s, 'trunk': -14 * s,
          },
          dy: -up(0.5) * 5,
        );
      case 'bounce':
        return ActFrame(dy: -up(0.6) * 4);
      case 'give':
        final s = sin(2.0);
        return ActFrame(turns: {'upperR': -4 * s, 'foreR': 4 * s});
      default:
        return ActFrame.rest;
    }
  }
}
