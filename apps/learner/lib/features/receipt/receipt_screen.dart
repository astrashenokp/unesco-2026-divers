import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../data/mission_repository.dart';
import '../../data/gameplay.dart';
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
  late Future<
      ({
        Receipt receipt,
        String? currentVersion,
        List<ProcessLevel> rubric,
      })> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// Fetches the receipt, and the mission's *current* version alongside
  /// it when that is knowable.
  ///
  /// ADR-005 makes published content immutable: a correction creates a
  /// new version rather than editing the old one. So a receipt issued
  /// against version 1.0.0 of a mission that is now at 1.1.0 describes
  /// work done on material that has since been corrected, and the
  /// learner is entitled to know that — their record stands, and the
  /// ground under it moved.
  ///
  /// The version lookup is allowed to fail quietly. A correction notice
  /// is worth showing when we are sure; the absence of one must never be
  /// mistaken for a promise that nothing changed, and blocking the whole
  /// receipt because a second request failed would trade something the
  /// learner asked for against something extra.
  Future<
      ({
        Receipt receipt,
        String? currentVersion,
        List<ProcessLevel> rubric,
      })> _load() async {
    final receipt = await widget.repository.getReceipt(widget.receiptId);
    final missionId = receipt.missionId;
    if (missionId == null) {
      return (receipt: receipt, currentVersion: null, rubric: const <ProcessLevel>[]);
    }
    try {
      final mission = await widget.repository.getMission(missionId);
      return (
        receipt: receipt,
        currentVersion: mission.version,
        rubric: mission.rubric,
      );
    } catch (_) {
      return (receipt: receipt, currentVersion: null, rubric: const <ProcessLevel>[]);
    }
  }

  void _retry() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(title: Text(s.receiptScreenTitle)),
      body: LivingBackground(
        variant: GroundVariant.grid,
        child: FutureBuilder<
            ({
              Receipt receipt,
              String? currentVersion,
              List<ProcessLevel> rubric,
            })>(
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

          final receipt = snapshot.data!.receipt;
          final currentVersion = snapshot.data!.currentVersion;
          final rubric = snapshot.data!.rubric;
          final corrected = currentVersion != null &&
              currentVersion != receipt.missionVersion;
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
                // First on the page when it applies. A learner who reads
                // their whole conclusion before being told the material
                // changed has read it under a false impression.
                if (corrected) ...[
                  CorrectionBanner(
                    title: s.correctionTitle,
                    body: s.correctionBody(
                        receipt.missionVersion, currentVersion),
                  ),
                  SizedBox(height: tokens.space(2)),
                ],
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

                // The sequence, not just the summary: this product scores
                // process, so the receipt has to render process. The order
                // also shows whether a conclusion came before or after the
                // evidence meant to support it.
                Text(s.receiptHowYouGotThere,
                    style: Theme.of(context).textTheme.titleLarge),
                const SectionRule(),
                ReceiptTimeline(
                  steps: [
                    ReceiptStep(
                      kind: ReceiptStepKind.checked,
                      label: s.stepChecked(receipt.evidenceRefs.length),
                    ),
                    ReceiptStep(
                      kind: ReceiptStepKind.concluded,
                      label: s.stepConcluded,
                      detail: receipt.assessments
                          .map((a) => s.axisOptionLabel(a.label))
                          .join(' · '),
                    ),
                  ],
                ),
                SizedBox(height: tokens.space(2)),

                // The scoring ladder was on the completion step and
                // missing here — so a learner who reopened their own
                // receipt from history saw the conclusions and none of
                // the scale they were judged against.
                //
                // No rung is marked. `Receipt` in the contract records
                // the assessments but not the process level reached, so
                // marking one would mean inferring it from the evidence
                // reference count, which is not the same number. Shown
                // as the reference it can honestly be.
                if (rubric.isNotEmpty) ...[
                  Text(s.ladderTitle,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SectionRule(),
                  Text(s.ladderIntro,
                      style: Theme.of(context).textTheme.bodySmall),
                  SizedBox(height: tokens.space(1.5)),
                  LevelLadder(
                    rungs: [
                      for (final rung in rubric)
                        LadderRung(
                          level: rung.level,
                          criteria: rung.criteria,
                          xp: rung.xpGuidance,
                        ),
                    ],
                    reached: null,
                    levelLabel: s.ladderLevel,
                    xpLabel: s.ladderXp,
                  ),
                  SizedBox(height: tokens.space(3)),
                ],

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
                else ...[
                  Text(
                    s.receiptEvidenceCount(receipt.evidenceRefs.length),
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: tokens.space(0.5)),
                  Text(s.receiptEvidenceExplain,
                      style: Theme.of(context).textTheme.bodySmall),
                  SizedBox(height: tokens.space(1)),
                  for (final ref in receipt.evidenceRefs)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: tokens.space(0.5)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.tag, size: 16, color: tokens.textMuted),
                          SizedBox(width: tokens.space(1)),
                          Expanded(
                            child: Text(
                              ref,
                              // Monospace so it reads as a reference to
                              // look up rather than as something written
                              // for the learner to understand.
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
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
                      Text(s.receiptCreated(s.formatDateTime(receipt.createdAt)),
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
