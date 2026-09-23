import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/task_content_pack.dart';
import '../../data/models/learning.dart';
import '../../state/learning_controller.dart';
import '../../state/session_controller.dart';
import '../widgets/common.dart';

/// Daily task 1 — watch a 15-minute lesson.
///
/// There is no real video file bundled (that would bloat the APK for rural
/// users on metered data), so this plays a timed, chaptered lesson. Watch
/// time is credited only while playing, and progress is written to Hive
/// every minute so closing the app mid-lesson never loses credit.
class VideoTaskScreen extends StatefulWidget {
  /// Subject material for this track.
  final TaskContentPack pack;

  const VideoTaskScreen({super.key, required this.pack});

  @override
  State<VideoTaskScreen> createState() => _VideoTaskScreenState();
}

class _VideoTaskScreenState extends State<VideoTaskScreen> {
  VideoLesson get _lesson => widget.pack.video;

  Timer? _timer;
  bool _playing = false;

  /// Seconds watched inside this session, on top of what is already banked.
  int _sessionSeconds = 0;
  int _bankedMinutes = 0;
  int _creditedThisSession = 0;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionController>();
    final learning = context.read<LearningController>();
    final userId = session.user?.id;
    if (userId != null) {
      _bankedMinutes = learning.progressFor(userId).videoMinutes;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _totalMinutesWatched => _bankedMinutes + (_sessionSeconds ~/ 60);

  bool get _isComplete => _totalMinutesWatched >= _lesson.minutes;

  double get _fraction =>
      (_totalMinutesWatched / _lesson.minutes).clamp(0.0, 1.0);

  void _togglePlay() {
    if (_isComplete) return;
    setState(() => _playing = !_playing);
    if (_playing) {
      // 1 tick = 1 second of lesson time. Kept real so the 15-minute task
      // cannot be farmed by tapping.
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } else {
      _timer?.cancel();
    }
  }

  Future<void> _tick() async {
    if (!mounted) return;
    setState(() => _sessionSeconds++);

    // Credit whole minutes as they complete.
    final earnedMinutes = _sessionSeconds ~/ 60;
    if (earnedMinutes > _creditedThisSession) {
      final delta = earnedMinutes - _creditedThisSession;
      _creditedThisSession = earnedMinutes;
      await _credit(delta);
    }

    if (_isComplete) {
      _timer?.cancel();
      if (mounted) setState(() => _playing = false);
    }
  }

  Future<void> _credit(int minutes) async {
    final session = context.read<SessionController>();
    final learning = context.read<LearningController>();
    final userId = session.user?.id;
    if (userId == null) return;
    final awarded = await learning.addVideoMinutes(userId, minutes);
    if (!mounted) return;
    if (awarded > 0) {
      showSnack(context, 'Lesson complete — +$awarded points earned');
    }
  }

  /// Debug-build affordance: nobody should sit through 15 real minutes to
  /// check the flow works.
  ///
  /// Compiled out of release builds by the [kDebugMode] guard on its button.
  /// It awards the full lesson's points without the lesson, so shipping it
  /// would make every points total and leaderboard position meaningless.
  Future<void> _skipForTesting() async {
    final remaining = _lesson.minutes - _totalMinutesWatched;
    if (remaining <= 0) return;
    _timer?.cancel();
    setState(() {
      _playing = false;
      _sessionSeconds += remaining * 60;
      _creditedThisSession += remaining;
    });
    await _credit(remaining);
  }

  String _clock(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final watchedSeconds = _bankedMinutes * 60 + _sessionSeconds;
    final totalSeconds = _lesson.minutes * 60;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily lesson')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // "Player" surface.
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0E2A12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isComplete
                              ? Icons.check_circle
                              : _playing
                              ? Icons.graphic_eq
                              : Icons.play_circle_fill,
                          size: 56,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _isComplete
                              ? 'Lesson finished'
                              : _playing
                              ? 'Playing…'
                              : 'Tap play to begin',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 10,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: _fraction,
                              minHeight: 5,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.22,
                              ),
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.accent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _clock(watchedSeconds),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _clock(totalSeconds),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              _lesson.title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _lesson.presenter,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _lesson.summary,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isComplete ? null : _togglePlay,
                    icon: Icon(
                      _playing
                          ? Icons.pause
                          : _isComplete
                          ? Icons.check
                          : Icons.play_arrow,
                    ),
                    label: Text(
                      _isComplete
                          ? 'Completed'
                          : _playing
                          ? 'Pause'
                          : 'Play lesson',
                    ),
                  ),
                ),
              ],
            ),
            // Debug builds only. Awarding a lesson's points without the
            // lesson cannot be offered to real students.
            if (kDebugMode && !_isComplete) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _skipForTesting,
                icon: const Icon(Icons.fast_forward, size: 18),
                label: const Text('Skip to end (debug build)'),
              ),
            ],
            const SizedBox(height: 18),

            InfoBanner(
              icon: _isComplete
                  ? Icons.emoji_events_outlined
                  : Icons.timer_outlined,
              message: _isComplete
                  ? 'You earned ${DailyTaskType.video.points} points for '
                        "today's lesson."
                  : 'Watch ${_lesson.minutes} minutes to earn '
                        '${DailyTaskType.video.points} points. Your progress '
                        'is saved every minute.',
            ),
          ],
        ),
      ),
    );
  }
}
