import 'package:flutter/material.dart';
import 'package:tictactoe/core/constants/app_colors.dart';

enum ThemePaletteType { defaultNeon, galaxy, retro, cyberpunk, spaceGlow }

class ThemePalette {
  final Color background;
  final Color board;
  final Color playerX;
  final Color playerO;
  final Color glow;
  final Color accent;

  const ThemePalette({
    required this.background,
    required this.board,
    required this.playerX,
    required this.playerO,
    required this.glow,
    required this.accent,
  });

  static const defaultNeon = ThemePalette(
    background: AppColors.background,
    board: AppColors.borderDefault,
    playerX: AppColors.neonPink,
    playerO: AppColors.neonCyan,
    glow: AppColors.neonPurple,
    accent: AppColors.neonYellow,
  );

  static const galaxy = ThemePalette(
    background: Color(0xFF090A0F),
    board: Color(0xFF1B1B2F),
    playerX: Color(0xFFFF4B2B),
    playerO: Color(0xFF00C9FF),
    glow: Color(0xFF8A2387),
    accent: Color(0xFFE94057),
  );

  static const retro = ThemePalette(
    background: Color(0xFF2B2118),
    board: Color(0xFF3B2F2F),
    playerX: Color(0xFFFFD700),
    playerO: Color(0xFFFF8C00),
    glow: Color(0xFFFF4500),
    accent: Color(0xFF32CD32),
  );

  static const cyberpunk = ThemePalette(
    background: Color(0xFF050512),
    board: Color(0xFF0A192F),
    playerX: Color(0xFF00FF41),
    playerO: Color(0xFFFF003C),
    glow: Color(0xFFF3E600),
    accent: Color(0xFF00E5FF),
  );

  static const spaceGlow = ThemePalette(
    background: Color(0xFF020010),
    board: Color(0xFF14102C),
    playerX: Color(0xFFBD00FF),
    playerO: Color(0xFF00F0FF),
    glow: Color(0xFF7000FF),
    accent: Color(0xFFFF007B),
  );

  static ThemePalette getPalette(ThemePaletteType type) {
    switch (type) {
      case ThemePaletteType.galaxy:
        return galaxy;
      case ThemePaletteType.retro:
        return retro;
      case ThemePaletteType.cyberpunk:
        return cyberpunk;
      case ThemePaletteType.spaceGlow:
        return spaceGlow;
      case ThemePaletteType.defaultNeon:
        return defaultNeon;
    }
  }
}
