/// Who is signed in, and what that permits.
///
/// The role comes from the credential the server accepted, not from
/// anything the client decided. Signing in as the operator means holding
/// the operator credential; without it the server issues a learner
/// principal and no amount of client-side wishing changes that.
///
/// **What this is not.** Routing to the operator screen happens on the
/// client, so this is navigation rather than authorisation. That is
/// acceptable only while the operator screen has no privileged data
/// behind it — it renders statistics handed to it, and there is no
/// operator endpoint to call. The moment one exists, the server must
/// check the role on every request, because a screen hidden by a client
/// is not a screen anyone is prevented from reaching.
library;

enum AccountRole { learner, operator }

class Account {
  const Account({
    required this.id,
    required this.role,
    required this.token,
  });

  /// The identifier the server knows this account by. Not a real name —
  /// `PRIVACY.md` collects none.
  final String id;
  final AccountRole role;

  /// The bearer credential, held only for the session.
  final String token;

  bool get isOperator => role == AccountRole.operator;
}
