import 'package:flutter/foundation.dart';
import 'package:tictactoe/core/constants/app_themes.dart';
import 'package:tictactoe/core/utils/progression_service.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();

  factory ThemeService() => _instance;
  ThemeService._internal();

  ThemePalette get currentPalette {
    final active = ProgressionService().profile.activeTheme;
    final type = ThemePaletteType.values.firstWhere(
      (e) => e.name == active,
      orElse: () => ThemePaletteType.defaultNeon,
    );
    return ThemePalette.getPalette(type);
  }

  bool isUnlocked(String themeId) {
    return ProgressionService().profile.unlockedThemes.contains(themeId);
  }

  Future<void> setActiveTheme(String themeId) async {
    await ProgressionService().setActiveTheme(themeId);
    notifyListeners();
  }
}
