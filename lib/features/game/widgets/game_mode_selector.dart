
import 'package:flutter/material.dart';
import 'package:tictactoe/core/constants/app_colors.dart';
import 'package:tictactoe/core/constants/app_text_styles.dart';
import 'package:tictactoe/core/models/game_models.dart';

class GameModeSelector extends StatelessWidget {
  final GameMode selected;
  final ValueChanged<GameMode> onChanged;

  const GameModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  String _labelFor(GameMode m) {
    switch (m) {
      case GameMode.pvp:
        return '1v1';
      case GameMode.pvAI:
        return 'vs AI';
      case GameMode.online:
        return 'ONLINE';
    }
  }

  IconData _iconFor(GameMode m) {
    switch (m) {
      case GameMode.pvp:
        return Icons.people_rounded;
      case GameMode.pvAI:
        return Icons.smart_toy_rounded;
      case GameMode.online:
        return Icons.wifi_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: GameMode.values.map((m) {
          final isSelected = m == selected;
          final itemColor = isSelected
              ? AppColors.neonPurple
              : AppColors.textSecondary;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.neonPurple.withValues(alpha: 0.25)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.neonPurple
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_iconFor(m), size: 14, color: itemColor),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        _labelFor(m),
                        style: AppTextStyles.labelLarge.copyWith(
                          color: itemColor,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
