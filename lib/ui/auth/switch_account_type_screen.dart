import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/app_user.dart';
import '../../data/models/enums.dart';
import '../../data/models/learning.dart';
import '../../state/learning_controller.dart';
import '../../state/session_controller.dart';
import '../shell/track_router.dart';
import '../widgets/common.dart';
import 'role_selection_screen.dart';
import 'student_details_screen.dart';

/// The only sanctioned crossing point between the two apps.
///
/// The marketplace and education tracks are otherwise completely separate —
/// separate shells, tabs, themes and content. Rather than let a tab quietly
/// open the other track (the "Learn" tab used to do exactly that), a switch is
/// an explicit, confirmed account change reached from Profile.
///
/// Switching *converts the existing account* rather than creating a second one,
/// so the user keeps their id, phone, Aadhaar verification, points, streak and
/// history. Only the track-specific parts change:
///
///  * -> Student: role becomes [UserRole.student] (no marketplace capability
///    at all, enforced by an empty RBAC set), and academic details are
///    collected if this account has never had them.
///  * -> Job seeker: the user picks a marketplace role, because "student" has
///    no marketplace meaning and every marketplace surface is gated on a
///    role-derived permission.
class SwitchAccountTypeScreen extends StatelessWidget {
  const SwitchAccountTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user;
    if (user == null) return const SizedBox.shrink();

    final current = user.category ?? UserCategory.jobSeeker;
    final other = current == UserCategory.student
        ? UserCategory.jobSeeker
        : UserCategory.student;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Switch account type')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            const Text(
              'Your account type decides which app you see.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'The two apps are separate: students get education, practice and '
              'competition, while job seekers get the agri market, jobs and '
              'transport. Your points, streak and history stay with you either '
              'way.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            _TypeCard(category: current, isCurrent: true, onTap: null),
            const SizedBox(height: 12),
            _TypeCard(
              category: other,
              isCurrent: false,
              onTap: () => _confirm(context, user, other),
            ),
            const SizedBox(height: 20),
            InfoBanner(
              icon: Icons.info_outline,
              message: other == UserCategory.student
                  ? 'Switching to Student replaces your marketplace role. Your '
                        'listings and jobs stay saved, but you will not see them '
                        'until you switch back.'
                  : 'Switching to Job Seeker asks you to choose a marketplace '
                        'role, so the right tabs and permissions can be applied.',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    AppUser user,
    UserCategory target,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Switch to ${target.label}?'),
        content: Text(
          target == UserCategory.student
              ? 'Your app will change to the student version — education '
                    'tasks, practice games and student competition. Marketplace '
                    'features will be hidden until you switch back.'
              : 'Your app will change to the job seeker version — agri market, '
                    'jobs and transport. Student features will be hidden until '
                    'you switch back.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    if (target == UserCategory.student) {
      await _toStudent(context, user);
    } else {
      await _toJobSeeker(context);
    }
  }

  /// Converts the account to the education track.
  ///
  /// Academic details are only collected when this account has never had them;
  /// somebody switching back and forth should not be re-interrogated.
  Future<void> _toStudent(BuildContext context, AppUser user) async {
    final learning = context.read<LearningController>();
    final session = context.read<SessionController>();

    if (!learning.hasProfile(user.id)) {
      final details = await Navigator.of(context).push<PendingStudentDetails>(
        MaterialPageRoute(
          builder: (_) => const StudentDetailsScreen(returnDetails: true),
        ),
      );
      // Cancelled part-way: leave the account exactly as it was.
      if (details == null) return;
      await learning.saveProfile(details.toProfile(user.id));
    }

    await session.updateUser(
      user.copyWith(
        category: UserCategory.student,
        role: UserRole.student,
        // Marketplace specialisations are meaningless for a student and would
        // otherwise linger on the record.
        subtype: null,
        clearSubtype: true,
      ),
    );
    if (!context.mounted) return;
    _restart(context);
  }

  /// Converts the account to the marketplace track. A role must be chosen,
  /// because every marketplace tab is gated on a role-derived permission.
  Future<void> _toJobSeeker(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const RoleSelectionScreen(
          category: UserCategory.jobSeeker,
          mode: RoleSelectionMode.switchExisting,
        ),
      ),
    );
    if (changed != true || !context.mounted) return;
    _restart(context);
  }

  /// Rebuilds from the track boundary so the new theme, shell and tabs all
  /// take effect, and clears history so there is no back route into the
  /// other track's screens.
  void _restart(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const TrackRouter()),
      (route) => false,
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.category,
    required this.isCurrent,
    required this.onTap,
  });

  final UserCategory category;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icon = category == UserCategory.student
        ? Icons.school_outlined
        : Icons.work_outline;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.primarySoft : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrent ? AppColors.primary : AppColors.border,
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isCurrent ? AppColors.primary : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isCurrent ? AppColors.textOnPrimary : AppColors.primary,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        category.label,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'CURRENT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    category.description,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!isCurrent)
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
