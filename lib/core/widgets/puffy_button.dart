import 'package:flutter/material.dart';

import '../audio/audio_service.dart';
import '../theme/app_theme.dart';
import 'bouncy_button.dart';

/// A "puffy" 3D button: rounded fill with a darker bottom edge, soft shadow
/// and a top highlight. Always bouncy.
class PuffyButton extends StatelessWidget {
  const PuffyButton({
    super.key,
    required this.child,
    required this.onTap,
    this.color,
    this.depthColor,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSizes.space5,
      vertical: AppSizes.space3,
    ),
    this.radius = AppSizes.radiusMd,
    this.semanticLabel,
    this.breathe = false,
    this.sfx = Sfx.tap,
    this.minSize = AppSizes.minTap,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Color? depthColor;
  final EdgeInsets padding;
  final double radius;
  final String? semanticLabel;
  final bool breathe;
  final Sfx? sfx;
  final double minSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fill = color ?? c.primary;
    final depth = depthColor ?? _darken(fill);
    return BouncyButton(
      onTap: onTap,
      semanticLabel: semanticLabel,
      breathe: breathe,
      sfx: sfx,
      minSize: minSize,
      child: Container(
        constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
        margin: const EdgeInsets.only(bottom: AppSizes.puffyDepth),
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(fill, AppPalette.white, 0.25)!, fill],
          ),
          boxShadow: [
            BoxShadow(
              color: depth,
              offset: const Offset(0, AppSizes.puffyDepth),
            ),
            const BoxShadow(
              color: AppPalette.shadow,
              offset: Offset(0, AppSizes.puffyDepth + 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Center(widthFactor: 1, heightFactor: 1, child: child),
      ),
    );
  }

  static Color _darken(Color c) =>
      Color.lerp(c, const Color(0xFF000000), 0.22)!;
}

/// Round puffy button holding an icon; 72dp by default.
class PuffyIconButton extends StatelessWidget {
  const PuffyIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.color,
    this.iconColor,
    this.size = AppSizes.minTap,
    this.breathe = false,
    this.sfx = Sfx.tap,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final Color? color;
  final Color? iconColor;
  final double size;
  final bool breathe;
  final Sfx? sfx;

  @override
  Widget build(BuildContext context) {
    return PuffyButton(
      onTap: onTap,
      color: color,
      semanticLabel: semanticLabel,
      breathe: breathe,
      sfx: sfx,
      minSize: size,
      radius: size / 2,
      padding: EdgeInsets.zero,
      child: Icon(
        icon,
        size: size * 0.5,
        color: iconColor ?? context.colors.onPrimary,
      ),
    );
  }
}
