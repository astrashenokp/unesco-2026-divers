import 'package:flutter/widgets.dart';

/// One place for every duration and curve in the product.
///
/// Deliberately *not* a `ThemeExtension`: motion is not themed, and
/// making it one would force these values through `lerp`, which is
/// meaningless for a curve. They are constants because consistency is
/// the whole point — a screen that invents its own 250ms is the reason
/// interfaces feel unsettled.
///
/// Every duration stays inside the 150–300ms band from `DESIGN_SYSTEM.md`
/// except [enter] and [celebrate], which cover entrances and rewards
/// where a longer arc reads as generous rather than sluggish.
abstract final class Motion {
  /// State flips: a chip selecting, a switch, an opacity change.
  static const fast = Duration(milliseconds: 150);

  /// The default for anything the eye should follow.
  static const standard = Duration(milliseconds: 300);

  /// Entrances — a card arriving, a node revealing.
  static const enter = Duration(milliseconds: 420);

  /// Rewards. Long enough to feel like a moment, short enough to skip.
  static const celebrate = Duration(milliseconds: 700);

  /// Press feedback. Below ~120ms a press stops feeling connected to the
  /// finger; above it, it starts to feel laggy.
  static const press = Duration(milliseconds: 120);

  /// Stagger between siblings in a list or grid.
  static const stagger = Duration(milliseconds: 60);

  /// Decelerating: the default for almost everything.
  static const curveStandard = Curves.easeOutCubic;

  /// Slight overshoot, for things that should feel physical — a node
  /// popping in, a tile landing.
  static const curveEmphasis = Curves.easeOutBack;

  /// Springy. Reserved for celebration; overshoots enough to be playful.
  static const curveSpring = Curves.elasticOut;

  /// Accelerating, for things leaving.
  static const curveExit = Curves.easeInCubic;

  /// Collapses a duration to zero when the learner has asked for less
  /// motion. Use this rather than branching at every call site, so no
  /// animation can quietly escape the setting.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false
          ? Duration.zero
          : duration;
}
