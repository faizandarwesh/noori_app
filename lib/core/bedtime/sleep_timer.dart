import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings.dart';

@immutable
class SleepState {
  const SleepState({this.endsAt, this.asleep = false});

  /// When the timer runs out; null when bedtime is off.
  final DateTime? endsAt;

  /// The timer ran out: the Good night screen is showing.
  final bool asleep;
}

/// Bedtime's sleep timer. Runs whenever bedtime is on, for the parent's
/// chosen 5/10/15 minutes, then puts the app to sleep.
class SleepTimerNotifier extends Notifier<SleepState> {
  Timer? _timer;

  @override
  SleepState build() {
    ref.onDispose(() => _timer?.cancel());
    ref.listen(appSettingsProvider, (prev, next) {
      if (prev?.bedtime != next.bedtime ||
          prev?.sleepMinutes != next.sleepMinutes) {
        state = _start(next);
      }
    });
    return _start(ref.read(appSettingsProvider));
  }

  SleepState _start(AppSettings s) {
    _timer?.cancel();
    if (!s.bedtime) return const SleepState();
    final length = Duration(minutes: s.sleepMinutes);
    _timer = Timer(length, () => state = const SleepState(asleep: true));
    return SleepState(endsAt: DateTime.now().add(length));
  }

  /// A grown-up woke the app: bedtime carries on with a fresh timer.
  void wake() => state = _start(ref.read(appSettingsProvider));
}

final sleepTimerProvider = NotifierProvider<SleepTimerNotifier, SleepState>(
  SleepTimerNotifier.new,
);
