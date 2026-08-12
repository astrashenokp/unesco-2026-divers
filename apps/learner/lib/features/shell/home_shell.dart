import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../data/mission_repository.dart';
import '../../l10n/strings.dart';
import '../common/demo_banner.dart';
import '../home/path_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/progress_screen.dart';
import '../settings/settings_screen.dart';

/// The signed-in shell. Phones get a bottom [NavigationBar]; tablets and
/// laptops get a side [NavigationRail], which is the platform-native
/// expectation on each and keeps the reachable controls near the thumb on
/// touch and near the pointer on desktop.
///
/// Destination order, labels and icons are identical across both, so a
/// learner switching between phone and laptop does not have to relearn
/// anything.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.repository});

  final MissionRepository repository;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;
    final formFactor = formFactorOf(context);

    final destinations = <({IconData icon, IconData selectedIcon, String label})>[
      (icon: Icons.route_outlined, selectedIcon: Icons.route, label: s.navPath),
      (
        icon: Icons.insights_outlined,
        selectedIcon: Icons.insights,
        label: s.navProgress
      ),
      (
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: s.navProfile
      ),
      (
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: s.navSettings
      ),
    ];

    final pages = [
      PathScreen(repository: widget.repository),
      ProgressScreen(repository: widget.repository),
      ProfileScreen(repository: widget.repository),
      const SettingsScreen(),
    ];

    // Keyed so switching tabs rebuilds the body but Flutter still reuses
    // each page's state where it can.
    // Path is a board you assemble a case on; progress and settings are
    // reading surfaces and stay quiet.
    final ground = _index == 0 ? GroundVariant.board : GroundVariant.plain;

    final body = AnimatedSwitcher(
      duration: Motion.of(context, Motion.fast),
      child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
    );

    if (formFactor.isPhone) {
      return Scaffold(
        body: LivingBackground(
          variant: ground,
          child: SafeArea(
            child: Column(
              children: [
                if (widget.repository.isDemo) const DemoBanner(),
                Expanded(child: body),
              ],
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // The rail carries its own ground and its own type, rather
            // than falling through to Material defaults — it was the one
            // surface in the app still rendering as an unstyled panel.
            Container(
              decoration: BoxDecoration(
                color: tokens.surfaceRaised,
                border: Border(
                  right: BorderSide(
                    color: tokens.textMuted.withValues(alpha: 0.14),
                  ),
                ),
              ),
              child: NavigationRail(
                backgroundColor: Colors.transparent,
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                // Labels always visible on wide screens: an icon-only
                // rail is a guessing game for first-time and low-vision
                // users.
                labelType: NavigationRailLabelType.all,
                minWidth: 92,
                groupAlignment: -0.85,
                indicatorColor: tokens.action.withValues(alpha: 0.14),
                indicatorShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(tokens.space(1.75)),
                ),
                selectedIconTheme: IconThemeData(color: tokens.action, size: 26),
                unselectedIconTheme:
                    IconThemeData(color: tokens.textMuted, size: 24),
                selectedLabelTextStyle:
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: tokens.action,
                        ),
                unselectedLabelTextStyle:
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: tokens.textMuted,
                        ),
                leading: Padding(
                  padding: EdgeInsets.symmetric(vertical: tokens.space(2.5)),
                  child: Lupa(
                    mood: LupaMood.idle,
                    size: 52,
                    semanticLabel: s.lupaLabel('idle'),
                  ),
                ),
                destinations: [
                  for (final d in destinations)
                    NavigationRailDestination(
                      padding: EdgeInsets.symmetric(vertical: tokens.space(0.5)),
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            // The background sits behind the content pane only — the rail
            // keeps a solid surface so its labels stay crisp.
            Expanded(
              child: LivingBackground(
                variant: ground,
                child: Column(
                  children: [
                    if (widget.repository.isDemo) const DemoBanner(),
                    Expanded(child: body),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
