import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../data/api_client.dart';
import '../../data/mission_repository.dart';
import '../../data/models.dart';
import '../../l10n/axis_localization.dart';
import '../../l10n/strings.dart';
import '../common/failure_view.dart';
import '../receipt/receipt_screen.dart';
import '../report/report_dialog.dart';

enum _Step { prediction, investigating, conclusion, receipt }

/// The whole mission: predict → investigate → conclude on three axes →
/// receipt. One screen with four steps, because the underlying Attempt is
/// one continuous object (`GAME_AND_LEARNING_DESIGN.md`), and the
/// conclusion is a single transaction server-side (ADR-008).
///
/// On a laptop the mission stays pinned on the left while the working
/// step scrolls on the right, so evidence and claim are visible together.
/// On a phone it is one column, in the same order.
class MissionScreen extends StatefulWidget {
  const MissionScreen({super.key, required this.repository, required this.missionId});

  final MissionRepository repository;
  final String missionId;

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  late Future<Mission> _bootstrapFuture;

  _Step _step = _Step.prediction;
  String? _busyMessage;
  String? _error;

  String? _reaction;
  int _preConfidence = 50;

  final Map<String, EvidenceResult> _collected = {};
  Hint? _hint;

  AxisOption? _authenticity;
  int _authenticityConfidence = 70;
  AxisOption? _claim;
  int _claimConfidence = 70;
  AxisOption? _context;
  int _contextConfidence = 70;
  int _postConfidence = 50;
  String? _shareDecision;

