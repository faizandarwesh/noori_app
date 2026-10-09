import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../features/bedtime/goodnight_screen.dart';
import '../features/demo/mascot_demo_screen.dart';
import '../features/home/home_screen.dart';
import '../features/lantern/lantern_screen.dart';
import '../features/lantern/wardrobe_screen.dart';
import '../features/onboarding/language_pick_screen.dart';
import '../features/quiz/quiz_screen.dart';
import '../features/reader/reader_screen.dart';
import '../features/reward/reward_result.dart';
import '../features/reward/reward_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/word_game/word_game_screen.dart';
import '../features/word_jar/word_jar_screen.dart';
import 'routes.dart';

export 'routes.dart';

/// Pages grow in from slightly smaller while fading, a soft playful move.
CustomTransitionPage<void> _page(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppMotion.entrance,
      reverseTransitionDuration: AppMotion.entrance,
      transitionsBuilder: (context, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: AppMotion.pop);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );

GoRouter buildRouter() => GoRouter(
  initialLocation: Routes.splash,
  routes: [
    GoRoute(
      path: Routes.splash,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: SplashScreen()),
    ),
    GoRoute(
      path: Routes.language,
      pageBuilder: (context, state) => _page(state, const LanguagePickScreen()),
    ),
    GoRoute(
      path: Routes.home,
      pageBuilder: (context, state) => _page(state, const HomeScreen()),
    ),
    GoRoute(
      path: Routes.storyPattern,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: ReaderScreen(storyId: state.pathParameters['id']!),
        transitionDuration: AppMotion.heroFlight,
        reverseTransitionDuration: AppMotion.heroFlight,
        // The story card's hero does the travelling; the player's chrome
        // fades in around it as it lands.
        transitionsBuilder: (context, anim, _, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: anim,
            curve: const Interval(0.45, 1, curve: Curves.easeOut),
          ),
          child: child,
        ),
      ),
    ),
    GoRoute(
      path: Routes.quizPattern,
      pageBuilder: (context, state) =>
          _page(state, QuizScreen(storyId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: Routes.rewardPattern,
      pageBuilder: (context, state) => _page(
        state,
        RewardScreen(
          storyId: state.pathParameters['id']!,
          result: state.extra as RewardResult?,
        ),
      ),
    ),
    GoRoute(
      path: Routes.goodnight,
      pageBuilder: (context, state) => _page(state, const GoodnightScreen()),
    ),
    GoRoute(
      path: Routes.jar,
      pageBuilder: (context, state) => _page(state, const WordJarScreen()),
    ),
    GoRoute(
      path: Routes.lantern,
      pageBuilder: (context, state) => _page(state, const LanternScreen()),
    ),
    GoRoute(
      path: Routes.wardrobe,
      pageBuilder: (context, state) => _page(state, const WardrobeScreen()),
    ),
    GoRoute(
      path: Routes.wordGame,
      pageBuilder: (context, state) => _page(state, const WordGameScreen()),
    ),
    GoRoute(
      path: Routes.settings,
      pageBuilder: (context, state) => _page(state, const SettingsScreen()),
    ),
    GoRoute(
      path: Routes.demo,
      pageBuilder: (context, state) => _page(state, const MascotDemoScreen()),
    ),
  ],
  errorBuilder: (context, state) => const HomeScreen(),
);
