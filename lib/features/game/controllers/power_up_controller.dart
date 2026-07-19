import 'package:flutter/foundation.dart';
import 'package:tictactoe/core/models/game_models.dart';
import 'package:tictactoe/core/models/power_up_models.dart';

class PowerUpState {
  final PowerUp powerUp;
  int currentCooldown;
  bool isAvailable;

  PowerUpState({
    required this.powerUp,
    this.currentCooldown = 0,
    this.isAvailable = true,
  });
}

class PowerUpController extends ChangeNotifier {
  final Map<Player, List<PowerUpState>> _playerPowerUps = {};
  
  PowerUpType? _activePowerUp;
  Player? _activePlayer;

  PowerUpController() {
    _initPowerUps();
  }

  void _initPowerUps() {
    // Give each player a default set of power-ups for now
    _playerPowerUps[Player.x] = PowerUp.availablePowerUps
        .map((p) => PowerUpState(powerUp: p))
        .toList();
    _playerPowerUps[Player.o] = PowerUp.availablePowerUps
        .map((p) => PowerUpState(powerUp: p))
        .toList();
  }

  List<PowerUpState> getPowerUps(Player player) {
    return _playerPowerUps[player] ?? [];
  }

  PowerUpType? get activePowerUp => _activePowerUp;

  void activatePowerUp(Player player, PowerUpType type) {
    final states = _playerPowerUps[player];
    if (states == null) return;
    
    final state = states.firstWhere((s) => s.powerUp.type == type);
    if (!state.isAvailable || state.currentCooldown > 0) return;

    _activePowerUp = type;
    _activePlayer = player;
    notifyListeners();
  }

  void consumeActivePowerUp() {
    if (_activePowerUp == null || _activePlayer == null) return;

    final states = _playerPowerUps[_activePlayer];
    if (states != null) {
      final state = states.firstWhere((s) => s.powerUp.type == _activePowerUp);
      state.currentCooldown = state.powerUp.cooldownTurns;
    }

    _activePowerUp = null;
    _activePlayer = null;
    notifyListeners();
  }

  void cancelActivePowerUp() {
    _activePowerUp = null;
    _activePlayer = null;
    notifyListeners();
  }

  void decrementCooldowns(Player player) {
    final states = _playerPowerUps[player];
    if (states == null) return;

    bool changed = false;
    for (var state in states) {
      if (state.currentCooldown > 0) {
        state.currentCooldown--;
        changed = true;
      }
    }
    
    if (changed) notifyListeners();
  }
}
