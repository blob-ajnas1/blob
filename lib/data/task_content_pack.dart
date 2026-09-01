/// Bundles everything the three daily task screens need, so one set of task
/// mechanics can serve two completely different subject areas.
///
/// The video, quiz and game screens take a pack and render whatever it holds.
/// That keeps the education track's content strictly education (no crops,
/// mandis, commission or labour) without duplicating game code, and means
/// adding a third track later is a data change, not a UI change.
library;

import 'edu_content.dart';
import 'learning_content.dart';

// Task screens take a pack and nothing else, so they get the content shapes
// from here rather than reaching into either track's content library.
export 'task_types.dart';

class TaskContentPack {
  /// Today's 15-minute lesson.
  final VideoLesson video;

  /// The ten daily quiz questions.
  final List<QuizQuestion> quiz;

  /// Round data for the daily game.
  final List<MathRound> mathRounds;

  /// Per-track game title and framing copy.
  final String mathTitle;
  final String mathSubtitle;

  /// Whether maths answers are money. Drives ₹ formatting and Indian digit
  /// grouping — a student solving `18²` should see "324", not "₹324".
  final bool mathAnswersAreMoney;

  /// Framing shown on the quiz and video screens.
  final String quizSubject;

  const TaskContentPack({
    required this.video,
    required this.quiz,
    required this.mathRounds,
    required this.mathTitle,
    required this.mathSubtitle,
    required this.quizSubject,
    this.mathAnswersAreMoney = false,
  });

  /// Education track — school and college subjects.
  static const TaskContentPack education = TaskContentPack(
    video: EduContent.todaysVideo,
    quiz: EduContent.dailyQuiz,
    mathRounds: EduContent.mathRounds,
    mathTitle: 'Quick Maths',
    mathSubtitle: 'Solve exam-style sums against the clock',
    quizSubject: 'Science, maths, civics and English',
  );

  /// Job-seeker track — market and trade knowledge.
  static const TaskContentPack marketplace = TaskContentPack(
    video: LearningContent.todaysVideo,
    quiz: LearningContent.dailyQuiz,
    mathRounds: LearningContent.mathRounds,
    mathTitle: 'Market Maths',
    mathSubtitle: 'Work out quintal and commission totals',
    quizSubject: 'Farming and scheme knowledge',
    mathAnswersAreMoney: true,
  );
}
