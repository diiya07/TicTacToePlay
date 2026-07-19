import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:tictactoe/core/models/game_models.dart';

class DailyChallengeService extends ChangeNotifier {
  static final DailyChallengeService _instance = DailyChallengeService._internal();

  factory DailyChallengeService() => _instance;
  DailyChallengeService._internal();

  final FirebaseDatabase _db = FirebaseDatabase.instance;
  
  DailyChallenge? _currentChallenge;
  bool _isLoading = false;

  DailyChallenge? get currentChallenge => _currentChallenge;
  bool get isLoading => _isLoading;

  Future<void> fetchDailyChallenge() async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      // YYYY-MM-DD
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final snapshot = await _db.ref('daily_challenges/$dateStr').get();
      
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        
        final variantStr = data['variant'] as String? ?? 'classic';
        final variant = GameVariant.values.firstWhere(
            (e) => e.name == variantStr, 
            orElse: () => GameVariant.classic);
            
        final presetList = data['boardPreset'] as List<dynamic>? ?? [];
        final boardPreset = presetList.map((e) {
          final s = e.toString();
          if (s == 'x') return Player.x;
          if (s == 'o') return Player.o;
          return Player.none;
        }).toList();

        _currentChallenge = DailyChallenge(
          id: dateStr,
          date: now,
          variant: variant,
          boardPreset: boardPreset.length >= 9 ? boardPreset : List.filled(9, Player.none),
          rewardCoins: data['rewardCoins'] as int? ?? 50,
          rewardXp: data['rewardXp'] as int? ?? 100,
        );
      } else {
        // Fallback or empty challenge
        _currentChallenge = null;
      }
    } catch (e) {
      debugPrint('[DailyChallengeService] Failed to fetch: $e');
      _currentChallenge = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
