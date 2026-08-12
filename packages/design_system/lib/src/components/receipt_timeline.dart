import 'package:flutter/material.dart';

import '../motion.dart';
import '../tokens.dart';

/// What kind of step this was.
enum ReceiptStepKind { predicted, checked, asked, concluded, decided }

@immutable
class ReceiptStep {
  const ReceiptStep({
    required this.kind,
    required this.label,
    this.detail,
  });

  final ReceiptStepKind kind;
  final String label;
  final String? detail;
}

/// The Evidence Receipt as a sequence, not a summary.
///
/// `DESIGN_SYSTEM.md` asks for a receipt timeline, and the distinction
/// matters more here than it looks: a summary shows what the learner
/// concluded, while a timeline shows *how they got there*. This product
/// scores process, so the receipt has to render process.
///
/// It also makes an honest record possible — the order shows whether a
/// conclusion came before or after the evidence that supports it.
class ReceiptTimeline extends StatelessWidget {
  const ReceiptTimeline({super.key, required this.steps});

  final List<ReceiptStep> steps;

  (Color, IconData) _style(ReceiptStepKind kind, EvidenceGymTokens t) =>
      switch (kind) {
        ReceiptStepKind.predicted => (t.unknown, Icons.bolt_outlined),
        ReceiptStepKind.checked => (t.evidencePrimary, Icons.search),
        ReceiptStepKind.asked => (t.action, Icons.chat_bubble_outline),
        ReceiptStepKind.concluded => (t.evidenceSecondary, Icons.balance),
        ReceiptStepKind.decided => (t.focus, Icons.ios_share_outlined),
      };

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The rail: a marker per step, joined by a line that
                // stops at the last one rather than trailing into space.
                SizedBox(
                  width: 34,
                  child: Column(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Motion.of(
                          context,
                          Motion.enter + Motion.stagger * i,
                        ),
                        curve: Motion.curveEmphasis,
                        builder: (context, t, child) =>
                            Transform.scale(scale: 0.6 + 0.4 * t, child: child),
                        child: Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: tokens.surfaceRaised,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _style(steps[i].kind, tokens).$1,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _style(steps[i].kind, tokens).$2,
                            size: 15,
                            color: _style(steps[i].kind, tokens).$1,
                          ),
                        ),
                      ),
                      if (i != steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: EdgeInsets.symmetric(vertical: tokens.space(0.5)),
                            color: tokens.textMuted.withValues(alpha: 0.3),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: tokens.space(1.5)),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: tokens.space(2)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].label,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (steps[i].detail != null)
                          Text(steps[i].detail!,
                              style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A published mission changed after this receipt was issued.
///
/// `ADR-005` makes published content immutable and requires a correction
/// to create a new version while preserving history. This is how that
/// reaches the learner: their record stands, and they are told the
/// ground under it moved. It never silently rewrites what they saw.
class CorrectionBanner extends StatelessWidget {
  const CorrectionBanner({
    super.key,
    required this.title,
    required this.body,
    this.onViewChange,
    this.viewChangeLabel,
  });

  final String title;
  final String body;
  final VoidCallback? onViewChange;
  final String? viewChangeLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(tokens.space(2)),
        decoration: BoxDecoration(
          color: tokens.misleading.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(tokens.space(2)),
          border: Border.all(color: tokens.misleading.withValues(alpha: 0.55)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_edu_outlined, color: tokens.misleading, size: 20),
                SizedBox(width: tokens.space(1)),
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
              ],
            ),
            SizedBox(height: tokens.space(1)),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
            if (onViewChange != null && viewChangeLabel != null) ...[
              SizedBox(height: tokens.space(1)),
              OutlinedButton(
                onPressed: onViewChange,
                child: Text(viewChangeLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
