import 'package:flutter/material.dart';
import 'package:tictactoe/core/constants/app_colors.dart';
import 'package:tictactoe/features/game/controllers/game_controller.dart';
import 'package:tictactoe/features/game/controllers/power_up_controller.dart';

class PowerUpGameScreen extends StatefulWidget {
  final GameController gameController;

  const PowerUpGameScreen({super.key, required this.gameController});

  @override
  State<PowerUpGameScreen> createState() => _PowerUpGameScreenState();
}

class _PowerUpGameScreenState extends State<PowerUpGameScreen> {
  late PowerUpController _powerUpController;

  @override
  void initState() {
    super.initState();
    _powerUpController = PowerUpController();
    widget.gameController.addListener(_onTurnChanged);
  }

  void _onTurnChanged() {
    // Decrement cooldowns on turn change
    // This is a simplified approach, actual logic might need to distinguish 
    // exactly when a turn "completes" vs just changing player
  }

  @override
  void dispose() {
    widget.gameController.removeListener(_onTurnChanged);
    _powerUpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _powerUpController,
      builder: (context, _) {
        final powerUps = _powerUpController.getPowerUps(widget.gameController.currentPlayer);
        
        return Container(
          height: 80,
          margin: const EdgeInsets.only(top: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: powerUps.length,
            itemBuilder: (context, index) {
              final state = powerUps[index];
              final isCoolingDown = state.currentCooldown > 0;
              final isActive = _powerUpController.activePowerUp == state.powerUp.type;
              
              return GestureDetector(
                onTap: () {
                  if (!isCoolingDown) {
                    _powerUpController.activatePowerUp(
                      widget.gameController.currentPlayer, 
                      state.powerUp.type
                    );
                  }
                },
                child: Container(
                  width: 64,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.neonGold : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCoolingDown ? AppColors.textMuted : AppColors.neonCyan,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.flash_on, 
                          color: isCoolingDown ? AppColors.textMuted : 
                                 isActive ? AppColors.background : AppColors.neonCyan,
                        ),
                        if (isCoolingDown)
                          Text(
                            '${state.currentCooldown}',
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
