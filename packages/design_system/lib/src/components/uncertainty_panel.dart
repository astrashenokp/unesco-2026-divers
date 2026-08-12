import 'package:flutter/material.dart';

import '../motion.dart';
import '../tokens.dart';

/// Shown when a learner answers "not enough evidence" on any axis.
///
/// This is the component the whole product argues for. Every interface
/// like this one has an "unknown" option, and almost every one treats it
/// as the answer you give when you have given up — smaller, greyer, last
/// in the list, worth fewer points. Learners read that layout correctly
/// and stop choosing it, which is precisely the habit that makes people
/// share things they have not checked.
///
/// So when the answer is chosen, it gets acknowledged rather than
/// tolerated, and then it gets put to work: naming what evidence *would*
/// settle the question turns "I don't know" from a stopping point into a
/// plan. That move is the difference between uncertainty and apathy, and
/// it is the one worth teaching.
///
/// Nothing selected here is sent anywhere. `ConclusionInput` in the
/// contract is `additionalProperties: false`, and widening a shared
/// contract to carry a client-side reflection would be the wrong trade —
/// the thinking is the point, not the telemetry.
class UncertaintyPanel extends StatefulWidget {
  const UncertaintyPanel({
    super.key,
    required this.title,
    required this.body,
    required this.prompt,
    required this.options,
    this.footnote,
  });

  /// Affirms the choice. Never phrased as a consolation.
  final String title;
  final String body;

  /// "What would settle this?"
  final String prompt;

  /// Kinds of evidence that would resolve the question. Deliberately
  /// generic — these are the moves that work on any claim, which is what
  /// makes them worth learning rather than memorising.
  final List<String> options;

  /// Optional line tying this to the share decision below it.
  final String? footnote;

  @override
  State<UncertaintyPanel> createState() => _UncertaintyPanelState();
}

class _UncertaintyPanelState extends State<UncertaintyPanel> {
  final _chosen = <String>{};

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.of(context, Motion.enter),
      curve: Motion.curveEmphasis,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child),
      ),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: tokens.space(2)),
        padding: EdgeInsets.all(tokens.space(2)),
        decoration: BoxDecoration(
          // The neutral token, not danger and not a caution. Saying you
          // do not know is not a warning state.
          color: tokens.unknown.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(tokens.space(2)),
          border: Border.all(color: tokens.unknown.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A live region: the panel appears in response to a choice
            // made elsewhere on the page, so a screen reader user would
            // otherwise never learn it arrived.
            Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.balance, color: tokens.unknown, size: 20),
                  SizedBox(width: tokens.space(1)),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: tokens.space(1)),
            Text(widget.body, style: Theme.of(context).textTheme.bodyMedium),
            SizedBox(height: tokens.space(2)),
            Text(
              widget.prompt,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: tokens.space(1)),
            Wrap(
              spacing: tokens.space(1),
              runSpacing: tokens.space(1),
              children: [
                for (final option in widget.options)
                  ConstrainedBox(
                    // The 44dp minimum target applies here as much as to
                    // any other control.
                    constraints: const BoxConstraints(minHeight: 44),
                    child: FilterChip(
                      label: Text(option),
                      selected: _chosen.contains(option),
                      // FilterChip announces its own selected state, so
                      // no wrapping Semantics node is added — a second
                      // one would produce a duplicate announcement.
                      onSelected: (selected) => setState(() {
                        selected ? _chosen.add(option) : _chosen.remove(option);
                      }),
                    ),
                  ),
              ],
            ),
            if (widget.footnote != null) ...[
              SizedBox(height: tokens.space(1.5)),
              Text(
                widget.footnote!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
