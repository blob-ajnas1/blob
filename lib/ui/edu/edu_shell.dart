import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/session_controller.dart';
import '../learning/history_screen.dart';
import '../widgets/floating_nav.dart';
import 'edu_compete_screen.dart';
import 'edu_home_screen.dart';
import 'edu_profile_screen.dart';

/// Root shell for the education track.
///
/// Deliberately a separate shell from [AppShell] rather than a variant of it:
/// [AppShell] assembles tabs from marketplace permissions, and a student holds
/// none, so sharing it would mean threading "not for students" exceptions
/// through every branch. A student's four tabs are fixed and entirely
/// education-focused — there is no crop, job, transport, property or payment
/// surface anywhere in this tree, and no route back into the marketplace
/// except "Switch account type" in Profile.
class EduShell extends StatefulWidget {
  const EduShell({super.key});

  @override
  State<EduShell> createState() => _EduShellState();
}

class _EduShellState extends State<EduShell> {
  int _index = 0;

  static const _tabs = <_EduTab>[
    _EduTab(
      icon: Icons.today_outlined,
      activeIcon: Icons.today,
      labelKey: 'edu_tab_today',
      screen: EduHomeScreen(),
    ),
    _EduTab(
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events,
      labelKey: 'edu_tab_compete',
      screen: EduCompeteScreen(),
    ),
    _EduTab(
      icon: Icons.timeline_outlined,
      activeIcon: Icons.timeline,
      labelKey: 'edu_tab_progress',
      screen: HistoryScreen(),
    ),
    _EduTab(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      labelKey: 'profile',
      screen: EduProfileScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Watched so a category switch or profile edit rebuilds the shell.
    final session = context.watch<SessionController>();
    if (session.user == null) return const SizedBox.shrink();

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [for (final t in _tabs) t.screen],
      ),
      bottomNavigationBar: FloatingNavBar(
        selectedIndex: _index,
        underlined: true,
        onTap: (i) => setState(() => _index = i),
        items: [
          for (final tab in _tabs)
            FloatingNavItem(
              id: tab.labelKey,
              label: session.t(tab.labelKey),
              icon: tab.icon,
              activeIcon: tab.activeIcon,
            ),
        ],
      ),
    );
  }
}

class _EduTab {
  final IconData icon;
  final IconData activeIcon;
  final String labelKey;
  final Widget screen;

  const _EduTab({
    required this.icon,
    required this.activeIcon,
    required this.labelKey,
    required this.screen,
  });
}
