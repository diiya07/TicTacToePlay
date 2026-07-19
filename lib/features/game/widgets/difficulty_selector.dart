import 'package:flutter/material.dart';
import 'package:tictactoe/core/constants/app_colors.dart';
import 'package:tictactoe/core/constants/app_text_styles.dart';
import 'package:tictactoe/core/models/game_models.dart';

class DifficultySelector extends StatelessWidget {
  final Difficulty selected;
  final ValueChanged<Difficulty> onChanged;

  const DifficultySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  Color _colorFor(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return AppColors.diffEasy;
      case Difficulty.medium:
        return AppColors.diffMedium;
      case Difficulty.hard:
        return AppColors.diffHard;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: Difficulty.values.map((d) {
        final isSelected = d == selected;
        final color = _colorFor(d);
        return GestureDetector(
          onTap: () => onChanged(d),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : AppColors.borderDefault,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              d.label,
              style: AppTextStyles.labelLarge.copyWith(
                color: isSelected ? color : AppColors.textMuted,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
