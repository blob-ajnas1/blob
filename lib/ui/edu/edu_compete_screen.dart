import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/learning.dart';
import '../../state/learning_controller.dart';
import '../../state/session_controller.dart';
import '../widgets/common.dart';
import '../widgets/place_map.dart';

/// Education track — "Compete" tab.
///
/// Ranks students against students only. The board is scoped by
/// [UserCategory.student] rather than showing everyone, because the two tracks
/// answer entirely different questions: a job seeker's points come from market
/// and scheme knowledge, a student's from science, maths, civics and English.
/// Mixing them would rank people on incomparable work and would also leak
/// marketplace users into a student's app.
class EduCompeteScreen extends StatelessWidget {
  const EduCompeteScreen({super.key});

  static const _category = UserCategory.student;

  @override
  Widget build(BuildContext context) {
    final learning = context.watch<LearningController>();
    final me = context.watch<SessionController>().user;

    final board = learning.leaderboard(limit: 50, category: _category);
    final myRank = me == null
        ? null
        : learning.rankOf(me.id, category: _category);
    final myPoints = me == null ? 0 : learning.totalPoints(me.id);
    final myStreak = me == null ? 0 : learning.currentStreak(me.id);
    final totalStudents = learning.totalLearners(category: _category);
    final activeStudents = learning.activeToday(category: _category);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            _CompeteHeader(
              rank: myRank,
              points: myPoints,
              streak: myStreak,
              totalStudents: totalStudents,
              activeStudents: activeStudents,
            ),
            const SizedBox(height: 18),
            if (board.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: EmptyState(
                  icon: Icons.emoji_events_outlined,
                  title: 'No student scores yet',
                  message:
                      'Finish a task on the Today tab to put yourself on the '
                      'board. Rankings update the moment points are earned.',
                ),
              )
            else ...[
              if (board.length >= 3) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SectionHeader('Top of the class'),
                ),
                const SizedBox(height: 8),
                _Podium(top: board.take(3).toList()),
                const SizedBox(height: 18),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SectionHeader(
                  board.length == 1
                      ? 'All students'
                      : 'All students (${board.length})',
                ),
              ),
              const SizedBox(height: 4),
              for (var i = 0; i < board.length; i++)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _BoardRow(
                    rank: i + 1,
                    entry: board[i],
                    isMe: board[i].userId == me?.id,
                  ),
                ),
              // Someone who has not scored is absent from the board entirely;
              // say so explicitly rather than letting them wonder why they are
              // missing.
              if (me != null && myRank == null) ...[
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: InfoBanner(
                    icon: Icons.trending_up_rounded,
                    message: myPoints == 0
                        ? 'You are not ranked yet \u2014 finish one task today '
                              'to appear here.'
                        : 'You have $myPoints points. Keep going to enter the '
                              'top 50.',
                  ),
                ),
              ],
            ],
            const SizedBox(height: 18),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader('How points work'),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _PointsGuide(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Blue banner summarising the student's own standing.
class _CompeteHeader extends StatelessWidget {
  const _CompeteHeader({
    required this.rank,
    required this.points,
    required this.streak,
    required this.totalStudents,
    required this.activeStudents,
  });

  final int? rank;
  final int points;
  final int streak;
  final int totalStudents;
  final int activeStudents;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.accent,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Student competition',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$activeStudents active today',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            rank == null
                ? 'Ranked against $totalStudents students across the country.'
                : 'You are ranked #$rank of $totalStudents students.',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeaderStat(
                  label: 'My rank',
                  value: rank == null ? '\u2014' : '#$rank',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeaderStat(label: 'Points', value: '$points'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeaderStat(label: 'Streak', value: '${streak}d'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textOnPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.top});

  final List<LeaderboardEntry> top;

  @override
  Widget build(BuildContext context) {
    // Visual order is 2 - 1 - 3, matching a real podium.
    final ordered = [top[1], top[0], top[2]];
    const ranks = [2, 1, 3];
    const heights = [70.0, 96.0, 56.0];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 3; i++)
              Expanded(
                child: _PodiumColumn(
                  rank: ranks[i],
                  entry: ordered[i],
                  height: heights[i],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.rank,
    required this.entry,
    required this.height,
  });

  final int rank;
  final LeaderboardEntry entry;
  final double height;

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) {
      1 => const Color(0xFFD4A017),
      2 => const Color(0xFF9E9E9E),
      _ => const Color(0xFFA1662F),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rank == 1)
          const Icon(
            Icons.emoji_events_rounded,
            size: 22,
            color: Color(0xFFD4A017),
          )
        else
          const SizedBox(height: 22),
        const SizedBox(height: 6),
        Container(
          height: 44,
          width: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primarySoft,
            border: Border.all(color: medal, width: 2),
          ),
          child: Text(
            _initials(entry.name),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            entry.name.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          '${entry.points} pts',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: rank == 1 ? AppColors.primary : AppColors.primarySoft,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '$rank',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: rank == 1 ? AppColors.textOnPrimary : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _BoardRow extends StatelessWidget {
  const _BoardRow({
    required this.rank,
    required this.entry,
    required this.isMe,
  });

  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primarySoft : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? AppColors.primary : AppColors.border,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: rank <= 3 ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
          Container(
            height: 36,
            width: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMe ? AppColors.primary : AppColors.primarySoft,
            ),
            child: Text(
              _initials(entry.name),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isMe ? AppColors.textOnPrimary : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'YOU',
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
                const SizedBox(height: 2),
                // Every row here is a student, so the category label would be
                // the same on all of them; the district alone is the useful
                // distinguisher.
                PlaceLink(
                  name: entry.district,
                  subtitle: entry.name,
                  iconSize: 12,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.points}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              if (entry.streak > 0)
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 12,
                      color: AppColors.streak,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${entry.streak}d',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.streak,
                      ),
                    ),
                  ],
                )
              else
                const Text(
                  'pts',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Spells out the scoring rules. Without this a learner can see their total
/// move but not understand what moved it.
class _PointsGuide extends StatelessWidget {
  const _PointsGuide();

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
        children: [
          for (final type in DailyTaskType.values) ...[
            Row(
              children: [
                Container(
                  height: 32,
                  width: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    switch (type) {
                      DailyTaskType.video => Icons.play_circle_outline,
                      DailyTaskType.games => Icons.sports_esports_outlined,
                      DailyTaskType.quiz => Icons.quiz_outlined,
                    },
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    type.label,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '+${type.points}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (type != DailyTaskType.values.last)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}
