import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../state/session_controller.dart';
import '../learning/history_screen.dart';
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
      label: 'Today',
      screen: EduHomeScreen(),
    ),
    _EduTab(
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events,
      label: 'Compete',
      screen: EduCompeteScreen(),
    ),
    _EduTab(
      icon: Icons.timeline_outlined,
      activeIcon: Icons.timeline,
      label: 'Progress',
      screen: HistoryScreen(),
    ),
    _EduTab(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      screen: EduProfileScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Watched so a category switch or profile edit rebuilds the shell.
    final user = context.watch<SessionController>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [for (final t in _tabs) t.screen],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _index,
          elevation: 0,
          onTap: (i) => setState(() => _index = i),
          items: [
            for (var i = 0; i < _tabs.length; i++)
              BottomNavigationBarItem(
                icon: _EduNavIcon(icon: _tabs[i].icon, selected: false),
                activeIcon: _EduNavIcon(
                  icon: _tabs[i].activeIcon,
                  selected: true,
                ),
                label: _tabs[i].label,
              ),
          ],
        ),
      ),
    );
  }
}

class _EduTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;

  const _EduTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
  });
}

/// Matches the marketplace shell's active-tab rule exactly, so the two apps
/// feel like one product: the layout language is shared, only the hue differs.
class _EduNavIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;

  const _EduNavIcon({required this.icon, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 3,
          margin: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Icon(icon),
      ],
    );
  }
}
