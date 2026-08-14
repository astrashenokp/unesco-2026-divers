import 'gameplay.dart';

// Typed mirror of contracts/openapi.yaml. Keep in lockstep with that file;
// do not hand-add fields the contract does not define (ADR-008, API_CONTRACT.md).

class LearningPathNode {
  const LearningPathNode({
    required this.missionId,
    required this.title,
    required this.state,
    this.boosterDue = false,
  });

  final String missionId;
  final String title;
  final String state; // locked | available | completed

  /// This node practises a skill that is due for review.
  ///
  /// Not read from the wire, and deliberately not added to the contract
  /// by me. `Progress.skills[].dueAt` already says *which skills* are
  /// due, but `LearningPath.nodes` carries no skill tags, so there is no
  /// way to join the two — the client would have to fetch every mission
  /// to find out which node practises a due skill.
  ///
  /// The demo repository can compute it because it holds the fixtures.
  /// Against a real server it stays false until the contract carries
  /// either `skillTags` on a path node or a `boosterDue` flag; that is a
  /// contract question, not something to paper over here.
  final bool boosterDue;

  factory LearningPathNode.fromJson(Map<String, dynamic> json) =>
      LearningPathNode(
        missionId: json['missionId'] as String,
        title: json['title'] as String,
        state: json['state'] as String,
      );
}

class LearningPath {
  const LearningPath({
    required this.version,
    required this.locale,
    required this.nodes,
  });

  final String version;
  final String locale;
  final List<LearningPathNode> nodes;

  factory LearningPath.fromJson(Map<String, dynamic> json) => LearningPath(
        version: json['version'] as String,
        locale: json['locale'] as String,
        nodes: (json['nodes'] as List)
            .map((n) => LearningPathNode.fromJson(n as Map<String, dynamic>))
            .toList(),
      );
}

class MissionMedia {
  const MissionMedia({
    required this.type,
    required this.altText,
    this.url,
    this.transcript,
  });

  final String type; // image | video | audio | text
  final String altText;
  final String? url;
  final String? transcript;

  factory MissionMedia.fromJson(Map<String, dynamic> json) => MissionMedia(
        type: json['type'] as String,
        altText: json['altText'] as String,
        url: json['url'] as String?,
        transcript: json['transcript'] as String?,
      );
}

class EvidenceActionSpec {
  const EvidenceActionSpec({
    required this.id,
    required this.type,
    required this.label,
  });

  final String id;
  final String type;
  final String label;

  factory EvidenceActionSpec.fromJson(Map<String, dynamic> json) =>
      EvidenceActionSpec(
        id: json['id'] as String,
        type: json['type'] as String,
        label: json['label'] as String,
      );
}

class Mission {
  const Mission({
    required this.id,
    required this.version,
    required this.title,
    required this.claim,
    required this.media,
    required this.reactions,
    required this.evidenceActions,
    required this.skillTags,
    this.testsCriticalIgnoring = false,
    this.minimumCompletionEvidence = 1,
    this.contentWarnings,
    this.rubric = const [],
  });

  final String id;
  final String version;
  final String title;
  final String claim;
  final MissionMedia media;
  final List<String> reactions; // trust | suspicious | investigate
  final List<EvidenceActionSpec> evidenceActions;
  final List<String> skillTags;
  final bool testsCriticalIgnoring; // ADR-008
  final int minimumCompletionEvidence;

  /// What this mission's case material contains, e.g. `natural-disaster`.
  ///
  /// Drives two things: whether the mission appears in the younger
  /// audience mode at all, and whether a warning is shown before the
  /// media. `content/p0-demo-pack` already carries these tags per
  /// mission and a `minimumAge` on its manifest, so the vocabulary is
  /// Role 3's and settled — but `Mission` in `contracts/openapi.yaml` is
  /// `additionalProperties: false` and has no field for them, so nothing
  /// reaches this client from a real server yet.
  ///
  /// Parsed defensively anyway, so it starts working the moment the
  /// contract carries it, with no client change.
  /// Null means the source did not say. Empty means it said "nothing".
  ///
  /// The distinction is the whole safety of the younger audience mode,
  /// and Rina caught that I had lost it: parsing a missing field as an
  /// empty list made a server that does not implement content warnings
  /// look exactly like content reviewed and certified as unremarkable,
  /// so every live mission would have passed the child filter.
  ///
  /// The contract now makes the field required precisely so that an
  /// empty array is a positive statement. Until a server sends it, this
  /// stays null and the younger mode declines to show the mission —
  /// which is the failure that costs a hidden mission rather than the
  /// one that costs a child.
  final List<String>? contentWarnings;

