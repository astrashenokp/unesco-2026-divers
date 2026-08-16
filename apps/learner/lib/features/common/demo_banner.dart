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
/// Shown while the app is reading the pack bundled in the build because
/// the server cannot be reached.
///
/// This used to say "DEMO DATA — not live evidence", which was wrong in
/// both halves. The content is the same reviewed pack the server serves,
/// with the same rubric and the same scoring; reading it locally is a
/// capability of the product rather than a rehearsal of one. Calling it
/// a demo made the offline path look like something you would switch off
/// before showing anyone.
///
/// What it does say is the thing that actually differs: nothing is being
/// sent anywhere, so a conclusion reached now is recorded on this device
/// and not on an account.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: tokens.space(2),
          vertical: tokens.space(1),
        ),
        color: tokens.evidenceSecondary.withValues(alpha: 0.14),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, size: 18, color: tokens.textMuted),
            SizedBox(width: tokens.space(1)),
            Expanded(
              child: Text(
                s.offlinePackNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
