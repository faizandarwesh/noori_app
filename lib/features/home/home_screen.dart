import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/audio/audio_service.dart';
import '../../core/content/catalog.dart';
import '../../core/content/scenes.dart';
import '../../core/content/story.dart';
import '../../core/mascot/noori_guide.dart';
import '../../core/progress/progress.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/firefly_layer.dart';
import '../../core/widgets/lantern.dart';
import '../parent/parent_gate.dart';
import 'widgets/dawn_sky.dart';
import 'widgets/story_card.dart';

/// Home: nothing but stories. A 3D carousel of living story cards under a
/// slowly shifting dawn sky. Swipe with springy physics; tap the middle card
/// and it grows into the story. Noori watches from the corner, following
/// each swipe with her eyes. She speaks here only once, on the first visit.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _guide = NooriGuideController();
  late final PageController _pager = PageController(
    viewportFraction: AppSizes.carouselViewport,
  );
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: AppMotion.cardFloat,
  )..repeat();

  /// The card the carousel last came to rest on.
  int _rest = 0;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = ref.read(appSettingsProvider);
      if (!settings.homeGreeted) {
        // Noori's one greeting, on the very first visit.
        _guide.say('home_first_visit');
        ref.read(appSettingsProvider.notifier).markHomeGreeted();
      }
    });
  }

  @override
  void dispose() {
    _pager.dispose();
    _float.dispose();
    _guide.dispose();
    super.dispose();
  }

  double get _page {
    if (_pager.hasClients && _pager.position.haveDimensions) {
      return _pager.page ?? _rest.toDouble();
    }
    return _rest.toDouble();
  }

  void _onPageChanged(int _) {
    ref.read(audioServiceProvider).play(Sfx.whoosh);
    HapticFeedback.selectionClick();
  }

  bool _onScroll(ScrollNotification n) {
    if (n is ScrollEndNotification) _rest = _page.round();
    return false;
  }

  Future<void> _tapCard(int index, StoryEntry entry) async {
    if (_opening) return;
    if (index != _page.round()) {
      // A neighbour: bring it to the middle first.
      await _pager.animateToPage(
        index,
        duration: AppMotion.entrance,
        curve: Curves.easeOutBack,
      );
      return;
    }
    _opening = true;
    try {
      // Make sure the story is loaded, so its scene is ready for the hero.
      await Future.wait([
        ref.read(storyProvider(entry.id).future),
        ref.read(scenesProvider.future),
      ]);
      if (!mounted) return;
      // Not awaited: a finished story returns Home via context.go (reader →
      // quiz → reward), which never completes this push's future. The lock
      // only needs to cover the hero flight, to swallow double taps.
      unawaited(context.push(Routes.story(entry.id)));
      await Future<void>.delayed(AppMotion.heroFlight);
    } finally {
      _opening = false;
    }
  }

  void _openLantern() {
    if (_opening) return;
    context.push(Routes.lantern);
  }

  Future<void> _openSettings() async {
    if (await ParentGate.show(context) && mounted) {
      await context.push(Routes.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final progress = ref.watch(progressProvider);
    final catalog = ref.watch(catalogProvider).value;
    final scenes = ref.watch(scenesProvider).value;
    final stories = catalog?.playable(progress) ?? const <StoryEntry>[];
    final screen = MediaQuery.sizeOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final cardSize = screen * AppSizes.carouselCardScale;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          DawnSky(night: settings.bedtime),
          FireflyLayer(count: settings.bedtime ? 22 : 12),
          if (stories.isNotEmpty)
            NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: PageView.builder(
                controller: _pager,
                physics: const _SpringyPagePhysics(),
                onPageChanged: _onPageChanged,
                itemCount: stories.length,
                itemBuilder: (context, i) {
                  final entry = stories[i];
                  return Center(
                    child: _CarouselSlot(
                      pager: _pager,
                      float: _float,
                      index: i,
                      rtl: rtl,
                      size: cardSize,
                      onTap: () => _tapCard(i, entry),
                      label: entry.title.of(settings.lang),
                      builder: (swipe) => Consumer(
                        builder: (context, ref, _) {
                          final story = ref
                              .watch(storyProvider(entry.id))
                              .value;
                          return StoryCard(
                            storyId: entry.id,
                            title: entry.title.of(settings.lang),
                            lang: settings.lang,
                            screen: screen,
                            scene: story?.firstPage == null
                                ? null
                                : scenes?[story!.firstPage!.scene],
                            page: story?.firstPage,
                            completed: progress.isCompleted(entry.id),
                            swipe: swipe,
                          );
                        },
                      ),
                    ),
                  ).popIn(i.clamp(0, 2), base: 150.ms);
                },
              ),
            ),
          // The single grown-ups' door: a small gear behind the parent gate.
          PositionedDirectional(
            top: 0,
            end: AppSizes.space3,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSizes.space2),
                child: BouncyButton(
                  semanticLabel: 'Settings',
                  minSize: AppSizes.settingsTap,
                  onTap: _openSettings,
                  child: Container(
                    width: AppSizes.settingsTap,
                    height: AppSizes.settingsTap,
                    decoration: const BoxDecoration(
                      color: CinemaPalette.glass,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.settings_rounded,
                      size: AppSizes.settingsIcon,
                      color: context.colors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ).popIn(4),
            ),
          ),
          PositionedDirectional(
            start: AppSizes.space3,
            end: AppSizes.space3,
            bottom: AppSizes.space2,
            child: SafeArea(
              top: false,
              child: Align(
                alignment: AlignmentDirectional.bottomStart,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Flexible, so her first-visit bubble wraps beside the lantern.
                    Flexible(
                      child: AnimatedBuilder(
                        animation: _pager,
                        builder: (context, _) {
                          // Cards slide against the swipe: she watches them go.
                          var look = ((_page - _rest) * 2.5).clamp(-1.0, 1.0);
                          if (!rtl) look = -look;
                          return NooriGuide(
                            controller: _guide,
                            size: AppSizes.homeMascot,
                            look: look,
                            repeatOnTap: false,
                            onTap: _openLantern,
                          );
                        },
                      ),
                    ),
                    // Her lantern glows brighter with every firefly earned.
                    BouncyButton(
                      semanticLabel: "Noori's lantern",
                      minSize: AppSizes.minTap,
                      onTap: _openLantern,
                      child: Lantern(
                        count: ref.watch(progressProvider).fireflies,
                        size: AppSizes.homeLantern,
                        showCount: false,
                      ),
                    ),
                  ],
                ).popIn(5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lays one card out in the carousel: tilted, shrunk and pulled inwards by
/// its distance from the middle; the middle card floats and glows.
class _CarouselSlot extends StatefulWidget {
  const _CarouselSlot({
    required this.pager,
    required this.float,
    required this.index,
    required this.rtl,
    required this.size,
    required this.onTap,
    required this.label,
    required this.builder,
  });

  final PageController pager;
  final Animation<double> float;
  final int index;
  final bool rtl;
  final Size size;
  final VoidCallback onTap;
  final String label;
  final Widget Function(ValueListenable<double> swipe) builder;

  @override
  State<_CarouselSlot> createState() => _CarouselSlotState();
}

class _CarouselSlotState extends State<_CarouselSlot> {
  late final _swipe = _SwipeOffset(widget.pager, widget.index);

  @override
  void dispose() {
    _swipe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = context.colors.primary;
    // Built once; only the transform above it changes per frame.
    final card = RepaintBoundary(
      child: BouncyButton(
        semanticLabel: widget.label,
        minSize: 0,
        onTap: widget.onTap,
        child: SizedBox.fromSize(
          size: widget.size,
          child: widget.builder(_swipe),
        ),
      ),
    );
    final halo = RepaintBoundary(
      child: Container(
        width: widget.size.width,
        height: widget.size.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: 0.65),
              blurRadius: 36,
              spreadRadius: 4,
            ),
          ],
        ),
      ),
    );

    return AnimatedBuilder(
      animation: Listenable.merge([widget.pager, widget.float]),
      builder: (context, _) {
        final d = _swipe.raw;
        final near = (1 - d.abs()).clamp(0.0, 1.0);
        final side = widget.rtl ? -d : d;
        final bob =
            math.sin(widget.float.value * math.pi * 2) *
            AppSizes.carouselBob *
            near;
        final scale = 1 - AppSizes.carouselShrink * d.abs().clamp(0.0, 1.5);
        final m = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..translateByDouble(-side * widget.size.width * 0.16, -bob, 0, 1)
          ..rotateY(-side * AppSizes.carouselTilt)
          ..scaleByDouble(scale, scale, 1, 1);
        return Transform(
          alignment: Alignment.center,
          transform: m,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (near > 0.02) Opacity(opacity: near, child: halo),
              card,
            ],
          ),
        );
      },
    );
  }
}

/// How far a card is from the middle of the carousel: 0 centred, ±1 one
/// card away. Drives the card scene's parallax without rebuilding it.
class _SwipeOffset extends ChangeNotifier implements ValueListenable<double> {
  _SwipeOffset(this._pager, this._index) {
    _pager.addListener(notifyListeners);
  }

  final PageController _pager;
  final int _index;

  double get raw {
    if (!_pager.hasClients || !_pager.position.haveDimensions) {
      return _index.toDouble() - _pager.initialPage;
    }
    return _index - (_pager.page ?? 0);
  }

  @override
  double get value => raw.clamp(-1.0, 1.0) * 0.8;

  @override
  void dispose() {
    _pager.removeListener(notifyListeners);
    super.dispose();
  }
}

/// Paging with a little spring: cards overshoot softly and settle.
class _SpringyPagePhysics extends PageScrollPhysics {
  const _SpringyPagePhysics({super.parent});

  @override
  _SpringyPagePhysics applyTo(ScrollPhysics? ancestor) =>
      _SpringyPagePhysics(parent: buildParent(ancestor));

  @override
  SpringDescription get spring =>
      const SpringDescription(mass: 1, stiffness: 150, damping: 17);
}
