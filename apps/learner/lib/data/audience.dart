/// Who a session is for, and which missions that admits.
///
/// The product is built for children as well as adults. That decision
/// changes what may appear on screen, not how anything is scored: a
/// younger learner does the same three-axis reasoning on the same
/// skills, with the harsher case material left out.
library;

/// The two content modes.
enum AudienceMode {
  /// Everything in the pack.
  adult,

  /// Everything except missions built on distressing case material.
  child,
}

/// Content-warning tags that a younger learner may meet.
///
/// **An allowlist, not a blocklist, and that is the whole point.** A
/// blocklist admits every tag nobody thought of, so the first time
/// content arrives carrying a warning this file has not seen — from a
/// new pack, a new author, a later version — it would be shown to a
/// child precisely because it was unfamiliar. Getting that wrong is not
/// a rendering bug.
///
/// So anything not named here keeps a mission out of the younger mode,
/// and the cost of that choice is the right way round: an unknown tag
/// hides a mission that might have been fine, rather than showing one
/// that might not be.
///
/// **This list is editorial, and it is Role 3's to own, not mine.** These
/// are the tags in the demo pack plus the obvious neighbours; a real
/// pack needs the content author to say which of their own warnings are
/// suitable. Adding a tag here is a content-review decision.
const kWarningsSuitableForChildren = <String>{
  'academic-integrity',
  'advertising',
  'marketing-claim',
  'clickbait',
  'statistics-misuse',
  'ai-generated-media',
  'impersonation',
};

/// Whether a mission carrying [contentWarnings] belongs in [mode].
///
/// An empty list means the mission declared nothing to warn about, which
/// is different from carrying an unrecognised tag: absence is not the
/// same as unknown, and treating it as such would empty the younger mode
/// of everything the moment content stopped tagging.
bool suitableFor(AudienceMode mode, Iterable<String> contentWarnings) {
  if (mode == AudienceMode.adult) return true;
  return contentWarnings.every(kWarningsSuitableForChildren.contains);
}
