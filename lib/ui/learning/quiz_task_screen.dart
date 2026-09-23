import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/task_content_pack.dart';
import '../../state/learning_controller.dart';
import '../../state/session_controller.dart';
import '../widgets/common.dart';

/// Daily task 3 — the ten question quiz.
///
/// One question per page so the answer options stay thumb-sized on a phone,
/// with the explanation revealed immediately after each pick. Explaining the
/// answer on the spot is the whole point of a learning app; a score-only
/// quiz teaches nothing.
///
/// The result is submitted once, at the end, rather than per question. A
/// half-finished quiz should not bank partial credit — otherwise the daily
/// target could be farmed by opening the quiz ten times and answering one
/// question each visit.
class QuizTaskScreen extends StatefulWidget {
  /// Subject material for this track.
  final TaskContentPack pack;

  const QuizTaskScreen({super.key, required this.pack});

  @override
  State<QuizTaskScreen> createState() => _QuizTaskScreenState();
}

class _QuizTaskScreenState extends State<QuizTaskScreen> {
  /// Built per attempt, not shared statically: the answer options are
  /// shuffled so the correct one is never predictably in the same slot, and
  /// the question order varies so a repeat attempt is not pure recall of the
  /// sequence.
  late final List<QuizQuestion> _questions = [
    for (final q in widget.pack.quiz) q.shuffled(),
  ]..shuffle();

  int _index = 0;
  int _correct = 0;
  int? _picked;
  bool _finished = false;
  bool _saving = false;
  int _pointsAwarded = 0;

  QuizQuestion get _question => _questions[_index];

  void _pick(int optionIndex) {
    if (_picked != null) return;
    setState(() {
      _picked = optionIndex;
      if (optionIndex == _question.correctIndex) _correct++;
    });
  }

  Future<void> _next() async {
    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _picked = null;
      });
      return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    final session = context.read<SessionController>();
    final learning = context.read<LearningController>();
    final userId = session.user?.id;
    if (userId == null) return;

    setState(() => _saving = true);
    final awarded = await learning.submitQuiz(
      userId,
      answered: _questions.length,
      correct: _correct,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _finished = true;
      _pointsAwarded = awarded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_finished ? 'Quiz result' : 'Daily quiz'),
        // Leaving mid-quiz discards progress, so make that an explicit choice
        // instead of a silent back-swipe loss.
        leading: _finished
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _confirmExit,
              ),
      ),
      body: SafeArea(child: _finished ? _buildResult() : _buildQuestion()),
    );
  }

  Future<void> _confirmExit() async {
    if (_index == 0 && _picked == null) {
      Navigator.of(context).pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave the quiz?'),
        content: const Text(
          'Your answers so far will not be saved. The quiz only counts '
          'towards today\u2019s task once all ten questions are answered.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  Widget _buildQuestion() {
    final question = _question;
    final answered = _picked != null;

    return Column(
      children: [
        _QuizHeader(
          current: _index + 1,
          total: _questions.length,
          correct: _correct,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 22),
                for (var i = 0; i < question.options.length; i++) ...[
                  _AnswerTile(
                    label: question.options[i],
                    letter: String.fromCharCode(65 + i),
                    state: !answered
                        ? _AnswerState.idle
                        : i == question.correctIndex
                        ? _AnswerState.correct
                        : i == _picked
                        ? _AnswerState.wrong
                        : _AnswerState.dimmed,
                    onTap: () => _pick(i),
                  ),
                  const SizedBox(height: 10),
                ],
                if (answered) ...[
                  const SizedBox(height: 8),
                  _Explanation(
                    correct: _picked == question.correctIndex,
                    text: question.explanation,
                  ),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: (!answered || _saving) ? null : _next,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : Text(
                        _index == _questions.length - 1
                            ? 'Finish quiz'
                            : 'Next question',
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final total = _questions.length;
    final pct = (_correct / total * 100).round();
    // Bands, not a pass/fail line — the task credit is for finishing, and
    // discouraging a learner who scored 4/10 is counterproductive.
    final (headline, message, color) = switch (pct) {
      >= 90 => (
        'Excellent',
        'You have this material down. Try tomorrow\u2019s quiz for a harder set.',
        AppColors.success,
      ),
      >= 60 => (
        'Well done',
        'A solid score. Review the explanations you missed and it will stick.',
        AppColors.primary,
      ),
      _ => (
        'Good effort',
        'Rewatch today\u2019s video — the answers you missed are covered in it.',
        AppColors.warning,
      ),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  height: 108,
                  width: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.10),
                    border: Border.all(color: color, width: 3),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_correct/$total',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                        Text(
                          '$pct%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  headline,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_pointsAwarded > 0)
            InfoBanner(
              icon: Icons.emoji_events_rounded,
              message:
                  'Quiz task complete \u2014 +$_pointsAwarded points added to '
                  'your total.',
              color: AppColors.warning,
              background: AppColors.accentSoft,
            )
          else
            const InfoBanner(
              icon: Icons.check_circle_outline_rounded,
              message:
                  'Answers saved. Today\u2019s quiz points were already '
                  'awarded, so this run counts as practice.',
            ),
          const SizedBox(height: 20),
          const SectionHeader('Review your answers'),
          const SizedBox(height: 4),
          for (var i = 0; i < _questions.length; i++)
            _ReviewRow(number: i + 1, question: _questions[i]),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to tasks'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizHeader extends StatelessWidget {
  const _QuizHeader({
    required this.current,
    required this.total,
    required this.correct,
  });

  final int current;
  final int total;
  final int correct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Question $current of $total',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.check_circle_rounded,
                size: 15,
                color: AppColors.success,
              ),
              const SizedBox(width: 4),
              Text(
                '$correct correct',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: current / total,
              minHeight: 7,
              backgroundColor: AppColors.primarySoft,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

enum _AnswerState { idle, correct, wrong, dimmed }

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.label,
    required this.letter,
    required this.state,
    required this.onTap,
  });

  final String label;
  final String letter;
  final _AnswerState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (state) {
      _AnswerState.idle => (
        AppColors.card,
        AppColors.border,
        AppColors.textPrimary,
      ),
      _AnswerState.correct => (
        AppColors.clearedSoft,
        AppColors.success,
        AppColors.success,
      ),
      _AnswerState.wrong => (
        AppColors.dangerSoft,
        AppColors.danger,
        AppColors.danger,
      ),
      _AnswerState.dimmed => (
        AppColors.background,
        AppColors.border,
        AppColors.textSecondary,
      ),
    };

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: state == _AnswerState.idle ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: border,
              width: state == _AnswerState.idle ? 1 : 1.6,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 28,
                width: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state == _AnswerState.idle
                      ? AppColors.primarySoft
                      : fg.withValues(alpha: 0.14),
                ),
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: state == _AnswerState.idle ? AppColors.primary : fg,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: fg,
                    height: 1.3,
                  ),
                ),
              ),
              if (state == _AnswerState.correct)
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: AppColors.success,
                )
              else if (state == _AnswerState.wrong)
                const Icon(
                  Icons.cancel_rounded,
                  size: 20,
                  color: AppColors.danger,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Explanation extends StatelessWidget {
  const _Explanation({required this.correct, required this.text});

  final bool correct;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: correct ? AppColors.clearedSoft : AppColors.pendingSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.thumb_up_alt_rounded : Icons.lightbulb_rounded,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                correct ? 'Correct' : 'Not quite',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.number, required this.question});

  final int number;
  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 22,
            width: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySoft,
            ),
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  question.options[question.correctIndex],
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