  Attempt? _attempt;
  Mission? _mission;
  String? _receiptId;
  int _xpAwarded = 0;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();
  }

  Future<Mission> _bootstrap() async {
    final mission = await widget.repository.getMission(widget.missionId);
    final attempt = await widget.repository.startAttempt(mission.id, mission.version);
    _mission = mission;
    _attempt = attempt;
    return mission;
  }

  Future<void> _run(Future<void> Function() action, String busyMessage) async {
    setState(() {
      _busyMessage = busyMessage;
      _error = null;
    });
    try {
      await action();
    } on EvidenceGymApiException catch (e) {
      if (mounted) setState(() => _error = e.problem.detail ?? e.problem.title);
    } finally {
      if (mounted) setState(() => _busyMessage = null);
    }
  }

  Future<void> _submitPrediction() async {
    final attempt = _attempt;
    if (_reaction == null || attempt == null) return;
    await _run(() async {
      final updated = await widget.repository.submitPrediction(
        attempt.id,
        PredictionInput(
          reaction: _reaction!,
          confidence: _preConfidence,
          version: attempt.version,
        ),
      );
      _attempt = updated;
      if (!mounted) return;
      setState(() => _step = _Step.investigating);
      // After setState, not before: _announceStep reads _step, so
      // announcing first names the stage being left.
      _announceStep(Strings.of(context));
    }, Strings.of(context).busyPrediction);
  }

  Future<void> _useEvidenceAction(EvidenceActionSpec action) async {
    final attempt = _attempt;
    final mission = _mission;
    if (attempt == null || mission == null) return;
    await _run(() async {
      final result = await widget.repository.useEvidenceAction(
        attempt.id,
        mission.id,
        action.id,
        attempt.version,
      );
      // Adopt the version the server reports. Without this the
      // conclusion would send the version last seen at prediction time,
      // which every evidence action has since moved past — a guaranteed
      // 409 with no way back (ADR-009).
      _attempt = Attempt(
        id: attempt.id,
        missionId: attempt.missionId,
        missionVersion: attempt.missionVersion,
        state: 'investigating',
        version: result.attemptVersion,
      );
      if (mounted) setState(() => _collected[action.id] = result);
    }, Strings.of(context).busyEvidence(action.label));
  }

  Future<void> _askCoach() async {
    final attempt = _attempt;
    final mission = _mission;
    if (attempt == null || mission == null) return;
    await _run(() async {
      final hint = await widget.repository.requestHint(attempt.id, mission.id);
      if (mounted) setState(() => _hint = hint);
    }, Strings.of(context).askCoach);
  }

  /// Mirrors the server-pinned mission policy: a conclusion needs the
  /// mission's minimum evidence actions, unless this mission version is
  /// deliberately testing whether the learner concludes without
  /// investigating (ADR-008).
  bool get _canConclude =>
      (_mission?.testsCriticalIgnoring ?? false) ||
      _collected.length >= (_mission?.minimumCompletionEvidence ?? 1);

  Future<void> _submitConclusion() async {
    final attempt = _attempt;
    if (attempt == null ||
        _authenticity == null ||
        _claim == null ||
        _context == null ||
        _shareDecision == null) {
      return;
    }
    await _run(() async {
      final result = await widget.repository.submitConclusion(
        attempt.id,
        ConclusionInput(
          authenticity:
              AxisAssessment(label: _authenticity!.code, confidence: _authenticityConfidence),
          claimVeracity: AxisAssessment(label: _claim!.code, confidence: _claimConfidence),
          contextIntegrity:
              AxisAssessment(label: _context!.code, confidence: _contextConfidence),
          postConfidence: _postConfidence,
          shareDecision: _shareDecision!,
          version: attempt.version,
        ),
      );
      _receiptId = result.receiptId;
      _xpAwarded = result.xpAwarded;
      if (!mounted) return;
      setState(() => _step = _Step.receipt);
      // After setState, not before: _announceStep reads _step, so
      // announcing first names the stage being left.
      _announceStep(Strings.of(context));
    }, Strings.of(context).busyConclusion);
  }

  void _openReport() {
    showReportDialog(
      context: context,
      missionId: widget.missionId,
      isDemo: widget.repository.isDemo,
      onSubmit: (reason, detail) => widget.repository.reportContent(
        missionId: widget.missionId,
        reason: reason,
        detail: detail,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;
    final wide = formFactorOf(context).isWide;

    return Scaffold(
      appBar: AppBar(
        // The tapped node lands as a small badge beside the title, so
        // the circle travels here rather than the screen appearing from
        // nowhere. It must not go in `leading` — that slot holds the
        // back button, and taking it over strands the learner.
        title: Row(
          children: [
            Hero(
              tag: 'mission-${widget.missionId}',
              createRectTween: (begin, end) =>
                  MaterialRectCenterArcTween(begin: begin, end: end),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: tokens.action,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.explore_outlined, size: 16, color: tokens.onAction),
              ),
            ),
            SizedBox(width: tokens.space(1)),
            Expanded(
              child: Text(
                _mission?.title ?? s.appName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openReport,
            icon: const Icon(Icons.flag_outlined),
            tooltip: s.reportTitle,
          ),
        ],
      ),
      body: FutureBuilder<Mission>(
        future: _bootstrapFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: Semantics(label: s.loading, child: const CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return FailureView(
              error: snapshot.error,
              onRetry: () => setState(() => _bootstrapFuture = _bootstrap()),
              isDemo: widget.repository.isDemo,
            );
          }

          final mission = snapshot.data!;
          final brief = _MissionBrief(mission: mission);
          final steps = _buildStep(mission, s);

          return LivingBackground(
            variant: GroundVariant.grid,
            child: SafeArea(
            child: Column(
              children: [
                if (_error != null) _ErrorBanner(message: _error!),
                if (_busyMessage != null) _BusyBanner(message: _busyMessage!),
                Expanded(
                  child: wide
                      // Two panes on laptop/tablet: the claim stays put
                      // while the working step scrolls beside it.
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.all(tokens.space(3)),
                                child: brief,
                              ),
                            ),
                            const VerticalDivider(width: 1),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.all(tokens.space(3)),
                                child: steps,
                              ),
                            ),
                          ],
                        )
                      : ReadableWidth(
                          child: Padding(
                            padding: EdgeInsets.all(tokens.space(2)),
                            child: steps,
                          ),
                        ),
                ),
              ],
            ),
          ),
          );
        },
      ),
    );
  }

  /// Names the stage the learner has just arrived at.
  ///
  /// The stages swap in place, so there is no route change for assistive
  /// technology to notice and nothing moves focus. Without this a screen
  /// reader user submits a prediction and hears silence, then finds
  /// themselves somewhere unexplained.
  void _announceStep(Strings s) {
    final name = switch (_step) {
      _Step.prediction => s.stepPrediction,
      _Step.investigating => s.stepInvestigating,
      _Step.conclusion => s.stepConclusion,
      _Step.receipt => s.stepReceipt,
    };
    SemanticsService.sendAnnouncement(
      View.of(context),
      s.stepArrived(name),
      Directionality.of(context),
    );
  }

  Widget _buildStep(Mission mission, Strings s) {
    final wide = formFactorOf(context).isWide;
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.standard),
      switchInCurve: Motion.curveStandard,
      switchOutCurve: Motion.curveExit,
      // The step leaving slides left, the one arriving comes from the
      // right — the same forward-travel language as the page
      // transition, so moving through a mission feels continuous.
      transitionBuilder: (child, animation) {
        final entering = child.key == ValueKey(_step.name);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(entering ? 0.06 : -0.06, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: switch (_step) {
        _Step.prediction => _PredictionStep(
            key: const ValueKey('prediction'),
            mission: mission,
            showBrief: !wide,
            reaction: _reaction,
            confidence: _preConfidence,
            onReaction: (r) => setState(() => _reaction = r),
            onConfidence: (c) => setState(() => _preConfidence = c),
            onSubmit: _reaction == null ? null : _submitPrediction,
          ),
        _Step.investigating => _InvestigatingStep(
            key: const ValueKey('investigating'),
            mission: mission,
            collected: _collected,
            onAction: _useEvidenceAction,
            hint: _hint,
            onAskCoach: _askCoach,
            canConclude: _canConclude,
            onConclude: () {
              setState(() => _step = _Step.conclusion);
              _announceStep(s);
            },
          ),
        _Step.conclusion => _ConclusionStep(
            key: const ValueKey('conclusion'),
            authenticity: _authenticity,
            onAuthenticity: (o) => setState(() => _authenticity = o),
            authenticityConfidence: _authenticityConfidence,
            onAuthenticityConfidence: (c) => setState(() => _authenticityConfidence = c),
            claim: _claim,
            onClaim: (o) => setState(() => _claim = o),
            claimConfidence: _claimConfidence,
            onClaimConfidence: (c) => setState(() => _claimConfidence = c),
            contextIntegrity: _context,
            onContextIntegrity: (o) => setState(() => _context = o),
            contextConfidence: _contextConfidence,
            onContextConfidence: (c) => setState(() => _contextConfidence = c),
            postConfidence: _postConfidence,
            onPostConfidence: (c) => setState(() => _postConfidence = c),
            shareDecision: _shareDecision,
            onShareDecision: (v) => setState(() => _shareDecision = v),
            canSubmit: _authenticity != null &&
                _claim != null &&
                _context != null &&
                _shareDecision != null,
            onSubmit: _submitConclusion,
          ),
        _Step.receipt => _ReceiptStep(
            key: const ValueKey('receipt'),
            receiptId: _receiptId ?? '',
            xpAwarded: _xpAwarded,
            onOpenReceipt: _receiptId == null
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReceiptScreen(
                          repository: widget.repository,
                          receiptId: _receiptId!,
                        ),
                      ),
                    ),
            onDone: () => Navigator.of(context).pop(),
          ),
      },
    );
  }
}

