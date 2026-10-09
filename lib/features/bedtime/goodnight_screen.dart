import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/bedtime/sleep_timer.dart';
import '../../core/mascot/noori_mascot.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/firefly_layer.dart';
import '../../core/widgets/puffy_button.dart';
import '../parent/parent_gate.dart';

/// Shown when the bedtime sleep timer runs out. Noori is asleep under the
/// stars; only a grown-up (through the parent gate) can wake the app.
class GoodnightScreen extends ConsumerStatefulWidget {
  const GoodnightScreen({super.key});

  @override
  ConsumerState<GoodnightScreen> createState() => _GoodnightScreenState();
}

class _GoodnightScreenState extends ConsumerState<GoodnightScreen> {
  Future<void> _wake() async {
    if (await ParentGate.show(context) && mounted) {
      ref.read(sleepTimerProvider.notifier).wake();
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // The back button can't skip bedtime.
      canPop: false,
      child: Scaffold(
        backgroundColor: AppPalette.navy,
        body: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppPalette.navy, AppPalette.indigo],
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: FireflyLayer(count: 30, seed: 5, maxRadius: 2.5),
            ),
            // The moon, glowing softly.
            Positioned(
              top: AppSizes.bigTap,
              right: AppSizes.space6,
              child:
                  Container(
                        width: AppSizes.bigTap,
                        height: AppSizes.bigTap,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppPalette.moonCream,
                          boxShadow: [
                            BoxShadow(
                              color: AppPalette.glowGold.withValues(alpha: 0.5),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      )
                      .animate(onPlay: (a) => a.repeat(reverse: true))
                      .scaleXY(
                        begin: 1,
                        end: 1.05,
                        duration: 3.seconds,
                        curve: AppMotion.soft,
                      ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.space4),
                child: Column(
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: PuffyIconButton(
                        icon: Icons.lock_person_rounded,
                        semanticLabel: 'Wake up',
                        color: AppPalette.nightCard,
                        iconColor: AppPalette.moonCream,
                        sfx: null,
                        onTap: _wake,
                      ),
                    ),
                    const Spacer(),
                    // Fast asleep, and quiet: Noori doesn't speak at bedtime.
                    const NooriMascot(
                      state: NooriState.sleepy,
                      size: AppSizes.mascotLg,
                    ).animate().fadeIn(duration: 1200.ms),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
