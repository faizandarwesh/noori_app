import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mascot/noori_outfit.dart';
import '../storage/local_store.dart';
import 'progress.dart';

/// One thing in Noori's wardrobe: a scarf or a hat.
@immutable
class WardrobeItem {
  const WardrobeItem.scarf(NooriScarf this.scarf) : hat = null;
  const WardrobeItem.hat(NooriHat this.hat) : scarf = null;

  final NooriScarf? scarf;
  final NooriHat? hat;

  String get id => scarf?.id ?? hat!.id;
  int get price => scarf?.price ?? hat!.price;

  /// Every item, cheapest first within each kind.
  static final all = [
    for (final s in NooriScarf.values) WardrobeItem.scarf(s),
    for (final h in NooriHat.values) WardrobeItem.hat(h),
  ];

  @override
  bool operator ==(Object other) => other is WardrobeItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// What Noori owns and what she's wearing.
@immutable
class Wardrobe {
  const Wardrobe({this.owned = const {}, this.outfit = const NooriOutfit()});

  /// Ids of bought items. Free items (the sunset scarf, no hat) are always
  /// owned.
  final Set<String> owned;
  final NooriOutfit outfit;

  bool owns(WardrobeItem item) => item.price == 0 || owned.contains(item.id);

  bool isWearing(WardrobeItem item) =>
      item.scarf == outfit.scarf ||
      (item.hat != null && item.hat == outfit.hat);
}

enum BuyResult { bought, notEnough, alreadyOwned }

class WardrobeNotifier extends Notifier<Wardrobe> {
  static const _owned = 'wardrobe.owned';
  static const _scarf = 'wardrobe.scarf';
  static const _hat = 'wardrobe.hat';

  LocalStore get _store => ref.read(localStoreProvider);

  @override
  Wardrobe build() {
    final s = ref.watch(localStoreProvider);
    final owned = {for (final id in s.read(_owned) as List? ?? const []) '$id'};
    NooriScarf scarf = NooriScarf.sunset;
    NooriHat hat = NooriHat.none;
    for (final v in NooriScarf.values) {
      if (v.name == s.read(_scarf)) scarf = v;
    }
    for (final v in NooriHat.values) {
      if (v.name == s.read(_hat)) hat = v;
    }
    final w = Wardrobe(owned: owned);
    // Only wear what is actually owned.
    return Wardrobe(
      owned: owned,
      outfit: NooriOutfit(
        scarf: w.owns(WardrobeItem.scarf(scarf)) ? scarf : NooriScarf.sunset,
        hat: w.owns(WardrobeItem.hat(hat)) ? hat : NooriHat.none,
      ),
    );
  }

  /// Buys [item] with fireflies and puts it on.
  BuyResult buy(WardrobeItem item) {
    if (state.owns(item)) return BuyResult.alreadyOwned;
    if (!ref.read(progressProvider.notifier).spendFireflies(item.price)) {
      return BuyResult.notEnough;
    }
    state = Wardrobe(owned: {...state.owned, item.id}, outfit: state.outfit);
    _store.write(_owned, state.owned.toList());
    wear(item);
    return BuyResult.bought;
  }

  /// Puts on an owned item. Wearing the hat she already has on takes it off.
  void wear(WardrobeItem item) {
    if (!state.owns(item)) return;
    final outfit = switch (item) {
      WardrobeItem(scarf: final s?) => state.outfit.copyWith(scarf: s),
      WardrobeItem(hat: final h?) => state.outfit.copyWith(
        hat: state.outfit.hat == h ? NooriHat.none : h,
      ),
      _ => state.outfit,
    };
    state = Wardrobe(owned: state.owned, outfit: outfit);
    _store
      ..write(_scarf, outfit.scarf.name)
      ..write(_hat, outfit.hat.name);
  }
}

final wardrobeProvider = NotifierProvider<WardrobeNotifier, Wardrobe>(
  WardrobeNotifier.new,
);

/// What Noori wears on every screen.
final nooriOutfitProvider = Provider<NooriOutfit>(
  (ref) => ref.watch(wardrobeProvider.select((w) => w.outfit)),
);