// ---------------------------------------------------------------- pieces

/// Localizes the band and spoken percentage once, so every confidence
/// question in the flow phrases itself the same way.
class _Confidence extends StatelessWidget {
  const _Confidence({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return ConfidenceSlider(
      label: label,
      value: value,
      onChanged: onChanged,
      bandLabel: s.confidenceBand(value),
      describeValue: (v) => '${s.percentSpoken(v)}, ${s.confidenceBand(v)}',
    );
  }
}

class _MissionBrief extends StatelessWidget {
  const _MissionBrief({required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The media is described in text as well as shown: alt text is the
        // primary content here, not a fallback.
        Semantics(
          image: true,
          label: mission.media.altText,
          child: ExcludeSemantics(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 160),
              padding: EdgeInsets.all(tokens.space(2)),
              decoration: BoxDecoration(
                color: tokens.surfaceRaised,
                borderRadius: BorderRadius.circular(tokens.space(2)),
                border: Border.all(color: tokens.textMuted.withValues(alpha: 0.2)),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    switch (mission.media.type) {
                      'video' => Icons.videocam_outlined,
                      'audio' => Icons.graphic_eq,
                      'text' => Icons.article_outlined,
                      _ => Icons.image_outlined,
                    },
                    color: tokens.textMuted,
                  ),
                  SizedBox(height: tokens.space(1)),
                  Text(mission.media.altText, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: tokens.space(2)),
        Text(mission.claim, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    // liveRegion, like the busy banner beside it. Without it a failed
    // evidence check announced nothing at all — the button simply went
    // quiet and a screen-reader user had no idea why.
    return Semantics(
      liveRegion: true,
      child: Container(
      width: double.infinity,
      margin: EdgeInsets.all(tokens.space(1)),
      padding: EdgeInsets.all(tokens.space(1.5)),
      decoration: BoxDecoration(
        color: tokens.misleading.withValues(alpha: 0.08),
        border: Border.all(color: tokens.misleading),
        borderRadius: BorderRadius.circular(tokens.space(1)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: tokens.misleading),
          SizedBox(width: tokens.space(1)),
          Expanded(child: Text(message)),
        ],
      ),
      ),
    );
  }
}

class _BusyBanner extends StatelessWidget {
  const _BusyBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.space(2), vertical: tokens.space(1)),
        child: Row(
          children: [
            const Lupa(mood: LupaMood.thinking, size: 40, respondToTap: false),
            SizedBox(width: tokens.space(1)),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _PredictionStep extends StatelessWidget {
  const _PredictionStep({
    super.key,
    required this.mission,
    required this.showBrief,
    required this.reaction,
    required this.confidence,
    required this.onReaction,
    required this.onConfidence,
    required this.onSubmit,
  });

  final Mission mission;
  final bool showBrief;
  final String? reaction;
  final int confidence;
  final ValueChanged<String> onReaction;
  final ValueChanged<int> onConfidence;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    String label(String code) => switch (code) {
          'trust' => s.reactionTrust,
          'suspicious' => s.reactionSuspicious,
          _ => s.reactionInvestigate,
        };

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showBrief) ...[
            _MissionBrief(mission: mission),
            SizedBox(height: tokens.space(2)),
          ],
          Text(s.firstInstinct, style: Theme.of(context).textTheme.titleLarge),
          const SectionRule(),
          Wrap(
            spacing: tokens.space(1),
            runSpacing: tokens.space(1),
            children: [
              for (final r in mission.reactions)
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: ChoiceChip(
                    label: Text(label(r)),
                    selected: reaction == r,
                    onSelected: (_) => onReaction(r),
                  ),
                ),
            ],
          ),
          SizedBox(height: tokens.space(2)),
          _Confidence(
            label: s.howConfident,
            value: confidence,
            onChanged: onConfidence,
          ),
          SizedBox(height: tokens.space(3)),
          if (onSubmit == null)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.space(1)),
              child: Text(s.needReaction,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ElevatedButton(onPressed: onSubmit, child: Text(s.startInvestigating)),
          SizedBox(height: tokens.space(2)),
        ],
      ),
    );
  }
}

