import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/learning.dart';
import '../../state/learning_controller.dart';
import '../../state/session_controller.dart';
import '../widgets/common.dart';
import '../widgets/place_map.dart';

/// Step 5a — leaderboard: recent winners and top performers.
///
/// "Recent winners" is the podium (top three); "top performers" is the full
/// ranked list. The signed-in user's own row is always highlighted, and if
/// they fall outside the visible list their rank is pinned at the bottom so
/// the board never feels like it excludes them.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final learning = context.watch<LearningController>();
    final me = context.watch<SessionController>().user;
    final board = learning.leaderboard(limit: 50);
    final myRank = me == null ? null : learning.rankOf(me.id);
    final myPoints = me == null ? 0 : learning.totalPoints(me.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Leaderboard')),
      body: SafeArea(
        child: board.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: EmptyState(
                    icon: Icons.leaderboard_outlined,
                    title: 'No scores yet',
                    message:
                        'Complete a daily task to put yourself on the board. '
                        'Rankings update the moment points are earned.',
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 28),
                children: [
                  if (board.length >= 3) ...[
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SectionHeader('Recent winners'),
                    ),
                    const SizedBox(height: 8),
                    _Podium(top: board.take(3).toList()),
                    const SizedBox(height: 18),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SectionHeader('Top performers'),
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
                  if (me != null && myRank == null) ...[
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InfoBanner(
                        icon: Icons.trending_up_rounded,
                        message: myPoints == 0
                            ? 'You are not ranked yet \u2014 finish one task '
                                  'today to appear here.'
                            : 'You have $myPoints points. Keep going to enter '
                                  'the top 50.',
                      ),
                    ),
                  ],
                ],
              ),
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
    final ranks = [2, 1, 3];
    final heights = [70.0, 96.0, 56.0];

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
                // Split so only the district half is tappable; the category is
                // not a place and should not look like one.
                Row(
                  children: [
                    Text(
                      '${entry.category.label} \u00b7 ',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Flexible(
                      child: PlaceLink(
                        name: entry.district,
                        subtitle: entry.name,
                        iconSize: 12,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
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

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}
