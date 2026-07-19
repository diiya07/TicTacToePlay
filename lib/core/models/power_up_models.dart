import 'package:tictactoe/core/models/game_models.dart';

class PowerUp {
  final PowerUpType type;
  final String name;
  final String description;
  final int cooldownTurns;
  final int coinCost;

  const PowerUp({
    required this.type,
    required this.name,
    required this.description,
    required this.cooldownTurns,
    required this.coinCost,
  });

  static const List<PowerUp> availablePowerUps = [
    PowerUp(
      type: PowerUpType.blockOpponent,
      name: 'Block',
      description: 'Block a cell so your opponent cannot play there.',
      cooldownTurns: 3,
      coinCost: 50,
    ),
    PowerUp(
      type: PowerUpType.doubleMark,
      name: 'Double',
      description: 'Play twice in a single turn.',
      cooldownTurns: 4,
      coinCost: 100,
    ),
    PowerUp(
      type: PowerUpType.shuffle,
      name: 'Shuffle',
      description: 'Randomly shuffle the board pieces.',
      cooldownTurns: 5,
      coinCost: 150,
    ),
    PowerUp(
      type: PowerUpType.freeze,
      name: 'Freeze',
      description: 'Skip your opponent\'s next turn.',
      cooldownTurns: 4,
      coinCost: 120,
    ),
  ];

  static PowerUp getByType(PowerUpType type) {
    return availablePowerUps.firstWhere((p) => p.type == type);
  }
}
