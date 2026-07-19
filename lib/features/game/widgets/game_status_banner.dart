import 'package:flutter/material.dart';
import 'package:tictactoe/core/constants/app_colors.dart';
import 'package:tictactoe/core/constants/app_text_styles.dart';
import 'package:tictactoe/core/models/game_models.dart';

class GameStatusBanner extends StatelessWidget {
  final GameResult result;
  final bool isAIThinking;
  final String playerXName;
  final String playerOName;
  final Player currentPlayer;

  const GameStatusBanner({
    super.key,
    required this.result,
    required this.isAIThinking,
    required this.currentPlayer,
    required this.playerXName,
    required this.playerOName,
  });

  String get _label {
    if (isAIThinking) return 'AI THINKING...';
    switch (result.status) {
      case GameStatus.playing:
        final name = currentPlayer == Player.x ? playerXName : playerOName;
        return '$name\'S TURN';
      case GameStatus.xWon:
        return '$playerXName WINS!';
      case GameStatus.oWon:
        return '$playerOName WINS!';
      case GameStatus.draw:
        return 'DRAW!';
    }
  }

  Color get _color {
    if (isAIThinking) return AppColors.textMuted;
    switch (result.status) {
      case GameStatus.playing:
        return currentPlayer == Player.x
            ? AppColors.playerX
            : AppColors.playerO;
      case GameStatus.xWon:
        return AppColors.playerX;
      case GameStatus.oWon:
        return AppColors.playerO;
      case GameStatus.draw:
        return AppColors.neonYellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: Text(
        _label,
        key: ValueKey(_label),
        style: AppTextStyles.displaySmall.copyWith(
          color: _color,
          shadows: [
            Shadow(color: _color.withValues(alpha: 0.7), blurRadius: 12),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
