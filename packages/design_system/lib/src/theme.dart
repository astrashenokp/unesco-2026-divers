import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds the single Evidence Gym theme. System-fallback fonts only —
/// no bundled webfont, so Ukrainian text always renders and there is
/// no missing-font-asset risk. See MASCOT_AND_VISUAL_LANGUAGE.md.
ThemeData buildEvidenceGymTheme() {
  const tokens = EvidenceGymTokens.standard;

  final colorScheme = ColorScheme.fromSeed(
    seedColor: tokens.action,
    brightness: Brightness.light,
    primary: tokens.action,
    surface: tokens.surface,
    error: tokens.danger,
  );

  final base = ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: tokens.surface,
    useMaterial3: true,
    // No fontFamily on purpose: the platform default already covers
    // Ukrainian on every target, and bundling a webfont would add a
    // network dependency and a missing-glyph risk for exactly the
    // characters this product cannot afford to lose.
    // Zoom is the standing Material 3 default; kept explicit (rather
    // than a newer builder we cannot compiler-check in this
    // environment) so transitions are guaranteed to build.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      },
    ),
  );

  return base.copyWith(
    extensions: const [tokens],
    textTheme: base.textTheme.copyWith(
      // Bold, tracked-out display type: the "big type + a confident
      // line" read borrowed from vau.agency, without a custom font.
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        color: tokens.textPrimary,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
        color: tokens.textPrimary,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: tokens.textPrimary,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(color: tokens.textPrimary),
      bodyMedium:
          base.textTheme.bodyMedium?.copyWith(color: tokens.textPrimary),
      bodySmall: base.textTheme.bodySmall?.copyWith(color: tokens.textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(44, 44),
        backgroundColor: tokens.action,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.space(1.5)),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: tokens.space(3),
          vertical: tokens.space(2),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 44),
        foregroundColor: tokens.action,
        side: BorderSide(color: tokens.action),
      ),
    ),
    focusColor: tokens.focus,
    cardTheme: CardThemeData(
      color: tokens.surfaceRaised,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.space(2)),
      ),
    ),
  );
}

/// A single [evidenceSecondary]-colored rule under a section heading —
/// the recurring "line under big type" motif. Purely decorative
/// (excluded from the semantics tree) so it never competes with real
/// content for a screen reader user.
class SectionRule extends StatelessWidget {
  const SectionRule({super.key, this.width = 56});

  final double width;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ExcludeSemantics(
      child: Container(
        width: width,
        height: 3,
        margin: EdgeInsets.only(top: tokens.space(1), bottom: tokens.space(2)),
        decoration: BoxDecoration(
          color: tokens.evidenceSecondary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
