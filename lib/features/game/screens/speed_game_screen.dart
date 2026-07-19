import 'package:flutter/material.dart';
import 'package:tictactoe/core/constants/app_colors.dart';
import 'package:tictactoe/core/constants/app_text_styles.dart';
import 'package:tictactoe/features/game/controllers/game_controller.dart';
import 'package:tictactoe/features/game/controllers/speed_timer_controller.dart';

class SpeedGameScreen extends StatefulWidget {
  final GameController controller;

  const SpeedGameScreen({super.key, required this.controller});

  @override
  State<SpeedGameScreen> createState() => _SpeedGameScreenState();
}

class _SpeedGameScreenState extends State<SpeedGameScreen> {
  late SpeedTimerController _timerController;

  @override
  void initState() {
    super.initState();
    _timerController = SpeedTimerController(
      timeLimitSeconds: 5, // 5 seconds per turn
      onTimeout: () {
        // Handle timeout - forfeit turn or auto-lose
        // Need to wire this to GameController later
      },
    );
    _timerController.start();
    widget.controller.addListener(_onGameStateChanged);
  }

  void _onGameStateChanged() {
    if (widget.controller.result.isOver) {
      _timerController.pause();
    } else {
      _timerController.reset();
      _timerController.start();
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
    widget.controller.removeListener(_onGameStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListenableBuilder(
          listenable: _timerController,
          builder: (context, _) {
            final isUrgent = _timerController.secondsRemaining <= 2;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isUrgent ? AppColors.neonPink : AppColors.neonCyan,
                  width: isUrgent ? 2 : 1,
                ),
              ),
              child: Text(
                '00:0${_timerController.secondsRemaining}',
                style: AppTextStyles.displaySmall.copyWith(
                  color: isUrgent ? AppColors.neonPink : AppColors.neonCyan,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
