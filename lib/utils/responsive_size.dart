import 'package:flutter/material.dart';

class ResponsiveSize {
  ResponsiveSize._();

  static double _screenWidth = 375;
  static double _screenHeight = 812;
  static double _textScaleFactor = 1.0;

  static void init(BuildContext context) {
    final mq = MediaQuery.of(context);
    _screenWidth = mq.size.width;
    _screenHeight = mq.size.height;
    _textScaleFactor = mq.textScaler.scale(1.0).clamp(0.8, 1.2);
  }

  // Responsive padding based on screen width
  static double get paddingSmall => _screenWidth * 0.03;
  static double get paddingMedium => _screenWidth * 0.04;
  static double get paddingLarge => _screenWidth * 0.05;

  // Responsive font sizes with text scaling
  static double get fontSmall => 12 * _textScaleFactor;
  static double get fontMedium => 14 * _textScaleFactor;
  static double get fontLarge => 16 * _textScaleFactor;
  static double get fontXLarge => 20 * _textScaleFactor;
  static double get fontXXLarge => 24 * _textScaleFactor;
  static double get fontHuge => 32 * _textScaleFactor;

  // Responsive spacing
  static double get spacingSmall => _screenHeight * 0.01;
  static double get spacingMedium => _screenHeight * 0.015;
  static double get spacingLarge => _screenHeight * 0.02;
  static double get spacingXLarge => _screenHeight * 0.03;

  // Responsive icon sizes
  static double get iconSmall => _screenWidth * 0.05;
  static double get iconMedium => _screenWidth * 0.06;
  static double get iconLarge => _screenWidth * 0.08;

  // Responsive card sizes
  static double get cardBorderRadius => _screenWidth * 0.04;
  static double get buttonBorderRadius => _screenWidth * 0.03;

  // Direct access to raw dimensions (use sparingly)
  static double get screenWidth => _screenWidth;
  static double get screenHeight => _screenHeight;

  // Check if screen is small
  static bool get isSmallScreen => _screenWidth < 360;
  static bool get isMediumScreen => _screenWidth >= 360 && _screenWidth < 400;
  static bool get isLargeScreen => _screenWidth >= 400;
}
