import 'package:flutter/material.dart';
import 'package:tictactoe/core/constants/app_colors.dart';
import 'package:tictactoe/core/constants/app_text_styles.dart';

/// Shows a dialog to rename a player. Returns the new name or null if cancelled.
Future<String?> showPlayerNameDialog(
  BuildContext context, {
  required String currentName,
  required bool isPlayerX,
}) {
  final controller = TextEditingController(text: currentName);
  final color = isPlayerX ? AppColors.playerX : AppColors.playerO;
  final label = isPlayerX ? 'PLAYER X NAME' : 'PLAYER O NAME';

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      title: Text(
        label,
        style: AppTextStyles.headlineLarge.copyWith(color: color),
      ),
      content: _NameTextField(controller: controller, color: color),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'CANCEL',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            ctx,
            controller.text.trim().isEmpty
                ? null
                : controller.text.trim().toUpperCase(),
          ),
          child: Text(
            'SAVE',
            style: AppTextStyles.labelLarge.copyWith(color: color),
          ),
        ),
      ],
    ),
  );
}

class _NameTextField extends StatelessWidget {
  final TextEditingController controller;
  final Color color;

  const _NameTextField({required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      maxLength: 12,
      textCapitalization: TextCapitalization.characters,
      style: AppTextStyles.headlineLarge.copyWith(color: Colors.white),
      cursorColor: color,
      decoration: InputDecoration(
        counterStyle: AppTextStyles.bodyMedium,
        hintText: 'Enter name...',
        hintStyle: AppTextStyles.bodyMedium,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: color.withValues(alpha: 0.4)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: color, width: 2),
        ),
      ),
    );
  }
}
