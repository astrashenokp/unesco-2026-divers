import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/account.dart';
import '../../data/api_client.dart';
import '../../data/audience.dart';
import '../../data/connectivity.dart';
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
  String? _error;
  bool _busy = false;

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
  Future<void> _signIn(AccountRole role) async {
    final s = Strings.of(context);
    final token = _tokenFor(role);
    if (token == null) {
      // No credential configured for this build. Said plainly rather
      // than failing with a 401 a learner cannot interpret.
      setState(() => _error = s.signInNotConfigured);
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

                    // Two accounts, named for what they are. Which one
                    // someone gets is decided by the credential the
                    // server accepts, not by which button they press —
                    // the button only chooses which credential to send.
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        key: const ValueKey('auth.signInLearner'),
                        onPressed:
                            _busy ? null : () => _signIn(AccountRole.learner),
                        icon: const Icon(Icons.person_outline),
                        label: Text(s.signInAsLearner),
                      ),
                    ),
                    SizedBox(height: tokens.space(1)),
                    Text(
                      s.signInAsLearnerHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    SizedBox(height: tokens.space(2.5)),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: const ValueKey('auth.signInOperator'),
                        onPressed:
                            _busy ? null : () => _signIn(AccountRole.operator),
                        icon: const Icon(Icons.insights_outlined),
                        label: Text(s.signInAsOperator),
                      ),
                    ),
                    SizedBox(height: tokens.space(1)),
                    Text(
                      s.signInAsOperatorHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

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