class _InvestigatingStep extends StatelessWidget {
  const _InvestigatingStep({
    super.key,
    required this.mission,
    required this.collected,
    required this.onAction,
    required this.hint,
    required this.onAskCoach,
    required this.canConclude,
    required this.onConclude,
  });

  final Mission mission;
  final Map<String, EvidenceResult> collected;
  final ValueChanged<EvidenceActionSpec> onAction;
  final Hint? hint;
  final VoidCallback onAskCoach;
  final bool canConclude;
  final VoidCallback onConclude;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.investigateTitle, style: Theme.of(context).textTheme.titleLarge),
          const SectionRule(),
          // The checks are objects the learner picks up, not a toolbar.
          Wrap(
            spacing: tokens.space(1.5),
            runSpacing: tokens.space(1.5),
            children: [
              for (final (index, action) in mission.evidenceActions.indexed)
                PropTile(
                  prop: propForActionType(action.type),
                  label: action.label,
                  semanticLabel: collected.containsKey(action.id)
                      ? s.propUsed(action.label)
                      : action.label,
                  used: collected.containsKey(action.id),
                  delayIndex: index,
                  onTap: () => onAction(action),
                ),
            ],
          ),
          SizedBox(height: tokens.space(2)),
          if (collected.isNotEmpty) ...[
            Row(
              children: [
                Text(s.whatYouFound, style: Theme.of(context).textTheme.titleLarge),
                SizedBox(width: tokens.space(1)),
                Expanded(child: Slid(height: 24, steps: mission.evidenceActions.length, reached: collected.length)),
              ],
            ),
            SizedBox(height: tokens.space(1)),
            // The findings are the whole payoff of tapping a check, and
            // they arrive in place with nothing to draw attention to
            // them. Without this the button appears to do nothing to a
            // screen-reader user, which is the same as it not working.
            Semantics(
              liveRegion: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (index, result) in collected.values.indexed)
                    RevealOnScroll(
                      delayIndex: index,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: tokens.space(1.5)),
                        child: _EvidenceCard(result: result),
                      ),
                    ),
                ],
              ),
            ),
            // Two or more findings can disagree, and a list hides that.
            if (collected.length > 1) ...[
              SizedBox(height: tokens.space(2)),
              Text(s.howItConnects, style: Theme.of(context).textTheme.titleLarge),
              const SectionRule(),
              EvidenceGraph(
                claimLabel: mission.claim,
                nodes: [
                  for (final result in collected.values)
                    EvidenceNode(
                      id: result.actionId,
                      label: result.items.isEmpty
                          ? s.notFoundInSources
                          : result.items.first.title,
                      // `not_found` qualifies rather than contradicts:
                      // absence of a report is not evidence against.
                      relation: switch (result.status) {
                        'ok' => EdgeRelation.supports,
                        'not_found' => EdgeRelation.qualifies,
                        _ => EdgeRelation.qualifies,
                      },
                      relationLabel: s.relation(
                        result.status == 'ok' ? 'supports' : 'qualifies',
                      ),
                    ),
                ],
              ),
            ],
          ],
          SizedBox(height: tokens.space(2)),

          // The coach is opt-in and sits below the evidence, never above
          // it: the learner should reach for their own checks first.
          if (hint != null) ...[
            // Same reason as the evidence block: the answer appears
            // below the button that asked for it, and nothing announces
            // that it arrived.
            Semantics(
              liveRegion: true,
              child: CoachBubble(
              text: s.hintText(hint!.text),
              uncertainty: hint!.uncertainty,
              aiLabel: s.aiCoachLabel,
              uncertaintyLabel: s.uncertaintySentence(hint!.uncertainty),
              isFallback: hint!.fallback,
              fallbackLabel: s.coachFallback,
              rungLabel: s.hintLevel(hint!.level),
              exhaustedLabel: s.hintExhausted,
              level: hint!.level,
              ),
            ),
            SizedBox(height: tokens.space(2)),
          ],
          OutlinedButton.icon(
            onPressed: onAskCoach,
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(s.askCoach),
          ),
          SizedBox(height: tokens.space(2)),

          if (!canConclude)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.space(1)),
              child: Text(s.needOneEvidence, style: Theme.of(context).textTheme.bodySmall),
            ),
          ElevatedButton(
            onPressed: canConclude ? onConclude : null,
            child: Text(s.conclude),
          ),
          SizedBox(height: tokens.space(2)),
        ],
      ),
    );
  }
}

