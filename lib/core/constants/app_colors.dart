import 'dart:ui';

class AppColors {
  AppColors._();

  // Background
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121A);
  static const Color surfaceElevated = Color(0xFF1A1A26);

  // Brand
  static const Color neonPink = Color(0xFFFF2D78);
  static const Color neonCyan = Color(0xFF00F5FF);
  static const Color neonPurple = Color(0xFF9D4EDD);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonYellow = Color(0xFFFFE600);
  static const Color neonGold = Color(0xFFFFD700);

  // Player colors
  static const Color playerX = neonPink;
  static const Color playerO = neonCyan;

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8888AA);
  static const Color textMuted = Color(0xFF444466);

  // Border
  static const Color borderDefault = Color(0xFF1E1E2E);
  static const Color borderActive = Color(0xFF333355);

  // Win line
  static const Color winLine = neonGreen;

  // Difficulty
  static const Color diffEasy = neonGreen;
  static const Color diffMedium = neonYellow;
  static const Color diffHard = neonPink;

  // Progression & Tiers
  static const Color coinGold = Color(0xFFFFD700);
  static const Color xpAccent = Color(0xFF00E5FF);
  static const Color tierBronze = Color(0xFFCD7F32);
  static const Color tierSilver = Color(0xFFC0C0C0);
  static const Color tierGold = Color(0xFFFFD700);
  static const Color tierPlatinum = Color(0xFFE5E4E2);
  static const Color tierDiamond = Color(0xFFB9F2FF);
}
