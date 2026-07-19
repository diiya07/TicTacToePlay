import 'package:flutter/material.dart';
import 'package:tictactoe/core/constants/app_colors.dart';
import 'package:tictactoe/core/constants/app_text_styles.dart';
import 'package:tictactoe/core/models/game_models.dart';

class BoardCell extends StatefulWidget {
  final Player player;
  final bool isWinningCell;
  final bool isHinted;     // ← highlight this cell as the hint
  final bool isEnabled;
  final VoidCallback onTap;
  final int index;
  final double fontSize;   // ← scales for 3×3 vs 5×5
  final Color? themeColor;
  final Player currentPlayer; // ← whose turn it is (for hover ghost)

  const BoardCell({
    super.key,
    required this.player,
    required this.onTap,
    required this.index,
    required this.fontSize,
    this.isWinningCell = false,
    this.isHinted = false,
    this.isEnabled = true,
    this.themeColor,
    this.currentPlayer = Player.x, // safe default
  });

  @override
  State<BoardCell> createState() => _BoardCellState();
}

class _BoardCellState extends State<BoardCell>
    with TickerProviderStateMixin {
  // ── Symbol scale-in animation ───────────────────────────────────────────
  late final AnimationController _symbolCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _glowAnim;

  // ── Hint pulse animation ────────────────────────────────────────────────
  AnimationController? _hintCtrl;
  Animation<double>? _hintAnim;

  @override
  void initState() {
    super.initState();
    _symbolCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _symbolCtrl, curve: Curves.elasticOut),
    );
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _symbolCtrl, curve: Curves.easeOut),
    );

    if (widget.player != Player.none) _symbolCtrl.forward();
    if (widget.isHinted) _startHintPulse();
  }

  @override
  void didUpdateWidget(BoardCell old) {
    super.didUpdateWidget(old);

    // Symbol animation
    if (old.player == Player.none && widget.player != Player.none) {
      _symbolCtrl.forward(from: 0);
    }
    if (widget.player == Player.none) _symbolCtrl.reset();

    // Hint animation
    if (widget.isHinted && !old.isHinted) _startHintPulse();
    if (!widget.isHinted && old.isHinted) _stopHintPulse();
  }

  void _startHintPulse() {
    _hintCtrl ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _hintAnim = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _hintCtrl!, curve: Curves.easeInOut),
    );
  }

  void _stopHintPulse() {
    _hintCtrl?.stop();
    _hintCtrl?.dispose();
    _hintCtrl = null;
    _hintAnim = null;
  }

  @override
  void dispose() {
    _symbolCtrl.dispose();
    _hintCtrl?.dispose();
    super.dispose();
  }

  Color get _playerColor {
    if (widget.isWinningCell) return widget.themeColor ?? AppColors.winLine;
    return widget.player == Player.x ? AppColors.playerX : AppColors.playerO;
  }

  Color get _hintColor => widget.themeColor ?? AppColors.neonPurple;

  @override
  Widget build(BuildContext context) {
    final bool hasPlayer = widget.player != Player.none;
    final bool showHint = widget.isHinted && !hasPlayer;

    return GestureDetector(
      onTap: hasPlayer || !widget.isEnabled ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _symbolCtrl,
          ...[_hintCtrl].whereType<AnimationController>(),
        ]),
        builder: (context, _) {
          final double hintOpacity =
              showHint ? (_hintAnim?.value ?? 0.5) : 0.0;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: showHint
                    ? _hintColor.withValues(alpha: hintOpacity)
                    : widget.isWinningCell
                        ? AppColors.winLine
                        : hasPlayer
                            ? _playerColor.withValues(alpha: 0.6)
                            : AppColors.borderDefault,
                width: (widget.isWinningCell || showHint) ? 2.5 : 1.5,
              ),
              boxShadow: [
                if (hasPlayer)
                  BoxShadow(
                    color: _playerColor.withValues(alpha: 0.35 * _glowAnim.value),
                    blurRadius: widget.isWinningCell ? 24 : 16,
                    spreadRadius: widget.isWinningCell ? 2 : 0,
                  ),
                if (showHint)
                  BoxShadow(
                    color: _hintColor.withValues(alpha: 0.4 * hintOpacity),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Center(
              child: hasPlayer
                  ? Transform.scale(
                      scale: _scaleAnim.value,
                      child: Text(
                        widget.player.symbol,
                        style: AppTextStyles.cellSymbol.copyWith(
                          fontSize: widget.fontSize,
                          color: _playerColor,
                          shadows: [
                            Shadow(
                              color: _playerColor.withValues(alpha: 0.8),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                      ),
                    )
                  : widget.isEnabled && !showHint
                      ? _HoverIndicator(
                          fontSize: widget.fontSize,
                          currentPlayer: widget.currentPlayer,
                        )
                      : null,
            ),
          );
        },
      ),
    );
  }
}

// ── Web-only hover ghost ──────────────────────────────────────────────────────

class _HoverIndicator extends StatefulWidget {
  final double fontSize;
  final Player currentPlayer;
  const _HoverIndicator({
    required this.fontSize,
    required this.currentPlayer,
  });

  @override
  State<_HoverIndicator> createState() => _HoverIndicatorState();
}

class _HoverIndicatorState extends State<_HoverIndicator> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final Color hoverColor = widget.currentPlayer == Player.x
        ? AppColors.playerX
        : AppColors.playerO;
    return MouseRegion(
      onEnter: (event) => setState(() => _hovering = true),
      onExit: (event) => setState(() => _hovering = false),
      child: AnimatedOpacity(
        opacity: _hovering ? 0.35 : 0.0,
        duration: const Duration(milliseconds: 150),
        child: Text(
          widget.currentPlayer.symbol,
          style: AppTextStyles.cellSymbol.copyWith(
            fontSize: widget.fontSize,
            color: hoverColor,
          ),
        ),
      ),
    );
  }
}
