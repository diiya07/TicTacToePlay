import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictactoe/core/models/game_models.dart';

class ProgressionService extends ChangeNotifier {
  static const String _profileKey = 'player_profile_v1';
  static final ProgressionService _instance = ProgressionService._internal();

  factory ProgressionService() => _instance;
  ProgressionService._internal();

  SharedPreferences? _prefs;
  PlayerProfile _profile = const PlayerProfile();

  PlayerProfile get profile => _profile;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadProfile();
  }

  Future<void> _loadProfile() async {
    final raw = _prefs?.getString(_profileKey);
    if (raw != null) {
      try {
        _profile = PlayerProfile.fromJson(jsonDecode(raw));
      } catch (e) {
        debugPrint('[ProgressionService] failed to parse profile: $e');
        _profile = const PlayerProfile();
      }
    }
    notifyListeners();
  }

  Future<void> _saveProfile() async {
    if (_prefs == null) return;
    await _prefs!.setString(_profileKey, jsonEncode(_profile.toJson()));
    notifyListeners();
  }

  PlayerTier _calculateTier(int xp) {
    if (xp >= 10000) return PlayerTier.diamond;
    if (xp >= 5000) return PlayerTier.platinum;
    if (xp >= 2500) return PlayerTier.gold;
    if (xp >= 1000) return PlayerTier.silver;
    return PlayerTier.bronze;
  }

  int _calculateLevel(int xp) {
    // Simple level formula: 1 level per 100 xp
    return (xp ~/ 100) + 1;
  }

  Future<void> addXp(int amount) async {
    if (amount <= 0) return;
    final newXp = _profile.xp + amount;
    _profile = PlayerProfile(
      xp: newXp,
      level: _calculateLevel(newXp),
      coins: _profile.coins,
      tier: _calculateTier(newXp),
      activeTheme: _profile.activeTheme,
      unlockedThemes: _profile.unlockedThemes,
    );
    await _saveProfile();
  }

  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    _profile = PlayerProfile(
      xp: _profile.xp,
      level: _profile.level,
      coins: _profile.coins + amount,
      tier: _profile.tier,
      activeTheme: _profile.activeTheme,
      unlockedThemes: _profile.unlockedThemes,
    );
    await _saveProfile();
  }

  Future<bool> spendCoins(int amount) async {
    if (amount <= 0 || _profile.coins < amount) return false;
    _profile = PlayerProfile(
      xp: _profile.xp,
      level: _profile.level,
      coins: _profile.coins - amount,
      tier: _profile.tier,
      activeTheme: _profile.activeTheme,
      unlockedThemes: _profile.unlockedThemes,
    );
    await _saveProfile();
    return true;
  }

  Future<void> unlockTheme(String themeId) async {
    if (_profile.unlockedThemes.contains(themeId)) return;
    final newThemes = List<String>.from(_profile.unlockedThemes)..add(themeId);
    _profile = PlayerProfile(
      xp: _profile.xp,
      level: _profile.level,
      coins: _profile.coins,
      tier: _profile.tier,
      activeTheme: _profile.activeTheme,
      unlockedThemes: newThemes,
    );
    await _saveProfile();
  }

  Future<void> setActiveTheme(String themeId) async {
    if (!_profile.unlockedThemes.contains(themeId)) return;
    _profile = PlayerProfile(
      xp: _profile.xp,
      level: _profile.level,
      coins: _profile.coins,
      tier: _profile.tier,
      activeTheme: themeId,
      unlockedThemes: _profile.unlockedThemes,
    );
    await _saveProfile();
  }
}
