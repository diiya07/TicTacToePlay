enum Difficulty { easy, medium, hard }

enum GameMode { pvp, pvAI, online }

enum GameVariant { classic, speed, gravity, powerUp, ultimate }

enum PowerUpType { blockOpponent, doubleMark, shuffle, freeze }

enum PlayerTier { bronze, silver, gold, platinum, diamond }

enum GameStatus { playing, xWon, oWon, draw }

enum Player { x, o, none }

/// Supported board configurations.
enum BoardSize { three, five }

extension PlayerExt on Player {
  String get symbol => this == Player.x
      ? 'X'
      : this == Player.o
      ? 'O'
      : '';
  Player get opponent {
    assert(this != Player.none, 'opponent() called on Player.none — check game state');
    return this == Player.x ? Player.o : Player.x;
  }
}

extension DifficultyExt on Difficulty {
  String get label {
    switch (this) {
      case Difficulty.easy:
        return 'EASY';
      case Difficulty.medium:
        return 'MED';
      case Difficulty.hard:
        return 'HARD';
    }
  }
}

extension BoardSizeExt on BoardSize {
  int get gridSize => this == BoardSize.three ? 3 : 5;
  int get winLength => this == BoardSize.three ? 3 : 5;
  int get cellCount => gridSize * gridSize;
  String get label => this == BoardSize.three ? '3×3' : '5×5';
}

class GameResult {
  final GameStatus status;
  final List<int> winningLine;

  const GameResult({required this.status, this.winningLine = const []});

  bool get isOver => status != GameStatus.playing;
  bool get hasWinner => status == GameStatus.xWon || status == GameStatus.oWon;
}

class ScoreEntry {
  final String playerName;
  final int wins;
  final int losses;
  final int draws;
  final DateTime lastPlayed;

  const ScoreEntry({
    required this.playerName,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.lastPlayed,
  });

  int get totalGames => wins + losses + draws;
  double get winRate => totalGames == 0 ? 0.0 : wins / totalGames;

  ScoreEntry copyWith({int? wins, int? losses, int? draws}) {
    return ScoreEntry(
      playerName: playerName,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      lastPlayed: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'playerName': playerName,
    'wins': wins,
    'losses': losses,
    'draws': draws,
    'lastPlayed': lastPlayed.toIso8601String(),
  };

  factory ScoreEntry.fromJson(Map<String, dynamic> json) => ScoreEntry(
    playerName: json['playerName'] as String,
    wins: json['wins'] as int,
    losses: json['losses'] as int,
    draws: json['draws'] as int,
    lastPlayed: DateTime.parse(json['lastPlayed'] as String),
  );
}

/// Carries setup choices from SetupScreen → GameScreen / OnlineGameScreen.
class GameConfig {
  final GameMode mode;
  final GameVariant variant;
  final BoardSize boardSize;
  final Difficulty difficulty;
  final String player1Name;
  final String player2Name;
  final int? timeLimitSeconds;
  final bool powerUpsEnabled;

  const GameConfig({
    required this.mode,
    this.variant = GameVariant.classic,
    this.boardSize = BoardSize.three,
    this.difficulty = Difficulty.hard,
    this.player1Name = 'PLAYER 1',
    this.player2Name = 'PLAYER 2',
    this.timeLimitSeconds,
    this.powerUpsEnabled = false,
  });
}

class PlayerProfile {
  final int xp;
  final int level;
  final int coins;
  final PlayerTier tier;
  final String activeTheme;
  final List<String> unlockedThemes;

  const PlayerProfile({
    this.xp = 0,
    this.level = 1,
    this.coins = 0,
    this.tier = PlayerTier.bronze,
    this.activeTheme = 'defaultNeon',
    this.unlockedThemes = const ['defaultNeon'],
  });

  Map<String, dynamic> toJson() => {
        'xp': xp,
        'level': level,
        'coins': coins,
        'tier': tier.name,
        'activeTheme': activeTheme,
        'unlockedThemes': unlockedThemes,
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
        xp: json['xp'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        coins: json['coins'] as int? ?? 0,
        tier: PlayerTier.values.firstWhere(
            (e) => e.name == json['tier'],
            orElse: () => PlayerTier.bronze),
        activeTheme: json['activeTheme'] as String? ?? 'defaultNeon',
        unlockedThemes: (json['unlockedThemes'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            ['defaultNeon'],
      );
}

class DailyChallenge {
  final String id;
  final DateTime date;
  final GameVariant variant;
  final List<Player> boardPreset;
  final int rewardCoins;
  final int rewardXp;

  const DailyChallenge({
    required this.id,
    required this.date,
    required this.variant,
    required this.boardPreset,
    this.rewardCoins = 50,
    this.rewardXp = 100,
  });
}

class MoveRecord {
  final int index;
  final Player player;
  final DateTime timestamp;

  const MoveRecord({
    required this.index,
    required this.player,
    required this.timestamp,
  });
}

class MatchReplay {
  final String matchId;
  final DateTime startTime;
  final GameConfig config;
  final List<MoveRecord> moves;

  const MatchReplay({
    required this.matchId,
    required this.startTime,
    required this.config,
    required this.moves,
  });
}
