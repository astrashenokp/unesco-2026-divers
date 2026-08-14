import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/audience.dart';
import '../../data/connectivity.dart';
import '../../app_settings.dart';
import '../../data/demo_fixtures.dart';
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
/// which only accepts tokens named in `EVIDENCE_GYM_DEV_TOKENS`:
///
///     flutter run -d chrome ///       --dart-define=API_BASE_URL=http://localhost:8000/ ///       --dart-define=DEV_AUTH_TOKEN=dev-token
///
/// TODO(Role 1): once Firebase is configured (`flutterfire configure`),
/// replace this with `signInAnonymously()` and return the real ID token.
/// ADR-008 already fixes guest auth as Firebase Anonymous Auth, verified
/// server-side like any other principal — not a bespoke demo principal.
const _devAuthToken = String.fromEnvironment('DEV_AUTH_TOKEN');

Future<String?> _guestTokenProvider() async =>
    _devAuthToken.isEmpty ? null : _devAuthToken;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  /// Pre-filled in debug builds only.
  ///
  /// `SCREEN_INVENTORY.md` calls the demo route a *hidden* entry, and it
  /// should stay hidden in anything shipped — pre-filling a release
  /// build would put every visitor one tap from fixture data. `flutter
  /// run` is debug by default, so development and rehearsal get the
  /// convenience while `flutter build --release` keeps the gate.
  final _demoKeyController =
      TextEditingController(text: kDebugMode ? demoAccessKey : '');
  String? _error;

  @override
  void dispose() {
    _demoKeyController.dispose();
    super.dispose();
  }

  void _open(MissionRepository repository) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HomeShell(repository: repository)),
    );
  }

  void _continueAsGuest() {
    final connectivity = ConnectivityScope.of(context);
    final client = EvidenceGymApiClient(
      baseUrl: Uri.parse(_apiBaseUrl),
      authTokenProvider: _guestTokenProvider,
    )
      // Every request reports whether the server answered, which is what
      // drives the offline banner. Nothing is gated on it: a stale flag
      // must never lock out a learner who is in fact online.
      ..onReachability = ({required bool reachable}) =>
          connectivity.report(reachable: reachable);
    _open(LiveMissionRepository(client));
  }

  void _enterDemoKey() {
    final entered = _demoKeyController.text.trim().toUpperCase();
    if (entered != demoAccessKey) {
      setState(() => _error = Strings.of(context).demoKeyWrong(demoAccessKey));
      return;
    }
    setState(() => _error = null);
    // The settings object is stable for the app's lifetime, so reading
    // .locale through it later always yields the current language.
    final settings = AppSettingsScope.of(context);
    _open(DemoMissionRepository(
      localeCode: () => settings.locale.languageCode,
      audience: () => settings.audience,
    ));
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
                    //
                    // One notice, not one per route. A second copy for
                    // the demo pushed the demo button below the fold on
                    // a phone-sized screen — a notice that hides the
                    // thing it is explaining is worse than none. The
                    // demo already carries its own line further down,
                    // and it collapses by default so the screen stays
                    // short for someone who does not want to read it.
                    const DataNotice(isDemo: false),
                    SizedBox(height: tokens.space(2)),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _continueAsGuest,
                        child: Text(s.continueAsGuest),
                      ),
                    ),
                    SizedBox(height: tokens.space(3)),
                    Text(s.orDivider, style: Theme.of(context).textTheme.bodySmall),
                    SizedBox(height: tokens.space(2)),
                    TextField(
                      key: const ValueKey('auth.demoKey'),
                      controller: _demoKeyController,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: s.demoKeyLabel,
                        errorText: _error,
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _enterDemoKey(),
                    ),
                    // `errorText` above draws the error and is only read
                    // aloud while the field has focus — but the error is
                    // produced by pressing the button below it, so a
                    // learner who cannot see the field is told nothing
                    // and simply appears unable to get in.
                    //
                    // This node carries no visible text of its own: the
                    // decoration already shows the message, and a second
                    // copy on screen would be a duplicate for everyone
                    // else. It exists only to speak.
                    if (_error != null)
                      Semantics(
                        liveRegion: true,
                        label: _error,
                        child: const SizedBox.shrink(),
                      ),
                    SizedBox(height: tokens.space(1)),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        key: const ValueKey('auth.enterDemo'),
                        onPressed: _enterDemoKey,
                        child: Text(s.enterDemo),
                      ),
                    ),
                    if (kDebugMode) ...[
                      SizedBox(height: tokens.space(1)),
                      Text(
                        s.demoKeyPrefilled,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: tokens.evidenceSecondary),
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
