import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'puppets.dart';

/// One parallax layer of a scene: an SVG, or the page's cast.
@immutable
class SceneLayerSpec {
  const SceneLayerSpec({
    required this.art,
    required this.depth,
    this.drift = 0,
    this.bob = 0,
  });

  factory SceneLayerSpec.fromJson(Map<String, dynamic> j) => SceneLayerSpec(
    art: (j['cast'] as bool? ?? false) ? null : j['art'] as String,
    depth: (j['depth'] as num).toDouble(),
    drift: (j['drift'] as num? ?? 0).toDouble(),
    bob: (j['bob'] as num? ?? 0).toDouble(),
  );

  /// Path under assets/illustrations/, or null for the cast layer.
  final String? art;
  final double depth, drift, bob;

  bool get isCast => art == null;
  String get asset => 'assets/illustrations/$art';
}

/// A little hidden surprise in a scene (a frog under a leaf, a sleeping
/// caterpillar) that comes alive when a child finds and taps it. [x], [y]
/// place its bottom-centre and [size] is its height, as fractions of the
/// screen, like a cast member.
@immutable
class SceneSecret {
  const SceneSecret({
    required this.kind,
    required this.x,
    required this.y,
    required this.size,
    this.flip = false,
  });

  factory SceneSecret.fromJson(Map<String, dynamic> j) => SceneSecret(
    kind: SecretKind.values.byName(j['kind'] as String),
    x: (j['x'] as num).toDouble(),
    y: (j['y'] as num).toDouble(),
    size: (j['size'] as num? ?? 0.05).toDouble(),
    flip: j['flip'] as bool? ?? false,
  );

  final SecretKind kind;
  final double x, y, size;
  final bool flip;
}

enum SecretKind { butterfly, frog, caterpillar, snail, ladybird, mouse, fish }

@immutable
class SceneSpec {
  const SceneSpec(this.layers, {this.ambient, this.secrets = const []});

  factory SceneSpec.fromJson(Map<String, dynamic> j) => SceneSpec(
    [
      for (final l in j['layers'] as List)
        SceneLayerSpec.fromJson(l as Map<String, dynamic>),
    ],
    ambient: j['ambient'] as String?,
    secrets: [
      for (final s in j['secrets'] as List? ?? const [])
        SceneSecret.fromJson(s as Map<String, dynamic>),
    ],
  );

  final List<SceneLayerSpec> layers;

  /// Soundscape looped under the narration: birds, river, wind or waves.
  final String? ambient;

  /// Hidden surprises to find in the scene while a story plays.
  final List<SceneSecret> secrets;
}

/// All scenes, from assets/content/scenes.json.
@immutable
class Scenes {
  const Scenes(this._scenes, {this.puppets = Puppets.empty});

  static const asset = 'assets/content/scenes.json';

  factory Scenes.fromJson(
    Map<String, dynamic> j, {
    Puppets puppets = Puppets.empty,
  }) => Scenes({
    for (final e in (j['scenes'] as Map<String, dynamic>).entries)
      e.key: SceneSpec.fromJson(e.value as Map<String, dynamic>),
  }, puppets: puppets);

  final Map<String, SceneSpec> _scenes;

  /// The puppets a scene's cast can use.
  final Puppets puppets;

  SceneSpec? operator [](String id) => _scenes[id];
  Iterable<String> get ids => _scenes.keys;
}

final scenesProvider = FutureProvider<Scenes>((ref) async {
  final raw = await rootBundle.loadString(Scenes.asset);
  // Puppets load with the scenes, so a scene's cast is ready to draw as
  // soon as the scene is. Decoded here rather than with loadString, which
  // hands files over 50 KB to a background isolate.
  final bytes = await rootBundle.load(Puppets.asset);
  final puppets = utf8.decode(bytes.buffer.asUint8List());
  return Scenes.fromJson(
    jsonDecode(raw) as Map<String, dynamic>,
    puppets: Puppets.fromJson(jsonDecode(puppets) as Map<String, dynamic>),
  );
});
