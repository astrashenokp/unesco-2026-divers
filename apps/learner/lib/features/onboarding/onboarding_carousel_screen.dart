import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../app_settings.dart';
import '../../l10n/strings.dart';
import '../auth/auth_screen.dart';

/// The pre-auth value-proposition carousel
/// (`MASCOT_AND_VISUAL_LANGUAGE.md`, "Pre-auth sequence").
///
/// Never auto-advances: an auto-playing carousel is unreadable for slow
/// readers and hostile to screen readers.
class OnboardingCarouselScreen extends StatefulWidget {
  const OnboardingCarouselScreen({super.key});

  @override
  State<OnboardingCarouselScreen> createState() => _OnboardingCarouselScreenState();
}

class _OnboardingCarouselScreenState extends State<OnboardingCarouselScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToAuth() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  void _next() {
    if (_index == 2) {
      _goToAuth();
      return;
    }
    final duration = Motion.of(context, Motion.standard);
    if (duration == Duration.zero) {
      // jumpToPage rather than a zero-duration animateTo: the latter
      // still schedules a frame of animation.
      _controller.jumpToPage(_index + 1);
      return;
    }
    _controller.nextPage(duration: duration, curve: Motion.curveStandard);
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    final slides = <({String title, String body, LupaMood mood})>[
      (title: s.onboard1Title, body: s.onboard1Body, mood: LupaMood.idle),
      (title: s.onboard2Title, body: s.onboard2Body, mood: LupaMood.asking),
      (title: s.onboard3Title, body: s.onboard3Body, mood: LupaMood.encouraging),
    ];

    return Scaffold(
      body: SafeArea(
        child: ReadableWidth(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(tokens.space(2)),
                // A Wrap, not a Row: at 200% text the language switch and
                // Skip together exceed a phone's width, and a Row would
                // clip Skip off the edge rather than move it down.
                child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: tokens.space(1),
                    children: [
                      // Language first, before anything asks to be read.
                      // Burying it in settings means a Ukrainian speaker
                      // has to get through an English onboarding to
                      // reach it.
                      const _LanguagePicker(),
                      TextButton(
                        key: const ValueKey('onboarding.skip'),
                        onPressed: _goToAuth,
                        child: Text(s.skip),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: slides.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final slide = slides[i];
                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: tokens.space(3)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: tokens.space(2)),
                          Lupa(mood: slide.mood, size: 140, semanticLabel: s.lupaLabel(slide.mood.name)),
                          SizedBox(height: tokens.space(3)),
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SectionRule(),
                          Text(
                            slide.body,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          SizedBox(height: tokens.space(2)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Decorative: the page number is already announced by the
              // PageView itself, so dots would only add noise.
              ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < slides.length; i++)
                      AnimatedContainer(
                        duration: Motion.of(context, Motion.fast),
                        margin: EdgeInsets.symmetric(horizontal: tokens.space(0.5)),
                        width: i == _index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _index ? tokens.action : tokens.textMuted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(tokens.space(3)),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _next,
                    child: Text(_index == slides.length - 1 ? s.getStarted : s.next),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Language choice, available before the first word of onboarding.
class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker();

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final code = settings.locale.languageCode;

    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'uk', label: Text('Укр')),
        ButtonSegment(value: 'en', label: Text('Eng')),
      ],
      selected: {code},
      showSelectedIcon: false,
      onSelectionChanged: (selection) =>
          settings.locale = Locale(selection.first),
    );
  }
}
