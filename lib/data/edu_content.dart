/// Education-track content: lessons, quizzes and games for students.
///
/// Deliberately separate from `learning_content.dart` (the job-seeker track,
/// whose material is market- and trade-oriented). A student's app must contain
/// nothing about crops, mandis, commission or labour — so rather than filtering
/// agri content at render time, the two content sets simply never mix.
///
/// Kept offline as `const` so the daily tasks work with no connectivity, the
/// same constraint that drives the rest of the app.
library;

import 'dart:math';

import 'task_types.dart';

class EduContent {
  EduContent._();

  /// Today's 15-minute lesson. Study skills rather than a single subject, so
  /// it is useful to a Class 8 student and an undergraduate alike.
  static const VideoLesson todaysVideo = VideoLesson(
    id: 'edu_active_recall',
    title: 'How to Study Smarter: Active Recall & Spaced Repetition',
    presenter: 'Meera Krishnan, Learning Skills Educator',
    minutes: 15,
    summary:
        'Why re-reading notes feels productive but fails, and how testing '
        'yourself at spreading intervals moves knowledge into long-term '
        'memory before an exam.',
  );

  /// Exactly ten questions — the daily quiz target.
  ///
  /// Spread across science, maths, general knowledge, civics and English so
  /// the quiz suits a mixed cohort. As with the other track, each is authored
  /// answer-first for readability and shuffled at presentation time by
  /// [QuizQuestion.shuffled] — otherwise a learner could score 10/10 by
  /// tapping the first option ten times and the quiz would measure nothing.
  static const List<QuizQuestion> dailyQuiz = [
    QuizQuestion(
      question: 'Which is the largest planet in our solar system?',
      options: ['Jupiter', 'Saturn', 'Earth', 'Mars'],
      correctIndex: 0,
      explanation:
          'Jupiter is about 11 times the diameter of Earth and more massive '
          'than every other planet combined.',
    ),
    QuizQuestion(
      question: 'What is the value of 15% of 240?',
      options: ['36', '32', '40', '24'],
      correctIndex: 0,
      explanation: '10% of 240 is 24 and 5% is 12, so 15% = 24 + 12 = 36.',
    ),
    QuizQuestion(
      question:
          'Who is regarded as the chief architect of the Indian '
          'Constitution?',
      options: [
        'Dr. B. R. Ambedkar',
        'Jawaharlal Nehru',
        'Sardar Patel',
        'Rajendra Prasad',
      ],
      correctIndex: 0,
      explanation:
          'Dr. Ambedkar chaired the Drafting Committee of the Constituent '
          'Assembly.',
    ),
    QuizQuestion(
      question: 'Which gas do plants absorb from the air for photosynthesis?',
      options: ['Carbon dioxide', 'Oxygen', 'Nitrogen', 'Hydrogen'],
      correctIndex: 0,
      explanation:
          'Plants take in carbon dioxide and release oxygen, using light '
          'energy to build glucose.',
    ),
    QuizQuestion(
      question: 'What is the square root of 169?',
      options: ['13', '12', '14', '17'],
      correctIndex: 0,
      explanation: '13 × 13 = 169.',
    ),
    QuizQuestion(
      question: 'Choose the correctly spelled word:',
      options: ['Necessary', 'Neccessary', 'Necessery', 'Necesary'],
      correctIndex: 0,
      explanation:
          'One "c", two "s": necessary. A common mnemonic is "one collar, '
          'two sleeves".',
    ),
    QuizQuestion(
      question:
          'Which article of the Indian Constitution guarantees the '
          'Right to Education?',
      options: ['Article 21A', 'Article 14', 'Article 19', 'Article 32'],
      correctIndex: 0,
      explanation:
          'Article 21A, added by the 86th Amendment, makes free and '
          'compulsory education a fundamental right for ages 6 to 14.',
    ),
    QuizQuestion(
      question: 'What is the SI unit of electric current?',
      options: ['Ampere', 'Volt', 'Ohm', 'Watt'],
      correctIndex: 0,
      explanation:
          'Current is measured in amperes (A). Volt is potential difference, '
          'ohm is resistance and watt is power.',
    ),
    QuizQuestion(
      question:
          'In the sentence "She sings beautifully", the word '
          '"beautifully" is a:',
      options: ['Adverb', 'Adjective', 'Noun', 'Pronoun'],
      correctIndex: 0,
      explanation:
          'It modifies the verb "sings", describing how the action is done, '
          'which makes it an adverb.',
    ),
    QuizQuestion(
      question: 'Which Indian city is known as the "Silicon Valley of India"?',
      options: ['Bengaluru', 'Hyderabad', 'Pune', 'Chennai'],
      correctIndex: 0,
      explanation:
          'Bengaluru hosts the largest concentration of India\u2019s IT and '
          'software industry.',
    ),
  ];

