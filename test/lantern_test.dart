import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noori/app/noori_app.dart';
import 'package:noori/core/audio/audio_service.dart';
import 'package:noori/core/mascot/noori_outfit.dart';
import 'package:noori/core/progress/progress.dart';
import 'package:noori/core/progress/wardrobe.dart';
import 'package:noori/core/storage/local_store.dart';
import 'package:noori/core/theme/app_theme.dart';
import 'package:noori/core/widgets/bouncy_button.dart';
import 'package:noori/features/lantern/lantern_screen.dart';
import 'package:noori/features/lantern/wardrobe_screen.dart';
import 'package:noori/features/word_game/word_game_screen.dart';

ProviderContainer _container(MemoryStore store) => ProviderContainer(
  overrides: [
    audioServiceProvider.overrideWithValue(AudioService(enabled: false)),
    localStoreProvider.overrideWithValue(store),
  ],
);

Future<void> _pumpFor(WidgetTester tester, Duration d) async {
  const frame = Duration(milliseconds: 50);
  for (var t = Duration.zero; t < d; t += frame) {
    await tester.pump(frame);
  }
}

Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 15));
}

const _mint = WardrobeItem.scarf(NooriScarf.mint);
const _crown = WardrobeItem.hat(NooriHat.crown);

void main() {
  setUp(rootBundle.clear);

  group('wardrobe', () {
    test('spending fireflies never dims the lantern', () {
      final store = MemoryStore({'progress.fireflies': 12});
      final c = _container(store);
      addTearDown(c.dispose);
      expect(c.read(wardrobeProvider.notifier).buy(_mint), BuyResult.bought);
      final p = c.read(progressProvider);
      expect(p.balance, 7);
      expect(p.fireflies, 12, reason: 'the lantern glows by everything earned');
    });

    test('too few fireflies: nothing is spent, nothing changes', () {
      final c = _container(MemoryStore({'progress.fireflies': 3}));
      addTearDown(c.dispose);
      expect(c.read(wardrobeProvider.notifier).buy(_mint), BuyResult.notEnough);
      expect(c.read(progressProvider).balance, 3);
      expect(c.read(wardrobeProvider).owns(_mint), isFalse);
    });

    test('a bought item goes on, stays owned, and is remembered', () {
      final store = MemoryStore({'progress.fireflies': 30});
      final c1 = _container(store);
      c1.read(wardrobeProvider.notifier)
        ..buy(_mint)
        ..buy(_crown);
      expect(c1.read(nooriOutfitProvider).scarf, NooriScarf.mint);
      expect(c1.read(nooriOutfitProvider).hat, NooriHat.crown);
      // Tapping the crown again takes it off; buying it twice costs nothing.
      c1.read(wardrobeProvider.notifier).wear(_crown);
      expect(c1.read(nooriOutfitProvider).hat, NooriHat.none);
      expect(
        c1.read(wardrobeProvider.notifier).buy(_crown),
        BuyResult.alreadyOwned,
      );
      expect(c1.read(progressProvider).balance, 30 - 5 - 15);
      c1.dispose();

      final c2 = _container(store);
      addTearDown(c2.dispose);
      expect(c2.read(nooriOutfitProvider).scarf, NooriScarf.mint);
      expect(c2.read(wardrobeProvider).owns(_crown), isTrue);
    });

    test('the sunset scarf and no hat are always hers', () {
      final c = _container(MemoryStore());
      addTearDown(c.dispose);
      final w = c.read(wardrobeProvider);
      expect(w.owns(const WardrobeItem.scarf(NooriScarf.sunset)), isTrue);
      expect(w.owns(const WardrobeItem.hat(NooriHat.none)), isTrue);
    });
  });

  testWidgets('Home lantern → Noori\'s Lantern → wardrobe', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    tester.view
      ..physicalSize = const Size(412, 892)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = _container(
      MemoryStore({
        'settings.languageChosen': true,
        'settings.homeGreeted': true,
        'progress.fireflies': 6,
      }),
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const NooriApp()),
    );
    await tester.tap(find.byType(Scaffold)); // skip splash
    await _pumpFor(tester, const Duration(seconds: 2));

    await tester.tap(find.bySemanticsLabel("Noori's lantern"));
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(find.byType(LanternScreen), findsOneWidget);
    expect(find.bySemanticsLabel('Fireflies: 6'), findsWidgets);

    await tester.tap(find.bySemanticsLabel('Wardrobe'));
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(find.byType(WardrobeScreen), findsOneWidget);

    // 6 fireflies: the 5-firefly mint scarf, yes; the 15-firefly crown, no.
    await tester.tap(find.bySemanticsLabel('mint scarf, 5 fireflies'));
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(c.read(nooriOutfitProvider).scarf, NooriScarf.mint);
    expect(c.read(progressProvider).balance, 1);

    final crown = find.bySemanticsLabel('crown hat, 15 fireflies');
    await tester.scrollUntilVisible(crown, 200);
    await tester.tap(crown);
    await _pumpFor(tester, const Duration(milliseconds: 600));
    expect(c.read(wardrobeProvider).owns(_crown), isFalse);
    expect(c.read(progressProvider).balance, 1);
    await _teardown(tester);
  });

  testWidgets('word game: five words found earn a firefly', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    final c = _container(
      MemoryStore({
        'progress.stars': {'bunty_big_mango': 3},
      }),
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(theme: AppTheme.day(), home: const WordGameScreen()),
      ),
    );
    await _pumpFor(tester, const Duration(seconds: 1));

    for (var round = 0; round < WordGameScreen.rounds; round++) {
      // The asked-for word is written out; its picture is the card with the
      // same label.
      final labels = tester
          .widgetList<BouncyButton>(find.byType(BouncyButton))
          .map((b) => b.semanticLabel)
          .whereType<String>();
      final target = labels.firstWhere(
        (l) => l != 'Back' && find.text(l).evaluate().isNotEmpty,
      );
      await tester.tap(find.bySemanticsLabel(target).last);
      await _pumpFor(tester, const Duration(milliseconds: 1500));
    }
    expect(c.read(progressProvider).fireflies, 1);
    await _pumpFor(tester, const Duration(seconds: 2)); // the finish pops in
    expect(find.bySemanticsLabel('Play again'), findsOneWidget);
    await _teardown(tester);
  });
}
