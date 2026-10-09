import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../theme/app_colors.dart';

/// Noori's scarf colours. The sunset scarf is hers from the start; the rest
/// cost fireflies in her wardrobe.
enum NooriScarf {
  sunset(0, NooriPalette.scarf, NooriPalette.scarfStripe),
  mint(5, NooriPalette.scarfMint, NooriPalette.scarfMintStripe),
  rose(5, NooriPalette.scarfRose, NooriPalette.scarfRoseStripe),
  ocean(5, NooriPalette.scarfOcean, NooriPalette.scarfOceanStripe),
  grape(8, NooriPalette.scarfGrape, NooriPalette.scarfGrapeStripe),
  rainbow(15, NooriPalette.scarf, NooriPalette.white);

  const NooriScarf(this.price, this.color, this.stripe);

  final int price;
  final Color color;
  final Color stripe;

  String get id => 'scarf.$name';
  bool get isRainbow => this == NooriScarf.rainbow;
}

/// Things Noori can wear on her head.
enum NooriHat {
  none(0),
  bow(5),
  flower(8),
  party(10),
  crown(15);

  const NooriHat(this.price);

  final int price;
  String get id => 'hat.$name';
}

/// What Noori is wearing right now.
@immutable
class NooriOutfit {
  const NooriOutfit({this.scarf = NooriScarf.sunset, this.hat = NooriHat.none});

  final NooriScarf scarf;
  final NooriHat hat;

  NooriOutfit copyWith({NooriScarf? scarf, NooriHat? hat}) =>
      NooriOutfit(scarf: scarf ?? this.scarf, hat: hat ?? this.hat);

  @override
  bool operator ==(Object other) =>
      other is NooriOutfit && other.scarf == scarf && other.hat == hat;

  @override
  int get hashCode => Object.hash(scarf, hat);
}
