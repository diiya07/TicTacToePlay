import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictactoe/core/models/game_models.dart';

class ScoreService {
  static const String _scoresKey = 'leaderboard_scores';
  static const String _playerXNameKey = 'player_x_name';
  static const String _playerONameKey = 'player_o_name';
  static const String _premiumKey = 'is_premium_unlocked';

  static final ScoreService _instance = ScoreService._internal();
  factory ScoreService() => _instance;
  ScoreService._internal();

  SharedPreferences? _prefs;
  List<ScoreEntry>? _cachedEntries;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Leaderboard ────────────────────────────────────────────────────────────

  Future<List<ScoreEntry>> getLeaderboard() async {
    if (_cachedEntries != null) return List.from(_cachedEntries!);

    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_scoresKey);
    if (raw == null) {
      _cachedEntries = [];
      return [];
    }
    final list = jsonDecode(raw) as List<dynamic>;
    _cachedEntries =
        list.map((e) => ScoreEntry.fromJson(e as Map<String, dynamic>)).toList()
          ..sort((a, b) => b.wins.compareTo(a.wins));
    return List.from(_cachedEntries!);
  }

  Future<void> recordResult({
    required String playerName,
    required GameStatus status,
    required bool isPlayerX,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    final entries = await getLeaderboard();
    final idx = entries.indexWhere((e) => e.playerName == playerName);

    final bool won =
        (isPlayerX && status == GameStatus.xWon) ||
        (!isPlayerX && status == GameStatus.oWon);
    final bool lost =
        (isPlayerX && status == GameStatus.oWon) ||
        (!isPlayerX && status == GameStatus.xWon);
    final bool drew = status == GameStatus.draw;

    if (idx == -1) {
      entries.add(
        ScoreEntry(
          playerName: playerName,
          wins: won ? 1 : 0,
          losses: lost ? 1 : 0,
          draws: drew ? 1 : 0,
          lastPlayed: DateTime.now(),
        ),
      );
    } else {
      entries[idx] = entries[idx].copyWith(
        wins: entries[idx].wins + (won ? 1 : 0),
        losses: entries[idx].losses + (lost ? 1 : 0),
        draws: entries[idx].draws + (drew ? 1 : 0),
      );
    }

    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await _prefs!.setString(_scoresKey, encoded);
    _cachedEntries = entries
      ..sort((a, b) => b.wins.compareTo(a.wins)); 
  }

  Future<void> clearLeaderboard() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_scoresKey);
    _cachedEntries = null; 
  }

  // ── Player Names ───────────────────────────────────────────────────────────

  Future<String> getPlayerName(bool isX) async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getString(isX ? _playerXNameKey : _playerONameKey) ??
        (isX ? 'PLAYER 1' : 'PLAYER 2');
  }

  Future<void> setPlayerName(bool isX, String name) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(isX ? _playerXNameKey : _playerONameKey, name);
  }

  // ── Premium ────────────────────────────────────────────────────────────────

  Future<bool> isPremiumUnlocked() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getBool(_premiumKey) ?? false;
  }

  Future<void> setPremiumUnlocked(bool value) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_premiumKey, value);
  }
}
