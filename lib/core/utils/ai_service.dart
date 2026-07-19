import 'dart:math';
import 'package:tictactoe/core/models/game_models.dart';

import 'game_logic.dart';

/// Heuristic AI engine for 5×5 (and any future large grid).
///
/// Priority order:
///   1. Win immediately if possible
///   2. Block opponent's winning move
///   3. Prefer centre cell
///   4. Prefer corner cells
///   5. Prefer cells adjacent to own existing pieces (clustering)
///   6. Random fallback
///
/// Minimax is NOT used here — O(b^d) explodes on 5×5.
class AiService {
  AiService._();

  // ── Public entry points ───────────────────────────────────────────────────

  /// Returns the AI's chosen move index for a large grid.
  static int getHeuristicMove(
    List<Player> board,
    Player aiPlayer,
    Difficulty difficulty, {
    required int gridSize,
    required int winLength,
  }) {
    switch (difficulty) {
      case Difficulty.easy:
        return GameLogic.getRandomMove(board);
      case Difficulty.medium:
        return Random().nextDouble() < 0.5
            ? _heuristicMove(board, aiPlayer, gridSize, winLength)
            : GameLogic.getRandomMove(board);
      case Difficulty.hard:
        return _heuristicMove(board, aiPlayer, gridSize, winLength);
    }
  }

  /// Returns the best move for [player] — used by the hint system.
  /// Does NOT depend on difficulty; always returns the strongest move.
  static int getBestHeuristicMove(
    List<Player> board,
    Player player, {
    required int gridSize,
    required int winLength,
  }) =>
      _heuristicMove(board, player, gridSize, winLength);

  // ── Core heuristic ────────────────────────────────────────────────────────

  static int _heuristicMove(
    List<Player> board,
    Player player,
    int gridSize,
    int winLength,
  ) {
    // 1. Winning move for AI.
    final int win = _findThreat(board, player, gridSize, winLength);
    if (win != -1) return win;

    // 2. Block opponent's winning move.
    final int block =
        _findThreat(board, player.opponent, gridSize, winLength);
    if (block != -1) return block;

    // 3. Near-win: prefer moves that create the most threats.
    final int threatMove =
        _highestThreatMove(board, player, gridSize, winLength);
    if (threatMove != -1) return threatMove;

    // 4. Centre.
    final int centre = (gridSize * gridSize) ~/ 2;
    if (board[centre] == Player.none) return centre;

    // 5. Corners.
    final List<int> corners = [
      0,
      gridSize - 1,
      gridSize * (gridSize - 1),
      gridSize * gridSize - 1,
    ];
    final List<int> freeCorners =
        corners.where((i) => board[i] == Player.none).toList();
    if (freeCorners.isNotEmpty) {
      return freeCorners[Random().nextInt(freeCorners.length)];
    }

    // 6. Adjacent to own pieces (clustering).
    final int adjacent =
        _bestAdjacentMove(board, player, gridSize);
    if (adjacent != -1) return adjacent;

    // 7. Random fallback.
    return GameLogic.getRandomMove(board);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns a move that immediately completes [winLength] for [player],
  /// or -1 if none exists.
  static int _findThreat(
    List<Player> board,
    Player player,
    int gridSize,
    int winLength,
  ) {
    final List<Player> copy = List<Player>.from(board);
    for (int i = 0; i < board.length; i++) {
      if (board[i] != Player.none) continue;
      copy[i] = player;
      final GameResult result = GameLogic.checkWinner(copy, gridSize, winLength);
      copy[i] = Player.none;
      if (result.hasWinner) return i;
    }
    return -1;
  }

  /// Returns the move that maximises the number of new [winLength-1] threats
  /// for [player]. Breaks ties randomly.
  static int _highestThreatMove(
    List<Player> board,
    Player player,
    int gridSize,
    int winLength,
  ) {
    final int nearWin = winLength - 1;
    if (nearWin < 2) return -1;

    int bestScore = 0;
    final List<int> bestMoves = <int>[];
    final List<Player> copy = List<Player>.from(board);

    for (int i = 0; i < board.length; i++) {
      if (board[i] != Player.none) continue;
      copy[i] = player;
      final int score = _countSequences(copy, player, gridSize, nearWin);
      copy[i] = Player.none;

      if (score > bestScore) {
        bestScore = score;
        bestMoves
          ..clear()
          ..add(i);
      } else if (score == bestScore && bestScore > 0) {
        bestMoves.add(i);
      }
    }

    if (bestMoves.isEmpty) return -1;
    return bestMoves[Random().nextInt(bestMoves.length)];
  }

  /// Counts how many sequences of exactly [length] for [player] exist.
  static int _countSequences(
    List<Player> board,
    Player player,
    int gridSize,
    int length,
  ) {
    const List<List<int>> directions = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];
    int count = 0;

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        for (final List<int> dir in directions) {
          final int dr = dir[0], dc = dir[1];
          final int endRow = row + dr * (length - 1);
          final int endCol = col + dc * (length - 1);
          if (endRow < 0 || endRow >= gridSize) continue;
          if (endCol < 0 || endCol >= gridSize) continue;

          bool match = true;
          for (int k = 0; k < length; k++) {
            final int r = row + k * dr;
            final int c = col + k * dc;
            if (r < 0 || r >= gridSize || c < 0 || c >= gridSize) {
              match = false;
              break;
            }
            final int idx = r * gridSize + c;
            if (idx < 0 || idx >= board.length || board[idx] != player) {
              match = false;
              break;
            }
          }
          if (match) count++;
        }
      }
    }
    return count;
  }

  /// Returns the empty cell most adjacent to existing [player] pieces.
  /// Scores each candidate by how many friendly neighbours it has.
  static int _bestAdjacentMove(
    List<Player> board,
    Player player,
    int gridSize,
  ) {
    final Map<int, int> scores = <int, int>{};

    for (int i = 0; i < board.length; i++) {
      if (board[i] != player) continue;
      final int row = i ~/ gridSize;
      final int col = i % gridSize;

      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          final int r = row + dr;
          final int c = col + dc;
          if (r < 0 || r >= gridSize || c < 0 || c >= gridSize) continue;
          final int idx = r * gridSize + c;
          if (idx < 0 || idx >= board.length) continue;
          if (board[idx] != Player.none) continue;
          scores[idx] = (scores[idx] ?? 0) + 1;
        }
      }
    }

    if (scores.isEmpty) return -1;

    // Pick the highest-scored candidate, break ties randomly.
    final int maxScore = scores.values.reduce(max);
    final List<int> best =
        scores.entries.where((e) => e.value == maxScore).map((e) => e.key).toList();
    return best[Random().nextInt(best.length)];
  }
}
