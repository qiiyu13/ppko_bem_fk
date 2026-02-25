import 'package:flutter/material.dart';

class ResponsiveSize {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double textScaleFactor;
  static late double safeAreaHorizontal;
  static late double safeAreaVertical;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;
    textScaleFactor = _mediaQueryData.textScaler.scale(1.0).clamp(0.8, 1.2);
    safeAreaHorizontal =
        _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    safeAreaVertical =
        _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
  }

  // Responsive padding based on screen width
  static double get paddingSmall => screenWidth * 0.03;
  static double get paddingMedium => screenWidth * 0.04;
  static double get paddingLarge => screenWidth * 0.05;

  // Responsive font sizes with text scaling
  static double get fontSmall => 12 * textScaleFactor;
  static double get fontMedium => 14 * textScaleFactor;
  static double get fontLarge => 16 * textScaleFactor;
  static double get fontXLarge => 20 * textScaleFactor;
  static double get fontXXLarge => 24 * textScaleFactor;
  static double get fontHuge => 32 * textScaleFactor;

  // Responsive spacing
  static double get spacingSmall => screenHeight * 0.01;
  static double get spacingMedium => screenHeight * 0.015;
  static double get spacingLarge => screenHeight * 0.02;
  static double get spacingXLarge => screenHeight * 0.03;

  // Responsive icon sizes
  static double get iconSmall => screenWidth * 0.05;
  static double get iconMedium => screenWidth * 0.06;
  static double get iconLarge => screenWidth * 0.08;

  // Responsive card sizes
  static double get cardBorderRadius => screenWidth * 0.04;
  static double get buttonBorderRadius => screenWidth * 0.03;

  // Check if screen is small (iPhone SE, small Android)
  static bool get isSmallScreen => screenWidth < 360;
  static bool get isMediumScreen => screenWidth >= 360 && screenWidth < 400;
  static bool get isLargeScreen => screenWidth >= 400;
}
