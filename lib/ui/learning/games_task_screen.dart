import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../data/external_games.dart';
import '../../data/task_content_pack.dart';
import '../../data/models/learning.dart';
import '../../state/learning_controller.dart';
import '../../state/session_controller.dart';
import '../widgets/common.dart';

/// Daily task 2 — play 3 interactive rounds.
///
/// One mechanic: exam-style arithmetic. Each of the day's rounds draws a
/// fresh set of questions, so the task stays replayable without needing
/// separate mini-games.
class GamesTaskScreen extends StatefulWidget {
  /// Subject material for this track. Mechanics are identical; only the
  /// content differs, so a student never sees market or trade material.
  final TaskContentPack pack;

  const GamesTaskScreen({super.key, required this.pack});

  @override
  State<GamesTaskScreen> createState() => _GamesTaskScreenState();
}

class _GamesTaskScreenState extends State<GamesTaskScreen> {
  int _roundsDoneToday = 0;

  @override
  void initState() {
    super.initState();
    final userId = context.read<SessionController>().user?.id;
    if (userId != null) {
      _roundsDoneToday = context
          .read<LearningController>()
          .progressFor(userId)
          .gamesPlayed;
    }
  }

  /// Open an external Play Store game: try the native market:// intent
  /// first, and fall back to the web Play Store URL if it fails or the
  /// platform cannot handle market links (e.g. web preview, devices
  /// without the Play Store app).
  Future<void> _openExternalGame(ExternalGame game) async {
    var opened = false;
    try {
      opened = await launchUrl(
        game.marketUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('market:// launch failed for ${game.packageName}: $e');
      }
      opened = false;
    }

    if (!opened) {
      try {
        opened = await launchUrl(
          game.webUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('web store launch failed for ${game.packageName}: $e');
        }
        opened = false;
      }
    }

    if (!mounted) return;
    if (!opened) {
      showSnack(
        context,
        'Could not open the store for ${game.title}. Check your internet '
        'connection and try again.',
        error: true,
      );
    }
  }

  Future<void> _openGame() async {
    final result = await Navigator.of(context).push<({int score, int outOf})>(
      MaterialPageRoute(builder: (_) => _MathGame(pack: widget.pack)),
    );
    if (result == null || !mounted) return;

    final session = context.read<SessionController>();
    final learning = context.read<LearningController>();
    final userId = session.user?.id;
    if (userId == null) return;

    final awarded = await learning.addGameRound(
      userId,
      score: result.score,
      outOf: result.outOf,
    );
    if (!mounted) return;
    setState(() {
      _roundsDoneToday = learning.progressFor(userId).gamesPlayed;
    });
    if (awarded > 0) {
      showSnack(context, 'All 3 games complete — +$awarded points earned');
    } else {
      showSnack(
        context,
        'Round saved — ${DailyTaskType.games.target - _roundsDoneToday} to go',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pack = widget.pack;

    return Scaffold(
      appBar: AppBar(title: const Text('Learning games')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sports_esports,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_roundsDoneToday of '
                          '${DailyTaskType.games.target} rounds done',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Finish all 3 to earn '
                          '${DailyTaskType.games.points} points',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _GameCard(
              title: pack.mathTitle,
              subtitle: pack.mathSubtitle,
              icon: Icons.calculate_outlined,
              onTap: _openGame,
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 4),
            const InfoBanner(
              icon: Icons.info_outline,
              message:
                  'You can replay as many times as you like, but each day '
                  'counts a maximum of 3 rounds towards your points.',
            ),
            const SizedBox(height: 26),
            const SectionHeader('More games on Play Store'),
            const SizedBox(height: 10),
            for (final game in externalGames) ...[
              _ExternalGameCard(
                game: game,
                onTap: () => _openExternalGame(game),
              ),
              const SizedBox(height: 12),
            ],
            const InfoBanner(
              icon: Icons.open_in_new,
              message:
                  'These open in Google Play Store. The games are '
                  'installed separately and do not count towards daily points.',
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Play Store game tile. Shown below the in-app games so the daily
/// points flow stays the primary action on this screen.
class _ExternalGameCard extends StatelessWidget {
  final ExternalGame game;
  final VoidCallback onTap;

  const _ExternalGameCard({required this.game, required this.onTap});

  IconData get _categoryIcon => switch (game.category) {
    'Action / Stealth' => Icons.visibility_outlined,
    'Arcade / Runner' => Icons.directions_run_rounded,
    'Puzzle / Brain Teaser' => Icons.psychology_outlined,
    _ => Icons.videogame_asset_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(_categoryIcon, color: AppColors.accent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          game.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          game.category,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    game.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Play',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Game 1

/// Five market-arithmetic questions.
class _MathGame extends StatefulWidget {
  final TaskContentPack pack;
  const _MathGame({required this.pack});

  @override
  State<_MathGame> createState() => _MathGameState();
}

class _MathGameState extends State<_MathGame> {
  late final List<MathRound> _rounds;
  int _index = 0;
  int _score = 0;
  int? _picked;

  @override
  void initState() {
    super.initState();
    _rounds = List.of(widget.pack.mathRounds)..shuffle(Random());
  }

  void _pick(int value) {
    if (_picked != null) return;
    setState(() {
      _picked = value;
      if (value == _rounds[_index].answer) _score++;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (_index >= _rounds.length - 1) {
        Navigator.of(context).pop((score: _score, outOf: _rounds.length));
      } else {
        setState(() {
          _index++;
          _picked = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final round = _rounds[_index];
    return Scaffold(
      appBar: AppBar(title: Text(widget.pack.mathTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GameProgress(
                current: _index + 1,
                total: _rounds.length,
                score: _score,
              ),
              const SizedBox(height: 28),
              Text(
                round.prompt,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 32),
              for (final option in round.options) ...[
                _OptionButton(
                  label: widget.pack.mathAnswersAreMoney
                      ? '\u20B9${_format(option)}'
                      : _plain(option),
                  state: _picked == null
                      ? _OptionState.idle
                      : option == round.answer
                      ? _OptionState.correct
                      : option == _picked
                      ? _OptionState.wrong
                      : _OptionState.dimmed,
                  onTap: () => _pick(option),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Non-money answers render as the plain integer. Rounds are authored so
  /// every answer is a whole number, and any unit is stated in the prompt
  /// (e.g. "= ? (%)") rather than inferred here — guessing a unit from the
  /// prompt text would silently mislabel answers as content grows.
  String _plain(int value) => value.toString();

  String _format(int value) {
    final s = value.toString();
    if (s.length <= 3) return s;
    // Indian grouping: last 3, then pairs.
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last3';
  }
}

// ---------------------------------------------------------------- Shared

class _GameProgress extends StatelessWidget {
  final int current;
  final int total;
  final int score;

  const _GameProgress({
    required this.current,
    required this.total,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : current / total,
              minHeight: 7,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$score correct',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionButton extends StatelessWidget {
  final String label;
  final _OptionState state;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (state) {
      _OptionState.idle => (
        AppColors.surface,
        AppColors.border,
        AppColors.textPrimary,
      ),
      _OptionState.correct => (
        AppColors.primary,
        AppColors.primary,
        Colors.white,
      ),
      _OptionState.wrong => (
        AppColors.dangerSoft,
        AppColors.danger,
        AppColors.danger,
      ),
      _OptionState.dimmed => (
        AppColors.background,
        AppColors.border,
        AppColors.textSecondary,
      ),
    };

    return InkWell(
      onTap: state == _OptionState.idle ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: fg,
          ),
        ),
      ),
    );
  }
}
