import 'package:flutter/material.dart';

/// Which track the user signed up for in Step 2 of onboarding.
enum UserCategory { student, jobSeeker }

extension UserCategoryX on UserCategory {
  String get id => name;

  String get label => switch (this) {
    UserCategory.student => 'Student',
    UserCategory.jobSeeker => 'Job Seeker',
  };

  String get subtitle => switch (this) {
    UserCategory.student => 'Currently studying in school or college',
    UserCategory.jobSeeker => 'Not studying — looking for work',
  };

  String get description => switch (this) {
    UserCategory.student =>
      'Daily learning tasks, quizzes and games matched to your class',
    UserCategory.jobSeeker =>
      'Skill-building tasks and job listings matched to your goals',
  };

  IconData get icon => switch (this) {
    UserCategory.student => Icons.school_outlined,
    UserCategory.jobSeeker => Icons.work_outline,
  };

  /// Only students are asked for academic background (Step 3).
  bool get needsAcademicProfile => this == UserCategory.student;

  static UserCategory? tryFromId(String? value) {
    if (value == null) return null;
    for (final c in UserCategory.values) {
      if (c.name == value) return c;
    }
    return null;
  }
}

/// The three daily micro-tasks.
enum DailyTaskType { video, games, quiz }

extension DailyTaskTypeX on DailyTaskType {
  String get id => name;

  String get label => switch (this) {
    DailyTaskType.video => 'Watch a video',
    DailyTaskType.games => 'Play Quick Maths',
    DailyTaskType.quiz => 'Complete the quiz',
  };

  String get subtitle => switch (this) {
    DailyTaskType.video => '15 minutes of focused learning',
    DailyTaskType.games => '3 rounds of exam-style sums',
    DailyTaskType.quiz => '10 questions',
  };

  IconData get icon => switch (this) {
    DailyTaskType.video => Icons.play_circle_outline,
    DailyTaskType.games => Icons.sports_esports_outlined,
    DailyTaskType.quiz => Icons.quiz_outlined,
  };

  /// Units needed to count the task as done.
  int get target => switch (this) {
    DailyTaskType.video => 15, // minutes
    DailyTaskType.games => 3, // rounds
    DailyTaskType.quiz => 10, // questions
  };

  String get unitLabel => switch (this) {
    DailyTaskType.video => 'min',
    DailyTaskType.games => 'rounds',
    DailyTaskType.quiz => 'questions',
  };

  /// Points awarded on completion.
  int get points => switch (this) {
    DailyTaskType.video => 30,
    DailyTaskType.games => 30,
    DailyTaskType.quiz => 40,
  };

  static DailyTaskType fromId(String value) => DailyTaskType.values
      .firstWhere((e) => e.name == value, orElse: () => DailyTaskType.video);
}

/// Academic background captured in Step 3 (students only).
class StudentProfile {
  final String userId;
  final String tenthMarksCardNumber;
  final String currentClass;
  final String collegeName;
  final String goals;
  final DateTime updatedAt;

  const StudentProfile({
    required this.userId,
    required this.tenthMarksCardNumber,
    required this.currentClass,
    required this.collegeName,
    required this.goals,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'tenth_marks_card_number': tenthMarksCardNumber,
    'current_class': currentClass,
    'college_name': collegeName,
    'goals': goals,
    'updated_at': updatedAt.toIso8601String(),
  };

  factory StudentProfile.fromMap(Map<dynamic, dynamic> m) => StudentProfile(
    userId: m['user_id'] as String? ?? '',
    tenthMarksCardNumber: m['tenth_marks_card_number'] as String? ?? '',
    currentClass: m['current_class'] as String? ?? '',
    collegeName: m['college_name'] as String? ?? '',
    goals: m['goals'] as String? ?? '',
    updatedAt:
        DateTime.tryParse(m['updated_at'] as String? ?? '') ?? DateTime.now(),
  );
}

/// One day's progress for one user. Keyed `${userId}_${dayKey}`.
class DailyProgress {
  final String userId;

  /// yyyy-MM-dd in local time.
  final String dayKey;
  final int videoMinutes;
  final int gamesPlayed;
  final int quizAnswered;
  final int quizCorrect;
  final int pointsEarned;

