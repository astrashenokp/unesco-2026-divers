import 'account.dart';

/// The two accounts this build signs in with, and the credentials shown
/// on screen for them.
///
/// **These are meant to be public.** They are demonstration accounts —
/// printed on the sign-in screen so anyone opening the product can use
/// it without being handed a note. A credential that has to be kept
/// secret would not be printed, and one that is printed is not a secret.
///
/// **The password check here is presentation, not security.** The real
/// gate is the bearer token the server accepts: the API refuses anything
/// it was not configured with, and returns 401. Matching a password in
/// the client only decides *which* configured token to send. Anyone who
/// wanted to skip it could read the token out of a debug bundle — which
/// is exactly why release builds discard both tokens entirely and this
/// screen then offers nothing to sign in with.
///
/// When Firebase lands (ADR-008), this file goes away: real sign-in
/// verifies a password server-side and the client never holds one.
class DemoCredential {
  const DemoCredential({
    required this.login,
    required this.password,
    required this.role,
  });

  final String login;
  final String password;
  final AccountRole role;
}

const kDemoCredentials = [
  DemoCredential(
    login: 'learner',
    password: 'evidence2026',
    role: AccountRole.learner,
  ),
  DemoCredential(
    login: 'operator',
    password: 'cohort2026',
    role: AccountRole.operator,
  ),
];

/// Returns the account these credentials name, or null.
///
/// Trimmed and case-insensitive on the login, because a login typed off
/// a screen picks up stray capitals and spaces, and failing someone for
/// that teaches nothing. The password is compared exactly — a password
/// that ignores case is a shorter password.
DemoCredential? credentialFor(String login, String password) {
  final wanted = login.trim().toLowerCase();
  for (final candidate in kDemoCredentials) {
    if (candidate.login == wanted && candidate.password == password) {
      return candidate;
    }
  }
  return null;
}