  /// Quick-maths game: exam-style arithmetic done under time pressure.
  static const List<MathRound> mathRounds = [
    (prompt: '24 × 15 = ?', answer: 360, options: [360, 340, 380, 320]),
    (prompt: '18² = ?', answer: 324, options: [324, 304, 344, 361]),
    // Answers are plain integers on purpose: a fraction like 7/8 (87.5%)
    // would need a scaled encoding and a decoder in the UI, which is a lot of
    // fragile machinery for one sum. 3/4 keeps the round exact.
    (
      prompt: '3/4 expressed as a percentage = ? (%)',
      answer: 75,
      options: [75, 70, 80, 65],
    ),
    (prompt: 'If 5x = 45, then x = ?', answer: 9, options: [9, 8, 11, 10]),
    (prompt: 'HCF of 36 and 48 = ?', answer: 12, options: [12, 6, 18, 24]),
    (
      prompt: 'Average of 12, 18, 24 and 30 = ?',
      answer: 21,
      options: [21, 22, 20, 24],
    ),
  ];

  /// Word bank for the "Match the Term" game — academic vocabulary.
  static const List<TermPair> termPairs = [
    (term: 'Photosynthesis', meaning: 'Plants making food from sunlight'),
    (term: 'Democracy', meaning: 'Government elected by the people'),
    (term: 'Perimeter', meaning: 'Total distance around a shape'),
    (term: 'Synonym', meaning: 'Word with the same meaning'),
    (term: 'Gravity', meaning: 'Force pulling objects toward each other'),
    (term: 'Latitude', meaning: 'Distance north or south of the equator'),
    (term: 'Fraction', meaning: 'A part of a whole number'),
    (term: 'Ecosystem', meaning: 'Living things and their environment'),
  ];

  /// Sequencing game: put steps or values into the correct order. Tests
  /// reasoning rather than recall.
  static const List<OrderRound> orderRounds = [
    (
      prompt: 'Arrange these fractions from smallest to largest',
      ordered: ['1/5', '1/4', '1/3', '1/2'],
    ),
    (
      prompt: 'Order the stages of the water cycle',
      ordered: ['Evaporation', 'Condensation', 'Precipitation', 'Collection'],
    ),
    (
      prompt: 'Order these planets outward from the Sun',
      ordered: ['Mercury', 'Venus', 'Earth', 'Mars'],
    ),
    (
      prompt: 'Order these numbers from smallest to largest',
      ordered: ['0.07', '0.7', '7.0', '70'],
    ),
    (
      prompt: 'Order these units from shortest to longest',
      ordered: ['Millimetre', 'Centimetre', 'Metre', 'Kilometre'],
    ),
  ];

  /// Deterministic pick so every learner sees the same content on a given
  /// day — a leaderboard is only fair if the day's tasks are identical for
  /// everyone. Seeding on the date rather than shuffling randomly also means
  /// the content is stable if a learner reopens the app mid-task.
  static T pickForDay<T>(List<T> items, DateTime day) {
    final seed = day.year * 10000 + day.month * 100 + day.day;
    return items[Random(seed).nextInt(items.length)];
  }
}
