import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

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
    _controller.nextPage(
      duration: context.tokens.motionSlow,
      curve: Curves.easeOutCubic,
    );
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
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.all(tokens.space(2)),
                  child: TextButton(onPressed: _goToAuth, child: Text(s.skip)),
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
                          Lupa(mood: slide.mood, size: 140),
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
                        duration: tokens.motionFast,
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
