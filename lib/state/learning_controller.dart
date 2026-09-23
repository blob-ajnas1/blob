import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/local_db.dart';
import '../data/models/app_user.dart';
import '../data/models/learning.dart';

/// Owns daily tasks, points, streaks, history and the leaderboard.
///
/// All state is Hive-backed so progress survives a restart and works fully
/// offline — a student on a patchy rural connection must never lose a day's
/// streak because the network dropped.
class LearningController extends ChangeNotifier {
  final _db = LocalDb.instance;
  final _uuid = const Uuid();

  static const _kLastActiveDay = 'learning_last_active_day';

  // ---------------- Student profile ----------------

  StudentProfile? profileFor(String userId) {
    final raw = _db.get(LocalDb.studentProfiles, userId);
    return raw == null ? null : StudentProfile.fromMap(raw);
  }

  bool hasProfile(String userId) => profileFor(userId) != null;

  Future<void> saveProfile(StudentProfile profile) async {
    await _db.put(LocalDb.studentProfiles, profile.userId, profile.toMap());
    notifyListeners();
  }

  // ---------------- Daily progress ----------------

  DailyProgress progressFor(String userId, {DateTime? date}) {
    final day = date ?? DateTime.now();
    final raw = _db.get(
      LocalDb.dailyProgress,
      DailyProgress.keyFor(userId, day),
    );
    if (raw != null) return DailyProgress.fromMap(raw);
    return DailyProgress(userId: userId, dayKey: DailyProgress.dayKeyOf(day));
  }

  Future<void> _saveProgress(DailyProgress progress) async {
    await _db.put(
      LocalDb.dailyProgress,
      '${progress.userId}_${progress.dayKey}',
      progress.toMap(),
    );
  }

  /// Records video watch time. Returns points newly awarded.
  Future<int> addVideoMinutes(String userId, int minutes) async {
    final current = progressFor(userId);
    final wasComplete = current.isComplete(DailyTaskType.video);
    final updated = current.copyWith(
      videoMinutes: min(
        current.videoMinutes + minutes,
        DailyTaskType.video.target,
      ),
    );
    return _finalise(
      userId: userId,
      before: current,
      after: updated,
      type: DailyTaskType.video,
      wasComplete: wasComplete,
      title: 'Watched the daily lesson',
    );
  }

  /// Records one completed game round.
  Future<int> addGameRound(String userId, {int? score, int? outOf}) async {
    final current = progressFor(userId);
    final wasComplete = current.isComplete(DailyTaskType.games);
    final updated = current.copyWith(
      gamesPlayed: min(current.gamesPlayed + 1, DailyTaskType.games.target),
    );
    return _finalise(
      userId: userId,
      before: current,
      after: updated,
      type: DailyTaskType.games,
      wasComplete: wasComplete,
      title: 'Played a learning game',
      score: score,
      outOf: outOf,
    );
  }

  /// Records a finished quiz.
  Future<int> submitQuiz(
    String userId, {
    required int answered,
    required int correct,
  }) async {
    final current = progressFor(userId);
    final wasComplete = current.isComplete(DailyTaskType.quiz);
    final updated = current.copyWith(
      quizAnswered: min(
        current.quizAnswered + answered,
        DailyTaskType.quiz.target,
      ),
      quizCorrect: current.quizCorrect + correct,
    );
    return _finalise(
      userId: userId,
      before: current,
      after: updated,
      type: DailyTaskType.quiz,
      wasComplete: wasComplete,
      title: 'Completed the daily quiz',
      score: correct,
      outOf: answered,
    );
  }

  /// Persists progress, awards points on first completion, logs history.
  Future<int> _finalise({
    required String userId,
    required DailyProgress before,
    required DailyProgress after,
    required DailyTaskType type,
    required bool wasComplete,
    required String title,
    int? score,
    int? outOf,
  }) async {
    final nowComplete = after.isComplete(type);
    // Points are awarded once, on the transition into completion.
    final awarded = (!wasComplete && nowComplete) ? type.points : 0;
    final saved = after.copyWith(pointsEarned: after.pointsEarned + awarded);
    await _saveProgress(saved);

    if (awarded > 0) {
      await _log(
        userId: userId,
        type: type,
        title: title,
        points: awarded,
        score: score,
        outOf: outOf,
      );
      await _touchStreak(userId);
    }
    notifyListeners();
    return awarded;
  }

  Future<void> _log({
    required String userId,
    required DailyTaskType type,
    required String title,
    required int points,
    int? score,
    int? outOf,
  }) async {
    final record = ActivityRecord(
      id: _uuid.v4(),
      userId: userId,
      type: type,
      title: title,
      points: points,
      score: score,
      outOf: outOf,
      createdAt: DateTime.now(),
    );
    await _db.put(LocalDb.activities, record.id, record.toMap());
  }

  Future<void> _touchStreak(String userId) => _db.setSetting(
    '${_kLastActiveDay}_$userId',
    DailyProgress.dayKeyOf(DateTime.now()),
  );

  // ---------------- Points & streak ----------------

  int totalPoints(String userId) {
    var total = 0;
    for (final raw in _db.all(LocalDb.dailyProgress)) {
      if (raw['user_id'] == userId) {
        total += (raw['points_earned'] as num?)?.toInt() ?? 0;
      }
    }
    return total;
  }

