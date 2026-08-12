import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../l10n/strings.dart';

/// A standing marker that the data on screen is a fixture.
///
/// `SCREEN_INVENTORY.md` requires the demo route to label demo data
/// outside the recorded learner experience. This is that label: quiet
/// enough to ignore while playing, impossible to miss in a screenshot,
/// so a demo capture can never be mistaken for live evidence.
///
/// Styled in `evidenceSecondary`, not `danger` — a fixture is not a
/// hazard, and red here would spend the alarm colour on nothing.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    return Semantics(
      label: '${s.demoBadge}. ${s.demoBannerText}',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: tokens.space(2),
            vertical: tokens.space(0.75),
          ),
          color: tokens.evidenceSecondary.withValues(alpha: 0.18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.science_outlined, size: 14, color: tokens.textMuted),
              SizedBox(width: tokens.space(0.75)),
              Flexible(
                child: Text(
                  s.demoBannerText,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
