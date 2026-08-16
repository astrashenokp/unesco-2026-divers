import 'package:evidence_gym_learner/data/account.dart';
import 'package:evidence_gym_learner/data/demo_accounts.dart';
import 'package:flutter_test/flutter_test.dart';

/// The credentials are printed on the sign-in screen on purpose — they
/// are demonstration accounts, and one that had to stay secret would not
/// be on the screen. What these pin is that the two accounts stay
/// distinct and that matching stays strict where it should be.
void main() {
  test('each credential resolves to its own role', () {
    expect(credentialFor('learner', 'evidence2026')?.role,
        AccountRole.learner);
    expect(credentialFor('operator', 'cohort2026')?.role,
        AccountRole.operator);
  });

  test('the two accounts do not share a password', () {
    // Sharing one would make the role a coin toss rather than a choice.
    final passwords = kDemoCredentials.map((c) => c.password).toSet();
    expect(passwords.length, kDemoCredentials.length);
  });

  test('a login typed off the screen is forgiven its case and spaces', () {
    // Someone copying from a screen picks up stray capitals and a
    // trailing space. Failing them for that teaches nothing.
    expect(credentialFor('  Learner  ', 'evidence2026')?.role,
        AccountRole.learner);
    expect(credentialFor('OPERATOR', 'cohort2026')?.role,
        AccountRole.operator);
  });

  test('the password is compared exactly', () {
    // A password that ignores case is a shorter password.
    expect(credentialFor('learner', 'EVIDENCE2026'), isNull);
    expect(credentialFor('learner', ' evidence2026'), isNull);
  });

  test('a wrong pairing is refused, not quietly upgraded', () {
    // The learner's password must not open the operator account, and a
    // login with no password must not open anything.
    expect(credentialFor('operator', 'evidence2026'), isNull);
    expect(credentialFor('learner', ''), isNull);
    expect(credentialFor('', ''), isNull);
    expect(credentialFor('nobody', 'nothing'), isNull);
  });
}
