import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:tictactoe/core/models/game_models.dart';
import 'package:tictactoe/core/utils/progression_service.dart';

class FirebaseLeaderboardService {
  static final FirebaseLeaderboardService _instance =
      FirebaseLeaderboardService._internal();
  factory FirebaseLeaderboardService() => _instance;
  FirebaseLeaderboardService._internal();

  final FirebaseDatabase _db = FirebaseDatabase.instance;
  static const int _topN = 50;

  // ── Push a result to Firebase after each game ──────────────────────────────

  Future<void> pushResult({
    required String playerName,
    required GameStatus status,
    required bool isPlayerX,
  }) async {
    try {
      final profile = ProgressionService().profile;
      final ref = _db.ref('leaderboard/global/$playerName');

      final snapshot = await ref.get();
      int wins = 0, losses = 0, draws = 0;

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        wins = data['wins'] as int? ?? 0;
        losses = data['losses'] as int? ?? 0;
        draws = data['draws'] as int? ?? 0;
      }

      switch (status) {
        case GameStatus.xWon:
          isPlayerX ? wins++ : losses++;
          break;
        case GameStatus.oWon:
          isPlayerX ? losses++ : wins++;
          break;
        case GameStatus.draw:
          draws++;
          break;
        case GameStatus.playing:
          break;
      }

      final int total = wins + losses + draws;
      final double winRate = total > 0 ? wins / total : 0.0;

      await ref.set({
        'playerName': playerName,
        'wins': wins,
        'losses': losses,
        'draws': draws,
        'totalGames': total,
        'winRate': winRate,
        'level': profile.level,
        'tier': profile.tier.name,
        'lastUpdated': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('[FirebaseLeaderboardService] push failed: $e');
    }
  }

  // ── Fetch top-N global entries ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchTopEntries() async {
    try {
      final snapshot = await _db
          .ref('leaderboard/global')
          .orderByChild('wins')
          .limitToLast(_topN)
          .get();

      if (!snapshot.exists) return [];

      final map = Map<String, dynamic>.from(snapshot.value as Map);
      final entries = map.values
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList()
        ..sort((a, b) => (b['wins'] as int).compareTo(a['wins'] as int));

      return entries;
    } catch (e) {
      debugPrint('[FirebaseLeaderboardService] fetch failed: $e');
      return [];
    }
  }
}
