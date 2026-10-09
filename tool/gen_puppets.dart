// Draws Noori's puppets: characters built from separately moving parts.
//
//   dart run tool/gen_puppets.dart
//
// Writes one SVG per part to assets/illustrations/puppets/<id>/ (each drawn
// over the puppet's whole viewBox, so parts line up when stacked) and the
// rig to assets/content/puppets.json: pivots, faces, hands and poses. The
// faces themselves (eyes, brows, mouth, beak) are painted live by
// PuppetView so they can blink and change expression.
//
// Angles in poses are degrees; on paired parts positive turns towards the
// body's middle and negative swings outward. Style follows the rest of the
// app: flat shapes, soft radial gradients, no outlines.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

void main() {
  final puppets = <Puppet>[
    // Story 1: Ali and the Thirsty Sparrow.
    person(
      'ali',
      kid: true,
      skin: '#E8B48A',
      hair: '#2B2024',
      top: '#5B9BE0',
      bottom: '#4A86CC',
      shoes: '#8A5A3B',
      head: 'cap',
      accent: '#FFFFFF',
    ),
    person(
      'baba',
      kid: false,
      skin: '#D9A178',
      hair: '#3A2E2B',
      top: '#F1E7D3',
      bottom: '#E4D7BF',
      shoes: '#6B4A33',
      head: 'beard',
      accent: '#7A5A44',
      vest: true,
    ),
    sparrow(),
    // Story 2: Bunty Monkey Learns Bismillah.
    person(
      'ayesha',
      kid: true,
      skin: '#EDBF98',
      hair: '#3A2420',
      top: '#FF8FB8',
      bottom: '#FFD2E3',
      shoes: '#E0557F',
      head: 'ponytails',
      accent: '#FF5C93',
      frock: true,
    ),
    person(
      'nani',
      kid: false,
      skin: '#E2B48E',
      hair: '#D8D3D0',
      top: '#B49AD8',
      bottom: '#E8DDF3',
      shoes: '#7D6299',
      head: 'nani',
      accent: '#F7F2EA',
      dupatta: '#F7F2EA',
    ),
    monkey(),
    squirrel(),
    // Story 3: Dodo Elephant Tells the Truth.
    elephant(),
    bear(),
    // Story 4: Tippu Turtle's Seed.
    turtle(),
    rabbit('chiku'),
    // Story 5: Hamza and the Magic of Salam.
    person(
      'hamza',
      kid: true,
      skin: '#DDA57D',
      hair: '#231A1D',
      top: '#FFD03A',
      bottom: '#F2EBDD',
      shoes: '#7A5236',
      head: 'short',
      accent: '#E3A900',
    ),
    person(
      'zainab',
      kid: true,
      skin: '#C98F67',
      hair: '#1E1618',
      top: '#5CC8B8',
      bottom: '#FFFFFF',
      shoes: '#2E8F82',
      head: 'headband',
      accent: '#FFB703',
      frock: true,
    ),
    person(
      'bilal',
      kid: true,
      skin: '#E3AD84',
      hair: '#3B2A22',
      top: '#FF8A5B',
      bottom: '#5C6B8A',
      shoes: '#3A3F55',
      head: 'curly',
      accent: '#D9643A',
    ),
    person(
      'ammi',
      kid: false,
      skin: '#E6B58C',
      hair: '#2A1C1E',
      top: '#F49AAE',
      bottom: '#FBE3E8',
      shoes: '#B05570',
      head: 'dupatta',
      accent: '#3FB6A8',
      dupatta: '#3FB6A8',
    ),
    parrot('mithu'),
  ];

  final root = Directory('assets/illustrations/puppets');
  final json = <String, Object?>{};
  for (final p in puppets) {
    final dir = Directory('${root.path}/${p.id}')..createSync(recursive: true);
    for (final f in dir.listSync().whereType<File>()) {
      f.deleteSync();
    }
    for (final part in p.parts) {
      File('${dir.path}/${part.id}.svg')
          .writeAsStringSync(svg(p.w, p.h, part.defs, part.body));
    }
    json[p.id] = p.toJson();
  }
  const encoder = JsonEncoder.withIndent('  ');
  File(
    'assets/content/puppets.json',
  ).writeAsStringSync('${encoder.convert({'rigs': rigs, 'puppets': json})}\n');
  stdout.writeln('Wrote ${puppets.length} puppets.');
}

// ---- Rigs --------------------------------------------------------------------

/// Poses shared by everyone with two arms and two legs.
const rigs = {
  'biped': {
    'stand': {'upperL': -8, 'upperR': -8, 'foreL': 6, 'foreR': 6},
    'walk': {'upperL': -6, 'upperR': -6, 'foreL': 8, 'foreR': 8},
    'wave': {'upperL': -8, 'foreL': 6, 'upperR': -105, 'foreR': -65},
    'cheer': {'upperL': -150, 'upperR': -150, 'foreL': -10, 'foreR': -10},
    'hold_hand': {'upperL': -8, 'foreL': 6, 'upperR': -38, 'foreR': -6},
    'hold_hand_l': {'upperR': -8, 'foreR': 6, 'upperL': -38, 'foreL': -6},
    'hold': {'upperL': -8, 'foreL': 6, 'upperR': 8, 'foreR': 78},
    'hold_both': {'upperL': 8, 'foreL': 82, 'upperR': 8, 'foreR': 82},
    'drink': {'upperL': -8, 'foreL': 6, 'upperR': 4, 'foreR': 150, 'head': -6},
    'think': {
      'upperL': 6, 'foreL': 70, 'upperR': 10, 'foreR': 145, //
      'face': 'think', 'look': 'upRight',
    },
    'clap': {'upperL': 14, 'foreL': 112, 'upperR': 14, 'foreR': 112},
    'dua': {'upperL': 2, 'foreL': 128, 'upperR': 2, 'foreR': 128},
    'hug': {'upperL': -70, 'foreL': 105, 'upperR': -70, 'foreR': 105},
    'welcome': {'upperL': -60, 'upperR': -60, 'foreL': -20, 'foreR': -20},
    'point': {'upperL': -8, 'foreL': 6, 'upperR': -82, 'foreR': -4},
    'give': {'upperL': -8, 'foreL': 6, 'upperR': -58, 'foreR': 36},
    'shocked': {'upperL': 26, 'foreL': 160, 'upperR': 26, 'foreR': 160},
    'tummy': {'upperL': 14, 'foreL': 72, 'upperR': 14, 'foreR': 72},
    'shy': {
      'upperL': 10, 'foreL': 52, 'upperR': 10, 'foreR': 52, //
      'head': 8, 'face': 'shy', 'look': 'down',
    },
    'cover_eyes': {'upperL': 22, 'foreL': 168, 'upperR': 22, 'foreR': 168},
    'dig': {'upperL': 22, 'foreL': 34, 'upperR': 22, 'foreR': 34, 'head': 6},
    'pour': {'upperL': -8, 'foreL': 6, 'upperR': -52, 'foreR': 62},
    'reach': {'upperL': -8, 'foreL': 6, 'upperR': -165, 'foreR': -5},
    'carry': {'upperL': 18, 'foreL': 92, 'upperR': 18, 'foreR': 92},
    'thumbs_up': {'upperL': 14, 'foreL': 72, 'upperR': -30, 'foreR': 150},
    'hand_on_shoulder': {
      'upperL': -8, 'foreL': 6, 'upperR': -62, 'foreR': 28, //
    },
    'tuck': {'upperL': -40, 'foreL': 50, 'upperR': -40, 'foreR': 50},
    'sit': {
      'legL': -78, 'legR': -78, 'upperL': 10, 'foreL': 60, //
      'upperR': 10, 'foreR': 60, 'drop': 30,
    },
    'kneel': {
      'legL': -32, 'legR': -32, 'upperL': -8, 'foreL': 6, //
      'upperR': -8, 'foreR': 6, 'drop': 8,
    },
    'lie': {
      'upperL': 4,
      'foreL': 20,
      'upperR': 4,
      'foreR': 20,
      'face': 'sleep',
    },
    'hang': {'upperL': -170, 'foreL': 0, 'upperR': -170, 'foreR': 0},
    'kneel_pat': {
      'legL': -32, 'legR': -32, 'drop': 8, 'upperL': -8, 'foreL': 6, //
      'upperR': -62, 'foreR': 28,
    },
  },
  'bird': {
    'stand': <String, Object>{},
    'spread': {'wingL': -75, 'wingR': -75},
    'fly': {'wingL': -40, 'wingR': -40, 'wing': -30, 'legs': -30},
    'tired': {'head': 16, 'wing': 12, 'tail': 10, 'face': 'tired'},
    'drink': {'head': 38, 'tail': -14},
    'sleep': {'head': 10, 'face': 'sleep'},
  },
  'elephant': {
    'stand': <String, Object>{},
    'kick': {'legF2': -38, 'trunk': -10},
    'spray': {'trunk': -95, 'trunkTip': -40, 'ear': -8},
    'trunk_up': {'trunk': -55, 'trunkTip': -45},
    'worried': {'head': 8, 'ear': 14, 'trunk': 12, 'trunkTip': 14},
    'hide': {'head': 10, 'ear': 10, 'trunk': 20},
  },
};

