import 'package:flutter/material.dart';
import 'package:tictactoe/core/constants/app_colors.dart';

/// Draws an animated neon win line over the board grid.
/// Cell centres are computed dynamically for any [gridSize].
class WinLinePainter extends CustomPainter {
  final List<int> winningCells;
  final double progress;
  final int gridSize;
  final Color? themeColor;
  final double gap;
  final double padding;

  WinLinePainter({
    required this.winningCells,
    required this.progress,
    required this.gridSize,
    required this.gap,
    required this.padding,
    this.themeColor,
  });

  Offset _cellCenter(int index, Size size) {
    final int col = index % gridSize;
    final int row = index ~/ gridSize;

    final double totalGap = gap * (gridSize - 1);
    final double cellSize = (size.width - padding * 2 - totalGap) / gridSize;

    return Offset(
      padding + col * (cellSize + gap) + cellSize / 2,
      padding + row * (cellSize + gap) + cellSize / 2,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (winningCells.length < 2 || progress == 0) return;

    final Offset start = _cellCenter(winningCells.first, size);
    final Offset end = _cellCenter(winningCells.last, size);

    final Paint paint = Paint()
      ..color = themeColor ?? AppColors.winLine
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Glowing effect
    final Paint glowPaint = Paint()
      ..color = (themeColor ?? AppColors.winLine).withValues(alpha: 0.3)
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Offset currentEnd = Offset(
      start.dx + (end.dx - start.dx) * progress,
      start.dy + (end.dy - start.dy) * progress,
    );

    canvas.drawLine(start, currentEnd, glowPaint);
    canvas.drawLine(start, currentEnd, paint);
  }

  @override
  bool shouldRepaint(WinLinePainter old) {
    return old.progress != progress ||
        old.winningCells != winningCells ||
        old.gridSize != gridSize ||
        old.themeColor != themeColor ||
        old.gap != gap ||
        old.padding != padding;
  }
}

class WinLineOverlay extends StatefulWidget {
  final Widget child;
  final List<int> winningCells;
  final int gridSize;
  final Color? themeColor;
  final double boardPadding;

  const WinLineOverlay({
    super.key,
    required this.child,
    required this.winningCells,
    required this.gridSize,
    required this.boardPadding,
    this.themeColor,
  });

  @override
  State<WinLineOverlay> createState() => _WinLineOverlayState();
}

class _WinLineOverlayState extends State<WinLineOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _lineAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _lineAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
    if (widget.winningCells.isNotEmpty) _ctrl.forward();
  }

  @override
  void didUpdateWidget(WinLineOverlay old) {
    super.didUpdateWidget(old);
    if (widget.winningCells.isNotEmpty && old.winningCells.isEmpty) {
      _ctrl.forward(from: 0);
    } else if (widget.winningCells.isEmpty) {
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _lineAnim,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: WinLinePainter(
            winningCells: widget.winningCells,
            progress: _lineAnim.value,
            gridSize: widget.gridSize,
            gap: widget.gridSize <= 3 ? 12 : 8,
            padding: widget.boardPadding,
            themeColor: widget.themeColor,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