  /// Consecutive days (ending today or yesterday) with at least one completed
  /// task. Counting yesterday keeps the streak alive until midnight so a user
  /// who has not opened the app yet today does not see it reset to zero.
  int currentStreak(String userId) {
    final active = _activeDayKeys(userId);
    if (active.isEmpty) return 0;

    final today = DateTime.now();
    final todayKey = DailyProgress.dayKeyOf(today);
    final yesterdayKey = DailyProgress.dayKeyOf(
      today.subtract(const Duration(days: 1)),
    );

    DateTime cursor;
    if (active.contains(todayKey)) {
      cursor = today;
    } else if (active.contains(yesterdayKey)) {
      cursor = today.subtract(const Duration(days: 1));
    } else {
      return 0;
    }

    var streak = 0;
    while (active.contains(DailyProgress.dayKeyOf(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// The "Challenge Day" number shown on the dashboard: today's position in
  /// the ongoing streak. Always at least 1 so a fresh user sees "Day 1".
  int challengeDay(String userId) {
    final streak = currentStreak(userId);
    final todayActive = progressFor(userId).completedCount > 0;
    if (streak == 0) return 1;
    return todayActive ? streak : streak + 1;
  }

  Set<String> _activeDayKeys(String userId) {
    final keys = <String>{};
    for (final raw in _db.all(LocalDb.dailyProgress)) {
      if (raw['user_id'] != userId) continue;
      final progress = DailyProgress.fromMap(raw);
      if (progress.completedCount > 0) keys.add(progress.dayKey);
    }
    return keys;
  }

  /// Last [days] days as (dayKey, completedCount) for the streak strip.
  List<({String dayKey, DateTime date, int completed})> recentDays(
    String userId, {
    int days = 7,
  }) {
    final today = DateTime.now();
    return List.generate(days, (i) {
      final date = today.subtract(Duration(days: days - 1 - i));
      final progress = progressFor(userId, date: date);
      return (
        dayKey: DailyProgress.dayKeyOf(date),
        date: date,
        completed: progress.completedCount,
      );
    });
  }

  // ---------------- History ----------------

  List<ActivityRecord> history(String userId, {int? limit}) {
    final records = _db
        .all(LocalDb.activities)
        .where((r) => r['user_id'] == userId)
        .map(ActivityRecord.fromMap)
        .toList();
    // Sorted in memory — avoids a composite index requirement if this
    // ever moves to Firestore.
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (limit != null && records.length > limit) {
      return records.sublist(0, limit);
    }
    return records;
  }

  // ---------------- Leaderboard ----------------

  /// Ranked scores, highest first.
  ///
  /// [category] scopes the board to one track. Students and job seekers answer
  /// completely different questions, so a combined board would rank people on
  /// incomparable work — each track competes only against itself.
  List<LeaderboardEntry> leaderboard({int limit = 20, UserCategory? category}) {
    final byUser = <String, int>{};
    for (final raw in _db.all(LocalDb.dailyProgress)) {
      final id = raw['user_id'] as String? ?? '';
      if (id.isEmpty) continue;
      byUser[id] =
          (byUser[id] ?? 0) + ((raw['points_earned'] as num?)?.toInt() ?? 0);
    }

    final entries = <LeaderboardEntry>[];
    for (final raw in _db.all(LocalDb.users)) {
      final user = AppUser.fromMap(raw);
      if (category != null && user.category != category) continue;
      final points = byUser[user.id] ?? 0;
      if (points <= 0) continue;
      entries.add(
        LeaderboardEntry(
          userId: user.id,
          name: user.name,
          district: user.district,
          points: points,
          streak: currentStreak(user.id),
          category: user.category ?? UserCategory.jobSeeker,
        ),
      );
    }
    entries.sort((a, b) {
      final byPoints = b.points.compareTo(a.points);
      return byPoints != 0 ? byPoints : b.streak.compareTo(a.streak);
    });
    return entries.length > limit ? entries.sublist(0, limit) : entries;
  }

  /// 1-based position, or null when the user has not scored yet.
  ///
  /// Pass [category] to rank within one track, matching whichever board the
  /// user is actually looking at.
  int? rankOf(String userId, {UserCategory? category}) {
    final board = leaderboard(limit: 1000, category: category);
    for (var i = 0; i < board.length; i++) {
      if (board[i].userId == userId) return i + 1;
    }
    return null;
  }

  // ---------------- Live user count ----------------

  /// Learners active today, derived from real progress records rather than a
  /// fabricated number. A small baseline is added so the figure reads as a
  /// community rather than "1 user" on a fresh install.
  /// [category] scopes the count to one track, so the education app reports
  /// "students active today" rather than everyone on the platform.
  int activeToday({UserCategory? category}) {
    final todayKey = DailyProgress.dayKeyOf(DateTime.now());
    final allowed = category == null ? null : _userIdsIn(category);
    var count = 0;
    for (final raw in _db.all(LocalDb.dailyProgress)) {
      if (raw['day_key'] != todayKey) continue;
      if (allowed != null && !allowed.contains(raw['user_id'] as String?)) {
        continue;
      }
      count++;
    }
    return count;
  }

  int totalLearners({UserCategory? category}) {
    var count = 0;
    for (final raw in _db.all(LocalDb.users)) {
      final raw0 = raw['category'];
      if (raw0 == null) continue;
      if (category != null && raw0 != category.id) continue;
      count++;
    }
    return count;
  }

  Set<String> _userIdsIn(UserCategory category) {
    final ids = <String>{};
    for (final raw in _db.all(LocalDb.users)) {
      if (raw['category'] == category.id) {
        final id = raw['id'] as String?;
        if (id != null) ids.add(id);
      }
    }
    return ids;
  }
}
