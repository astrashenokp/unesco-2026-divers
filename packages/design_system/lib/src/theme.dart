// Scoped import: the iOS/macOS transition lives in cupertino, not
// material, and importing cupertino wholesale would make several names
// ambiguous against material.
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
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
    // Fade-forwards is Material 3's shared-axis transition: content
    // slides a short distance along the travel direction while it
    // crossfades. It reads as "forward into a detail" far better than
    // Zoom, which reads as a window opening from nowhere.
    //
    // iOS and macOS keep the platform back-swipe transition, because
    // overriding it breaks the edge-swipe gesture people expect there.
    //
    // Each is wrapped so reduce-motion is honoured. Flutter does *not*
    // do this for routes on its own — measured: a pushed route is still
    // mid-animation 100ms in with disableAnimations set.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _CalmPageTransitionsBuilder(FadeForwardsPageTransitionsBuilder()),
        TargetPlatform.iOS: _CalmPageTransitionsBuilder(CupertinoPageTransitionsBuilder()),
        TargetPlatform.macOS: _CalmPageTransitionsBuilder(CupertinoPageTransitionsBuilder()),
        TargetPlatform.windows: _CalmPageTransitionsBuilder(FadeForwardsPageTransitionsBuilder()),
        TargetPlatform.linux: _CalmPageTransitionsBuilder(FadeForwardsPageTransitionsBuilder()),
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


/// Delegates to [inner], unless the learner has asked for less motion —
/// then the new route simply appears.
///
/// Flutter honours `disableAnimations` for implicit animations but not
/// for route transitions, so without this a reduce-motion user still
/// gets every push and pop animated.
class _CalmPageTransitionsBuilder extends PageTransitionsBuilder {
  const _CalmPageTransitionsBuilder(this.inner);

  final PageTransitionsBuilder inner;

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return child;
    if (route == null) return child;
    return inner.buildTransitions<T>(
        route, context, animation, secondaryAnimation, child);
  }
}
