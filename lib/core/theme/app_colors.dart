import 'package:flutter/material.dart';

/// Raw colour tokens. Widgets should not read these directly; they read the
/// active [NooriColors] theme extension so Day and Bedtime can swap cleanly.
abstract final class AppPalette {
  // Day
  static const peach = Color(0xFFFFD6BA);
  static const mint = Color(0xFFB8F2E6);
  static const sky = Color(0xFFAED9E0);
  static const sunshine = Color(0xFFFFB703);
  static const coral = Color(0xFFFB8500);
  static const cream = Color(0xFFFFF8EC);
  static const ink = Color(0xFF3B2F3F);
  static const inkSoft = Color(0xFF6E6070);

  // Bedtime
  static const navy = Color(0xFF1B1F3B);
  static const indigo = Color(0xFF2E3267);
  static const glowGold = Color(0xFFFFD166);
  static const moonCream = Color(0xFFF4EEDC);
  static const nightCard = Color(0xFF272B55);

  // Shared
  static const white = Color(0xFFFFFFFF);
  static const shadow = Color(0x33000000);
  static const firefly = Color(0xFFFFE680);
  static const fireflyGlow = Color(0xFFFFD166);
  static const lockGrey = Color(0xFF9A9AA8);
  static const leafLight = Color(0xFF8BD17C);
  static const leafMid = Color(0xFF4FAE6A);
  static const leafDark = Color(0xFF2F7F5B);
  static const trunk = Color(0xFF9B6B4A);
}

/// Noori the owl's own palette: soft teal and cream.
abstract final class NooriPalette {
  static const body = Color(0xFF45ADA5);
  static const bodyLight = Color(0xFF7FD3C8);
  static const bodyDark = Color(0xFF2C8580);
  static const face = Color(0xFFFFF3DC);
  static const belly = Color(0xFFFCE9C8);
  static const bellyScallop = Color(0xFFEFD3A8);
  static const eyeWhite = Color(0xFFFFFFFF);
  static const pupil = Color(0xFF2D2433);
  static const beak = Color(0xFFFFB703);
  static const beakDark = Color(0xFFE08E00);
  static const cheek = Color(0x66FF8A8A);
  static const scarf = Color(0xFFFB8500);
  static const scarfStripe = Color(0xFFFFD166);

  // Wardrobe: scarves.
  static const scarfMint = Color(0xFF2EC4A0);
  static const scarfMintStripe = Color(0xFFE6FFF7);
  static const scarfRose = Color(0xFFFF6FA3);
  static const scarfRoseStripe = Color(0xFFFFD6E6);
  static const scarfOcean = Color(0xFF3D8BFF);
  static const scarfOceanStripe = Color(0xFFBFE0FF);
  static const scarfGrape = Color(0xFF9B6BE0);
  static const scarfGrapeStripe = Color(0xFFFFD166);
  static const rainbow = [
    Color(0xFFFF6B6B),
    Color(0xFFFFB347),
    Color(0xFFFFE66D),
    Color(0xFF7BD389),
    Color(0xFF5DADE2),
    Color(0xFFA98BE0),
  ];

  // Wardrobe: hats.
  static const bow = Color(0xFFFF5C8A);
  static const bowKnot = Color(0xFFD9406E);
  static const petal = Color(0xFFFF9EC4);
  static const petalCentre = Color(0xFFFFD166);
  static const partyHat = Color(0xFF6C8CFF);
  static const partyStripe = Color(0xFFFFD166);
  static const pompom = Color(0xFFFF6B6B);
  static const crownGold = Color(0xFFFFC93C);
  static const crownShade = Color(0xFFE0A100);
  static const gemPink = Color(0xFFFF5C8A);
  static const gemBlue = Color(0xFF4FC3F7);
  static const white = Color(0xFFFFFFFF);
  static const feet = Color(0xFFF2A23A);
  static const groundShadow = Color(0x26000000);
  static const eyelid = Color(0xFFF1D9B0);
  static const zzz = Color(0xFFC7DBFF);
  static const sparkle = Color(0xFFFFD166);
  static const thinkDot = Color(0xFFFFFFFF);
}

/// Eyelid colours matching the skin around each story character's eyes.
abstract final class CastPalette {
  static const rabbitLid = Color(0xFFF1ECF5);
  static const monkeyLid = Color(0xFFF3D1AC);
  static const parrotLid = Color(0xFFFFFFFF);
  static const elephantLid = Color(0xFFA6BDD2);
  static const turtleLid = Color(0xFFFFFFFF);
  static const lash = Color(0xFF2D2433);
}

/// Home's living sky. Each mode cycles slowly through its set of
/// (top, middle, bottom) gradients.
abstract final class SkyPalette {
  static const dawn = [
    [Color(0xFF8EC5E8), Color(0xFFFFC9B5), Color(0xFFFFE6C7)],
    [Color(0xFFB7A6E6), Color(0xFFFFB8B0), Color(0xFFFFDDB0)],
    [Color(0xFF9ED2E6), Color(0xFFFFD3A5), Color(0xFFFFF0C9)],
    [Color(0xFFA9B9F0), Color(0xFFF9C2D0), Color(0xFFFFE2C2)],
  ];
  static const night = [
    [Color(0xFF141832), Color(0xFF2E3267), Color(0xFF4A3F7A)],
    [Color(0xFF1B1F3B), Color(0xFF34306E), Color(0xFF5B4A86)],
    [Color(0xFF111530), Color(0xFF283066), Color(0xFF43407E)],
  ];
  static const cloudDay = Color(0xE6FFFFFF);
  static const cloudNight = Color(0x40C7DBFF);
}