class _ConclusionStep extends StatelessWidget {
  const _ConclusionStep({
    super.key,
    required this.authenticity,
    required this.onAuthenticity,
    required this.authenticityConfidence,
    required this.onAuthenticityConfidence,
    required this.claim,
    required this.onClaim,
    required this.claimConfidence,
    required this.onClaimConfidence,
    required this.contextIntegrity,
    required this.onContextIntegrity,
    required this.contextConfidence,
    required this.onContextConfidence,
    required this.postConfidence,
    required this.onPostConfidence,
    required this.shareDecision,
    required this.onShareDecision,
    required this.canSubmit,
    required this.onSubmit,
  });

  final AxisOption? authenticity;
  final ValueChanged<AxisOption> onAuthenticity;
  final int authenticityConfidence;
  final ValueChanged<int> onAuthenticityConfidence;
  final AxisOption? claim;
  final ValueChanged<AxisOption> onClaim;
  final int claimConfidence;
  final ValueChanged<int> onClaimConfidence;
  final AxisOption? contextIntegrity;
  final ValueChanged<AxisOption> onContextIntegrity;
  final int contextConfidence;
  final ValueChanged<int> onContextConfidence;
  final int postConfidence;
  final ValueChanged<int> onPostConfidence;
  final String? shareDecision;
  final ValueChanged<String> onShareDecision;
  final bool canSubmit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    final shareOptions = <String, String>{
      'do_not_share': s.shareDoNot,
      'share_with_context': s.shareWithContext,
      'continue_investigating': s.shareKeepInvestigating,
    };