  /// The mission's curated process-level rubric, rungs 0 to 4.
  ///
  /// XP is read off this and never hard-coded — `packages/gameplay`
  /// makes that rule explicit, and it is why a rubric change is a
  /// content change rather than a code change. Sofia's pack already
  /// carries `rubric.processLevels`; `Mission` in the contract does not,
  /// so this is another field that reaches the client only in demo mode
  /// until the contract carries it. Parsed defensively so it starts
  /// working the moment it does.
  final List<ProcessLevel> rubric;

  factory Mission.fromJson(Map<String, dynamic> json) => Mission(
        id: json['id'] as String,
        version: json['version'] as String,
        title: json['title'] as String,
        claim: json['claim'] as String,
        media: MissionMedia.fromJson(json['media'] as Map<String, dynamic>),
        reactions: (json['reactions'] as List).cast<String>(),
        evidenceActions: (json['evidenceActions'] as List)
            .map((e) => EvidenceActionSpec.fromJson(e as Map<String, dynamic>))
            .toList(),
        skillTags: (json['skillTags'] as List).cast<String>(),
        testsCriticalIgnoring: json['testsCriticalIgnoring'] as bool? ?? false,
        minimumCompletionEvidence:
            (json['minimumCompletionEvidence'] as num?)?.toInt() ?? 1,
        contentWarnings: (json['contentWarnings'] as List?)?.cast<String>(),
        rubric: [
          for (final level in (json['rubric']
                  as Map<String, dynamic>?)?['processLevels'] as List? ??
              const [])
            ProcessLevel(
              level: (level['level'] as num).toInt(),
              xpGuidance: (level['xpGuidance'] as num).toInt(),
              criteria: level['criteria'] as String? ?? '',
              skillTags:
                  (level['skillTags'] as List?)?.cast<String>() ?? const [],
            ),
        ],
      );
}

class Attempt {
  const Attempt({
    required this.id,
    required this.missionId,
    required this.missionVersion,
    required this.state,
    required this.version,
  });

  final String id;
  final String missionId;
  final String missionVersion;
  final String state; // ready|predicted|investigating|concluded|reflected|completed
  final int version;

  factory Attempt.fromJson(Map<String, dynamic> json) => Attempt(
        id: json['id'] as String,
        missionId: json['missionId'] as String,
        missionVersion: json['missionVersion'] as String,
        state: json['state'] as String,
        version: json['version'] as int,
      );
}

class PredictionInput {
  const PredictionInput({
    required this.reaction,
    required this.confidence,
    required this.version,
  });

  final String reaction; // trust | suspicious | investigate
  final int confidence;
  final int version;

  Map<String, dynamic> toJson() => {
        'reaction': reaction,
        'confidence': confidence,
        'version': version,
      };
}

class EvidenceLicense {
  const EvidenceLicense({
    required this.identifier,
    required this.attribution,
    required this.useBasis,
  });

  final String identifier;
  final String attribution;
  final String useBasis;

  factory EvidenceLicense.fromJson(Map<String, dynamic> json) =>
      EvidenceLicense(
        identifier: json['identifier'] as String,
        attribution: json['attribution'] as String,
        useBasis: json['useBasis'] as String,
      );
}

class EvidenceSource {
  const EvidenceSource({
    required this.sourceType,
    required this.publisher,
    required this.retrievedAt,
    required this.license,
    required this.limitations,
    this.author,
    this.canonicalUrl,
    this.canonicalId,
    this.publishedAt,
    this.snapshotHash,
  });

