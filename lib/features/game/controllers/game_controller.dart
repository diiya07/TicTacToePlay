import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tictactoe/core/constants/app_colors.dart';
import 'package:tictactoe/core/models/game_models.dart';
import 'package:tictactoe/core/utils/ai_service.dart';
import 'package:tictactoe/core/utils/firebase_leaderboard_service.dart';
import 'package:tictactoe/core/utils/game_logic.dart';
import 'package:tictactoe/core/utils/progression_service.dart';
import 'package:tictactoe/core/utils/score_service.dart';

// ── Per-mode session score ────────────────────────────────────────────────────

class _SessionScore {
  int x = 0;
  int o = 0;
  int draws = 0;

  void reset() {
    x = 0;
    o = 0;
    draws = 0;
  }
}

// ── GameController ─────────────────────────────────────────────────────────────

class GameController extends ChangeNotifier {
  // ── Board state ───────────────────────────────────────────────────────────
  List<Player> _board = List.filled(9, Player.none);
  final List<int> _moveHistory = [];
  Player _currentPlayer = Player.x;
  GameResult _result = const GameResult(status: GameStatus.playing);

  // ── Settings ──────────────────────────────────────────────────────────────
  GameMode _gameMode;
  GameVariant _variant;
  Difficulty _difficulty;
  BoardSize _boardSize;

  // ── Match Replay ──────────────────────────────────────────────────────────
  final List<MoveRecord> _replayLog = [];


  // ── Flags ─────────────────────────────────────────────────────────────────
  bool _isAIThinking = false;

  /// Hard lock: prevents any tap while AI is computing or game is over.
  bool _boardLocked = false;

  /// Incremented on every reset; invalidates any pending AI callbacks.
  int _generation = 0;

  // ── Hint ─────────────────────────────────────────────────────────────────
  int? _hintIndex;

  // ── Session scores (one bucket per mode) ─────────────────────────────────
  final Map<GameMode, _SessionScore> _scores = {
    GameMode.pvp: _SessionScore(),
    GameMode.pvAI: _SessionScore(),
    GameMode.online: _SessionScore(),
  };

  // ── Names ─────────────────────────────────────────────────────────────────
  String _playerXName = 'PLAYER 1';
  String _player2Name = 'PLAYER 2';
  static const String _aiName = 'AI';

  // ── Analytics / ad hooks ──────────────────────────────────────────────────
  int _gamesCompleted = 0;
  bool _isPremiumUnlocked = false;

  // ── Progression (XP + Coins) last earned ────────────────────────────────
  int _lastXpEarned = 0;
  int _lastCoinsEarned = 0;

  final ScoreService _scoreService = ScoreService();
  final ProgressionService _progressionService = ProgressionService();
  final FirebaseLeaderboardService _fbLeaderboard = FirebaseLeaderboardService();

  // ── Constructor ───────────────────────────────────────────────────────────

  GameController({
    GameMode gameMode = GameMode.pvAI,
    GameVariant variant = GameVariant.classic,
    Difficulty difficulty = Difficulty.hard,
    BoardSize boardSize = BoardSize.three,
  }) : _gameMode = gameMode,
       _variant = variant,
       _difficulty = difficulty,
       _boardSize = boardSize;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<Player> get board => List<Player>.unmodifiable(_board);
  Player get currentPlayer => _currentPlayer;
  GameResult get result => _result;
  GameMode get gameMode => _gameMode;
  GameVariant get variant => _variant;
  Difficulty get difficulty => _difficulty;
  BoardSize get boardSize => _boardSize;
  bool get isAIThinking => _isAIThinking;
  int? get hintIndex => _hintIndex;
  int get gamesCompleted => _gamesCompleted;
  int get lastXpEarned => _lastXpEarned;
  int get lastCoinsEarned => _lastCoinsEarned;

  int get gridSize => _boardSize.gridSize;
  int get winLength => _boardSize.winLength;

  int get scoreX => _scores[_gameMode]!.x;
  int get scoreO => _scores[_gameMode]!.o;
  int get draws => _scores[_gameMode]!.draws;

  String get playerXName => _playerXName;
  String get playerOName => _gameMode == GameMode.pvAI ? _aiName : _player2Name;

  bool get isPlayerTurn {
    if (_gameMode == GameMode.pvp) return true;
    return _currentPlayer == Player.x;
  }

  bool get isPremiumUnlocked => _isPremiumUnlocked;
  Color get themeColor =>
      _isPremiumUnlocked ? AppColors.neonGold : AppColors.neonPurple;
  Future<void> loadPremiumState() async {
    try {
      _isPremiumUnlocked = await _scoreService.isPremiumUnlocked();
      if (!_isDisposed) notifyListeners();
    } catch (e) {
      debugPrint('[GameController] loadPremiumState error: $e');
    }
  }

