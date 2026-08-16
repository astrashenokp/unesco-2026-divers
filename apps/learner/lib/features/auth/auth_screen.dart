import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/account.dart';
import '../../data/api_client.dart';
import '../../data/audience.dart';
import '../../data/connectivity.dart';
import '../../data/demo_accounts.dart';
import '../../data/mission_cache.dart';
import '../../app_settings.dart';
import '../../data/mission_repository.dart';
import '../../l10n/strings.dart';
import '../common/data_notice.dart';
import '../shell/home_shell.dart';

const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000/',
);

/// A token for local development, supplied at build time.
///
/// Empty in any build that does not pass it, so nothing ships with a
/// credential baked in. Paired with the API's own opt-in dev verifier,
/// which only accepts the token named in `EVIDENCE_GYM_DEV_IDENTITY_TOKEN`:
///
///     flutter run -d chrome ///       --dart-define=API_BASE_URL=http://localhost:8000/ ///       --dart-define=DEV_AUTH_TOKEN=dev-token
///
/// Once Firebase is configured (`flutterfire configure`), replace this
/// development-only path with `signInAnonymously()` and return the real ID token.
/// ADR-008 already fixes guest auth as Firebase Anonymous Auth, verified
/// server-side like any other principal — not a bespoke demo principal.
const _devAuthToken = String.fromEnvironment('DEV_AUTH_TOKEN');
const _devAdminToken = String.fromEnvironment('DEV_ADMIN_TOKEN');

