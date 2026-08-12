import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../l10n/strings.dart';

/// The single place that turns a thrown error into something a learner
/// can act on. Every data-loading screen routes through this so "no
/// connection" never gets presented as though the server said something,
/// and a server error never gets blamed on the network.
class FailureView extends StatelessWidget {
  const FailureView({
    super.key,
    required this.error,
    required this.onRetry,
    this.isDemo = false,
  });

  final Object? error;
  final VoidCallback onRetry;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    final apiError = error is EvidenceGymApiException
        ? error! as EvidenceGymApiException
        : null;
    final offline = apiError?.isOffline ?? false;

    // Guest sign-in currently reaches the API with no token, and the
    // server has no identity verifier wired in, so the primary button on
    // the first screen leads straight here. Reporting the raw problem
    // title left the learner at a dead end with nothing to try; the demo
    // key is a working route and saying so costs nothing.
    final authUnavailable = apiError?.isAuthUnavailable ?? false;

    final title = offline
        ? s.offlineTitle
        : authUnavailable
            ? s.signInUnavailableTitle
            : (apiError?.problem.title ?? s.pathError);
    final body = offline
        ? s.offlineBody
        : authUnavailable
            ? s.signInUnavailableBody
            : null;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.space(3)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lupa(
              // Neither being offline nor sign-in being down is the
              // learner's fault, so Lupa is not alarmed at them.
              mood: offline || authUnavailable
                  ? LupaMood.idle
                  : LupaMood.concerned,
              size: 80,
              semanticLabel:
                  s.lupaLabel(offline || authUnavailable ? 'idle' : 'concerned'),
            ),
            SizedBox(height: tokens.space(2)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  offline
                      ? Icons.wifi_off_outlined
                      : authUnavailable
                          ? Icons.key_off_outlined
                          : Icons.error_outline,
                  // Connection trouble is not a hazard — styling it in
                  // danger red would teach alarm where none is warranted.
                  // The same goes for sign-in being unavailable.
                  color: offline || authUnavailable
                      ? tokens.textMuted
                      : tokens.danger,
                  size: 20,
                ),
                SizedBox(width: tokens.space(1)),
                Flexible(
                  child: Text(title, style: Theme.of(context).textTheme.titleLarge),
                ),
              ],
            ),
            if (body != null) ...[
              SizedBox(height: tokens.space(1)),
              Text(body, textAlign: TextAlign.center),
            ],
            if (authUnavailable) ...[
              SizedBox(height: tokens.space(1)),
              Text(s.signInUnavailableHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            if (offline && isDemo) ...[
              SizedBox(height: tokens.space(1)),
              Text(s.offlineDemoHint, style: Theme.of(context).textTheme.bodySmall),
            ],
            SizedBox(height: tokens.space(2)),
            ElevatedButton(onPressed: onRetry, child: Text(s.retry)),
          ],
        ),
      ),
    );
  }
}