  final String sourceType;
  final String publisher;
  final DateTime retrievedAt;
  final EvidenceLicense license;
  final List<String> limitations;
  final String? author;
  final String? canonicalUrl;
  final String? canonicalId;
  final DateTime? publishedAt;
  final String? snapshotHash;

  factory EvidenceSource.fromJson(Map<String, dynamic> json) => EvidenceSource(
        sourceType: json['sourceType'] as String,
        publisher: json['publisher'] as String,
        author: json['author'] as String?,
        canonicalUrl: json['canonicalUrl'] as String?,
        canonicalId: json['canonicalId'] as String?,
        publishedAt: json['publishedAt'] == null
            ? null
            : DateTime.parse(json['publishedAt'] as String),
        retrievedAt: DateTime.parse(json['retrievedAt'] as String),
        snapshotHash: json['snapshotHash'] as String?,
        license:
            EvidenceLicense.fromJson(json['license'] as Map<String, dynamic>),
        limitations: (json['limitations'] as List).cast<String>(),
      );
}

class EvidenceItem {
  const EvidenceItem({
    required this.evidenceId,
    required this.type,
    required this.title,
    required this.source,
    required this.retrievedAt,
    required this.verificationStatus,
    this.sourceUrl,
  });

  final String evidenceId;
  final String type;
  final String title;
  final EvidenceSource source;
  final String? sourceUrl;
  final DateTime retrievedAt;
  final String verificationStatus; // verified_metadata|curated|unverified|conflicting

  factory EvidenceItem.fromJson(Map<String, dynamic> json) => EvidenceItem(
        evidenceId: json['evidenceId'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        source: EvidenceSource.fromJson(json['source'] as Map<String, dynamic>),
        sourceUrl: json['sourceUrl'] as String?,
        retrievedAt: DateTime.parse(json['retrievedAt'] as String),
        verificationStatus: json['verificationStatus'] as String,
      );
}

class EvidenceResult {
  const EvidenceResult({
    required this.actionId,
    required this.status,
    required this.items,
    required this.limitations,
    required this.attemptVersion,
  });

  final String actionId;
  final String status; // ok|not_found|unavailable|blocked
  final List<EvidenceItem> items;
  final List<String> limitations;

  /// The attempt's version after this action (ADR-009).
  ///
  /// There is no `GET /attempts/{id}`, so this is the only way the client
  /// learns the current version between a prediction and a conclusion.
  /// Without it, sending `version` at conclusion would be a guess.
  final int attemptVersion;

  factory EvidenceResult.fromJson(Map<String, dynamic> json) => EvidenceResult(
        actionId: json['actionId'] as String,
        status: json['status'] as String,
        items: (json['items'] as List)
            .map((e) => EvidenceItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        limitations: (json['limitations'] as List).cast<String>(),
        attemptVersion: (json['attemptVersion'] as num).toInt(),
      );
}

/// A bounded Socratic hint. Never a verdict: [uncertainty] and [fallback]
/// are required by the contract precisely so the client cannot present a
/// hint as an authoritative answer.
class Hint {
  const Hint({
    required this.text,
    required this.level,
    required this.evidenceRefs,
    required this.uncertainty,
    required this.safetyFlags,
    required this.fallback,
    this.suggestedActionId,
  });

  final String text;
  final int level; // 1..4 before completion; never the gold conclusion
  final String? suggestedActionId;
  final List<String> evidenceRefs;
  final String uncertainty; // low | medium | high
  final List<String> safetyFlags;

  /// True when the deterministic fallback answered instead of the model.
  final bool fallback;

  factory Hint.fromJson(Map<String, dynamic> json) => Hint(
        text: json['text'] as String,
        level: json['level'] as int,
        suggestedActionId: json['suggestedActionId'] as String?,
        evidenceRefs: (json['evidenceRefs'] as List).cast<String>(),
        uncertainty: json['uncertainty'] as String,
        safetyFlags: (json['safetyFlags'] as List).cast<String>(),
        fallback: json['fallback'] as bool,
      );
}

class AxisAssessment {
  const AxisAssessment({required this.label, required this.confidence});

  final String label;
  final int confidence;

  Map<String, dynamic> toJson() => {'label': label, 'confidence': confidence};

