import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/learning.dart';
import '../../state/learning_controller.dart';
import '../../state/session_controller.dart';
import '../widgets/common.dart';

/// Step 5b — the full activity log: every completed task, score and the
/// points it earned.
///
/// Grouped by day rather than one flat list, because "what did I do on
/// Tuesday" is the question a streak-based app actually gets asked. A filter
/// row narrows to a single task type.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  /// null means "all types".
  DailyTaskType? _filter;

  @override
  Widget build(BuildContext context) {
    final learning = context.watch<LearningController>();
    final user = context.watch<SessionController>().user;
    if (user == null) return const SizedBox.shrink();

    final all = learning.history(user.id);
    final records = _filter == null
        ? all
        : all.where((r) => r.type == _filter).toList();
    final grouped = _groupByDay(records);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('History')),
      body: SafeArea(
        child: Column(
          children: [
            _SummaryBar(
              totalPoints: learning.totalPoints(user.id),
              activities: all.length,
              streak: learning.currentStreak(user.id),
            ),
            _FilterRow(
              selected: _filter,
              onChanged: (value) => setState(() => _filter = value),
            ),
            Expanded(
              child: records.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: EmptyState(
                          icon: Icons.history_toggle_off_rounded,
                          title: all.isEmpty
                              ? 'No activity yet'
                              : 'Nothing in this filter',
                          message: all.isEmpty
                              ? 'Completed tasks appear here with the score '
                                    'and points you earned.'
                              : 'Try a different task type, or clear the '
                                    'filter to see everything.',
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      children: [
                        for (final group in grouped) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 6),
                            child: Row(
                              children: [
                                Text(
                                  _dayLabel(group.date),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: AppColors.border,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '+${group.points} pts',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          for (final record in group.records)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: _HistoryRow(record: record),
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<({DateTime date, List<ActivityRecord> records, int points})> _groupByDay(
    List<ActivityRecord> records,
  ) {
    final buckets = <String, List<ActivityRecord>>{};
    for (final record in records) {
      final key = DailyProgress.dayKeyOf(record.createdAt);
      buckets.putIfAbsent(key, () => []).add(record);
    }
    final keys = buckets.keys.toList()..sort((a, b) => b.compareTo(a));
    return keys.map((key) {
      final list = buckets[key]!;
      return (
        date: list.first.createdAt,
        records: list,
        points: list.fold<int>(0, (sum, r) => sum + r.points),
      );
    }).toList();
  }

  String _dayLabel(DateTime date) {
    final today = DateTime.now();
    final key = DailyProgress.dayKeyOf(date);
    if (key == DailyProgress.dayKeyOf(today)) return 'Today';
    if (key ==
        DailyProgress.dayKeyOf(today.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.totalPoints,
    required this.activities,
    required this.streak,
  });

  final int totalPoints;
  final int activities;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCell(value: '$totalPoints', label: 'Total points'),
          ),
          _divider(),
          Expanded(
            child: _SummaryCell(value: '$activities', label: 'Activities'),
          ),
          _divider(),
          Expanded(
            child: _SummaryCell(value: '$streak', label: 'Day streak'),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 32, color: AppColors.border);
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onChanged});

  final DailyTaskType? selected;
  final ValueChanged<DailyTaskType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          _Chip(
            label: 'All',
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final type in DailyTaskType.values) ...[
            const SizedBox(width: 8),
            _Chip(
              label: type.label,
              icon: type.icon,
              selected: selected == type,
              onTap: () => onChanged(type),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.card,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected ? AppColors.textOnPrimary : AppColors.primary,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.textOnPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.record});

  final ActivityRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(record.type.icon, size: 19, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.score == null
                      ? _time(record.createdAt)
                      : 'Score ${record.scoreLabel} \u00b7 '
                            '${_time(record.createdAt)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '+${record.points}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _time(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${dt.hour < 12 ? 'AM' : 'PM'}';
  }
}
