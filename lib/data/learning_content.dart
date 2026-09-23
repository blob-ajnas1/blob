/// Static learning content. Kept offline so the daily tasks work without
/// connectivity — the same constraint that drives the rest of the app.
library;

import 'task_types.dart';

// Re-exported so existing importers of this library keep resolving MathRound,
// TermPair and OrderRound. See task_types.dart for why neither content library
// owns these shapes.
export 'task_types.dart';

class LearningContent {
  LearningContent._();

  static const VideoLesson todaysVideo = VideoLesson(
    id: 'vid_soil_health',
    title: 'Soil Health & Crop Rotation Basics',
    presenter: 'Dr. Anita Rao, Agricultural Extension Officer',
    minutes: 15,
    summary:
        'How rotating crops rebuilds nitrogen, breaks pest cycles and raises '
        'yield without extra fertiliser cost.',
  );

  /// Exactly ten questions — the daily quiz target.
  static const List<QuizQuestion> dailyQuiz = [
    QuizQuestion(
      question: 'Which nutrient do legume crops add back into the soil?',
      options: ['Nitrogen', 'Chlorine', 'Sodium', 'Lead'],
      correctIndex: 0,
      explanation:
          'Legumes host rhizobium bacteria in root nodules, which fix '
          'atmospheric nitrogen into the soil.',
    ),
    QuizQuestion(
      question: 'What is the ideal moisture level for storing paddy safely?',
      options: ['Below 14%', 'Around 25%', 'Around 30%', 'Above 40%'],
      correctIndex: 0,
      explanation:
          'Above 14% moisture, stored grain grows fungus and loses market '
          'grade quickly.',
    ),
    QuizQuestion(
      question: 'Crop rotation mainly helps to:',
      options: [
        'Break pest and disease cycles',
        'Make plants grow taller',
        'Increase rainfall',
        'Reduce sunlight need',
      ],
      correctIndex: 0,
      explanation:
          'Pests specialising in one crop lose their host when a different '
          'family is planted the next season.',
    ),
    QuizQuestion(
      question: 'What does MSP stand for in Indian agriculture?',
      options: [
        'Minimum Support Price',
        'Maximum Sale Price',
        'Market Standard Price',
        'Modern Seed Programme',
      ],
      correctIndex: 0,
      explanation:
          'MSP is the floor price the government guarantees for notified '
          'crops, protecting farmers from a market crash.',
    ),
    QuizQuestion(
      question: 'Drip irrigation is preferred over flood irrigation because:',
      options: [
        'It saves water and delivers it to the root',
        'It is always cheaper to install',
        'It needs no maintenance',
        'It works without any water source',
      ],
      correctIndex: 0,
      explanation:
          'Drip cuts water use substantially by delivering directly to the '
          'root zone instead of soaking the whole field.',
    ),
    QuizQuestion(
      question: 'A soil pH of 7 means the soil is:',
      options: ['Neutral', 'Strongly acidic', 'Strongly alkaline', 'Saline'],
      correctIndex: 0,
      explanation:
          'pH 7 is neutral. Below 7 is acidic, above 7 is alkaline. Most '
          'crops prefer 6 to 7.5.',
    ),
    QuizQuestion(
      question: 'Which document proves ownership of agricultural land?',
      options: [
        'Record of Rights (RTC / Pahani)',
        'Ration card',
        'Voter ID',
        'Driving licence',
      ],
      correctIndex: 0,
      explanation:
          'The Record of Rights, Tenancy and Crops lists the owner, extent '
          'and crop details of a survey number.',
    ),
    QuizQuestion(
      question: 'Vermicompost is produced using:',
      options: ['Earthworms', 'Fish', 'Goats', 'Chickens'],
      correctIndex: 0,
      explanation:
          'Earthworms digest organic waste into a nutrient-rich compost that '
          'improves soil structure.',
    ),
    QuizQuestion(
      question: 'A Kisan Credit Card is mainly used to:',
      options: [
        'Access short-term crop loans at low interest',
        'Book train tickets',
        'Pay electricity bills only',
        'Buy a tractor outright',
      ],
      correctIndex: 0,
      explanation:
          'The KCC gives farmers timely, low-interest working capital for '
          'seeds, fertiliser and other input costs.',
    ),
    QuizQuestion(
      question: 'Mulching a field primarily helps to:',
      options: [
        'Retain soil moisture and suppress weeds',
        'Attract more insects',
        'Increase soil temperature in summer',
        'Replace the need for seeds',
      ],
      correctIndex: 0,
      explanation:
          'A mulch layer slows evaporation and blocks the light weeds need '
          'to germinate.',
    ),
  ];

  /// Word bank for the "Match the term" game round.
  static const List<TermPair> termPairs = [
    (term: 'Quintal', meaning: '100 kilograms'),
    (term: 'Kharif', meaning: 'Monsoon sowing season'),
    (term: 'Rabi', meaning: 'Winter sowing season'),
    (term: 'Mandi', meaning: 'Regulated wholesale market'),
    (term: 'Fallow', meaning: 'Land left unsown to recover'),
    (term: 'Yield', meaning: 'Output produced per unit of land'),
    (term: 'Arrears', meaning: 'Payment that is overdue'),
    (term: 'Broker', meaning: 'Agent who connects buyer and seller'),
  ];

  /// Quick-maths game: market arithmetic a trader actually does.
  static const List<MathRound> mathRounds = [
    (
      prompt: '12 quintals at ₹2,300 each = ?',
      answer: 27600,
      options: [27600, 25300, 28600, 26400],
    ),
    (
      prompt: '₹8,400 split equally among 4 workers = ?',
      answer: 2100,
      options: [2100, 2400, 1800, 2200],
    ),
    (
      prompt: '2.5% commission on ₹40,000 = ?',
      answer: 1000,
      options: [1000, 1500, 800, 1200],
    ),
    (
      prompt: '350 kg converted to quintals = ?',
      answer: 35,
      options: [35, 3, 350, 3500],
    ),
    (
      prompt: '₹650 per worker × 12 workers = ?',
      answer: 7800,
      options: [7800, 7200, 8400, 6500],
    ),
  ];

  /// Sequencing game: order crops by market price per quintal, lowest first.
  /// Previously hardcoded inside the game screen; lifted here so both tracks
  /// share one mechanic driven by data.
  static const List<OrderRound> orderRounds = [
    (
      prompt: 'Order these crops by price per quintal, lowest first',
      ordered: [
        'Sugarcane',
        'Paddy (Sona Masuri)',
        'Turmeric Fingers',
        'Arabica Coffee',
      ],
    ),
    (
      prompt: 'Order these weights from smallest to largest',
      ordered: ['1 kilogram', '1 quintal', '1 tonne', '10 tonnes'],
    ),
    (
      prompt: 'Order the stages of getting a crop to market',
      ordered: ['Sowing', 'Harvesting', 'Grading', 'Mandi sale'],
    ),
  ];
}
