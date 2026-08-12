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
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              // Labels always visible on wide screens: icon-only rails are
              // a guessing game for first-time and low-vision users.
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: EdgeInsets.symmetric(vertical: context.tokens.space(2)),
                child: const Lupa(mood: LupaMood.idle, size: 48),
              ),
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
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
