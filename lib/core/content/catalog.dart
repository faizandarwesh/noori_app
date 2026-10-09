import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/app_lang.dart';
import '../progress/progress.dart';

/// A story's entry in the catalog. Its pages live in
/// `assets/content/stories/<id>.json`.
@immutable
class StoryEntry {
  const StoryEntry({
    required this.id,
    required this.title,
    required this.value,
    required this.character,
  });

  factory StoryEntry.fromJson(Map<String, dynamic> j) => StoryEntry(
    id: j['id'] as String,
    title: LocalizedText.fromJson(j['title'] as Map<String, dynamic>),
    value: j['value'] as String? ?? '',
    character: j['character'] as String,
  );

  final String id;
  final LocalizedText title;

  /// The value the story teaches (sharing, honesty, …).
  final String value;

  /// Character art id, e.g. `rabbit` → assets/illustrations/characters/rabbit_face.svg.
  final String character;
}

@immutable
class Zone {
  const Zone({
    required this.id,
    required this.name,
    required this.badge,
    required this.unlockAfter,
    required this.stories,
  });

  factory Zone.fromJson(Map<String, dynamic> j) => Zone(
    id: j['id'] as String,
    name: LocalizedText.fromJson(j['name'] as Map<String, dynamic>),
    badge: j['badge'] as String,
    unlockAfter: j['unlockAfter'] as String?,
    stories: [
      for (final s in (j['stories'] as List? ?? const []))
        StoryEntry.fromJson(s as Map<String, dynamic>),
    ],
  );

  final String id;
  final LocalizedText name;

  /// Badge art id → `assets/illustrations/zones/<badge>.svg`.
  final String badge;

  /// Zone that must be fully completed first; null means open from the start.
  final String? unlockAfter;
  final List<StoryEntry> stories;
}

@immutable
class Catalog {
  const Catalog(this.zones);

  static const asset = 'assets/content/zones.json';

  factory Catalog.fromJson(Map<String, dynamic> j) => Catalog([
    for (final z in j['zones'] as List)
      Zone.fromJson(z as Map<String, dynamic>),
  ]);

  final List<Zone> zones;

  Zone? zone(String id) {
    for (final z in zones) {
      if (z.id == id) return z;
    }
    return null;
  }

  StoryEntry? story(String id) {
    for (final z in zones) {
      for (final s in z.stories) {
        if (s.id == id) return s;
      }
    }
    return null;
  }

  bool isZoneComplete(Zone z, Progress p) =>
      z.stories.isNotEmpty && z.stories.every((s) => p.isCompleted(s.id));

  /// A zone opens once its prerequisite is complete and it has stories.
  bool isZoneUnlocked(Zone z, Progress p) {
    if (z.stories.isEmpty) return false;
    final after = z.unlockAfter == null ? null : zone(z.unlockAfter!);
    return after == null || isZoneComplete(after, p);
  }

  /// Every story a child can play now, in catalog order. Zones that are
  /// still locked or empty never appear in the child UI.
  List<StoryEntry> playable(Progress p) => [
    for (final z in zones)
      if (isZoneUnlocked(z, p)) ...z.stories,
  ];
}

final catalogProvider = FutureProvider<Catalog>((ref) async {
  final raw = await rootBundle.loadString(Catalog.asset);
  return Catalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
});
