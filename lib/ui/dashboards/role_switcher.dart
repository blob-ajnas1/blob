import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/app_user.dart';
import '../../data/models/enums.dart';
import '../../state/session_controller.dart';
import '../widgets/common.dart';

/// Header button showing the active role, e.g. "🌾 Landowner ▾".
///
/// Tapping opens [showRoleSwitcherSheet]. The chevron is always drawn so the
/// button reads as tappable even on a one-role account, which uses the same
/// sheet to add a second role.
class ActiveRoleButton extends StatelessWidget {
  final AppUser user;
  const ActiveRoleButton({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Active role: ${user.role.label}. Tap to switch role.',
      child: Material(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: const Key('active-role-button'),
          borderRadius: BorderRadius.circular(14),
          onTap: () => showRoleSwitcherSheet(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 7, 6, 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(user.role.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Active role',
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        user.role.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 24,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Slide-up, scrollable list of the account's roles. Picking one switches
/// the active role in place; the dashboard underneath rebuilds on the next
/// frame without navigating anywhere.
Future<void> showRoleSwitcherSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const RoleSwitcherSheet(),
  );
}

class RoleSwitcherSheet extends StatelessWidget {
  const RoleSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final user = session.user;
    if (user == null) return const SizedBox.shrink();

    final addable = UserRole.values
        .where((r) => r.selfAssignable && !user.roles.contains(r))
        .toList();

    // The messenger belongs to the page under the sheet, so the confirmation
    // snackbar still shows after the sheet has closed.
    final messenger = ScaffoldMessenger.maybeOf(context);
    void confirm(String text) => messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const Text(
            'Switch role',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your home screen changes to match the role you pick.',
            style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          for (final role in user.roles)
            _RoleTile(
              role: role,
              selected: role == user.role,
              onTap: () async {
                Navigator.of(context).pop();
                if (role == user.role) return;
                await session.switchRole(role);
                confirm('Switched to ${role.label}');
              },
            ),
          if (addable.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'ADD ANOTHER ROLE',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            for (final role in addable)
              _RoleTile(
                role: role,
                selected: false,
                trailing: Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  if (await session.addRole(role)) {
                    confirm('${role.label} added — now active');
                  }
                },
              ),
            const SizedBox(height: 4),
            const InfoBanner(
              icon: Icons.verified_user_outlined,
              message:
                  'Roles that need a licence or company check (broker, '
                  'exporter, taxi or rental business) are added from '
                  'Profile, so they still get reviewed.',
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final UserRole role;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  const _RoleTile({
    required this.role,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? AppColors.primarySoft : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: Key('role-tile-${role.name}'),
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.surface : AppColors.background,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(role.emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role.switcherHint,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing ??
                    (selected
                        ? Icon(Icons.check_circle, color: AppColors.primary)
                        : Icon(
                            Icons.radio_button_unchecked,
                            color: AppColors.border,
                          )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
