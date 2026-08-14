import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../l10n/strings.dart';

/// Shown while the app cannot reach the server.
///
/// Its own colour, and deliberately not the danger one. Losing signal is
/// not a fault, not the learner's doing, and not dangerous — styling it
/// in red would teach alarm where none is warranted, and would compete
/// with the one place `danger` is allowed to mean something. It uses the
/// neutral token, which reads as "state of the world" rather than
/// "something has gone wrong".
///
/// It says what still works before it says what does not, because a
/// learner who is told only that they are offline reasonably assumes the
/// app is now useless and closes it.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    return Semantics(
      // Arrives without the learner doing anything, so it announces
      // itself rather than waiting to be found.
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: tokens.space(2),
          vertical: tokens.space(1),
        ),
        color: tokens.unknown.withValues(alpha: 0.16),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, size: 18, color: tokens.textMuted),
            SizedBox(width: tokens.space(1)),
            Expanded(
              child: Text(
                s.offlineBannerText,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
