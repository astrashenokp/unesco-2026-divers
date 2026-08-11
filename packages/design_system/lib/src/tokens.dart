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

  static const EvidenceGymTokens standard = EvidenceGymTokens(
    surface: Color(0xFFFAFAF7),
    surfaceRaised: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1E1B2E),
    textMuted: Color(0xFF615C78),
    action: Color(0xFF4A47A3),
    evidencePrimary: Color(0xFF1F8A85),
    evidenceSecondary: Color(0xFFD9A441),
    unknown: Color(0xFF6B7280),
    supported: Color(0xFF2E7D6B),
    contradicted: Color(0xFF8E4585),
    misleading: Color(0xFFC97A2B),
    focus: Color(0xFF2D9CDB),
    danger: Color(0xFFD64545),
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
