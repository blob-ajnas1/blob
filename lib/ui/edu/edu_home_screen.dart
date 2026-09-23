import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/learning.dart';
import '../../data/task_content_pack.dart';
import '../../state/learning_controller.dart';
import '../../state/session_controller.dart';
import '../learning/games_task_screen.dart';
import '../learning/quiz_task_screen.dart';
import '../learning/video_task_screen.dart';
import '../widgets/common.dart';

/// "Today" — the student's daily home.
///
/// Order follows the spec: live learner count, then the three daily tasks,
/// then progress tracking (challenge day + points). Everything is education
/// framed; the marketplace does not appear anywhere on this screen.
class EduHomeScreen extends StatelessWidget {
  const EduHomeScreen({super.key});

  static const _pack = TaskContentPack.education;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final learning = context.watch<LearningController>();
    final user = session.user;
    if (user == null) return const SizedBox.shrink();

    final progress = learning.progressFor(user.id);
    final challengeDay = learning.challengeDay(user.id);
    final points = learning.totalPoints(user.id);
    final rank = learning.rankOf(user.id);
    final profile = learning.profileFor(user.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            _StudentHeader(
              userName: user.name,
              currentClass: profile?.currentClass,
              activeToday: learning.activeToday(),
              totalLearners: learning.totalLearners(),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _TodayCard(progress: progress, challengeDay: challengeDay),
            ),
            const SizedBox(height: 22),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader('Today\u2019s tasks'),
            ),
            const SizedBox(height: 4),
            for (final type in DailyTaskType.values)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _TaskCard(
                  type: type,
                  done: progress.progressFor(type),
                  complete: progress.isComplete(type),
                  subtitle: _subtitleFor(type),
                  onTap: () => _openTask(context, type),
                ),
              ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader('Your progress'),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.streak,
                      value: 'Day $challengeDay',
                      label: 'Challenge day',
                      footnote: learning.currentStreak(user.id) > 1
                          ? '${learning.currentStreak(user.id)} day streak'
                          : 'Keep it going',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.stars_rounded,
                      color: AppColors.warning,
                      value: '$points',
                      label: 'Points earned',
                      footnote: rank == null
                          ? 'Not ranked yet'
                          : 'Rank #$rank overall',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _StreakStrip(days: learning.recentDays(user.id)),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitleFor(DailyTaskType type) => switch (type) {
    DailyTaskType.video => _pack.video.title,
    DailyTaskType.games => _pack.mathSubtitle,
    DailyTaskType.quiz => _pack.quizSubject,
  };

  void _openTask(BuildContext context, DailyTaskType type) {
    final screen = switch (type) {
      DailyTaskType.video => const VideoTaskScreen(pack: _pack),
      DailyTaskType.games => const GamesTaskScreen(pack: _pack),
      DailyTaskType.quiz => const QuizTaskScreen(pack: _pack),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

/// Blue header with the live learner count.
///
/// Both figures come from real records rather than being invented, so an early
/// install honestly reads "1". Fabricating a number would be a lie the user
/// cannot audit.
class _StudentHeader extends StatelessWidget {
  const _StudentHeader({
    required this.userName,
    required this.currentClass,
    required this.activeToday,
    required this.totalLearners,
  });

  final String userName;
  final String? currentClass;
  final int activeToday;
  final int totalLearners;

  @override
  Widget build(BuildContext context) {
    final firstName = userName.split(' ').first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, $firstName',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentClass == null
                          ? 'Student'
                          : 'Student \u00b7 $currentClass',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textOnPrimary.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textOnPrimary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 7,
                      width: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _CountBlock(
                  value: activeToday,
                  label: 'Active students today',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.textOnPrimary.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _CountBlock(
                  value: totalLearners,
                  label: 'Total students using the app',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountBlock extends StatelessWidget {
  const _CountBlock({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.textOnPrimary,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textOnPrimary.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.progress, required this.challengeDay});

  final DailyProgress progress;
  final int challengeDay;

  @override
  Widget build(BuildContext context) {
    final done = progress.completedCount;
    final all = progress.allComplete;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: all ? AppColors.success : AppColors.border,
          width: all ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                all ? Icons.verified_rounded : Icons.flag_circle_rounded,
                size: 20,
                color: all ? AppColors.success : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  all
                      ? 'Day $challengeDay complete'
                      : 'Challenge day $challengeDay',
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$done of 3',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.overallFraction,
              minHeight: 8,
              backgroundColor: AppColors.primarySoft,
              valueColor: AlwaysStoppedAnimation(
                all ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            all
                ? 'All three tasks done. Come back tomorrow to extend your '
                      'streak.'
                : 'Finish all three tasks today to keep your streak alive.',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.type,
    required this.done,
    required this.complete,
    required this.subtitle,
    required this.onTap,
  });

  final DailyTaskType type;
  final int done;
  final bool complete;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: complete ? AppColors.success : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: complete
                      ? AppColors.clearedSoft
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  complete ? Icons.check_rounded : type.icon,
                  color: complete ? AppColors.success : AppColors.primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: (done / type.target).clamp(0.0, 1.0),
                              minHeight: 5,
                              backgroundColor: AppColors.background,
                              valueColor: AlwaysStoppedAnimation(
                                complete
                                    ? AppColors.success
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$done/${type.target} ${type.unitLabel}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '+${type.points}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.footnote,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String footnote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            footnote,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Seven-day strip. Three filled pips means all tasks done that day, which
/// makes a broken streak visible at a glance.
class _StreakStrip extends StatelessWidget {
  const _StreakStrip({required this.days});

  final List<({String dayKey, DateTime date, int completed})> days;

  static const _weekday = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last 7 days',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in days)
                Column(
                  children: [
                    Container(
                      height: 30,
                      width: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: day.completed == 3
                            ? AppColors.primary
                            : day.completed > 0
                            ? AppColors.primarySoft
                            : AppColors.background,
                        border: Border.all(
                          color: day.completed > 0
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        '${day.date.day}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: day.completed == 3
                              ? AppColors.textOnPrimary
                              : day.completed > 0
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _weekday[day.date.weekday - 1],
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
