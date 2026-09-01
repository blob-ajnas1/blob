// External Play Store games surfaced in the Learning/Games tab.
//
// These are real third-party titles, not in-app mini-games: tapping one
// opens its Play Store page (native market:// intent first, web URL as
// fallback) so the user can install or launch it. They complement the
// built-in daily-round games rather than counting towards the daily
// points target.

class ExternalGame {
  final String title;
  final String category;
  final String packageName;
  final String description;

  const ExternalGame({
    required this.title,
    required this.category,
    required this.packageName,
    required this.description,
  });

  /// Native Android market URI — opens the Play Store app directly.
  Uri get marketUri => Uri.parse('market://details?id=$packageName');

  /// Web Play Store URL — the fallback for devices without a market
  /// handler (emulators, some tablets, desktop-like Android devices).
  Uri get webUri =>
      Uri.parse('https://play.google.com/store/apps/details?id=$packageName');
}

const externalGames = <ExternalGame>[
  ExternalGame(
    title: 'Hunter Assassin',
    category: 'Action / Stealth',
    packageName: 'com.rubygames.assassin',
    description:
        'Sneak through shadows, hunt targets one by one and dodge armed '
        'guards in this stealth-action hit.',
  ),
  ExternalGame(
    title: 'Subway Surfers',
    category: 'Arcade / Runner',
    packageName: 'com.kiloo.subwaysurf',
    description:
        'Endless runner — dash down the tracks, dodge trains and outrun the '
        'inspector in the world-famous chase.',
  ),
  ExternalGame(
    title: 'Save the Pets',
    category: 'Puzzle / Brain Teaser',
    packageName: 'com.bravestars.savethedog.drawgame',
    description:
        'Draw lines to shield pets from bees, lava and traps — a creative '
        'draw-to-save puzzle workout for the brain.',
  ),
  ExternalGame(
    title: 'Tower Rush',
    category: 'Arcade / Strategy',
    packageName: 'com.tower.rush.goldtier.ascend',
    description:
        'Stack floors, manage resources and climb the gold tier — quick '
        'decisions and steady nerves take your tower higher.',
  ),
];
