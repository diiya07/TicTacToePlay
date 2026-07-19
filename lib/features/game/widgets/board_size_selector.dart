import 'package:flutter/material.dart';
import 'package:tictactoe/core/constants/app_colors.dart';
import 'package:tictactoe/core/constants/app_text_styles.dart';
import 'package:tictactoe/core/models/game_models.dart';

/// Toggle between 3×3 and 5×5. Same visual language as DifficultySelector.
class BoardSizeSelector extends StatelessWidget {
  final BoardSize selected;
  final ValueChanged<BoardSize> onChanged;

  const BoardSizeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  Color _colorFor(BoardSize s) =>
      s == BoardSize.three ? AppColors.neonCyan : AppColors.neonPink;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: BoardSize.values.map((s) {
            final bool isSelected = s == selected;
            final Color color = _colorFor(s);
            return GestureDetector(
              onTap: () => onChanged(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
                  s.label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isSelected ? color : AppColors.textMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
