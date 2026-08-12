/// What kind of disinformation a learner chooses to work on.
///
/// A second axis, crossing the chapters rather than replacing them.
/// Chapters are the *skill* — who said it, when and where, how it is
/// framed — and those are the same everywhere. An arena is the *subject*
/// the skill is practised on.
///
/// The distinction matters because the skills genuinely do transfer and
/// the product should not imply otherwise: checking who is behind a
/// health claim is the same move as checking who is behind a war photo.
/// What differs is what the learner already believes, how much it costs
/// to be wrong, and how much it stings to look. Letting someone pick the
/// ground is what makes them willing to start.
library;

/// The subjects the demo pack covers.
///
/// Kept few and wide on purpose. Ten thin categories would be a menu of
/// empty rooms; four with real missions in them is a choice worth
/// making. The real taxonomy belongs to Role 3 along with the content —
/// this is the client's working set, matched to the missions that exist.
enum DisinfoArena {
  /// Floods, fires, attacks, unrest — anything urgent, where the pull to
  /// share first and check later is strongest.
  crisis,

  /// Studies, statistics, treatments, "researchers say".
  healthAndScience,

  /// Officials, rules, money, who benefits.
  powerAndMoney,

  /// Generated images, recycled clips, real footage with a new caption.
  syntheticAndRecycled,
}

/// Which arena each demo mission belongs to.
///
/// One arena per mission rather than several. A mission that appears
/// everywhere teaches nothing about where it belongs, and a learner who
/// meets the same case in three rooms stops trusting the rooms.
const demoArenaOf = <String, DisinfoArena>{
  'viral-flood-photo': DisinfoArena.crisis,
  'old-protest-clip': DisinfoArena.crisis,
  'citation-hunt': DisinfoArena.healthAndScience,
  'anonymous-claim': DisinfoArena.powerAndMoney,
  'true-numbers-false-story': DisinfoArena.powerAndMoney,
  'context-swap': DisinfoArena.syntheticAndRecycled,
  'synthetic-but-real-topic': DisinfoArena.syntheticAndRecycled,
};

/// Display order. Crisis first because it is the one people meet without
/// choosing to, and the one where sharing does the most damage fastest.
const kArenaOrder = [
  DisinfoArena.crisis,
  DisinfoArena.healthAndScience,
  DisinfoArena.powerAndMoney,
  DisinfoArena.syntheticAndRecycled,
];
