import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_settings.dart';
import 'data/connectivity.dart';
import 'features/onboarding/onboarding_carousel_screen.dart';

class EvidenceGymApp extends StatefulWidget {
  const EvidenceGymApp({super.key, this.settings});

  /// Injectable so widget tests can start in a chosen language or at a
  /// given text scale without driving the settings UI.
  final AppSettings? settings;

  @override
  State<EvidenceGymApp> createState() => _EvidenceGymAppState();
}

class _EvidenceGymAppState extends State<EvidenceGymApp> {
  late final AppSettings _settings = widget.settings ?? AppSettings();
  late final bool _ownsSettings = widget.settings == null;

  /// Shared across the app so one failed request updates every screen.
  /// Owned here rather than by a repository, because the answer is about
  /// the device's situation and not about any one data source.
  final Connectivity _connectivity = Connectivity();

  @override
  void dispose() {
    if (_ownsSettings) _settings.dispose();
    _connectivity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityScope(
      connectivity: _connectivity,
      child: AppSettingsScope(
        settings: _settings,
        child: AnimatedBuilder(
          animation: _settings,
          builder: (context, _) {
            return MaterialApp(
              title: 'Evidence Gym',
              debugShowCheckedModeBanner: false,
              theme: buildEvidenceGymTheme(),
              darkTheme: buildEvidenceGymTheme(brightness: Brightness.dark),
              themeMode: _settings.themeMode,
              locale: _settings.locale,
              supportedLocales: const [Locale('uk'), Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                final media = MediaQuery.of(context);
                return MediaQuery(
                  data: media.copyWith(
                    // Raises the floor only — never an upper bound. If the
                    // OS is already at 300%, we must not scale it back
                    // down to our slider value.
                    textScaler: media.textScaler.clamp(
                      minScaleFactor: _settings.textScale,
                    ),
                    // Reduce-motion is one-way: the app switch can only add
                    // calm on top of the OS preference, never override it.
                    disableAnimations:
                        media.disableAnimations || _settings.forceReduceMotion,
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
              home: const OnboardingCarouselScreen(),
            );
          },
        ),
      ),
    );
  }
}
