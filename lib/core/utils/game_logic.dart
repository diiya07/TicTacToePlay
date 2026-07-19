
import 'dart:math';

import 'package:tictactoe/core/models/game_models.dart';

/// Pure game rules — no UI, no state.
/// All methods are stateless and safe for concurrent use.
class GameLogic {
  GameLogic._();

  // ── Win detection ──────────────────────────────────────────────────────────
  //
  // Fully dynamic: works for any grid size and any win length.
  // No hardcoded patterns — iterates every cell in 4 directions.
  //
  // Directions: horizontal →, vertical ↓, diagonal ↘, diagonal ↙
  static const List<List<int>> _directions = [
    [0, 1],
    [1, 0],
    [1, 1],
    [1, -1],
  ];

  /// Returns a [GameResult] for the given [board].
  ///
  /// [gridSize]  — side length (3 for 3×3, 5 for 5×5).
  /// [winLength] — consecutive symbols required to win.
  ///
  /// Guarantees: no RangeError, no invalid index access.
  static GameResult checkWinner(
    List<Player> board,
    int gridSize,
    int winLength,
  ) {
    final int total = gridSize * gridSize;
    // Defensive: board must be exactly gridSize² in length.
    if (board.length != total) {
      assert(
        false,
        'checkWinner: board.length=${board.length}, expected $total',
      );
      return const GameResult(status: GameStatus.playing);
    }

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final int startIdx = row * gridSize + col;
        final Player player = board[startIdx];
        if (player == Player.none) continue;

        for (final List<int> dir in _directions) {
          final int dr = dir[0];
          final int dc = dir[1];

          // Fast boundary pre-check: does the sequence fit on the board?
          final int endRow = row + dr * (winLength - 1);
          final int endCol = col + dc * (winLength - 1);
          if (endRow < 0 || endRow >= gridSize) continue;
          if (endCol < 0 || endCol >= gridSize) continue;

          // Collect consecutive matching indices.
          final List<int> indices = <int>[];
          bool match = true;

          for (int k = 0; k < winLength; k++) {
            final int r = row + k * dr;
            final int c = col + k * dc;

            // Double-safety: row/col + computed index bounds.
            if (r < 0 || r >= gridSize || c < 0 || c >= gridSize) {
              match = false;
              break;
            }
            final int idx = r * gridSize + c;
            if (idx < 0 || idx >= total) {
              match = false;
              break;
            }
            if (board[idx] != player) {
              match = false;
              break;
            }
            indices.add(idx);
          }

          if (match && indices.length == winLength) {
            return GameResult(
              status: player == Player.x ? GameStatus.xWon : GameStatus.oWon,
              winningLine: List<int>.unmodifiable(indices),
            );
          }
        }
      }
    }

    if (!board.contains(Player.none)) {
      return const GameResult(status: GameStatus.draw);
    }
    return const GameResult(status: GameStatus.playing);
  }

  // ── 3×3 Minimax (untouched logic, now uses generic checkWinner) ───────────

  /// Entry point for 3×3 AI. Routes by difficulty.
  static int getMinimaxMove(
    List<Player> board,
    Player aiPlayer,
    Difficulty difficulty,
  ) {
    switch (difficulty) {
      case Difficulty.easy:
        return getRandomMove(board);
      case Difficulty.medium:
        return Random().nextDouble() < 0.6
            ? _getBestMove3x3(board, aiPlayer)
            : getRandomMove(board);
      case Difficulty.hard:
        return _getBestMove3x3(board, aiPlayer);
    }
  }

  static int _getBestMove3x3(List<Player> board, Player aiPlayer) {
    int bestScore = -1000;
    int bestMove = -1;
    for (int i = 0; i < board.length; i++) {
      if (board[i] == Player.none) {
        board[i] = aiPlayer;
        final int score = _minimax3x3(board, 0, false, aiPlayer);
        board[i] = Player.none;
        if (score > bestScore) {
          bestScore = score;
          bestMove = i;
        }
      }
    }
    return bestMove;
  }

  static int _minimax3x3(
    List<Player> board,
    int depth,
    bool isMaximizing,
    Player aiPlayer,
  ) {
    // Reuse generic checkWinner with fixed 3×3 params.
    final GameResult result = checkWinner(board, 3, 3);
    if (result.status ==
        (aiPlayer == Player.x ? GameStatus.xWon : GameStatus.oWon)) {
      return 10 - depth;
    }
    if (result.status ==
        (aiPlayer == Player.x ? GameStatus.oWon : GameStatus.xWon)) {
      return depth - 10;
    }
    if (result.status == GameStatus.draw) return 0;

    if (isMaximizing) {
      int best = -1000;
      for (int i = 0; i < board.length; i++) {
        if (board[i] == Player.none) {
          board[i] = aiPlayer;
          best = max(best, _minimax3x3(board, depth + 1, false, aiPlayer));
          board[i] = Player.none;
        }
      }
      return best;
    } else {
      int best = 1000;
      for (int i = 0; i < board.length; i++) {
        if (board[i] == Player.none) {
          board[i] = aiPlayer.opponent;
          best = min(best, _minimax3x3(board, depth + 1, true, aiPlayer));
          board[i] = Player.none;
        }
      }
      return best;
    }
  }

  // ── Shared utilities ───────────────────────────────────────────────────────

  /// Returns a random empty cell index, or -1 if board is full.
  static int getRandomMove(List<Player> board) {
    final List<int> available = <int>[
      for (int i = 0; i < board.length; i++)
        if (board[i] == Player.none) i,
    ];
    if (available.isEmpty) return -1;
    return available[Random().nextInt(available.length)];
  }

  /// Returns a list of all empty cell indices.
  static List<int> availableMoves(List<Player> board) => <int>[
    for (int i = 0; i < board.length; i++)
      if (board[i] == Player.none) i,
  ];

  // ── Variant Logic ──────────────────────────────────────────────────────────

  /// Applies gravity to a column, returning the lowest empty row index,
  /// or -1 if the column is full.
  static int applyGravity(List<Player> board, int col, int gridSize) {
    for (int row = gridSize - 1; row >= 0; row--) {
      int idx = row * gridSize + col;
      if (board[idx] == Player.none) {
        return idx;
      }
    }
    return -1;
  }

  /// Validates if a power-up can be used by the given player.
  static bool checkPowerUpValidity(
    PowerUpType type,
    List<Player> board,
    Player player,
  ) {
    switch (type) {
      case PowerUpType.blockOpponent:
        return board.contains(Player.none);
      case PowerUpType.doubleMark:
        return board.where((p) => p == Player.none).length >= 2;
      case PowerUpType.shuffle:
        return board.where((p) => p != Player.none).length > 2;
      case PowerUpType.freeze:
        return true;
    }
  }
}
