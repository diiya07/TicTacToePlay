import 'package:flutter/material.dart';
import 'package:tictactoe/core/constants/app_colors.dart';
import 'package:tictactoe/features/game/controllers/game_controller.dart';

class GravityGameScreen extends StatelessWidget {
  final GameController controller;

  const GravityGameScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonPurple, width: 2),
      ),
      child: const Text(
        'GRAVITY MODE ACTIVE',
        style: TextStyle(
          fontFamily: 'Orbitron',
          color: AppColors.neonPurple,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
