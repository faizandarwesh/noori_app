import 'dart:ui';

import 'package:flutter/foundation.dart';

/// One moving piece of a puppet, drawn by
/// `assets/illustrations/puppets/<puppet>/<id>.svg` over the puppet's whole
/// viewBox, and turned about [pivot].
@immutable
class PuppetPart {
  const PuppetPart({
    required this.id,
    required this.pivot,
    this.parent,
    this.mirror = false,
  });

  factory PuppetPart.fromJson(Map<String, dynamic> j) => PuppetPart(
    id: j['id'] as String,
    pivot: _offset(j['pivot']),
    parent: j['parent'] as String?,
    mirror: j['mirror'] as bool? ?? false,
  );

  final String id;

  /// In viewBox units.
  final Offset pivot;

  /// The part this one hangs from (a forearm from its upper arm): it
  /// follows the parent's turn before its own.
  final String? parent;

  /// Parts on the viewer's left: pose angles are mirrored, so one number
  /// means "raise outward" on both sides.
  final bool mirror;
}

/// Where a puppet's face is painted, in viewBox units of its [part].
@immutable
class PuppetFace {
  const PuppetFace({
    required this.part,
    required this.skin,
    required this.eyes,
    this.mouth,
    this.cheeks = const [],
    this.brows,
    this.beak,
    this.beakColor,
    this.ink,
  });

  factory PuppetFace.fromJson(Map<String, dynamic> j) => PuppetFace(
    part: j['part'] as String,
    skin: _color(j['skin']),
    eyes: [for (final e in j['eyes'] as List) _circle(e)],
    mouth: j['mouth'] == null ? null : _circle(j['mouth']),
    cheeks: [for (final c in j['cheeks'] as List? ?? const []) _circle(c)],
    brows: j['brows'] == null ? null : _color(j['brows']),
    beak: j['beak'] == null ? null : _circle(j['beak']),
    beakColor: j['beakColor'] == null ? null : _color(j['beakColor']),
    ink: j['ink'] == null ? null : _color(j['ink']),
  );

  final String part;

  /// Fills the eyelids when blinking and puffs the cheeks.
  final Color skin;

  /// Centre and radius of each eye.
  final List<(Offset, double)> eyes;

  /// Centre and width of the mouth.
  final (Offset, double)? mouth;
  final List<(Offset, double)> cheeks;
  final Color? brows;

  /// Birds: the beak's base centre and length. A positive length points
  /// right (a bird seen from the side), a negative one down (seen from the
  /// front). It opens to chirp, gasp or drink.
  final (Offset, double)? beak;
  final Color? beakColor;

  /// Eye and mouth colour (defaults to the shared dark ink).
  final Color? ink;
}

/// A hand that can hold a prop.
@immutable
class PuppetHand {
  const PuppetHand(this.part, this.at);

  factory PuppetHand.fromJson(Map<String, dynamic> j) =>
      PuppetHand(j['part'] as String, _offset(j['at']));

  final String part;
  final Offset at;
}

/// A pose: turns per part (degrees, outward-positive on mirrored parts),
/// optional shifts, and a default expression or gaze.
@immutable
class PuppetPose {
  const PuppetPose({
    this.turns = const {},
    this.shifts = const {},
    this.drop = 0,
    this.face,
    this.look,
  });

  factory PuppetPose.fromJson(Map<String, dynamic> j) {
    final turns = <String, double>{};
    final shifts = <String, Offset>{};
    for (final e in j.entries) {
      switch (e.key) {
        case 'drop' || 'face' || 'look':
          continue;
      }
      switch (e.value) {
        case final num a:
          turns[e.key] = a.toDouble();
        case [final num a, final num dx, final num dy]:
          turns[e.key] = a.toDouble();
          shifts[e.key] = Offset(dx.toDouble(), dy.toDouble());
      }
    }
    return PuppetPose(
      turns: turns,
      shifts: shifts,
      drop: (j['drop'] as num? ?? 0).toDouble(),
      face: j['face'] as String?,
      look: j['look'] as String?,
    );
  }

  final Map<String, double> turns;
  final Map<String, Offset> shifts;