/// The cinematic story player's overlays.
abstract final class CinemaPalette {
  /// Bottom of the subtitle strip's fade.
  static const subtitleShade = Color(0xB3141022);
  static const subtitleClear = Color(0x00141022);
  static const subtitleText = Color(0xFFFFFFFF);
  static const subtitleShadow = Color(0x99000000);
  static const pauseVeil = Color(0x66141022);
  static const glass = Color(0x33FFFFFF);
  static const glassBorder = Color(0x59FFFFFF);
}

/// Theme extension holding the semantic colours for the active mode.
@immutable
class NooriColors extends ThemeExtension<NooriColors> {
  const NooriColors({
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.primary,
    required this.primaryDeep,
    required this.secondary,
    required this.secondaryDeep,
    required this.onSurface,
    required this.onSurfaceSoft,
    required this.onPrimary,
    required this.highlight,
    required this.bubble,
    required this.onBubble,
    required this.skyTop,
    required this.skyBottom,
  });

  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color primary;
  final Color primaryDeep;
  final Color secondary;
  final Color secondaryDeep;
  final Color onSurface;
  final Color onSurfaceSoft;
  final Color onPrimary;

  /// Karaoke word highlight.
  final Color highlight;
  final Color bubble;
  final Color onBubble;
  final Color skyTop;
  final Color skyBottom;

  static const day = NooriColors(
    background: AppPalette.peach,
    backgroundAlt: AppPalette.mint,
    surface: AppPalette.cream,
    primary: AppPalette.sunshine,
    primaryDeep: Color(0xFFD99A00),
    secondary: AppPalette.coral,
    secondaryDeep: Color(0xFFC76A00),
    onSurface: AppPalette.ink,
    onSurfaceSoft: AppPalette.inkSoft,
    onPrimary: AppPalette.ink,
    highlight: AppPalette.sunshine,
    bubble: AppPalette.white,
    onBubble: AppPalette.ink,
    skyTop: AppPalette.sky,
    skyBottom: AppPalette.mint,
  );

  static const bedtime = NooriColors(
    background: AppPalette.navy,
    backgroundAlt: AppPalette.indigo,
    surface: AppPalette.nightCard,
    primary: AppPalette.glowGold,
    primaryDeep: Color(0xFFC9A04A),
    secondary: Color(0xFF8E94F2),
    secondaryDeep: Color(0xFF5E63B8),
    onSurface: AppPalette.moonCream,
    onSurfaceSoft: Color(0xFFB9B6CF),
    onPrimary: AppPalette.navy,
    highlight: AppPalette.glowGold,
    bubble: AppPalette.moonCream,
    onBubble: AppPalette.navy,
    skyTop: AppPalette.navy,
    skyBottom: AppPalette.indigo,
  );

  @override
  NooriColors copyWith({
    Color? background,
    Color? backgroundAlt,
    Color? surface,
    Color? primary,
    Color? primaryDeep,
    Color? secondary,
    Color? secondaryDeep,
    Color? onSurface,
    Color? onSurfaceSoft,
    Color? onPrimary,
    Color? highlight,
    Color? bubble,
    Color? onBubble,
    Color? skyTop,
    Color? skyBottom,
  }) {
    return NooriColors(
      background: background ?? this.background,
      backgroundAlt: backgroundAlt ?? this.backgroundAlt,
      surface: surface ?? this.surface,
      primary: primary ?? this.primary,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      secondary: secondary ?? this.secondary,
      secondaryDeep: secondaryDeep ?? this.secondaryDeep,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceSoft: onSurfaceSoft ?? this.onSurfaceSoft,
      onPrimary: onPrimary ?? this.onPrimary,
      highlight: highlight ?? this.highlight,
      bubble: bubble ?? this.bubble,
      onBubble: onBubble ?? this.onBubble,
      skyTop: skyTop ?? this.skyTop,
      skyBottom: skyBottom ?? this.skyBottom,
    );
  }

  @override
  NooriColors lerp(NooriColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return NooriColors(
      background: l(background, other.background),
      backgroundAlt: l(backgroundAlt, other.backgroundAlt),
      surface: l(surface, other.surface),
      primary: l(primary, other.primary),
      primaryDeep: l(primaryDeep, other.primaryDeep),
      secondary: l(secondary, other.secondary),
      secondaryDeep: l(secondaryDeep, other.secondaryDeep),
      onSurface: l(onSurface, other.onSurface),
      onSurfaceSoft: l(onSurfaceSoft, other.onSurfaceSoft),
      onPrimary: l(onPrimary, other.onPrimary),
      highlight: l(highlight, other.highlight),
      bubble: l(bubble, other.bubble),
      onBubble: l(onBubble, other.onBubble),
      skyTop: l(skyTop, other.skyTop),
      skyBottom: l(skyBottom, other.skyBottom),
    );
  }
}