  Future<void> unlockPremium() async {
    try {
      await _scoreService.setPremiumUnlocked(true);
      _isPremiumUnlocked = true;
      if (!_isDisposed) notifyListeners();
    } catch (e) {
      debugPrint('[GameController] unlockPremium error: $e');
    }
  }

  /// Apply a [GameConfig] received from SetupScreen as a route argument.
  /// Call this in [didChangeDependencies] before [init].
  void applyConfig(GameConfig cfg) {
    _gameMode = cfg.mode;
    _variant = cfg.variant;
    _boardSize = cfg.boardSize;
    _difficulty = cfg.difficulty;
    _playerXName = cfg.player1Name.toUpperCase();
    _player2Name = cfg.player2Name.toUpperCase();
    _resetBoard();
    // init() will call notifyListeners() after loading prefs.
  }

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> init() async {
    try {
      await loadPremiumState();
      // Only load saved names if applyConfig didn't set them.
      if (_playerXName == 'PLAYER 1') {
        _playerXName = await _scoreService.getPlayerName(true);
      }
      if (_player2Name == 'PLAYER 2') {
        _player2Name = await _scoreService.getPlayerName(false);
      }
      if (!_isDisposed) notifyListeners();
    } catch (e) {
      debugPrint('[GameController] init error: $e');
    }
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  void setGameMode(GameMode mode) {
    if (_gameMode == mode) return;
    _gameMode = mode;
    _clearHint();
    _resetBoard();
    notifyListeners();
  }

  void setDifficulty(Difficulty d) {
    _difficulty = d;
    notifyListeners();
  }

  void setBoardSize(BoardSize size) {
    if (_boardSize == size) return;
    _boardSize = size;
    _clearHint();
    _resetBoard();
    notifyListeners();
  }

  void setPlayerName(bool isX, String name) {
    final String cleaned = name.trim().isEmpty
        ? (isX ? 'PLAYER 1' : 'PLAYER 2')
        : name.trim().toUpperCase();
    if (isX) {
      _playerXName = cleaned;
    } else {
      _player2Name = cleaned;
    }
    try {
      _scoreService.setPlayerName(isX, cleaned);
    } catch (e) {
      debugPrint('[GameController] setPlayerName error: $e');
    }
    notifyListeners();
  }

  // ── Gameplay ──────────────────────────────────────────────────────────────

  void handleTap(int index) {
    // Defensive guards — order matters
    if (_boardLocked) return;
    if (!isPlayerTurn) return;
    if (_result.isOver) return;

    int targetIndex = index;

    if (_variant == GameVariant.gravity) {
      final col = index % gridSize;
      targetIndex = GameLogic.applyGravity(_board, col, gridSize);
      if (targetIndex == -1) return; // Column full
    } else {
      if (index < 0 || index >= _board.length) return;
      if (_board[index] != Player.none) return;
    }

    _clearHint();
    _makeMove(targetIndex, _currentPlayer);

    if (!_result.isOver && _gameMode == GameMode.pvAI) {
      _scheduleAIMove();
    }
  }

  void _makeMove(int index, Player player) {
    // Extra safety: never write out of bounds
    if (index < 0 || index >= _board.length) return;

    _board[index] = player;
    _moveHistory.add(index);
    _replayLog.add(MoveRecord(
      index: index,
      player: player,
      timestamp: DateTime.now(),
    ));
    _result = GameLogic.checkWinner(_board, gridSize, winLength);
    _currentPlayer = player.opponent;

    HapticFeedback.lightImpact();

    if (_result.isOver) {
      _boardLocked = true;
      _onGameOver();
    }

    if (!_isDisposed) notifyListeners();
  }

  void _scheduleAIMove() {
    _isAIThinking = true;
    _boardLocked = true;
    final int gen = _generation; // capture current generation
    if (!_isDisposed) notifyListeners();

    Future.delayed(const Duration(milliseconds: 600), () {
      // Stale callback — board was reset while AI was thinking
      if (_isDisposed || _generation != gen) return;

      if (!_result.isOver) {
        try {
          final int move = _getAIMove();
          if (move != -1 &&
              move < _board.length &&
              _board[move] == Player.none) {
            _makeMove(move, Player.o); // _makeMove handles board write + notifyListeners
            if (!_result.isOver) _boardLocked = false;
          } else {
            _boardLocked = false;
          }
        } catch (e) {
          debugPrint('[GameController] AI move error: $e');
          _boardLocked = false;
        }
      } else {
        _boardLocked = false;
      }

      _isAIThinking = false;
      if (!_isDisposed) notifyListeners();
    });
  }

  int _getAIMove() {
    if (_boardSize == BoardSize.three) {
      return GameLogic.getMinimaxMove(
        List<Player>.from(_board), // pass a copy — minimax mutates
        Player.o,
        _difficulty,
      );
    } else {
      return AiService.getHeuristicMove(
        _board,
        Player.o,
        _difficulty,
        gridSize: gridSize,
        winLength: winLength,
      );
    }
  }

  void _onGameOver() {
    HapticFeedback.heavyImpact();
    _gamesCompleted++;
    final _SessionScore bucket = _scores[_gameMode]!;

    // ── Compute XP and coins ──────────────────────────────────────────────
    int xp = 0;
    int coins = 0;
    bool isWin = false;

    switch (_result.status) {
      case GameStatus.xWon:
        bucket.x++;
        isWin = true;
        xp = 50 + (_difficulty == Difficulty.hard ? 25 : 0);
        coins = 10;
        _recordLeaderboard(_playerXName, _result.status, isPlayerX: true);
        if (_gameMode == GameMode.pvp) {
          _recordLeaderboard(_player2Name, _result.status, isPlayerX: false);
        }

      case GameStatus.oWon:
        bucket.o++;
        xp = 10;
        coins = 0;
        if (_gameMode == GameMode.pvp) {
          _recordLeaderboard(_player2Name, _result.status, isPlayerX: false);
          _recordLeaderboard(_playerXName, _result.status, isPlayerX: true);
        }

      case GameStatus.draw:
        bucket.draws++;
        xp = 20;
        coins = 5;
        _recordLeaderboard(_playerXName, _result.status, isPlayerX: true);
        if (_gameMode == GameMode.pvp) {
          _recordLeaderboard(_player2Name, _result.status, isPlayerX: false);
        }

      case GameStatus.playing:
        break;
    }

    // Speed mode XP bonus
    if (_variant == GameVariant.speed && isWin) xp += 15;

    _lastXpEarned = xp;
    _lastCoinsEarned = coins;

    if (xp > 0) _progressionService.addXp(xp);
    if (coins > 0) _progressionService.addCoins(coins);
  }

  Future<void> _recordLeaderboard(
    String name,
    GameStatus status, {
    required bool isPlayerX,
  }) async {
    try {
      await _scoreService.recordResult(
        playerName: name,
        status: status,
        isPlayerX: isPlayerX,
      );
      // Also push to Firebase global leaderboard
      await _fbLeaderboard.pushResult(
        playerName: name,
        status: status,
        isPlayerX: isPlayerX,
      );
    } catch (e) {
      debugPrint('[GameController] leaderboard record error: $e');
    }
  }

  // ── Hint system ───────────────────────────────────────────────────────────

  /// Computes and surfaces the best move for the human (current player).
  /// Called after a rewarded ad is earned.
  void applyHint() {
    if (_result.isOver || _boardLocked) return;
    try {
      final int hint = _computeHint();
      if (hint >= 0 && hint < _board.length && _board[hint] == Player.none) {
        _hintIndex = hint;
        if (!_isDisposed) notifyListeners();
      }
    } catch (e) {
      debugPrint('[GameController] hint error: $e');
    }
  }

  int _computeHint() {
    final Player human = _currentPlayer;
    if (_boardSize == BoardSize.three) {
      return GameLogic.getMinimaxMove(
        List<Player>.from(_board),
        human,
        Difficulty.hard,
      );
    } else {
      return AiService.getBestHeuristicMove(
        _board,
        human,
        gridSize: gridSize,
        winLength: winLength,
      );
    }
  }

  void _clearHint() {
    if (_hintIndex == null) return;
    _hintIndex = null;
  }

  bool get canUndo {
    if (_gameMode == GameMode.pvAI) {
      return _moveHistory.length >= 2 && !_result.isOver && !_isAIThinking;
    }
    return _moveHistory.isNotEmpty && !_result.isOver && !_isAIThinking;
  }

  void undoMove() {
    if (!canUndo) return;

    if (_gameMode == GameMode.pvAI) {
      // Undo AI move and Player move (last 2 moves if possible)
      if (_moveHistory.length >= 2) {
        final last = _moveHistory.removeLast();
        final secondLast = _moveHistory.removeLast();
        _board[last] = Player.none;
        _board[secondLast] = Player.none;
        _currentPlayer = Player.x;
      }
    } else {
      // Undo just the last move (PvP)
      final last = _moveHistory.removeLast();
      _board[last] = Player.none;
      _currentPlayer = _currentPlayer.opponent;
    }

    _clearHint();
    _result = const GameResult(status: GameStatus.playing);
    _boardLocked = false;
    notifyListeners();
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void resetGame() {
    _clearHint();
    _resetBoard();
    notifyListeners();
  }

  /// Resets only the current mode's scores. Other modes are untouched.
  void resetScores() {
    _scores[_gameMode]!.reset();
    notifyListeners();
  }

  void _resetBoard() {
    _generation++; // invalidate any in-flight AI Future.delayed callbacks
    _board = List<Player>.filled(_boardSize.cellCount, Player.none);
    _moveHistory.clear();
    _replayLog.clear();
    _currentPlayer = Player.x;
    _result = const GameResult(status: GameStatus.playing);
    _isAIThinking = false;
    _boardLocked = false;
  }

  // ── Dispose guard ─────────────────────────────────────────────────────────

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
