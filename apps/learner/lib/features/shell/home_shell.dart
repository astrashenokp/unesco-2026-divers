import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../app_settings.dart';
import '../../data/audience.dart';
import '../../data/connectivity.dart';
import '../../data/mission_repository.dart';
import '../../l10n/strings.dart';
import '../common/demo_banner.dart';
import '../common/offline_banner.dart';
import '../home/path_screen.dart';
import '../leaderboard/leaderboard_tab.dart';
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
        icon: Icons.leaderboard_outlined,
        selectedIcon: Icons.leaderboard,
        label: s.navBoard
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
      ProgressScreen(
        repository: widget.repository,
        onGoToPath: () => setState(() => _index = 0),
      ),
      LeaderboardTab(repository: widget.repository),
      ProfileScreen(repository: widget.repository),
      const SettingsScreen(),
    ];

    // Keyed so switching tabs rebuilds the body but Flutter still reuses
    // each page's state where it can.
    // Path is a board you assemble a case on; progress, profile and
    // settings are reading surfaces and stay quiet. The illustrated
    // board appears only on the path — behind dense text it would be
    // decoration competing with the thing being read.
    final onPath = _index == 0;
    final ground = onPath ? GroundVariant.board : GroundVariant.plain;
    const board = AssetImage('assets/backgrounds/investigation_board.png');

    final body = AnimatedSwitcher(
      duration: Motion.of(context, Motion.fast),
      child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
    );

    if (formFactor.isPhone) {
      return Scaffold(
        body: LivingBackground(
          variant: ground,
          artwork: onPath ? board : null,
          child: SafeArea(
            child: Column(
              children: [
                if (widget.repository.isDemo) const DemoBanner(),
                if (!ConnectivityScope.of(context).isOnline)
                  const OfflineBanner(),
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
                // The wide layout has room the phone does not, and the
                // rail was using none of it. These are read-only: the
                // rail is for moving between places, and a control here
                // would compete with the destination it sits under.
                //
                // Grouped at the bottom so they never push the
                // destinations off a short window.
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: tokens.space(2)),
                      child: _RailFooter(repository: widget.repository),
                    ),
                  ),
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            // The background sits behind the content pane only — the rail
            // keeps a solid surface so its labels stay crisp.
            Expanded(
              child: LivingBackground(
                variant: ground,
                artwork: onPath ? board : null,
                child: Column(
                  children: [
                    if (widget.repository.isDemo) const DemoBanner(),
                    if (!ConnectivityScope.of(context).isOnline)
                      const OfflineBanner(),
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


/// The quiet corner of the rail: what the learner has, and what the
/// session is.
///
/// Read-only on purpose. A rail is for moving between places, and a
/// control tucked into it competes with the destination above it. These
/// answer "where do I stand" without asking anyone to click.
///
/// Only on the wide layout, because it is the one with room to spare —
/// the phone puts the same facts on the screens themselves rather than
/// spending a bottom bar on them.
class _RailFooter extends StatelessWidget {
  const _RailFooter({required this.repository});

  final MissionRepository repository;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;
    final settings = AppSettingsScope.of(context);
    final streak = repository.streak;
    final paused = streak.isPaused(DateTime.now());

    // A rail is 92dp wide. Two attempts at putting sentences in it both
    // failed the same way: "not started" wrapped to two lines, "in a
    // row" wrapped under it, and "DEMO DATA" broke across two — three
    // ragged blocks of fragments where a glanceable fact was intended.
    //
    // The column is too narrow for prose, so it carries none. Each fact
    // is one short token, with the full sentence in its tooltip and its
    // semantics label. That is the honest division of labour: the rail
    // shows *that* there is a streak, and the profile says what it
    // means.
    Widget fact(IconData icon, String token, String spoken, Color tint) =>
        Tooltip(
          message: spoken,
          child: Semantics(
            label: spoken,
            child: ExcludeSemantics(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.space(0.6)),
                child: Column(
                  children: [
                    Icon(icon, size: 18, color: tint),
                    SizedBox(height: tokens.space(0.25)),
                    Text(
                      token,
                      maxLines: 1,
                      // A number or a short tag never needs to shrink;
                      // this only catches a translation that runs long,
                      // and shrinking beats wrapping in a column this
                      // narrow.
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

    return SizedBox(
      // Matches the rail's own minWidth so the block lines up with the
      // destinations above rather than floating narrower than them.
      width: 92,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.space(1.25)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(color: tokens.textMuted.withValues(alpha: 0.2)),
              fact(
                paused
                    ? Icons.pause_circle_outline
                    : Icons.local_fire_department_outlined,
                // A bare number, or a dash when there is nothing yet.
                // "not started" is a sentence and does not fit here.
                paused
                    ? '‖'
                    : (streak.current == 0 ? '—' : '${streak.current}'),
                paused
                    ? s.streakPausedExplain
                    : (streak.current == 0
                        ? s.streakNone
                        : '${s.streakDays(streak.current)} ${s.streakLabel}'),
                paused ? tokens.textMuted : tokens.evidenceSecondary,
              ),
              // Named rather than assumed. Someone handing a laptop to a
              // child should be able to see the mode without opening
              // settings, and someone who forgot they turned it on
              // should not have to wonder where the missions went.
              if (settings.audience == AudienceMode.child)
                fact(Icons.child_care_outlined, s.audienceChildShort,
                    s.audienceChild, tokens.evidencePrimary),
              if (repository.isDemo)
                fact(Icons.science_outlined, s.demoBadgeShort, s.demoBadge,
                    tokens.action),
            ],
          ),
        ),
      ),
    );
  }
}
