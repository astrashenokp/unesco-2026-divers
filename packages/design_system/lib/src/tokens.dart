import 'package:flutter/material.dart';

/// Semantic color/spacing/motion tokens for Evidence Gym.
///
/// Rationale for the palette lives in `docs/06-design/MASCOT_AND_VISUAL_LANGUAGE.md`.
/// Never reach for a raw [Color] in a feature widget — add or reuse a token here.
@immutable
class EvidenceGymTokens extends ThemeExtension<EvidenceGymTokens> {
  const EvidenceGymTokens({
    required this.surface,
    required this.surfaceRaised,
    required this.textPrimary,
    required this.textMuted,
    required this.action,
    required this.onAction,
    required this.evidencePrimary,
    required this.evidenceSecondary,
    required this.unknown,
    required this.supported,
    required this.contradicted,
    required this.misleading,
    required this.focus,
    required this.danger,
    required this.spaceUnit,
    required this.motionFast,
    required this.motionSlow,
  });

  final Color surface;
  final Color surfaceRaised;
  final Color textPrimary;
  final Color textMuted;
  final Color action;

  /// Label colour for anything filled with [action] or [evidencePrimary].
  ///
  /// A token rather than a hardcoded white, because white is only the
  /// right answer on the light theme. The dark theme's action colour is
  /// a pale lavender, and white text on it is unreadable — it needs a
  /// dark label. Hardcoding white made that a bug waiting for a theme.
  final Color onAction;
  final Color evidencePrimary;
  final Color evidenceSecondary;
  final Color unknown;
  final Color supported;
  final Color contradicted;
  final Color misleading;
  final Color focus;
  final Color danger;
  final double spaceUnit;
  final Duration motionFast;
  final Duration motionSlow;

  /// Every pair that actually appears together in the UI is checked
  /// against WCAG 2.2 AA by `test/contrast_test.dart`. Four of these
  /// values were adjusted after that test was written, because the
  /// original palette had been eyeballed and four pairs missed by a
  /// small margin. Do not hand-tune a colour here without re-running it.
  static const EvidenceGymTokens standard = EvidenceGymTokens(
    surface: Color(0xFFFAFAF7),
    surfaceRaised: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1E1B2E),
    textMuted: Color(0xFF615C78),
    action: Color(0xFF4A47A3),
    onAction: Color(0xFFFFFFFF),
    evidencePrimary: Color(0xFF1D847F),
    evidenceSecondary: Color(0xFFBA8D37),
    unknown: Color(0xFF6B7280),
    supported: Color(0xFF2E7D6B),
    contradicted: Color(0xFF8E4585),
    misleading: Color(0xFFC97A2B),
    focus: Color(0xFF2C98D6),
    danger: Color(0xFFD14343),
    spaceUnit: 8,
    motionFast: Duration(milliseconds: 150),
    motionSlow: Duration(milliseconds: 300),
  );

  /// The dark theme.
  ///
  /// Not an inversion of [standard]. Inverting a palette is the usual
  /// shortcut and it fails twice over: a mid-tone that carries 4.5:1
  /// against white carries far less against near-black, and a colour
  /// that reads as calm on paper reads as neon on it. Every accent here
  /// was lightened and desaturated until the same pairs pass, and every
  /// one is checked by the same test as the light theme.
  ///
  /// The ground is a deep indigo rather than pure black. Black would be
  /// cheaper on OLED, but white text on `#000` blooms and the edges of
  /// glyphs smear during scroll, which costs exactly the people the
  /// dark theme is meant to help. It also keeps the theme recognisably
  /// Lupa's, since indigo is her body colour.
  ///
  /// The relations keep their meanings and keep their distance from a
  /// green/red pairing — a dark theme is not licence to reintroduce the
  /// binary verdict the product argues against.
  static const EvidenceGymTokens dark = EvidenceGymTokens(
    surface: Color(0xFF14131C),
    surfaceRaised: Color(0xFF201E2C),
    textPrimary: Color(0xFFF3F1F8),
    textMuted: Color(0xFFADA7C2),
    action: Color(0xFFA6A2F0),
    // Dark label on the pale action fill — see [onAction].
    onAction: Color(0xFF14131C),
    evidencePrimary: Color(0xFF4FC9C0),
    evidenceSecondary: Color(0xFFE2B863),
    unknown: Color(0xFFA5ABBB),
    supported: Color(0xFF5EC7AB),
    contradicted: Color(0xFFDF95D2),
    misleading: Color(0xFFEDA463),
    focus: Color(0xFF78C6F7),
    danger: Color(0xFFF58A8A),
    spaceUnit: 8,
    motionFast: Duration(milliseconds: 150),
    motionSlow: Duration(milliseconds: 300),
  );

  /// 4/8-point spacing scale, per `DESIGN_SYSTEM.md`.
  double space(double units) => spaceUnit * units;

  @override
  EvidenceGymTokens copyWith({
    Color? surface,
    Color? surfaceRaised,
    Color? textPrimary,
    Color? textMuted,
    Color? action,
    Color? onAction,
    Color? evidencePrimary,
    Color? evidenceSecondary,
    Color? unknown,
    Color? supported,
    Color? contradicted,
    Color? misleading,
    Color? focus,
    Color? danger,
    double? spaceUnit,
    Duration? motionFast,
    Duration? motionSlow,
  }) {
    return EvidenceGymTokens(
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      action: action ?? this.action,
      onAction: onAction ?? this.onAction,
      evidencePrimary: evidencePrimary ?? this.evidencePrimary,
      evidenceSecondary: evidenceSecondary ?? this.evidenceSecondary,
      unknown: unknown ?? this.unknown,
      supported: supported ?? this.supported,
      contradicted: contradicted ?? this.contradicted,
      misleading: misleading ?? this.misleading,
      focus: focus ?? this.focus,
      danger: danger ?? this.danger,
      spaceUnit: spaceUnit ?? this.spaceUnit,
      motionFast: motionFast ?? this.motionFast,
      motionSlow: motionSlow ?? this.motionSlow,
    );
  }

  @override
  EvidenceGymTokens lerp(ThemeExtension<EvidenceGymTokens>? other, double t) {
    if (other is! EvidenceGymTokens) return this;
    return EvidenceGymTokens(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      action: Color.lerp(action, other.action, t)!,
      onAction: Color.lerp(onAction, other.onAction, t)!,
      evidencePrimary: Color.lerp(evidencePrimary, other.evidencePrimary, t)!,
      evidenceSecondary:
          Color.lerp(evidenceSecondary, other.evidenceSecondary, t)!,
      unknown: Color.lerp(unknown, other.unknown, t)!,
      supported: Color.lerp(supported, other.supported, t)!,
      contradicted: Color.lerp(contradicted, other.contradicted, t)!,
      misleading: Color.lerp(misleading, other.misleading, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      spaceUnit: spaceUnit,
      motionFast: motionFast,
      motionSlow: motionSlow,
    );
  }
}

extension EvidenceGymTokensContext on BuildContext {
  /// `context.tokens` — the only sanctioned way to read a design color/spacing value.
  EvidenceGymTokens get tokens =>
      Theme.of(this).extension<EvidenceGymTokens>() ??
      EvidenceGymTokens.standard;
}
