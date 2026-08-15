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
/// Kept few and wide on purpose. P0 has two populated arenas; the other two
/// remain disabled/empty presentation affordances until Role 3 adds matching
/// reviewed missions. The real taxonomy belongs to Role 3 along with the
/// content — this is the client's working set, matched to the missions that
/// exist.
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
  'authentic-media-wrong-context': DisinfoArena.crisis,
  'ai-citation-integrity': DisinfoArena.healthAndScience,
};

/// Arenas that actually have a mission in them, in display order.
///
/// Derived rather than declared. The four below were written when the
/// client carried seven made-up fixtures; the reviewed pack has two, so
/// two of the rooms had signs and no doors — and a grid of empty cards
/// reads as a broken product rather than as an honest one.
///
/// Deriving it means the grid grows by itself as content lands. Adding a
/// mission to `demoArenaOf` is all it takes for its arena to appear, and
/// nobody has to remember to update a second list.
List<DisinfoArena> get kPopulatedArenas => [
      for (final arena in kArenaOrder)
        if (demoArenaOf.containsValue(arena)) arena,
    ];

/// Every arena the taxonomy defines, in display order.
///
/// Crisis first because it is the one people meet without choosing to,
/// and the one where sharing does the most damage fastest. Kept complete
/// so the taxonomy stays readable as an intention; use
/// [kPopulatedArenas] for anything a learner sees.
const kArenaOrder = [
  DisinfoArena.crisis,
  DisinfoArena.healthAndScience,
  DisinfoArena.powerAndMoney,
  DisinfoArena.syntheticAndRecycled,
];
