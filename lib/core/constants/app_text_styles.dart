import 'package:flutter/material.dart';
import 'package:tictactoe/core/constants/app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    letterSpacing: 4,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 3,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 2,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 2,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 1.5,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 2,
  );

  static const TextStyle scoreLarge = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 52,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    letterSpacing: 2,
  );

  static const TextStyle cellSymbol = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 40,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle xpText = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.xpAccent,
    letterSpacing: 1,
  );

  static const TextStyle coinText = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.coinGold,
    letterSpacing: 1,
  );

  static const TextStyle tierBadge = TextStyle(
    fontFamily: 'Orbitron',
    fontSize: 12,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    letterSpacing: 2,
  );
}
