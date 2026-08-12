import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../data/mission_repository.dart';
import '../../data/models.dart';
import '../../l10n/axis_localization.dart';
import '../../l10n/strings.dart';
import '../common/failure_view.dart';

/// The Evidence Receipt: a reproducible record of how one attempt was
/// investigated, pinned to the exact mission version.
///
/// It is deliberately styled as a document rather than a scoreboard, and
/// it states outright that it is not a certificate that anything is true
/// or false (`DOMAIN_MODEL.md`: "a receipt is a learning record, not a
/// legal certificate of truth").
class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({
    super.key,
    required this.repository,
    required this.receiptId,
  });

  final MissionRepository repository;
  final String receiptId;

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  late Future<Receipt> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.getReceipt(widget.receiptId);
  }

  void _retry() =>
      setState(() => _future = widget.repository.getReceipt(widget.receiptId));

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(title: Text(s.receiptScreenTitle)),
      body: LivingBackground(
        variant: GroundVariant.grid,
        child: FutureBuilder<Receipt>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: Semantics(label: s.loading, child: const CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return FailureView(
              error: snapshot.error,
              onRetry: _retry,
              isDemo: widget.repository.isDemo,
            );
          }

          final receipt = snapshot.data!;
          // The contract guarantees exactly three assessments, in axis
          // order. Read defensively anyway: a malformed receipt should
          // render what it has rather than crash the screen.
          final axes = [
            AxisKind.authenticity,
            AxisKind.claimVeracity,
            AxisKind.contextIntegrity,
          ];

          return ReadableWidth(
            child: ListView(
              padding: EdgeInsets.all(tokens.space(2)),
              children: [
                Text(s.receiptConclusions, style: Theme.of(context).textTheme.titleLarge),
                const SectionRule(),
                for (var i = 0; i < receipt.assessments.length && i < axes.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: tokens.space(1)),
                    child: ThreeAxisChip(
                      axisName: axisNameOf(axes[i], s),
                      option: axisOptionFromCode(axes[i], receipt.assessments[i].label, s),
                      confidence: receipt.assessments[i].confidence,
                      confidenceSemantics: s.percentSpoken(receipt.assessments[i].confidence),
                    ),
                  ),
                SizedBox(height: tokens.space(3)),

                Row(
                  children: [
                    Text(s.receiptEvidence, style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(width: tokens.space(1)),
                    const Expanded(child: Slid(height: 24)),
                  ],
                ),
                SizedBox(height: tokens.space(1)),
                if (receipt.evidenceRefs.isEmpty)
                  Text(s.receiptNoEvidence, style: Theme.of(context).textTheme.bodyMedium)
                else
                  for (final ref in receipt.evidenceRefs)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: tokens.space(0.5)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 18, color: tokens.evidencePrimary),
                          SizedBox(width: tokens.space(1)),
                          Expanded(child: Text(ref)),
                        ],
                      ),
                    ),
                SizedBox(height: tokens.space(3)),

                // Provenance of the receipt itself.
                Container(
                  padding: EdgeInsets.all(tokens.space(2)),
                  decoration: BoxDecoration(
                    color: tokens.surfaceRaised,
                    borderRadius: BorderRadius.circular(tokens.space(2)),
                    border: Border.all(color: tokens.textMuted.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.receiptMissionVersion(receipt.missionVersion),
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(s.receiptCreated(receipt.createdAt.toLocal().toString()),
                          style: Theme.of(context).textTheme.bodySmall),
                      Text(
                        receipt.hash == 'demo-unsigned'
                            ? s.receiptUnsigned
                            : s.receiptHash(receipt.hash),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: tokens.space(2)),

                Text(
                  s.receiptDisclaimerText(receipt.disclaimer),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: tokens.space(3)),
              ],
            ),
          );
        },
        ),
      ),
    );
  }
}