    Widget axis(
      AxisKind kind,
      AxisOption? selected,
      ValueChanged<AxisOption> onChanged,
      int confidence,
      ValueChanged<int> onConfidence,
    ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AxisPicker(
            axisName: axisNameOf(kind, s),
            helpText: axisHelpOf(kind, s),
            options: localizedAxisOptions(kind, s),
            selected: selected,
            onChanged: onChanged,
          ),
          // The confidence question only appears once there is something
          // to be confident about.
          if (selected != null)
            _Confidence(
              label: s.howConfidentInThat,
              value: confidence,
              onChanged: onConfidence,
            ),
          SizedBox(height: tokens.space(2)),
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.conclusionTitle, style: Theme.of(context).textTheme.titleLarge),
          const SectionRule(),
          axis(AxisKind.authenticity, authenticity, onAuthenticity,
              authenticityConfidence, onAuthenticityConfidence),
          axis(AxisKind.claimVeracity, claim, onClaim, claimConfidence, onClaimConfidence),
          axis(AxisKind.contextIntegrity, contextIntegrity, onContextIntegrity,
              contextConfidence, onContextConfidence),
          _Confidence(
            label: s.overallConfidence,
            value: postConfidence,
            onChanged: onPostConfidence,
          ),
          SizedBox(height: tokens.space(2)),
          // Appears the moment any axis is answered with uncertainty, and
          // sits above the share question rather than below it — naming
          // what evidence is missing is what should inform the decision
          // to share, so it has to come first.
          if ([authenticity, claim, contextIntegrity]
              .any((option) => option?.tone == AxisTone.unknown))
            UncertaintyPanel(
              title: s.uncertaintyTitle,
              body: s.uncertaintyBody,
              prompt: s.uncertaintyPrompt,
              options: s.uncertaintyOptions,
              footnote: s.uncertaintyFootnote,
            ),
          Text(s.wouldYouShare, style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: tokens.space(1)),
          Wrap(
            spacing: tokens.space(1),
            runSpacing: tokens.space(1),
            children: [
              for (final entry in shareOptions.entries)
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: shareDecision == entry.key,
                    onSelected: (_) => onShareDecision(entry.key),
                  ),
                ),
            ],
          ),
          SizedBox(height: tokens.space(3)),
          if (!canSubmit)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.space(1)),
              child: Text(s.needConclusion,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ElevatedButton(
            onPressed: canSubmit ? onSubmit : null,
            child: Text(s.submitConclusion),
          ),
          SizedBox(height: tokens.space(2)),
        ],
      ),
    );
  }
}