  factory AxisAssessment.fromJson(Map<String, dynamic> json) => AxisAssessment(
        label: json['label'] as String,
        confidence: json['confidence'] as int,
      );
}

class ConclusionInput {
  const ConclusionInput({
    required this.authenticity,
    required this.claimVeracity,
    required this.contextIntegrity,
    required this.postConfidence,
    required this.shareDecision,
    required this.version,
  });

  final AxisAssessment authenticity;
  final AxisAssessment claimVeracity;
  final AxisAssessment contextIntegrity;
  final int postConfidence;
  final String shareDecision; // do_not_share|share_with_context|continue_investigating
  final int version;

  Map<String, dynamic> toJson() => {
        'authenticity': authenticity.toJson(),
        'claimVeracity': claimVeracity.toJson(),
        'contextIntegrity': contextIntegrity.toJson(),
        'postConfidence': postConfidence,
        'shareDecision': shareDecision,
        'version': version,
      };
}

class SkillProgress {
  const SkillProgress({required this.skill, required this.mastery, this.dueAt});

  final String skill;
  final double mastery;
  final DateTime? dueAt;

  factory SkillProgress.fromJson(Map<String, dynamic> json) => SkillProgress(
        skill: json['skill'] as String,
        mastery: (json['mastery'] as num).toDouble(),
        dueAt: json['dueAt'] == null ? null : DateTime.parse(json['dueAt'] as String),
      );
}

class Progress {
  const Progress({required this.totalXp, required this.skills});

  final int totalXp;
  final List<SkillProgress> skills;

  factory Progress.fromJson(Map<String, dynamic> json) => Progress(
        totalXp: json['totalXp'] as int,
        skills: (json['skills'] as List)
            .map((s) => SkillProgress.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

class Receipt {
  const Receipt({
    required this.id,
    required this.attemptId,
    required this.missionVersion,
    this.missionId,
    required this.assessments,
    required this.evidenceRefs,
    required this.createdAt,
    required this.hash,
    required this.disclaimer,
  });

  final String id;
  final String attemptId;
  final String missionVersion;

  /// Which mission this receipt is about.
  ///
  /// Not on the wire. `Receipt` in the contract carries `missionVersion`
  /// but no `missionId`, and there is no `GET /attempts/{id}` to resolve
  /// one from `attemptId` — so a receipt cannot be traced back to what
  /// it is about. That blocks two things: naming the mission in the
  /// learner's own history, and the ADR-005 correction flow, which has
  /// to compare this receipt's version against the mission's current
  /// one.
  ///
  /// The demo repository can fill it because it holds the attempt state.
  /// Against a real server it stays null and the correction banner
  /// simply never appears, which is the honest failure: no claim is made
  /// either way about whether the mission changed.
  final String? missionId;
  final List<AxisAssessment> assessments;
  final List<String> evidenceRefs;
  final DateTime createdAt;
  final String hash;
  final String disclaimer;

  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
        id: json['id'] as String,
        attemptId: json['attemptId'] as String,
        missionVersion: json['missionVersion'] as String,
        assessments: (json['assessments'] as List)
            .map((a) => AxisAssessment.fromJson(a as Map<String, dynamic>))
            .toList(),
        evidenceRefs: (json['evidenceRefs'] as List).cast<String>(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        hash: json['hash'] as String,
        disclaimer: json['disclaimer'] as String,
      );
}

/// RFC 9457 Problem Details. Thrown as [EvidenceGymApiException].
class Problem {
  const Problem({
    required this.type,
    required this.title,
    required this.status,
    required this.code,
    required this.traceId,
    this.detail,
  });

  final String type;
  final String title;
  final int status;
  final String code;
  final String? detail;
  final String traceId;

  factory Problem.fromJson(Map<String, dynamic> json) => Problem(
        type: json['type'] as String? ?? 'about:blank',
        title: json['title'] as String? ?? 'Unknown error',
        status: json['status'] as int? ?? 0,
        code: json['code'] as String? ?? 'unknown',
        detail: json['detail'] as String?,
        traceId: json['traceId'] as String? ?? 'unknown',
      );
}
