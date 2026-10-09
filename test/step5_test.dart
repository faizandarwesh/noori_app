import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noori/core/bedtime/sleep_timer.dart';
import 'package:noori/core/settings/app_settings.dart';
import 'package:noori/core/storage/local_store.dart';

void main() {
  testWidgets(
    'bedtime sleep timer puts the app to sleep, a grown-up wakes it',
    (tester) async {
      final store = MemoryStore();
      final c = ProviderContainer(
        overrides: [localStoreProvider.overrideWithValue(store)],
      );
      addTearDown(c.dispose);
      final sub = c.listen(sleepTimerProvider, (_, _) {});
      addTearDown(sub.close);

      expect(
        c.read(sleepTimerProvider).endsAt,
        isNull,
        reason: 'off outside bedtime',
      );

      c.read(appSettingsProvider.notifier)
        ..setSleepMinutes(5)
        ..setBedtime(true);
      expect(c.read(sleepTimerProvider).endsAt, isNotNull);

      await tester.pump(const Duration(minutes: 4));
      expect(c.read(sleepTimerProvider).asleep, isFalse);
      await tester.pump(const Duration(minutes: 1, seconds: 1));
      expect(c.read(sleepTimerProvider).asleep, isTrue);

      c.read(sleepTimerProvider.notifier).wake();
      expect(c.read(sleepTimerProvider).asleep, isFalse);
      expect(
        c.read(sleepTimerProvider).endsAt,
        isNotNull,
        reason: 'a fresh timer',
      );

      c.read(appSettingsProvider.notifier).setBedtime(false);
      expect(c.read(sleepTimerProvider).endsAt, isNull);
      expect(store.read('settings.sleepMinutes'), 5);
    },
  );

  test('sleep minutes only accept 5, 10 or 15', () {
    final c = ProviderContainer(
      overrides: [localStoreProvider.overrideWithValue(MemoryStore())],
    );
    addTearDown(c.dispose);
    c.read(appSettingsProvider.notifier).setSleepMinutes(7);
    expect(
      c.read(appSettingsProvider).sleepMinutes,
      AppSettings.defaultSleepMinutes,
    );
  });

  test('swipe-to-skip is off by default and remembered once switched on', () {
    final store = MemoryStore();
    final c1 = ProviderContainer(
      overrides: [localStoreProvider.overrideWithValue(store)],
    );
    expect(c1.read(appSettingsProvider).swipeToSkip, isFalse);
    c1.read(appSettingsProvider.notifier).setSwipeToSkip(true);
    c1.dispose();

    final c2 = ProviderContainer(
      overrides: [localStoreProvider.overrideWithValue(store)],
    );
    addTearDown(c2.dispose);
    expect(c2.read(appSettingsProvider).swipeToSkip, isTrue);
  });
}
