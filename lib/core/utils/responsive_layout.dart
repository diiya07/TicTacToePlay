import 'package:flutter/material.dart';

enum ScreenSize { mobile, tablet, desktop }

class ResponsiveLayout {
  ResponsiveLayout._();

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;

  static ScreenSize getSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return ScreenSize.mobile;
    if (width < tabletBreakpoint) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  static bool isMobile(BuildContext context) =>
      getSize(context) == ScreenSize.mobile;

  static bool isTablet(BuildContext context) =>
      getSize(context) == ScreenSize.tablet;

  static bool isDesktop(BuildContext context) =>
      getSize(context) == ScreenSize.desktop;

  /// Max content width for centering on large screens
  static double maxContentWidth(BuildContext context) {
    switch (getSize(context)) {
      case ScreenSize.mobile:
        return double.infinity;
      case ScreenSize.tablet:
        return 540;
      case ScreenSize.desktop:
        return 480;
    }
  }

  /// Board size as a fraction of screen
  static double boardSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shorter = size.shortestSide;
    switch (getSize(context)) {
      case ScreenSize.mobile:
        return shorter * 0.88;
      case ScreenSize.tablet:
        return shorter * 0.65;
      case ScreenSize.desktop:
        return 420;
    }
  }

  /// Padding value
  static double horizontalPadding(BuildContext context) {
    switch (getSize(context)) {
      case ScreenSize.mobile:
        return 16;
      case ScreenSize.tablet:
        return 32;
      case ScreenSize.desktop:
        return 48;
    }
  }
}