  /// How far (viewBox units) the whole puppet sinks, e.g. to sit or kneel.
  final double drop;
  final String? face;
  final String? look;

  static const stand = PuppetPose();
}

@immutable
class PuppetSpec {
  const PuppetSpec({
    required this.id,
    required this.size,
    required this.parts,
    required this.face,
    required this.poses,
    this.hands = const {},
    this.card = (0.0, 1.0),
    this.tap = 'hop',
  });

  factory PuppetSpec.fromJson(
    String id,
    Map<String, dynamic> j,
    Map<String, Map<String, PuppetPose>> rigs,
  ) {
    final own = j['poses'] as Map<String, dynamic>? ?? const {};
    return PuppetSpec(
      id: id,
      size: switch (j['size']) {
        [final num w, final num h] => Size(w.toDouble(), h.toDouble()),
        _ => throw FormatException('$id: size must be [w, h]'),
      },
      parts: [
        for (final p in j['parts'] as List)
          PuppetPart.fromJson(p as Map<String, dynamic>),
      ],
      face: PuppetFace.fromJson(j['face'] as Map<String, dynamic>),
      hands: {
        for (final e in (j['hands'] as Map<String, dynamic>? ?? {}).entries)
          e.key: PuppetHand.fromJson(e.value as Map<String, dynamic>),
      },
      poses: {
        ...?rigs[j['rig']],
        for (final e in own.entries)
          e.key: PuppetPose.fromJson(e.value as Map<String, dynamic>),
      },
      card: switch (j['card']) {
        [final num top, final num bottom] => (
          top.toDouble(),
          bottom.toDouble(),
        ),
        _ => (0.0, 1.0),
      },
      tap: j['tap'] as String? ?? 'hop',
    );
  }

  final String id;

  /// The viewBox every part is drawn in.
  final Size size;

  /// Back to front.
  final List<PuppetPart> parts;
  final PuppetFace face;
  final Map<String, PuppetHand> hands;
  final Map<String, PuppetPose> poses;

  /// The slice (top, bottom fractions of the height) shown on cards.
  final (double, double) card;

  /// The action played when the puppet is tapped or named.
  final String tap;

  String asset(String part) => 'assets/illustrations/puppets/$id/$part.svg';

  PuppetPart? part(String id) {
    for (final p in parts) {
      if (p.id == id) return p;
    }
    return null;
  }

  PuppetPose pose(String? name) => poses[name ?? 'stand'] ?? PuppetPose.stand;
}

/// Every puppet, from assets/content/puppets.json.
@immutable
class Puppets {
  const Puppets(this._puppets);

  static const asset = 'assets/content/puppets.json';
  static const empty = Puppets({});

  factory Puppets.fromJson(Map<String, dynamic> j) {
    final rigs = {
      for (final r in (j['rigs'] as Map<String, dynamic>? ?? {}).entries)
        r.key: {
          for (final p in (r.value as Map<String, dynamic>).entries)
            p.key: PuppetPose.fromJson(p.value as Map<String, dynamic>),
        },
    };
    return Puppets({
      for (final e in (j['puppets'] as Map<String, dynamic>).entries)
        e.key: PuppetSpec.fromJson(
          e.key,
          e.value as Map<String, dynamic>,
          rigs,
        ),
    });
  }

  final Map<String, PuppetSpec> _puppets;

  PuppetSpec? operator [](String id) => _puppets[id];
  Iterable<String> get ids => _puppets.keys;
}

Offset _offset(Object? v) => switch (v) {
  [final num x, final num y] => Offset(x.toDouble(), y.toDouble()),
  _ => throw FormatException('Expected [x, y], got $v'),
};

(Offset, double) _circle(Object? v) => switch (v) {
  [final num x, final num y, final num r] => (
    Offset(x.toDouble(), y.toDouble()),
    r.toDouble(),
  ),
  _ => throw FormatException('Expected [x, y, r], got $v'),
};

Color _color(Object? v) => switch (v) {
  final String hex when hex.startsWith('#') && hex.length == 7 => Color(
    0xFF000000 | int.parse(hex.substring(1), radix: 16),
  ),
  _ => throw FormatException('Expected #RRGGBB, got $v'),
};
