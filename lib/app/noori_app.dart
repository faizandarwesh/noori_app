import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/audio/audio_service.dart';
import '../core/bedtime/sleep_timer.dart';
import '../core/settings/app_settings.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class NooriApp extends ConsumerStatefulWidget {
  const NooriApp({super.key});

  @override
  ConsumerState<NooriApp> createState() => _NooriAppState();
}

class _NooriAppState extends ConsumerState<NooriApp> {
  late final GoRouter _router = buildRouter();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    final audio = ref.read(audioServiceProvider);
    audio.init().then((_) => _syncMusic());
    // Silence everything when the app goes to the background.
    _lifecycle = AppLifecycleListener(
      onHide: audio.pauseAll,
      onShow: audio.resumeMusic,
    );
  }

  void _syncMusic() {
    final s = ref.read(appSettingsProvider);
    final audio = ref.read(audioServiceProvider)..setSlowNarration(s.bedtime);
    audio.setSoundOn(s.soundOn);
    audio.playMusic(s.bedtime ? MusicTrack.bedtime : MusicTrack.day);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appSettingsProvider, (prev, next) {
      if (prev?.bedtime != next.bedtime || prev?.soundOn != next.soundOn) {
        _syncMusic();
      }
    });
    // Bedtime's sleep timer ran out: hush everything and say good night.
    ref.listen(sleepTimerProvider, (prev, next) {
      final audio = ref.read(audioServiceProvider);
      if (next.asleep && !(prev?.asleep ?? false)) {
        audio
          ..stopNarration()
          ..stopMusic();
        _router.push(Routes.goodnight);
      } else if (!next.asleep && (prev?.asleep ?? false)) {
        _syncMusic();
      }
    });
    final settings = ref.watch(appSettingsProvider);

    return MaterialApp.router(
      title: 'Noori',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: settings.bedtime ? AppTheme.bedtime() : AppTheme.day(),
      themeAnimationDuration: const Duration(milliseconds: 700),
      // Locale drives layout direction: Urdu mirrors the UI right-to-left.
      locale: Locale(settings.lang.name),
      supportedLocales: const [Locale('en'), Locale('ur')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