  const DailyProgress({
    required this.userId,
    required this.dayKey,
    this.videoMinutes = 0,
    this.gamesPlayed = 0,
    this.quizAnswered = 0,
    this.quizCorrect = 0,
    this.pointsEarned = 0,
  });

  static String keyFor(String userId, DateTime date) =>
      '${userId}_${dayKeyOf(date)}';

  static String dayKeyOf(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  int progressFor(DailyTaskType type) => switch (type) {
    DailyTaskType.video => videoMinutes,
    DailyTaskType.games => gamesPlayed,
    DailyTaskType.quiz => quizAnswered,
  };

  bool isComplete(DailyTaskType type) => progressFor(type) >= type.target;

  bool get allComplete =>
      DailyTaskType.values.every(isComplete);

  int get completedCount =>
      DailyTaskType.values.where(isComplete).length;

  /// 0.0 – 1.0 across all three tasks.
  double get overallFraction {
    var total = 0.0;
    for (final t in DailyTaskType.values) {
      total += (progressFor(t) / t.target).clamp(0.0, 1.0);
    }
    return total / DailyTaskType.values.length;
  }

  DailyProgress copyWith({
    int? videoMinutes,
    int? gamesPlayed,
    int? quizAnswered,
    int? quizCorrect,
    int? pointsEarned,
  }) => DailyProgress(
    userId: userId,
    dayKey: dayKey,
    videoMinutes: videoMinutes ?? this.videoMinutes,
    gamesPlayed: gamesPlayed ?? this.gamesPlayed,
    quizAnswered: quizAnswered ?? this.quizAnswered,
    quizCorrect: quizCorrect ?? this.quizCorrect,
    pointsEarned: pointsEarned ?? this.pointsEarned,
  );

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'day_key': dayKey,
    'video_minutes': videoMinutes,
    'games_played': gamesPlayed,
    'quiz_answered': quizAnswered,
    'quiz_correct': quizCorrect,
    'points_earned': pointsEarned,
  };

  factory DailyProgress.fromMap(Map<dynamic, dynamic> m) => DailyProgress(
    userId: m['user_id'] as String? ?? '',
    dayKey: m['day_key'] as String? ?? '',
    videoMinutes: (m['video_minutes'] as num?)?.toInt() ?? 0,
    gamesPlayed: (m['games_played'] as num?)?.toInt() ?? 0,
    quizAnswered: (m['quiz_answered'] as num?)?.toInt() ?? 0,
    quizCorrect: (m['quiz_correct'] as num?)?.toInt() ?? 0,
    pointsEarned: (m['points_earned'] as num?)?.toInt() ?? 0,
  );
}

/// Append-only log powering the History screen.
class ActivityRecord {
  final String id;
  final String userId;
  final DailyTaskType type;
  final String title;
  final int points;

  /// Score achieved, where meaningful (quiz correct count, game score).
  final int? score;
  final int? outOf;
  final DateTime createdAt;

  const ActivityRecord({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.points,
    required this.createdAt,
    this.score,
    this.outOf,
  });

  String get scoreLabel => score == null ? '—' : '$score/${outOf ?? '?'}';

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'type': type.name,
    'title': title,
    'points': points,
    'score': score,
    'out_of': outOf,
    'created_at': createdAt.toIso8601String(),
  };

  factory ActivityRecord.fromMap(Map<dynamic, dynamic> m) => ActivityRecord(
    id: m['id'] as String? ?? '',
    userId: m['user_id'] as String? ?? '',
    type: DailyTaskTypeX.fromId(m['type'] as String? ?? 'video'),
    title: m['title'] as String? ?? '',
    points: (m['points'] as num?)?.toInt() ?? 0,
    score: (m['score'] as num?)?.toInt(),
    outOf: (m['out_of'] as num?)?.toInt(),
    createdAt:
        DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}

/// A row on the leaderboard.
class LeaderboardEntry {
  final String userId;
  final String name;
  final String district;
  final int points;
  final int streak;
  final UserCategory category;

  const LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.district,
    required this.points,
    required this.streak,
    required this.category,
  });
}