class _ReceiptStep extends StatelessWidget {
  const _ReceiptStep({
    super.key,
    required this.receiptId,
    required this.xpAwarded,
    required this.onOpenReceipt,
    required this.onDone,
  });

  final String receiptId;
  final int xpAwarded;
  final VoidCallback? onOpenReceipt;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: tokens.space(2)),
          const Lupa(mood: LupaMood.encouraging, size: 120),
          SizedBox(height: tokens.space(2)),
          Text(
            s.receiptTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SectionRule(),
          Text(s.receiptXp(xpAwarded), style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: tokens.space(1)),
          const Slid(),
          SizedBox(height: tokens.space(1)),
          Text(s.receiptId(receiptId), style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: tokens.space(2)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.space(2)),
            child: Text(
              s.receiptDisclaimer,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          SizedBox(height: tokens.space(3)),
          ElevatedButton(onPressed: onOpenReceipt, child: Text(s.viewReceipt)),
          SizedBox(height: tokens.space(1)),
          OutlinedButton(onPressed: onDone, child: Text(s.backToPath)),
          SizedBox(height: tokens.space(2)),
        ],
      ),
    );
  }
}


/// One evidence result, with its limitations behind a disclosure.
///
/// The limitations are always reachable and never removed — what a piece
/// of evidence *cannot* tell you is part of the evidence. They start
/// collapsed only so the finding itself is readable at a glance; the
/// control says plainly what is inside rather than a bare "more".
class _EvidenceCard extends StatefulWidget {
  const _EvidenceCard({required this.result});

  final EvidenceResult result;

  @override
  State<_EvidenceCard> createState() => _EvidenceCardState();
}

class _EvidenceCardState extends State<_EvidenceCard> {
  bool _showLimitations = false;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;
    final result = widget.result;

    if (result.items.isEmpty) {
      return SourceCard(
        title: s.notFoundInSources,
        standing: SourceStanding.unverified,
        standingLabel: s.sourceStanding('unverified'),
        // "Checked", not "retrieved": nothing was retrieved here, and a
        // card that says otherwise implies a source that does not exist.
        retrievedLabel: s.checkedOn(s.formatDate(DateTime.now())),
        limitations: result.limitations,
      );
    }

    final item = result.items.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SourceCard(
          title: item.title,
          publisher: item.sourceUrl,
          standing: switch (item.verificationStatus) {
            'verified_metadata' => SourceStanding.verified,
            'curated' => SourceStanding.curated,
            'conflicting' => SourceStanding.conflicting,
            _ => SourceStanding.unverified,
          },
          standingLabel: s.sourceStanding(item.verificationStatus),
          retrievedLabel: s.retrievedAt(s.formatDate(item.retrievedAt)),
          limitations: _showLimitations ? result.limitations : const [],
        ),
        if (result.limitations.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  setState(() => _showLimitations = !_showLimitations),
              icon: Icon(
                _showLimitations ? Icons.expand_less : Icons.info_outline,
                size: 18,
              ),
              label: Text(
                _showLimitations ? s.hideLimitations : s.showLimitations,
              ),
            ),
          ),
        // Additional findings from the same action, if any.
        for (final extra in result.items.skip(1))
          Padding(
            padding: EdgeInsets.only(top: tokens.space(0.5)),
            child: Text('• ${extra.title}',
                style: Theme.of(context).textTheme.bodyMedium),
          ),
      ],
    );
  }
}
