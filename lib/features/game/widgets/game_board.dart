import 'package:flutter/material.dart';
import 'package:tictactoe/core/models/game_models.dart';
import 'package:tictactoe/features/game/widgets/board_cell.dart';
import 'package:tictactoe/features/game/widgets/win_line_overlay.dart';

/// Padding around the board grid — shared with WinLineOverlay so the
/// win-line painter stays perfectly aligned with cell centres.
const double kBoardPadding = 16.0;

class GameBoard extends StatelessWidget {
  final List<Player> board;
  final List<int> winningCells;
  final bool isEnabled;
  final int gridSize;
  final int? hintIndex;
  final Color? themeColor;
  final void Function(int) onCellTap;

  /// Whose turn it is — used to show the correct hover ghost symbol.
  final Player currentPlayer;

  const GameBoard({
    super.key,
    required this.board,
    required this.onCellTap,
    required this.gridSize,
    this.winningCells = const [],
    this.hintIndex,
    this.isEnabled = true,
    this.themeColor,
    this.currentPlayer = Player.x, // safe default
  });

  /// Font size scales inversely with grid size to keep symbols readable.
  double get _fontSize {
    switch (gridSize) {
      case 3:
        return 40;
      case 5:
        return 26;
      default:
        return (120 / gridSize).clamp(16, 40);
    }
  }

  /// Gap between cells — tighter on larger grids.
  double get _gap => gridSize <= 3 ? 12 : 8;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenH = MediaQuery.of(context).size.height;
        final double availW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width * 0.55;

        // Never taller than 80% of visible screen height.
        final double maxH = screenH * 0.80;
        const double hardCap = 500.0;

        final double size = [
          availW,
          maxH,
          hardCap,
        ].reduce((a, b) => a < b ? a : b);

        return SizedBox(
          width: size,
          height: size,
          child: WinLineOverlay(
            winningCells: winningCells,
            gridSize: gridSize,
            themeColor: themeColor,
            boardPadding: kBoardPadding, // keeps win-line painter in sync
            child: GridView.builder(
              padding: const EdgeInsets.all(kBoardPadding),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridSize,
                crossAxisSpacing: _gap,
                mainAxisSpacing: _gap,
              ),
              itemCount: board.length,
              itemBuilder: (context, i) {
                // Defensive: never render beyond board length
                if (i >= board.length) return const SizedBox.shrink();
                return BoardCell(
                  key: ValueKey('cell_${gridSize}_$i'),
                  index: i,
                  player: board[i],
                  fontSize: _fontSize,
                  isWinningCell: winningCells.contains(i),
                  isHinted: hintIndex == i,
                  isEnabled: isEnabled,
                  themeColor: themeColor,
                  currentPlayer: currentPlayer,
                  onTap: () => onCellTap(i),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