/// Both are ignored entirely in a release build.
///
/// `String.fromEnvironment` is resolved at compile time and baked into
/// the bundle, so nothing stopped someone running
/// `flutter build web --release --dart-define=DEV_AUTH_TOKEN=...` and
/// shipping a working credential to every visitor — readable with view
/// source. The guard makes that impossible rather than merely
/// discouraged: in release the value is discarded whatever was passed,
/// and the constant is tree-shaken out rather than carried as a dead
/// string.
///
/// Once Firebase is configured, this whole path is replaced by real
/// sign-in. ADR-008 already fixes that as the destination.
String? _tokenFor(AccountRole role) {
  if (kReleaseMode) return null;
  final token = role == AccountRole.operator ? _devAdminToken : _devAuthToken;
  return token.isEmpty ? null : token;
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Fills the fields from a printed credential.
  ///
  /// The credentials are on screen anyway, so making someone retype them
  /// tests their patience rather than the product. They still land in
  /// the fields rather than signing in directly, so what is about to be
  /// sent is visible before it is sent.
  void _fill(DemoCredential credential) {
    setState(() {
      _loginController.text = credential.login;
      _passwordController.text = credential.password;
      _error = null;
    });
  }

  void _open(MissionRepository repository, Account account) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HomeShell(repository: repository, account: account),
      ),
    );
  }

  /// Signs in with the credential configured for [role].
  ///
  /// The role is not asserted by the client — it is carried by which
  /// credential the server accepts. Holding the operator token is what
  /// makes someone an operator; without it the server issues a learner
  /// principal regardless of which button was pressed.
  /// Signs in with whatever is typed in the fields.
  ///
  /// The password check is presentation. The real gate is the bearer
  /// token the server accepts — matching a password here only decides
  /// which configured token to send, and the API refuses anything it was
  /// not configured with.
  Future<void> _submit() async {
    final s = Strings.of(context);
    final credential = credentialFor(
      _loginController.text,
      _passwordController.text,
    );
    if (credential == null) {
      setState(() => _error = s.signInWrong);
      return;
    }
    await _signIn(credential.role);
  }

  /// Opens the product on the pack shipped inside the build.
  ///
  /// No account, because there is no server to hold one. Everything
  /// finished stays on this device, and the banner says so — the same
  /// state the app falls into when a signed-in session loses its
  /// connection.
  void _openBundledPack() {
    final settings = AppSettingsScope.of(context);
    setState(() {
      _busy = false;
      _error = null;
    });
    _open(
      DemoMissionRepository(
        localeCode: () => settings.locale.languageCode,
        audience: () => settings.audience,
      ),
      const Account(id: '', role: AccountRole.learner, token: ''),
    );
  }

  Future<void> _signIn(AccountRole role) async {
    final token = _tokenFor(role);
    if (token == null) {
      // No credential in this build, which is what a release build
      // always looks like: both tokens are discarded so none can ship.
      //
      // That used to be a dead end, and on a deployed copy it would be
      // the *only* thing anyone met. The bundled pack is a real
      // capability rather than a rehearsal, so it is offered here
      // instead — clearly, as itself, with nothing pretending an
      // account exists.
      _openBundledPack();
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final connectivity = ConnectivityScope.of(context);
    final settings = AppSettingsScope.of(context);
    final client = EvidenceGymApiClient(
      baseUrl: Uri.parse(_apiBaseUrl),
      authTokenProvider: () async => token,
    )
      // Every request reports whether the server answered, which is what
      // drives the offline banner. Nothing is gated on it: a stale flag
      // must never lock out someone who is in fact online.
      ..onReachability = ({required bool reachable}) =>
          connectivity.report(reachable: reachable);

    // Storage may be unavailable — private browsing, a locked-down
    // profile. The cache is then simply absent and everything still
    // works online, which is the right failure for a convenience.
    SharedPreferences? store;
    try {
      store = await SharedPreferences.getInstance();
    } catch (_) {
      store = null;
    }
    if (!mounted) return;

    final repository = LiveMissionRepository(
      client,
      cache: MissionCache(store),
      prefetch: settings.prefetchMissions,
      // The offline pack. Not a demo mode and not labelled as one: it is
      // the reviewed content that ships with the app, and it is what the
      // product falls back to when the server cannot be reached. Calling
      // it a demo made a real capability look like a rehearsal.
      fallback: DemoMissionRepository(
        localeCode: () => settings.locale.languageCode,
        audience: () => settings.audience,
      ),
    );

    setState(() => _busy = false);
    _open(repository, Account(id: '', role: role, token: token));
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;
    final settings = AppSettingsScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: EdgeInsets.all(tokens.space(3)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Smaller than elsewhere. This screen has to carry a privacy
                    // notice and an audience choice as well as two ways in,
                    // and the mascot is the one thing on it that can shrink
                    // without losing meaning.
                    Lupa(mood: LupaMood.idle, size: 72, semanticLabel: s.lupaLabel('idle')),
                    SizedBox(height: tokens.space(2)),
                    Text(
                      s.authTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SectionRule(),
                    SizedBox(height: tokens.space(2)),
                    // Asked before either way in, because it decides
                    // which missions exist for this session — not after,
                    // buried in settings, once the harsher material has
                    // already been on screen.
                    _AudiencePicker(
                      value: settings.audience,
                      onChanged: (mode) =>
                          setState(() => settings.audience = mode),
                    ),
                    SizedBox(height: tokens.space(2)),
                    // Above the buttons, not below them. PRIVACY.md asks
                    // for clear notice, and notice placed after the
                    // action it describes is not notice.
                    const DataNotice(isDemo: false),
                    SizedBox(height: tokens.space(2)),

                    // Real fields, and the credentials for both
                    // accounts printed below them. These are
                    // demonstration accounts: a credential that must
                    // stay secret would not be printed, and one that is
                    // printed is not a secret.
                    TextField(
                      key: const ValueKey('auth.login'),
                      controller: _loginController,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: s.loginLabel,
                        prefixIcon: const Icon(Icons.person_outline),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: tokens.space(1.5)),
                    TextField(
                      key: const ValueKey('auth.password'),
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      onSubmitted: (_) => _busy ? null : _submit(),
                      decoration: InputDecoration(
                        labelText: s.passwordLabel,
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          // Revealing is standard now and it is the
                          // accessible choice: someone typing a password
                          // off a screen with a tremor or a screen
                          // reader needs to see what landed.
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                          icon: Icon(_showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          tooltip: _showPassword
                              ? s.passwordHide
                              : s.passwordShow,
                        ),
                      ),
                    ),
                    SizedBox(height: tokens.space(1.5)),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: const ValueKey('auth.signIn'),
                        onPressed: _busy ? null : _submit,
                        child: Text(s.signInAction),
                      ),
                    ),
                    SizedBox(height: tokens.space(2.5)),

                    _CredentialsCard(onUse: _fill),
                    if (_error != null) ...[
                      SizedBox(height: tokens.space(2)),
                      // Arrives in response to a press, so it announces
                      // itself rather than waiting to be found.
                      Semantics(
                        liveRegion: true,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(tokens.space(1.5)),
                          decoration: BoxDecoration(
                            color: tokens.misleading.withValues(alpha: 0.10),
                            borderRadius:
                                BorderRadius.circular(tokens.space(1.5)),
                            border: Border.all(
                              color:
                                  tokens.misleading.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            _error!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: tokens.space(2)),
                    Text(
                      s.demoExplain,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/// Adult or younger, chosen before anything is shown.
///
/// A segmented control rather than a switch. A switch has an off state
/// that reads as normal and an on state that reads as a deviation;
/// neither of these is the deviation, since the product is built for
/// both, and the control should not imply otherwise. Two equal segments
/// say that and cost a fraction of the height — this screen already
/// carries a privacy notice and two ways in, and an earlier two-card
/// version pushed the entry buttons out of reach on a phone.
///
/// Only the chosen option is explained. The description of the option
/// you did not pick is not what anyone is reading here.
class _AudiencePicker extends StatelessWidget {
  const _AudiencePicker({required this.value, required this.onChanged});

  final AudienceMode value;
  final ValueChanged<AudienceMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.audienceQuestion, style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: tokens.space(0.75)),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<AudienceMode>(
            segments: [
              ButtonSegment(
                value: AudienceMode.adult,
                icon: const Icon(Icons.person_outline),
                label: Text(s.audienceAdult),
              ),
              ButtonSegment(
                value: AudienceMode.child,
                icon: const Icon(Icons.child_care_outlined),
                label: Text(s.audienceChild),
              ),
            ],
            selected: {value},
            onSelectionChanged: (selection) => onChanged(selection.first),
          ),
        ),
        SizedBox(height: tokens.space(0.75)),
        // Announced, because the line changes in response to a press on
        // the control above it rather than being read on arrival.
        Semantics(
          liveRegion: true,
          child: Text(
            value == AudienceMode.child
                ? s.audienceChildBody
                : s.audienceAdultBody,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Text(s.audienceNotAGate, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}


/// The credentials for both accounts, printed.
///
/// On the screen rather than in a README, because the person who needs
/// them is looking at the screen. Each row fills the fields rather than
/// signing in directly, so what is about to be sent is visible first.
class _CredentialsCard extends StatelessWidget {
  const _CredentialsCard({required this.onUse});

  final void Function(DemoCredential) onUse;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(tokens.space(1.75)),
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(tokens.space(2)),
        border: Border.all(color: tokens.textMuted.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.key_outlined, size: 18, color: tokens.evidencePrimary),
              SizedBox(width: tokens.space(1)),
              Expanded(
                child: Text(s.accountsTitle,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
            ],
          ),
          SizedBox(height: tokens.space(0.5)),
          Text(s.accountsIntro,
              style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: tokens.space(1.5)),
          for (final credential in kDemoCredentials) ...[
            Semantics(
              button: true,
              label: '${s.roleName(credential.role)}. '
                  '${s.loginLabel}: ${credential.login}. '
                  '${s.passwordLabel}: ${credential.password}',
              onTap: () => onUse(credential),
              child: ExcludeSemantics(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onUse(credential),
                    borderRadius: BorderRadius.circular(tokens.space(1.5)),
                    child: Padding(
                      padding: EdgeInsets.all(tokens.space(1)),
                      child: Row(
                        children: [
                          Icon(
                            credential.role == AccountRole.operator
                                ? Icons.insights_outlined
                                : Icons.person_outline,
                            size: 18,
                            color: tokens.textMuted,
                          ),
                          SizedBox(width: tokens.space(1)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.roleName(credential.role),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                // Monospace: these are strings to copy
                                // exactly, and a proportional font makes
                                // an l and a 1 the same shape.
                                Text(
                                  '${credential.login} / ${credential.password}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                          Text(s.accountsUse,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: tokens.action,
                                    fontWeight: FontWeight.w700,
                                  )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
