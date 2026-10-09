import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

/// An SVG illustration. Scenery dims to a moonlit tint in the Bedtime theme.
class Illustration extends StatelessWidget {
  const Illustration(
    this.asset, {
    super.key,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.nightTint = true,
    this.semanticLabel,
  });

  final String asset;
  final BoxFit fit;
  final Alignment alignment;
  final bool nightTint;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final night = Theme.of(context).brightness == Brightness.dark;
    return SvgPicture.asset(
      asset,
      fit: fit,
      alignment: alignment,
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      colorFilter: night && nightTint
          ? ColorFilter.mode(
              AppPalette.navy.withValues(alpha: 0.55),
              BlendMode.srcATop,
            )
          : null,
    );
  }
}
