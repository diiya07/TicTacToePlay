import 'dart:async';
import 'package:flutter/foundation.dart';

class SpeedTimerController extends ChangeNotifier {
  final int timeLimitSeconds;
  final VoidCallback onTimeout;

  Timer? _timer;
  int _secondsRemaining;

  SpeedTimerController({
    required this.timeLimitSeconds,
    required this.onTimeout,
  }) : _secondsRemaining = timeLimitSeconds;

  int get secondsRemaining => _secondsRemaining;

  void start() {
    _timer?.cancel();
    _secondsRemaining = timeLimitSeconds;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        timer.cancel();
        onTimeout();
      }
    });
  }

  void pause() {
    _timer?.cancel();
  }

  void reset() {
    _timer?.cancel();
    _secondsRemaining = timeLimitSeconds;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
