import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/app_lang.dart';
import '../storage/local_store.dart';

@immutable
class AppSettings {
  const AppSettings({
    this.lang = AppLang.en,
    this.languageChosen = false,
    this.bedtime = false,
    this.soundOn = true,
    this.sleepMinutes = defaultSleepMinutes,
    this.homeGreeted = false,
    this.swipeToSkip = false,
  });

  static const sleepChoices = [5, 10, 15];
  static const defaultSleepMinutes = 10;

  final AppLang lang;
  final bool languageChosen;
  final bool bedtime;
  final bool soundOn;

  /// Bedtime sleep timer length: one of [sleepChoices].
  final int sleepMinutes;

  /// Noori has given her one Home greeting.
  final bool homeGreeted;

  /// Grown-ups can let a long swipe skip story scenes. Off by default, so
  /// little hands don't skip by accident.
  final bool swipeToSkip;

  AppSettings copyWith({
    AppLang? lang,
    bool? languageChosen,
    bool? bedtime,
    bool? soundOn,
    int? sleepMinutes,
    bool? homeGreeted,
    bool? swipeToSkip,
  }) => AppSettings(
    lang: lang ?? this.lang,
    languageChosen: languageChosen ?? this.languageChosen,
    bedtime: bedtime ?? this.bedtime,
    soundOn: soundOn ?? this.soundOn,
    sleepMinutes: sleepMinutes ?? this.sleepMinutes,
    homeGreeted: homeGreeted ?? this.homeGreeted,
    swipeToSkip: swipeToSkip ?? this.swipeToSkip,
  );
}

class AppSettingsNotifier extends Notifier<AppSettings> {
  static const _lang = 'settings.lang';
  static const _chosen = 'settings.languageChosen';
  static const _bedtime = 'settings.bedtime';
  static const _sound = 'settings.soundOn';
  static const _sleep = 'settings.sleepMinutes';
  static const _greeted = 'settings.homeGreeted';
  static const _swipe = 'settings.swipeToSkip';

  LocalStore get _store => ref.read(localStoreProvider);

  @override
  AppSettings build() {
    final s = ref.watch(localStoreProvider);
    final sleep = s.read(_sleep) as int?;
    return AppSettings(
      lang: AppLang.parse(s.read(_lang) as String?),
      languageChosen: s.read(_chosen) as bool? ?? false,
      bedtime: s.read(_bedtime) as bool? ?? false,
      soundOn: s.read(_sound) as bool? ?? true,
      sleepMinutes: AppSettings.sleepChoices.contains(sleep)
          ? sleep!
          : AppSettings.defaultSleepMinutes,
      homeGreeted: s.read(_greeted) as bool? ?? false,
      swipeToSkip: s.read(_swipe) as bool? ?? false,
    );
  }

  void setLang(AppLang lang) {
    state = state.copyWith(lang: lang, languageChosen: true);
    _store
      ..write(_lang, lang.name)
      ..write(_chosen, true);
  }

  void toggleLang() => setLang(state.lang.other);

  void setBedtime(bool on) {
    state = state.copyWith(bedtime: on);
    _store.write(_bedtime, on);
  }

  void setSound(bool on) {
    state = state.copyWith(soundOn: on);
    _store.write(_sound, on);
  }

  void setSleepMinutes(int minutes) {
    if (!AppSettings.sleepChoices.contains(minutes)) return;
    state = state.copyWith(sleepMinutes: minutes);
    _store.write(_sleep, minutes);
  }

  void setSwipeToSkip(bool on) {
    state = state.copyWith(swipeToSkip: on);
    _store.write(_swipe, on);
  }

  void markHomeGreeted() {
    state = state.copyWith(homeGreeted: true);
    _store.write(_greeted, true);
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