// ---- Model -------------------------------------------------------------------

class Part {
  Part(
    this.id,
    this.body, {
    required this.pivot,
    this.parent,
    this.mirror = false,
    this.defs = '',
  });

  final String id;
  final String body;
  final String defs;
  final List<num> pivot;
  final String? parent;
  final bool mirror;

  Map<String, Object?> toJson() => {
    'id': id,
    'pivot': pivot,
    if (parent != null) 'parent': parent,
    if (mirror) 'mirror': true,
  };
}

class Puppet {
  Puppet(
    this.id, {
    required this.w,
    required this.h,
    required this.rig,
    required this.parts,
    required this.face,
    this.hands = const {},
    this.card = const [0, 1],
    this.tap = 'cheer',
    Map<String, Object?>? poses,
  }) : poses = {...?poses};

  final String id;
  final num w, h;
  final String rig;
  final List<Part> parts;
  final Map<String, Object?> face;
  final Map<String, Object?> hands;
  final List<num> card;
  final String tap;
  final Map<String, Object?> poses;

  Map<String, Object?> toJson() => {
    'rig': rig,
    'size': [w, h],
    'card': card,
    'tap': tap,
    'parts': [for (final p in parts) p.toJson()],
    'face': face,
    'hands': hands,
    if (poses.isNotEmpty) 'poses': poses,
  };
}

String svg(num w, num h, String defs, String body) =>
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $w $h">\n'
    '${defs.isEmpty ? '' : '  <defs>$defs</defs>\n'}'
    '$body\n</svg>\n';

String radial(
  String id,
  String light,
  String dark, {
  num cx = 0.38,
  num cy = 0.3,
}) =>
    '<radialGradient id="$id" cx="$cx" cy="$cy" r="0.8">'
    '<stop offset="0" stop-color="$light"/><stop offset="1" stop-color="$dark"/>'
    '</radialGradient>';

String linear(String id, String top, String bottom) =>
    '<linearGradient id="$id" x1="0" y1="0" x2="0" y2="1">'
    '<stop offset="0" stop-color="$top"/><stop offset="1" stop-color="$bottom"/>'
    '</linearGradient>';

/// Mixes two #RRGGBB colours.
String mix(String a, String b, double t) {
  int ch(String c, int i) =>
      int.parse(c.substring(1 + i * 2, 3 + i * 2), radix: 16);
  final out = [
    for (var i = 0; i < 3; i++)
      (ch(a, i) + (ch(b, i) - ch(a, i)) * t).round().clamp(0, 255),
  ];
  return '#${out.map((v) => v.toRadixString(16).padLeft(2, '0')).join().toUpperCase()}';
}

String darker(String c, [double t = 0.18]) => mix(c, '#2D2433', t);
String lighter(String c, [double t = 0.3]) => mix(c, '#FFFFFF', t);

