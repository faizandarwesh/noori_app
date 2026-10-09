import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_lang.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/puffy_button.dart';

/// Grown-ups only: a sum with written-out numbers that a pre-reader can't
/// solve. Required before settings or any outbound link.
abstract final class ParentGate {
  /// Resolves true only if the grown-up answered correctly.
  static Future<bool> show(BuildContext context) async {
    final passed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: AppPalette.shadow,
      transitionDuration: AppMotion.entrance,
      pageBuilder: (context, _, _) => const _ParentGateDialog(),
      transitionBuilder: (context, anim, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: AppMotion.pop),
        child: FadeTransition(opacity: anim, child: child),
      ),
    );
    return passed ?? false;
  }
}

/// Written-out numbers 1–9.
const _numberWords = [
  LocalizedText(en: 'one', ur: 'ایک'),
  LocalizedText(en: 'two', ur: 'دو'),
  LocalizedText(en: 'three', ur: 'تین'),
  LocalizedText(en: 'four', ur: 'چار'),
  LocalizedText(en: 'five', ur: 'پانچ'),
  LocalizedText(en: 'six', ur: 'چھ'),
  LocalizedText(en: 'seven', ur: 'سات'),
  LocalizedText(en: 'eight', ur: 'آٹھ'),
  LocalizedText(en: 'nine', ur: 'نو'),
];

const _title = LocalizedText(en: 'For grown-ups', ur: 'بڑوں کے لیے');

String _question(int a, int b, AppLang lang) {
  final wa = _numberWords[a - 1].of(lang), wb = _numberWords[b - 1].of(lang);
  return lang == AppLang.en
      ? '${wa[0].toUpperCase()}${wa.substring(1)} plus $wb?'
      : '$wa جمع $wb کتنے ہوتے ہیں؟';
}

class _ParentGateDialog extends ConsumerStatefulWidget {
  const _ParentGateDialog();

  @override
  ConsumerState<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends ConsumerState<_ParentGateDialog> {
  final _random = math.Random();
  late final int _a = 3 + _random.nextInt(7);
  late final int _b = 3 + _random.nextInt(7);
  late final List<int> _choices = _makeChoices();

  List<int> _makeChoices() {
    final answer = _a + _b;
    final set = <int>{answer};
    while (set.length < 3) {
      final delta = (1 + _random.nextInt(3)) * (_random.nextBool() ? 1 : -1);
      set.add(answer + delta);
    }
    return set.toList()..shuffle(_random);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lang = ref.watch(appSettingsProvider).lang;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(AppSizes.space5),
          padding: const EdgeInsets.all(AppSizes.space5),
          constraints: const BoxConstraints(maxWidth: AppSizes.dialogMaxWidth),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            boxShadow: const [
              BoxShadow(
                color: AppPalette.shadow,
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lock_person_rounded,
                    color: c.onSurfaceSoft,
                    size: AppSizes.iconMd,
                  ),
                  const SizedBox(width: AppSizes.space2),
                  Expanded(
                    child: Text(
                      _title.of(lang),
                      style: AppTypography.style(
                        lang,
                        role: TextRole.label,
                        color: c.onSurfaceSoft,
                        weight: 600,
                      ),
                    ),
                  ),
                  PuffyIconButton(
                    icon: Icons.close_rounded,
                    semanticLabel: 'Close',
                    color: c.backgroundAlt,
                    size: AppSizes.minTap,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.space4),
              Text(
                _question(_a, _b, lang),
                textAlign: TextAlign.center,
                style: AppTypography.style(
                  lang,
                  role: TextRole.title,
                  color: c.onSurface,
                  weight: 700,
                ),
              ),
              const SizedBox(height: AppSizes.space5),
              Row(
                children: [
                  for (final (i, n) in _choices.indexed)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.space1,
                        ),
                        child: PuffyButton(
                          padding: EdgeInsets.zero,
                          semanticLabel: '$n',
                          color: c.backgroundAlt,
                          onTap: () => Navigator.of(context).pop(n == _a + _b),
                          child: Text(
                            '$n',
                            style: AppTypography.style(
                              AppLang.en,
                              role: TextRole.title,
                              color: c.onSurface,
                              weight: 700,
                            ),
                          ),
                        ).popIn(i),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
