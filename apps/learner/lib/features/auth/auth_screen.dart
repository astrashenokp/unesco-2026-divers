import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../app_settings.dart';
import '../../data/demo_fixtures.dart';
import '../../data/mission_repository.dart';
import '../../l10n/strings.dart';
import '../shell/home_shell.dart';

const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000/',
);

/// TODO(Role 1): once Firebase is configured (`flutterfire configure`),
/// replace this with `signInAnonymously()` and return the real ID token.
/// ADR-008 already fixes guest auth as Firebase Anonymous Auth, verified
/// server-side like any other principal — not a bespoke demo principal.
/// Until then "Continue as guest" reaches the API unauthenticated and the
/// server is expected to reject protected routes; the demo key below is
/// the reliable path for a presentation.
Future<String?> _placeholderGuestTokenProvider() async => null;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _demoKeyController = TextEditingController();
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
    _open(
      LiveMissionRepository(
        EvidenceGymApiClient(
          baseUrl: Uri.parse(_apiBaseUrl),
          authTokenProvider: _placeholderGuestTokenProvider,
        ),
      ),
    );
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
    _open(DemoMissionRepository(localeCode: () => settings.locale.languageCode));
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

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
                    const Lupa(mood: LupaMood.idle, size: 96),
                    SizedBox(height: tokens.space(2)),
                    Text(
                      s.authTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SectionRule(),
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
                    SizedBox(height: tokens.space(1)),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        key: const ValueKey('auth.enterDemo'),
                        onPressed: _enterDemoKey,
                        child: Text(s.enterDemo),
                      ),
                    ),
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