String n(num v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

/// A limb segment from (x, y1) straight down to y2, with round ends.
String limb(num x, num y1, num y2, num width, String color) =>
    '  <line x1="${n(x)}" y1="${n(y1)}" x2="${n(x)}" y2="${n(y2)}" stroke="$color" '
    'stroke-width="${n(width)}" stroke-linecap="round"/>';

// ---- People --------------------------------------------------------------------

/// A child or a grown-up in shalwar kameez (or a frock), front view.
Puppet person(
  String id, {
  required bool kid,
  required String skin,
  required String hair,
  required String top,
  required String bottom,
  required String shoes,
  required String head,
  required String accent,
  bool frock = false,
  bool vest = false,
  String? dupatta,
}) {
  const w = 100, h = 170;
  // Proportions: children have big heads and short limbs.
  final hc = kid ? (50, 44, 26) : (50, 30, 20);
  final (hx, hy, hr) = hc;
  final shoulderY = kid ? 80 : 64;
  final sxL = kid ? 33 : 31, sxR = w - sxL;
  final upper = kid ? 20 : 27, fore = kid ? 17 : 23;
  final armW = kid ? 10.5 : 11.0;
  final handR = kid ? 5.5 : 6.0;
  final hip = kid ? 124 : 120;
  final legLen = kid ? 36 : 40;
  final legW = kid ? 12.5 : 13.5;
  final hem = kid ? 134 : 132;
  final torsoTop = kid ? 72 : 56;
  final sleeve = darker(top, 0.08);
  final skinDark = darker(skin, 0.12);

  Part leg(String side) {
    final x = side == 'L' ? 43 : 57;
    final out = side == 'L' ? -1 : 1;
    final end = hip + legLen;
    return Part(
      'leg$side',
      [
        '  <path d="M${n(x - legW / 2)} $hip L${n(x + legW / 2)} $hip '
            'Q${n(x + legW / 2 + 1.6)} ${n(hip + legLen * 0.6)} ${n(x + legW / 2 - 1)} $end '
            'L${n(x - legW / 2 + 1)} $end Q${n(x - legW / 2 - 1.6)} ${n(hip + legLen * 0.6)} '
            '${n(x - legW / 2)} $hip Z" fill="$bottom"/>',
        '  <rect x="${n(x - legW / 2 + 1)}" y="${end - 4}" width="${n(legW - 2)}" height="4" rx="2" fill="${darker(bottom, 0.12)}"/>',
        '  <path d="M${n(x - 7 + out)} ${end + 6} Q${n(x - 7 + out)} ${end - 1} ${n(x + out)} ${end - 1} '
            'Q${n(x + 7 + out)} ${end - 1} ${n(x + 8 + out * 2)} ${end + 5} Q${n(x + out)} ${end + 8} ${n(x - 7 + out)} ${end + 6} Z" fill="$shoes"/>',
        '  <ellipse cx="${n(x - 2 + out)}" cy="${end + 2}" rx="2.6" ry="1.4" fill="#FFFFFF" opacity="0.35"/>',
      ].join('\n'),
      pivot: [x, hip + 2],
      mirror: side == 'L',
    );
  }

  // The kameez (or frock) and the neck.
  final b = StringBuffer()
    ..writeln(
      '  <rect x="${hx - 5}" y="${hy + hr - 10}" width="10" height="${torsoTop - hy - hr + 14}" rx="4" fill="$skinDark"/>',
    );
  final defs = StringBuffer()..write(linear('t', lighter(top, 0.18), top));
  if (frock) {
    final waist = kid ? 100 : 92;
    b
      ..writeln(
        '  <path d="M${n(hx - 12)} $torsoTop Q$hx ${torsoTop - 3} ${n(hx + 12)} $torsoTop '
        'Q${n(sxR + 1)} ${torsoTop + 2} ${n(sxR + 1)} ${torsoTop + 10} L${n(sxR)} $waist L${n(sxL)} $waist '
        'L${n(sxL - 1)} ${torsoTop + 10} Q${n(sxL - 1)} ${torsoTop + 2} ${n(hx - 12)} $torsoTop Z" fill="url(#t)"/>',
      )
      ..writeln(
        '  <path d="M${n(sxL)} ${waist - 2} L${n(sxR)} ${waist - 2} Q${n(sxR + 11)} ${waist + 18} ${n(sxR + 13)} $hem '
        'Q$hx ${hem + 6} ${n(sxL - 13)} $hem Q${n(sxL - 11)} ${waist + 18} ${n(sxL)} ${waist - 2} Z" fill="$top"/>',
      )
      ..writeln(
        '  <g fill="${lighter(top, 0.45)}">${[for (var i = 0; i < 7; i++) '<circle cx="${n(sxL - 11 + i * ((sxR - sxL + 22) / 6))}" cy="${hem + 1}" r="4"/>'].join()}</g>',
      )
      ..writeln(
        '  <rect x="${n(sxL)}" y="${waist - 4}" width="${n(sxR - sxL)}" height="5" rx="2.5" fill="$accent"/>',
      )
      ..writeln(
        '  <path d="M$hx ${waist - 2} l-7 -5 l0 9 Z M$hx ${waist - 2} l7 -5 l0 9 Z" fill="$accent"/>'
        '<circle cx="$hx" cy="${waist - 2}" r="2.4" fill="${darker(accent, 0.2)}"/>',
      )
      ..writeln(
        '  <path d="M${hx - 6} $torsoTop Q$hx ${torsoTop + 7} ${hx + 6} $torsoTop" fill="none" stroke="${lighter(top, 0.55)}" stroke-width="2.4" stroke-linecap="round"/>',
      );
  } else {
    b
      ..writeln(
        '  <path d="M${n(hx - 12)} $torsoTop Q$hx ${torsoTop - 3} ${n(hx + 12)} $torsoTop '
        'Q${n(sxR + 1)} ${torsoTop + 2} ${n(sxR + 1.5)} ${torsoTop + 10} L${n(sxR + 4)} ${hem - 1} '
        'Q$hx ${hem + 3} ${n(sxL - 4)} ${hem - 1} L${n(sxL - 1.5)} ${torsoTop + 10} '
        'Q${n(sxL - 1)} ${torsoTop + 2} ${n(hx - 12)} $torsoTop Z" fill="url(#t)"/>',
      )
      ..writeln(
        '  <path d="M${n(sxL - 2)} ${hem - 14} L${n(sxL - 3.6)} ${hem - 1} M${n(sxR + 2)} ${hem - 14} L${n(sxR + 3.6)} ${hem - 1}" '
        'stroke="${darker(top, 0.2)}" stroke-width="1.6" stroke-linecap="round"/>',
      )
      ..writeln(
        '  <path d="M${hx - 6} $torsoTop L$hx ${torsoTop + 8} L${hx + 6} $torsoTop" fill="none" stroke="${darker(top, 0.22)}" stroke-width="2" stroke-linejoin="round"/>',
      )
      ..writeln(
        '  <path d="M$hx ${torsoTop + 8} V${torsoTop + (kid ? 26 : 34)}" stroke="${darker(top, 0.15)}" stroke-width="1.4"/>',
      )
      ..writeln(
        '  <g fill="$accent">${[for (var i = 0; i < 3; i++) '<circle cx="$hx" cy="${torsoTop + 12 + i * (kid ? 6 : 8)}" r="1.5"/>'].join()}</g>',
      );
  }
  if (vest) {
    final vb = torsoTop + 50;
    b
      ..writeln(
        '  <path d="M${n(hx - 13)} ${torsoTop + 1} Q${n(sxL)} ${torsoTop + 2} ${n(sxL - 1)} ${torsoTop + 10} L${n(sxL - 1)} $vb '
        'Q${n(hx - 10)} ${vb + 4} ${n(hx - 3)} ${vb + 2} L${n(hx - 3)} ${torsoTop + 22} Z" fill="$accent"/>',
      )
      ..writeln(
        '  <path d="M${n(hx + 13)} ${torsoTop + 1} Q${n(sxR)} ${torsoTop + 2} ${n(sxR + 1)} ${torsoTop + 10} L${n(sxR + 1)} $vb '
        'Q${n(hx + 10)} ${vb + 4} ${n(hx + 3)} ${vb + 2} L${n(hx + 3)} ${torsoTop + 22} Z" fill="$accent"/>',
      )
      ..writeln(
        '  <path d="M${sxL + 4} ${torsoTop + 30} h8 M${sxR - 12} ${torsoTop + 30} h8" stroke="${darker(accent, 0.25)}" stroke-width="1.6" stroke-linecap="round"/>',
      );
  }
  if (dupatta != null && !vest) {
    // A dupatta across the chest, over one shoulder.
    b.writeln(
      '  <path d="M${sxL - 2} ${torsoTop + 4} Q$hx ${torsoTop + 30} ${sxR + 2} ${torsoTop + 14} L${sxR + 3} ${torsoTop + 24} '
      'Q$hx ${torsoTop + 42} ${sxL - 2} ${torsoTop + 14} Z" fill="$dupatta"/>'
      '<path d="M${sxL - 2} ${torsoTop + 14} Q$hx ${torsoTop + 42} ${sxR + 3} ${torsoTop + 24}" fill="none" stroke="${darker(dupatta, 0.15)}" stroke-width="1.6"/>',
    );
  }
  final body = Part(
    'body',
    b.toString().trimRight(),
    defs: defs.toString(),
    pivot: [hx, hip],
  );

  // The head: ears, face, hair or headwear.
  final hd = StringBuffer();
  final hdefs = radial('s', lighter(skin, 0.22), skin);
  final earY = hy + hr * 0.12;
  void ears() {
    for (final ex in [hx - hr + 0.5, hx + hr - 0.5]) {
      hd
        ..writeln(
          '  <circle cx="${n(ex)}" cy="${n(earY)}" r="${n(hr * 0.21)}" fill="$skin"/>',
        )
        ..writeln(
          '  <circle cx="${n(ex)}" cy="${n(earY)}" r="${n(hr * 0.11)}" fill="$skinDark"/>',
        );
    }
  }

  void face() =>
      hd.writeln('  <circle cx="$hx" cy="$hy" r="$hr" fill="url(#s)"/>');

  final hairHi = lighter(hair, 0.25);
  switch (head) {
    case 'cap':
      ears();
      face();
      hd
        ..writeln(
          '  <path d="M${hx - hr + 1} ${hy - 2} Q${hx - hr} ${hy - 10} ${hx - hr + 6} ${hy - 12} L${hx - hr + 7} ${hy + 2} Q${hx - hr + 3} $hy ${hx - hr + 1} ${hy + 4} Z" fill="$hair"/>',
        )
        ..writeln(
          '  <path d="M${hx + hr - 1} ${hy - 2} Q${hx + hr} ${hy - 10} ${hx + hr - 6} ${hy - 12} L${hx + hr - 7} ${hy + 2} Q${hx + hr - 3} $hy ${hx + hr - 1} ${hy + 4} Z" fill="$hair"/>',
        )
        ..writeln(
          '  <path d="M${hx - hr + 1} ${hy - 10} Q${hx - hr + 2} ${hy - hr - 8} $hx ${hy - hr - 9} Q${hx + hr - 2} ${hy - hr - 8} ${hx + hr - 1} ${hy - 10} Q$hx ${hy - 17} ${hx - hr + 1} ${hy - 10} Z" fill="$accent"/>',
        )
        ..writeln(
          '  <path d="M${hx - hr + 1} ${hy - 10} Q$hx ${hy - 17} ${hx + hr - 1} ${hy - 10} L${hx + hr - 1} ${hy - 6} Q$hx ${hy - 13} ${hx - hr + 1} ${hy - 6} Z" fill="#E1E8EE"/>',
        )
        ..writeln(
          '  <g fill="#BFD3E6">${[for (var i = -3; i <= 3; i++) '<circle cx="${hx + i * 6}" cy="${hy - 22 + (i * i) * 0.5}" r="1.3"/>'].join()}</g>',
        )
        ..writeln(
          '  <path d="M${hx - 12} ${hy - hr - 4} Q$hx ${hy - hr - 8} ${hx + 8} ${hy - hr - 5}" fill="none" stroke="#FFFFFF" stroke-width="2.5" stroke-linecap="round" opacity="0.8"/>',
        );
    case 'short' || 'curly':
      ears();
      face();
      hd.writeln(
        '  <path d="M${hx - hr + 1} ${hy + 1} Q${hx - hr - 2} ${hy - hr - 1} $hx ${hy - hr - 2} Q${hx + hr + 2} ${hy - hr - 1} ${hx + hr - 1} ${hy + 1} '
        'Q${hx + hr - 3} ${hy - 12} ${hx + 14} ${hy - 16} Q${hx + 6} ${hy - 10} ${hx - 4} ${hy - 14} Q${hx - 12} ${hy - 10} ${hx - 19} ${hy - 13} Q${hx - hr + 1} ${hy - 8} ${hx - hr + 1} ${hy + 1} Z" fill="$hair"/>',
      );
      if (head == 'curly') {
        hd.writeln(
          '  <g fill="$hair">${[for (var i = -3; i <= 3; i++) '<circle cx="${hx + i * 7}" cy="${hy - hr + 1 + (i * i) * 0.9}" r="6"/>'].join()}</g>',
        );
      }
      hd.writeln(
        '  <path d="M${hx - 10} ${hy - hr + 3} Q${hx - 2} ${hy - hr} ${hx + 6} ${hy - hr + 2}" fill="none" stroke="$hairHi" stroke-width="2.4" stroke-linecap="round"/>',
      );
    case 'ponytails':
      for (final side in [-1, 1]) {
        final px = hx + side * (hr + 4);
        hd
          ..writeln(
            '  <ellipse cx="$px" cy="${hy + 8}" rx="7.5" ry="13" fill="$hair" transform="rotate(${side * -14} $px ${hy + 8})"/>',
          )
          ..writeln(
            '  <path d="M${px - side * 3} ${hy - 9} l${side * 9} -6 l0 12 Z M${px - side * 3} ${hy - 9} l${side * -9} -6 l0 12 Z" fill="$accent"/>',
          )
          ..writeln(
            '  <circle cx="${px - side * 3}" cy="${hy - 9}" r="2.6" fill="${darker(accent, 0.2)}"/>',
          );
      }
      ears();
      face();
      hd
        ..writeln(
          '  <path d="M${hx - hr + 0.5} ${hy + 3} Q${hx - hr - 3} ${hy - hr} $hx ${hy - hr - 2} Q${hx + hr + 3} ${hy - hr} ${hx + hr - 0.5} ${hy + 3} '
          'Q${hx + hr - 3} ${hy - 13} ${hx + 3} ${hy - 19} Q$hx ${hy - 12} ${hx - 3} ${hy - 19} Q${hx - hr + 3} ${hy - 13} ${hx - hr + 0.5} ${hy + 3} Z" fill="$hair"/>',
        )
        ..writeln(
          '  <path d="M${hx - 14} ${hy - hr + 5} Q${hx - 8} ${hy - hr + 1} ${hx - 2} ${hy - hr + 3}" fill="none" stroke="$hairHi" stroke-width="2.2" stroke-linecap="round"/>',
        );
    case 'headband':
      hd.writeln(
        '  <path d="M${hx - hr - 3} ${hy + 6} Q${hx - hr - 5} ${hy - hr - 3} $hx ${hy - hr - 4} Q${hx + hr + 5} ${hy - hr - 3} ${hx + hr + 3} ${hy + 6} '
        'L${hx + hr + 2} ${hy + 18} Q${hx + hr - 2} ${hy + 22} ${hx + hr - 5} ${hy + 15} L${hx - hr + 5} ${hy + 15} Q${hx - hr + 2} ${hy + 22} ${hx - hr - 2} ${hy + 18} Z" fill="$hair"/>',
      );
      ears();
      face();
      hd
        ..writeln(
          '  <path d="M${hx - hr + 1} ${hy - 3} Q${hx - hr + 2} ${hy - hr - 1} $hx ${hy - hr - 1} Q${hx + hr - 2} ${hy - hr - 1} ${hx + hr - 1} ${hy - 3} '
          'Q${hx + 14} ${hy - 15} ${hx + 2} ${hy - 13} Q${hx - 10} ${hy - 16} ${hx - hr + 1} ${hy - 3} Z" fill="$hair"/>',
        )
        ..writeln(
          '  <path d="M${hx - hr + 3} ${hy - 12} Q$hx ${hy - hr - 6} ${hx + hr - 3} ${hy - 12}" fill="none" stroke="$accent" stroke-width="4.5" stroke-linecap="round"/>',
        )
        ..writeln(
          '  <circle cx="${hx + 15}" cy="${hy - 20}" r="4" fill="${lighter(accent, 0.2)}"/>'
          '<circle cx="${hx + 15}" cy="${hy - 20}" r="1.6" fill="#FFFFFF"/>',
        );
    case 'beard':
      ears();
      face();
      hd
        ..writeln(
          '  <path d="M${hx - hr + 0.5} ${hy - 1} Q${hx - hr - 1} ${hy - hr - 1} $hx ${hy - hr - 1.5} Q${hx + hr + 1} ${hy - hr - 1} ${hx + hr - 0.5} ${hy - 1} '
          'Q${hx + hr - 3} ${hy - 11} ${hx + 8} ${hy - 13} Q$hx ${hy - 10} ${hx - 8} ${hy - 13} Q${hx - hr + 3} ${hy - 11} ${hx - hr + 0.5} ${hy - 1} Z" fill="$hair"/>',
        )
        ..writeln(
          '  <path d="M${hx - hr + 1} ${hy + 2} Q${hx - hr + 2} ${hy + hr + 4} $hx ${hy + hr + 6} Q${hx + hr - 2} ${hy + hr + 4} ${hx + hr - 1} ${hy + 2} '
          'Q${hx + hr - 4} ${hy + 10} ${hx + 9} ${hy + 15} Q$hx ${hy + 19} ${hx - 9} ${hy + 15} Q${hx - hr + 4} ${hy + 10} ${hx - hr + 1} ${hy + 2} Z" fill="$hair"/>',
        )
        ..writeln(
          '  <path d="M${hx - 8} ${hy + 10.5} Q${hx - 4} ${hy + 7.5} $hx ${hy + 9} Q${hx + 4} ${hy + 7.5} ${hx + 8} ${hy + 10.5} Q${hx + 4} ${hy + 12} $hx ${hy + 10.8} Q${hx - 4} ${hy + 12} ${hx - 8} ${hy + 10.5} Z" fill="$hair"/>',
        )
        ..writeln(
          '  <path d="M${hx - 8} ${hy + hr + 1} Q$hx ${hy + hr + 4} ${hx + 6} ${hy + hr + 1}" fill="none" stroke="${lighter(hair, 0.35)}" stroke-width="1.6" stroke-linecap="round"/>',
        );
    case 'dupatta' || 'nani':
      final cloth = dupatta ?? accent;
      final trim = head == 'nani' ? '#C6B0E6' : lighter(cloth, 0.35);
      hd.writeln(
        '  <path d="M${hx - hr - 5} ${hy + 4} Q${hx - hr - 7} ${hy - hr - 6} $hx ${hy - hr - 7} Q${hx + hr + 7} ${hy - hr - 6} ${hx + hr + 5} ${hy + 4} '
        'L${hx + hr + 7} ${hy + hr + 12} Q${hx + hr} ${hy + hr + 16} ${hx + hr - 3} ${hy + hr + 6} L${hx - hr + 3} ${hy + hr + 6} Q${hx - hr} ${hy + hr + 16} ${hx - hr - 7} ${hy + hr + 12} Z" fill="$cloth"/>',
      );
      face();
      hd
        ..writeln(
          '  <path d="M${hx - 13} ${hy - 12} Q$hx ${hy - 20} ${hx + 13} ${hy - 12} Q${hx + 6} ${hy - 15} $hx ${hy - 14} Q${hx - 6} ${hy - 15} ${hx - 13} ${hy - 12} Z" fill="$hair"/>',
        )
        ..writeln(
          '  <path d="M${hx - hr - 3} ${hy + 8} Q${hx - hr - 4} ${hy - hr - 3} $hx ${hy - hr - 4} Q${hx + hr + 4} ${hy - hr - 3} ${hx + hr + 3} ${hy + 8} '
          'L${hx + hr - 1} ${hy + 8} Q${hx + hr - 1} ${hy - hr + 3} $hx ${hy - hr + 2} Q${hx - hr + 1} ${hy - hr + 3} ${hx - hr + 1} ${hy + 8} Z" fill="$cloth"/>',
        )
        ..writeln(
          '  <path d="M${hx - hr - 1} ${hy + 8} Q${hx - hr - 1} ${hy - hr} $hx ${hy - hr - 1} Q${hx + hr + 1} ${hy - hr} ${hx + hr + 1} ${hy + 8}" fill="none" stroke="$trim" stroke-width="2"/>',
        );
      if (head == 'nani') {
        hd.writeln(
          '  <g fill="none" stroke="#8C7A99" stroke-width="1.4"><circle cx="${hx - 7.5}" cy="${hy + 2}" r="5.6"/><circle cx="${hx + 7.5}" cy="${hy + 2}" r="5.6"/>'
          '<path d="M${hx - 1.9} ${hy + 1.5} Q$hx $hy ${hx + 1.9} ${hy + 1.5}"/></g>',
        );
      }
  }
  final headPart = Part(
    'head',
    hd.toString().trimRight(),
    defs: hdefs,
    pivot: [hx, hy + hr],
  );

  Part arm(String side, {required bool upperArm}) {
    final x = side == 'L' ? sxL : sxR;
    final y0 = upperArm ? shoulderY : shoulderY + upper;
    final y1 = upperArm ? shoulderY + upper : shoulderY + upper + fore;
    final parts = <String>[limb(x, y0, y1, armW, sleeve)];
    if (!upperArm) {
      parts
        ..add(
          '  <rect x="${n(x - armW / 2 - 0.5)}" y="${y1 - 2.5}" width="${n(armW + 1)}" height="3.6" rx="1.8" fill="${frock ? lighter(top, 0.45) : darker(top, 0.2)}"/>',
        )
        ..add(
          '  <circle cx="$x" cy="${n(y1 + handR - 0.5)}" r="$handR" fill="$skin"/>',
        )
        ..add(
          '  <path d="M${n(x - handR * 0.4)} ${n(y1 + handR * 1.3)} q${n(handR * 0.4)} ${n(handR * 0.5)} ${n(handR * 0.8)} 0" fill="none" stroke="$skinDark" stroke-width="1" stroke-linecap="round"/>',
        );
    }
    return Part(
      '${upperArm ? 'upper' : 'fore'}$side',
      parts.join('\n'),
      pivot: [x, y0],
      parent: upperArm ? null : 'upper$side',
      mirror: side == 'L',
    );
  }

  final handY = shoulderY + upper + fore + handR - 0.5;
  final eye = kid ? (9.5, 3.0, 4.6) : (7.5, 2.0, 3.7);
  final (eyeDx, eyeDy, eyeR) = eye;
  final puppet = Puppet(
    id,
    w: w,
    h: h,
    rig: 'biped',
    parts: [
      leg('L'),
      leg('R'),
      body,
      headPart,
      arm('L', upperArm: true),
      arm('L', upperArm: false),
      arm('R', upperArm: true),
      arm('R', upperArm: false),
    ],
    face: {
      'part': 'head',
      'skin': skin,
      'eyes': [
        [hx - eyeDx, hy + eyeDy, eyeR],
        [hx + eyeDx, hy + eyeDy, eyeR],
      ],
      'mouth': [hx, hy + (kid ? 14 : 12.5), kid ? 9 : 7.5],
      'cheeks': [
        [hx - hr * 0.62, hy + hr * 0.42, kid ? 4.2 : 3.2],
        [hx + hr * 0.62, hy + hr * 0.42, kid ? 4.2 : 3.2],
      ],
      'brows': head == 'nani' ? '#A89A9E' : hair,
    },
    hands: {
      'L': {
        'part': 'foreL',
        'at': [sxL, handY],
      },
      'R': {
        'part': 'foreR',
        'at': [sxR, handY],
      },
    },
    card: kid ? [0, 0.6] : [0, 0.5],
    tap: 'cheer',
  );
  return withReach(
    puppet,
    sL: [sxL, shoulderY],
    sR: [sxR, shoulderY],
    a: upper,
    b: fore + handR - 0.5,
    chest: shoulderY + (kid ? 12 : 16),
    belly: shoulderY + (kid ? 30 : 40),
  );
}

// ---- Animals ---------------------------------------------------------------------

/// Bunty: a cheeky brown monkey, front view.
Puppet monkey() {
  const fur = '#94603F', furHi = '#C38A5E', face = '#F3D1AC', inner = '#F0C9A0';
  return withReach(
    Puppet(
      'bunty',
      w: 120,
      h: 150,
      rig: 'biped',
      parts: [
        Part(
          'tail',
          '  <path d="M80 120 C104 118 112 96 102 84 C96 78 88 84 94 90" fill="none" stroke="$fur" stroke-width="6" stroke-linecap="round"/>',
          pivot: [78, 120],
        ),
        for (final (side, x) in [('L', 47), ('R', 73)])
          Part(
            'leg$side',
            '${limb(x, 124, 136, 10, fur)}\n'
                '  <ellipse cx="${x + (side == 'L' ? -1 : 1)}" cy="141" rx="11" ry="6.5" fill="$fur"/>\n'
                '  <ellipse cx="${x + (side == 'L' ? -1 : 1)}" cy="140" rx="6" ry="3" fill="$inner"/>',
            pivot: [x, 124],
            mirror: side == 'L',
          ),
        Part(
          'body',
          '  <ellipse cx="60" cy="108" rx="26" ry="30" fill="url(#b)"/>\n'
              '  <ellipse cx="60" cy="114" rx="16" ry="19" fill="$face"/>',
          defs: radial('b', furHi, fur),
          pivot: [60, 138],
        ),
        Part(
          'head',
          '  <circle cx="32" cy="52" r="10" fill="$fur"/><circle cx="32" cy="52" r="6" fill="$inner"/>\n'
              '  <circle cx="88" cy="52" r="10" fill="$fur"/><circle cx="88" cy="52" r="6" fill="$inner"/>\n'
              '  <circle cx="60" cy="52" r="26" fill="url(#b)"/>\n'
              '  <path d="M54 28 q6 -10 14 -4 q-6 0 -8 6 Z" fill="$fur"/>\n'
              '  <circle cx="51" cy="48" r="10.5" fill="$face"/><circle cx="69" cy="48" r="10.5" fill="$face"/>\n'
              '  <ellipse cx="60" cy="62" rx="17" ry="12" fill="$face"/>\n'
              '  <circle cx="57" cy="58" r="1.5" fill="#6B4430"/><circle cx="63" cy="58" r="1.5" fill="#6B4430"/>',
          defs: radial('b', furHi, fur),
          pivot: [60, 78],
        ),
        for (final (side, x) in [('L', 37), ('R', 83)]) ...[
          Part(
            'upper$side',
            limb(x, 92, 108, 8.5, fur),
            pivot: [x, 92],
            mirror: side == 'L',
          ),
          Part(
            'fore$side',
            '${limb(x, 108, 122, 8.5, fur)}\n  <circle cx="$x" cy="125" r="5.2" fill="$face"/>',
            pivot: [x, 108],
            parent: 'upper$side',
            mirror: side == 'L',
          ),
        ],
      ],
      face: {
        'part': 'head',
        'skin': face,
        'eyes': [
          [52, 48, 4.3],
          [68, 48, 4.3],
        ],
        'mouth': [60, 65, 11],
        'cheeks': [
          [44, 60, 3.6],
          [76, 60, 3.6],
        ],
        'brows': '#6B4430',
      },
      hands: {
        'L': {
          'part': 'foreL',
          'at': [37, 125],
        },
        'R': {
          'part': 'foreR',
          'at': [83, 125],
        },
      },
      tap: 'cheer+tail',
    ),
    sL: [37, 92],
    sR: [83, 92],
    a: 16,
    b: 17,
    chest: 100,
    belly: 114,
  );
}

/// Bhalu Chacha: a big gentle bear in a little red waistcoat.
Puppet bear() {
  const fur = '#8A5A34',
      furHi = '#B4824F',
      muzzle = '#E8C9A0',
      vest = '#C8553D';
  return withReach(
    Puppet(
      'bhalu',
      w: 130,
      h: 170,
      rig: 'biped',
      parts: [
        for (final (side, x) in [('L', 49), ('R', 81)])
          Part(
            'leg$side',
            '${limb(x, 132, 152, 19, fur)}\n'
                '  <ellipse cx="${x + (side == 'L' ? -2 : 2)}" cy="160" rx="14" ry="8.5" fill="$fur"/>\n'
                '  <ellipse cx="${x + (side == 'L' ? -2 : 2)}" cy="159" rx="8" ry="4.5" fill="$muzzle"/>',
            pivot: [x, 132],
            mirror: side == 'L',
          ),
        Part(
          'body',
          '  <ellipse cx="65" cy="114" rx="38" ry="42" fill="url(#b)"/>\n'
              '  <ellipse cx="65" cy="122" rx="23" ry="28" fill="$muzzle"/>\n'
              '  <path d="M33 92 Q40 78 54 75 L58 146 Q42 146 29 132 Q26 110 33 92 Z" fill="$vest"/>\n'
              '  <path d="M97 92 Q90 78 76 75 L72 146 Q88 146 101 132 Q104 110 97 92 Z" fill="$vest"/>\n'
              '  <g fill="#FFD166"><circle cx="54" cy="96" r="2.4"/><circle cx="55" cy="112" r="2.4"/><circle cx="56" cy="128" r="2.4"/></g>\n'
              '  <path d="M38 100 h10 M82 100 h10" stroke="${darker(vest, 0.25)}" stroke-width="2" stroke-linecap="round"/>',
          defs: radial('b', furHi, fur),
          pivot: [65, 156],
        ),
        Part(
          'head',
          '  <circle cx="37" cy="30" r="12" fill="$fur"/><circle cx="37" cy="30" r="6.5" fill="#D9A77A"/>\n'
              '  <circle cx="93" cy="30" r="12" fill="$fur"/><circle cx="93" cy="30" r="6.5" fill="#D9A77A"/>\n'
              '  <circle cx="65" cy="50" r="32" fill="url(#b)"/>\n'
              '  <ellipse cx="65" cy="64" rx="16" ry="12" fill="$muzzle"/>\n'
              '  <ellipse cx="65" cy="57.5" rx="6.5" ry="4.6" fill="#3B2A22"/><ellipse cx="63" cy="56" rx="2" ry="1.2" fill="#FFFFFF" opacity="0.6"/>\n'
              '  <path d="M65 62 V65" stroke="#3B2A22" stroke-width="1.6" stroke-linecap="round"/>',
          defs: radial('b', furHi, fur),
          pivot: [65, 80],
        ),
        for (final (side, x) in [('L', 31), ('R', 99)]) ...[
          Part(
            'upper$side',
            limb(x, 90, 114, 15, fur),
            pivot: [x, 90],
            mirror: side == 'L',
          ),
          Part(
            'fore$side',
            '${limb(x, 114, 132, 15, fur)}\n  <circle cx="$x" cy="137" r="8.5" fill="$fur"/>\n  <ellipse cx="$x" cy="139" rx="5" ry="3.6" fill="$muzzle"/>',
            pivot: [x, 114],
            parent: 'upper$side',
            mirror: side == 'L',
          ),
        ],
      ],
      face: {
        'part': 'head',
        'skin': furHi,
        'eyes': [
          [53, 46, 4.6],
          [77, 46, 4.6],
        ],
        'mouth': [65, 68, 10],
        'cheeks': [
          [45, 60, 4.6],
          [85, 60, 4.6],
        ],
        'brows': '#4A2F1E',
      },
      hands: {
        'L': {
          'part': 'foreL',
          'at': [31, 137],
        },
        'R': {
          'part': 'foreR',
          'at': [99, 137],
        },
      },
      card: [0, 0.62],
      tap: 'cheer',
    ),
    sL: [31, 90],
    sR: [99, 90],
    a: 24,
    b: 23,
    chest: 102,
    belly: 124,
  );
}

/// A rabbit in a hurry, with little red sneakers.
Puppet rabbit(String id) {
  const fur = '#E9CFAE',
      furDark = '#CFA57C',
      belly = '#FFF6EA',
      pink = '#F7B6C8';
  return withReach(
    Puppet(
      id,
      w: 120,
      h: 150,
      rig: 'biped',
      parts: [
        Part(
          'tail',
          '  <circle cx="90" cy="124" r="9" fill="$belly"/>',
          pivot: [84, 124],
        ),
        for (final (side, x) in [('L', 46), ('R', 74)])
          Part(
            'leg$side',
            '  <ellipse cx="${x + (side == 'L' ? -1 : 1)}" cy="142" rx="13" ry="7" fill="$fur"/>\n'
                '  <path d="M${x - 11 + (side == 'L' ? -1 : 1)} 143 Q${x + (side == 'L' ? -1 : 1)} 133 ${x + 12 + (side == 'L' ? -1 : 1)} 143 Q${x + (side == 'L' ? -1 : 1)} 151 ${x - 11 + (side == 'L' ? -1 : 1)} 143 Z" fill="#E63946"/>\n'
                '  <path d="M${x - 6} 141 h12" stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round"/>',
            pivot: [x, 134],
            mirror: side == 'L',
          ),
        Part(
          'body',
          '  <ellipse cx="60" cy="112" rx="29" ry="31" fill="url(#f)"/>\n'
              '  <ellipse cx="60" cy="118" rx="17" ry="20" fill="$belly"/>',
          defs: radial('f', lighter(fur, 0.4), fur),
          pivot: [60, 142],
        ),
        for (final (side, x, tilt) in [('L', 47, -8), ('R', 73, 8)])
          Part(
            'ear$side',
            '  <ellipse cx="$x" cy="22" rx="9" ry="24" fill="$fur" transform="rotate($tilt $x 22)"/>\n'
                '  <ellipse cx="$x" cy="24" rx="4.5" ry="17" fill="$pink" transform="rotate($tilt $x 24)"/>',
            pivot: [x, 44],
            parent: 'head',
            mirror: side == 'L',
          ),
        Part(
          'head',
          '  <circle cx="60" cy="64" r="28" fill="url(#f)"/>\n'
              '  <ellipse cx="60" cy="70" rx="11" ry="8" fill="$belly"/>\n'
              '  <ellipse cx="60" cy="67.5" rx="3.8" ry="2.8" fill="#F28AA5"/>\n'
              '  <g stroke="$furDark" stroke-width="1" stroke-linecap="round"><path d="M44 68 h-9 M44 71 l-8 3 M76 68 h9 M76 71 l8 3"/></g>',
          defs: radial('f', lighter(fur, 0.4), fur),
          pivot: [60, 90],
        ),
        for (final (side, x) in [('L', 37), ('R', 83)]) ...[
          Part(
            'upper$side',
            limb(x, 98, 107, 10, fur),
            pivot: [x, 98],
            mirror: side == 'L',
          ),
          Part(
            'fore$side',
            '${limb(x, 107, 116, 10, fur)}\n  <circle cx="$x" cy="119" r="5.6" fill="$belly"/>',
            pivot: [x, 107],
            parent: 'upper$side',
            mirror: side == 'L',
          ),
        ],
      ],
      face: {
        'part': 'head',
        'skin': fur,
        'eyes': [
          [50, 59, 4.6],
          [70, 59, 4.6],
        ],
        'mouth': [60, 74, 9],
        'cheeks': [
          [42, 71, 4.6],
          [78, 71, 4.6],
        ],
      },
      hands: {
        'L': {
          'part': 'foreL',
          'at': [37, 119],
        },
        'R': {
          'part': 'foreR',
          'at': [83, 119],
        },
      },
      tap: 'hop+cheer',
    ),
    sL: [37, 98],
    sR: [83, 98],
    a: 9,
    b: 12,
    chest: 104,
    belly: 116,
  );
}

/// A small orange squirrel with a big fluffy tail.
Puppet squirrel() {
  const fur = '#D9874A', furHi = '#EFA866', belly = '#F6DDBE';
  return withReach(
    Puppet(
      'squirrel',
      w: 110,
      h: 140,
      rig: 'biped',
      parts: [
        Part(
          'tail',
          '  <path d="M68 122 C102 120 112 84 98 56 C90 40 72 44 78 60 C86 78 84 100 64 110 Z" fill="url(#t)"/>\n'
              '  <path d="M92 66 C98 80 96 98 86 108" fill="none" stroke="$belly" stroke-width="3" stroke-linecap="round" opacity="0.6"/>',
          defs: radial('t', furHi, '#B9672F'),
          pivot: [68, 118],
        ),
        for (final (side, x) in [('L', 46), ('R', 64)])
          Part(
            'leg$side',
            '  <ellipse cx="${x + (side == 'L' ? -2 : 2)}" cy="134" rx="9" ry="5" fill="#B9672F"/>',
            pivot: [x, 126],
            mirror: side == 'L',
          ),
        Part(
          'body',
          '  <ellipse cx="55" cy="106" rx="21" ry="26" fill="url(#b)"/>\n  <ellipse cx="55" cy="112" rx="12" ry="17" fill="$belly"/>',
          defs: radial('b', furHi, fur),
          pivot: [55, 132],
        ),
        Part(
          'head',
          '  <path d="M34 40 L36 16 L50 34 Z M76 40 L74 16 L60 34 Z" fill="$fur"/>\n'
              '  <path d="M37 32 L38 22 L45 32 Z M73 32 L72 22 L65 32 Z" fill="#F2B49A"/>\n'
              '  <path d="M36 16 l-2 -6 M36 16 l3 -6 M74 16 l2 -6 M74 16 l-3 -6" stroke="$fur" stroke-width="2" stroke-linecap="round"/>\n'
              '  <circle cx="55" cy="52" r="22" fill="url(#b)"/>\n'
              '  <ellipse cx="55" cy="61" rx="11" ry="8" fill="$belly"/>\n'
              '  <ellipse cx="55" cy="57" rx="3.2" ry="2.4" fill="#5A3A26"/>',
          defs: radial('b', furHi, fur),
          pivot: [55, 74],
        ),
        for (final (side, x) in [('L', 40), ('R', 70)]) ...[
          Part(
            'upper$side',
            limb(x, 90, 99, 7, fur),
            pivot: [x, 90],
            mirror: side == 'L',
          ),
          Part(
            'fore$side',
            '${limb(x, 99, 106, 7, fur)}\n  <circle cx="$x" cy="108" r="4" fill="$belly"/>',
            pivot: [x, 99],
            parent: 'upper$side',
            mirror: side == 'L',
          ),
        ],
      ],
      face: {
        'part': 'head',
        'skin': fur,
        'eyes': [
          [47, 49, 3.8],
          [63, 49, 3.8],
        ],
        'mouth': [55, 63, 7],
        'cheeks': [
          [40, 58, 3.4],
          [70, 58, 3.4],
        ],
      },
      hands: {
        'L': {
          'part': 'foreL',
          'at': [40, 108],
        },
        'R': {
          'part': 'foreR',
          'at': [70, 108],
        },
      },
      tap: 'hop+tail',
    ),
    sL: [40, 90],
    sR: [70, 90],
    a: 9,
    b: 9,
    chest: 96,
    belly: 108,
  );
}

/// Tippu: an upright turtle in a little green cap.
Puppet turtle() {
  const skin = '#8ED081',
      skinHi = '#B4E6A6',
      shell = '#7A8F3A',
      shellHi = '#B7C96A';
  const plate = '#EDE3A8';
  return withReach(
    Puppet(
      'tippu',
      w: 120,
      h: 150,
      rig: 'biped',
      parts: [
        for (final (side, x) in [('L', 47), ('R', 73)])
          Part(
            'leg$side',
            '${limb(x, 126, 138, 15, skin)}\n  <ellipse cx="${x + (side == 'L' ? -2 : 2)}" cy="142" rx="11" ry="6.5" fill="$skin"/>\n'
                '  <g fill="#6FB866"><circle cx="${x - 5}" cy="145" r="1.6"/><circle cx="$x" cy="146" r="1.6"/><circle cx="${x + 5}" cy="145" r="1.6"/></g>',
            pivot: [x, 126],
            mirror: side == 'L',
          ),
        Part(
          'body',
          '  <ellipse cx="60" cy="102" rx="35" ry="37" fill="url(#s)"/>\n'
              '  <g fill="#D3DE8E" opacity="0.8"><path d="M26 92 l6 -6 l8 2 l1 9 l-7 5 l-7 -3 Z"/><path d="M94 92 l-6 -6 l-8 2 l-1 9 l7 5 l7 -3 Z"/></g>\n'
              '  <ellipse cx="60" cy="106" rx="24" ry="31" fill="$plate"/>\n'
              '  <path d="M38 94 h44 M37 108 h46 M40 122 h40 M60 76 V136" stroke="#D2C47E" stroke-width="2" stroke-linecap="round"/>',
          defs: radial('s', shellHi, shell),
          pivot: [60, 139],
        ),
        Part(
          'head',
          '${limb(60, 62, 74, 18, skin)}\n'
              '  <circle cx="60" cy="48" r="24" fill="url(#k)"/>\n'
              '  <path d="M36 40 Q37 18 60 17 Q83 18 84 40 Q60 33 36 40 Z" fill="#2E8B57"/>\n'
              '  <path d="M62 37 Q84 33 96 40 Q84 46 64 42 Z" fill="#23744A"/>\n'
              '  <path d="M40 34 Q60 28 80 34" fill="none" stroke="#5FC48A" stroke-width="2.2" stroke-linecap="round"/>\n'
              '  <circle cx="60" cy="17" r="3.4" fill="#FFB703"/>\n'
              '  <path d="M46 24 Q52 20 58 21" fill="none" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round" opacity="0.5"/>',
          defs: radial('k', skinHi, skin),
          pivot: [60, 72],
        ),
        for (final (side, x) in [('L', 28), ('R', 92)]) ...[
          Part(
            'upper$side',
            limb(x, 88, 101, 11, skin),
            pivot: [x, 88],
            mirror: side == 'L',
          ),
          Part(
            'fore$side',
            '${limb(x, 101, 113, 11, skin)}\n  <circle cx="$x" cy="116" r="6.2" fill="$skin"/>',
            pivot: [x, 101],
            parent: 'upper$side',
            mirror: side == 'L',
          ),
        ],
      ],
      face: {
        'part': 'head',
        'skin': skin,
        'eyes': [
          [51, 50, 4.4],
          [69, 50, 4.4],
        ],
        'mouth': [60, 61, 10],
        'cheeks': [
          [43, 57, 4],
          [77, 57, 4],
        ],
      },
      hands: {
        'L': {
          'part': 'foreL',
          'at': [28, 116],
        },
        'R': {
          'part': 'foreR',
          'at': [92, 116],
        },
      },
      tap: 'cheer',
    ),
    sL: [28, 88],
    sR: [92, 88],
    a: 13,
    b: 15,
    chest: 96,
    belly: 112,
  );
}

/// Dodo: a baby elephant with big floppy ears, seen from the side (facing
/// right).
Puppet elephant() {
  const hi = '#C9DAE8', base = '#93ADC6', far = '#8BA6BF', near = '#A3BAD0';
  return Puppet(
    'dodo',
    w: 160,
    h: 150,
    rig: 'elephant',
    parts: [
      Part(
        'tail',
        '  <path d="M22 88 q-12 4 -12 16" fill="none" stroke="$far" stroke-width="3" stroke-linecap="round"/>\n'
            '  <path d="M10 104 l-3 5 M10 104 l1 6 M10 104 l4 4" stroke="$far" stroke-width="2" stroke-linecap="round"/>',
        pivot: [22, 88],
      ),
      Part(
        'legB1',
        '  <rect x="34" y="104" width="18" height="40" rx="9" fill="$far"/>',
        pivot: [43, 108],
      ),
      Part(
        'legF1',
        '  <rect x="84" y="104" width="18" height="40" rx="9" fill="$far"/>',
        pivot: [93, 108],
      ),
      Part(
        'body',
        '  <ellipse cx="70" cy="96" rx="52" ry="36" fill="url(#b)"/>\n'
            '  <path d="M40 80 Q60 70 84 74" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" opacity="0.35"/>',
        defs: radial('b', hi, base),
        pivot: [70, 140],
      ),
      Part(
        'legB2',
        '  <rect x="50" y="108" width="18" height="38" rx="9" fill="$near"/>\n  <rect x="50" y="140" width="18" height="6" rx="3" fill="#E6EEF5"/>',
        pivot: [59, 112],
      ),
      Part(
        'legF2',
        '  <rect x="98" y="106" width="18" height="40" rx="9" fill="$near"/>\n  <rect x="98" y="140" width="18" height="6" rx="3" fill="#E6EEF5"/>',
        pivot: [107, 110],
      ),
      Part(
        'ear',
        '  <ellipse cx="102" cy="62" rx="21" ry="28" fill="$far"/>\n  <ellipse cx="104" cy="63" rx="13" ry="19" fill="#F2B8C6" opacity="0.75"/>',
        pivot: [108, 40],
        parent: 'head',
      ),
      Part(
        'head',
        '  <circle cx="126" cy="58" r="26" fill="url(#b)"/>\n'
            '  <path d="M112 40 Q122 34 132 36" fill="none" stroke="#FFFFFF" stroke-width="2.5" stroke-linecap="round" opacity="0.45"/>',
        defs: radial('b', hi, base),
        pivot: [112, 80],
      ),
      Part(
        'trunk',
        '  <path d="M130 70 C140 74 150 84 150 98 L140 98 C140 90 136 84 128 80 Z" fill="$near"/>\n'
            '  <path d="M141 86 h7" stroke="$far" stroke-width="2" stroke-linecap="round"/>',
        pivot: [134, 74],
        parent: 'head',
      ),
      Part(
        'trunkTip',
        '  <path d="M140 96 L150 96 C152 106 150 114 146 118 C142 122 135 119 137 113 C140 108 140 102 140 96 Z" fill="$near"/>\n'
            '  <path d="M142 106 h7" stroke="$far" stroke-width="2" stroke-linecap="round"/>',
        pivot: [145, 97],
        parent: 'trunk',
      ),
    ],
    face: {
      'part': 'head',
      'skin': '#B6CADC',
      'eyes': [
        [133, 52, 4.6],
      ],
      'mouth': [124, 76, 9],
      'cheeks': [
        [121, 66, 5],
      ],
      'brows': '#6F88A2',
    },
    hands: {
      'R': {
        'part': 'trunkTip',
        'at': [143, 119],
      },
    },
    tap: 'ears+trunk',
  );
}

/// Green parrot, front view (Mithu and a friend in the mango tree).
Puppet parrot(String id) {
  const g = '#3EA657', gHi = '#7EDB8A';
  return Puppet(
    id,
    w: 110,
    h: 150,
    rig: 'bird',
    parts: [
      Part(
        'tail',
        '  <path d="M60 120 L74 150 L62 148 L52 124 Z" fill="#3E9A63"/>\n  <path d="M52 120 L50 150 L42 146 L44 122 Z" fill="#FB8500"/>',
        pivot: [56, 120],
      ),
      Part(
        'body',
        '  <ellipse cx="55" cy="96" rx="26" ry="36" fill="url(#b)"/>\n'
            '  <ellipse cx="55" cy="104" rx="15" ry="24" fill="#A6E8A8"/>\n'
            '  <g fill="#F2A23A"><ellipse cx="46" cy="134" rx="7" ry="4"/><ellipse cx="64" cy="134" rx="7" ry="4"/></g>',
        defs: radial('b', gHi, g),
        pivot: [55, 134],
      ),
      for (final (side, x, tilt) in [('L', 30, 12), ('R', 80, -12)])
        Part(
          'wing$side',
          '  <ellipse cx="$x" cy="98" rx="10" ry="26" fill="$g" transform="rotate($tilt $x 98)"/>\n'
              '  <path d="M${x - 4} 110 q${side == 'L' ? -2 : 2} 8 ${side == 'L' ? -1 : 1} 14" fill="none" stroke="#FFB703" stroke-width="3" stroke-linecap="round"/>',
          pivot: [side == 'L' ? 36 : 74, 76],
          mirror: side == 'L',
        ),
      Part(
        'head',
        '  <path d="M50 26 C44 12 48 6 52 4 C54 12 56 18 54 26 Z" fill="#FB8500"/>\n'
            '  <path d="M56 26 C58 12 64 8 68 8 C66 16 62 22 59 28 Z" fill="#FFB703"/>\n'
            '  <circle cx="55" cy="48" r="24" fill="url(#b)"/>\n'
            '  <circle cx="45" cy="44" r="7.5" fill="#E9FBE6"/><circle cx="65" cy="44" r="7.5" fill="#E9FBE6"/>',
        defs: radial('b', gHi, g),
        pivot: [55, 70],
      ),
    ],
    face: {
      'part': 'head',
      'skin': '#E9FBE6',
      'eyes': [
        [45.5, 44, 4.2],
        [64.5, 44, 4.2],
      ],
      'cheeks': [
        [37, 57, 4.6],
        [73, 57, 4.6],
      ],
      'beak': [55, 50, -18],
      'beakColor': '#FFB703',
    },
    tap: 'flap+chirp',
  );
}

/// A little brown sparrow, from the side (facing right).
Puppet sparrow() {
  const body = '#B98757', bodyHi = '#D6A878', dark = '#7A5233', cap = '#8E5530';
  return Puppet(
    'sparrow',
    w: 100,
    h: 80,
    rig: 'bird',
    parts: [
      Part(
        'tail',
        '  <path d="M26 44 L4 34 L6 42 L2 50 L26 52 Z" fill="$dark"/>',
        pivot: [28, 47],
      ),
      Part(
        'legs',
        '  <g stroke="#C98A4B" stroke-width="2.2" stroke-linecap="round" fill="none">'
            '<path d="M42 60 V73 M42 73 l-4 3 M42 73 l4 3"/><path d="M52 60 V73 M52 73 l-4 3 M52 73 l4 3"/></g>',
        pivot: [47, 60],
      ),
      Part(
        'body',
        '  <ellipse cx="45" cy="48" rx="24" ry="16" fill="url(#b)"/>\n  <ellipse cx="50" cy="54" rx="15" ry="9" fill="#F1DCC0"/>',
        defs: radial('b', bodyHi, body),
        pivot: [46, 64],
      ),
      Part(
        'wing',
        '  <path d="M28 44 Q42 30 58 40 Q50 56 28 52 Z" fill="$dark"/>\n'
            '  <path d="M34 46 q8 -6 16 -4 M34 50 q8 -4 16 -3" fill="none" stroke="#E8CBA4" stroke-width="1.6" stroke-linecap="round"/>',
        pivot: [55, 41],
      ),
      Part(
        'head',
        '  <circle cx="66" cy="34" r="15" fill="url(#b)"/>\n'
            '  <path d="M52 32 Q56 17 70 18 Q80 20 81 30 Q68 25 52 32 Z" fill="$cap"/>\n'
            '  <ellipse cx="66" cy="40" rx="8" ry="5" fill="#F7EBDD"/>\n'
            '  <path d="M74 42 Q78 47 74 50 Q70 47 74 42 Z" fill="#3B2F3F"/>',
        defs: radial('b', bodyHi, body),
        pivot: [60, 46],
      ),
    ],
    face: {
      'part': 'head',
      'skin': body,
      'eyes': [
        [71, 31, 2.9],
      ],
      'cheeks': [
        [63, 39, 2.6],
      ],
      'beak': [79, 35, 9],
      'beakColor': '#F2A23A',
    },
    tap: 'flap+chirp',
  );
}

// ---- Reaching ----------------------------------------------------------------------

/// Adds the poses where hands must land somewhere exact (at the mouth, on
/// the cheeks, over the eyes, together in dua), solved for this puppet's
/// own arms: shoulders [sL]/[sR], upper arm [a], forearm-to-palm [b].
Puppet withReach(
  Puppet p, {
  required List<num> sL,
  required List<num> sR,
  required num a,
  required num b,
  required num chest,
  required num belly,
}) {
  final face = p.face;
  final mouth =
      face['mouth'] as List? ?? [sL[0] / 2 + sR[0] / 2, chest - 20, 8];
  final eyes = face['eyes'] as List;
  final cheeks = face['cheeks'] as List;
  final cx = (sL[0] + sR[0]) / 2;
  final mx = (mouth[0] as num).toDouble(), my = (mouth[1] as num).toDouble();

  Map<String, num> arms(List<num>? left, List<num>? right) => {
    if (left != null) ...reach('L', sL, left, a, b, cx),
    if (right != null) ...reach('R', sR, right, a, b, cx),
  };

  final restL = reach('L', sL, [sL[0] - 3, sL[1] + a + b - 1], a, b, cx);
  final ex = (eyes.length > 1 ? eyes : [eyes.first, eyes.first])
      .map((e) => [(e as List)[0] as num, e[1] as num])
      .toList();
  final ck = (cheeks.length > 1 ? cheeks : [cheeks.first, cheeks.first])
      .map((e) => [(e as List)[0] as num, e[1] as num])
      .toList();

  p.poses.addAll({
    'drink': {
      ...restL,
      ...arms(null, [mx + 2, my + 7]),
      'head': -6,
    },
    'eat': {
      ...restL,
      ...arms(null, [mx + 1, my + 4]),
    },
    'think': {
      ...arms([cx - 4, belly - 4], [mx + 4, my + 9]),
      'face': 'think',
      'look': 'upRight',
    },
    'shocked': arms([ck[0][0] - 2, ck[0][1]], [ck[1][0] + 2, ck[1][1]]),
    'cover_eyes': arms([ex[0][0], ex[0][1] + 1], [ex[1][0], ex[1][1] + 1]),
    'dua': {
      ...arms([cx - 7, chest - 2], [cx + 7, chest - 2]),
      'look': 'up',
    },
    'clap': arms([cx - 2.5, chest + 2], [cx + 2.5, chest + 2]),
    'tummy': arms([cx - 9, belly], [cx + 9, belly]),
    'rub': {
      ...restL,
      ...arms(null, [cx + 3, belly]),
    },
    'hold': {
      ...restL,
      ...arms(null, [cx + 9, chest + 8]),
    },
    'hold_both': arms([cx - 9, chest + 8], [cx + 9, chest + 8]),
    'hug': arms([cx - 12, chest - 2], [cx + 12, chest - 2]),
    'thumbs_up': {
      ...arms([cx - 9, belly], null),
      ...arms(null, [sR[0] + 6, sR[1] + a - b * 0.8]),
      'face': 'happy',
    },
    'wave': {
      ...restL,
      ...arms(null, [sR[0] + 12, sR[1] - a * 0.9]),
    },
    'pat': {
      ...restL,
      ...arms(null, [sR[0] + a * 0.9, sR[1] + 6]),
    },
  });
  return p;
}

/// Turns for one arm so its palm lands on [t], elbow bent outward.
Map<String, num> reach(
  String side,
  List<num> s,
  List<num> t,
  num a,
  num b,
  num cx,
) {
  final sx = s[0].toDouble(), sy = s[1].toDouble();
  var dx = t[0] - sx, dy = t[1] - sy;
  final want = math.sqrt(dx * dx + dy * dy);
  final d = want.clamp((a - b).abs() + 0.01, a + b - 0.01);
  if (want > 0) {
    dx *= d / want;
    dy *= d / want;
  }
  final base = math.atan2(dy, dx);
  final alpha = math.acos(
    ((a * a + d * d - b * b) / (2 * a * d)).clamp(-1.0, 1.0),
  );
  List<double> elbow(double sign) => [
    sx + a * math.cos(base + sign * alpha),
    sy + a * math.sin(base + sign * alpha),
  ];
  final e1 = elbow(1), e2 = elbow(-1);
  final e = (e1[0] - cx).abs() >= (e2[0] - cx).abs() ? e1 : e2;
  // A screen angle turning "hanging straight down" onto (x, y).
  double turn(double x, double y) => math.atan2(-x, y);
  final upper = turn(e[0] - sx, e[1] - sy);
  final fore = turn(sx + dx - e[0], sy + dy - e[1]);
  var rel = (fore - upper) * 180 / math.pi;
  while (rel > 180) {
    rel -= 360;
  }
  while (rel <= -180) {
    rel += 360;
  }
  var u = upper * 180 / math.pi;
  if (side == 'L') {
    u = -u;
    rel = -rel;
  }
  return {
    'upper$side': num.parse(u.toStringAsFixed(1)),
    'fore$side': num.parse(rel.toStringAsFixed(1)),
  };
}
