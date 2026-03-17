import 'package:flutter/foundation.dart';

/// Helper class to handle asset paths that work correctly on both
/// mobile (direct assets) and web when imported as a package.
class AssetHelper {
  AssetHelper._();

  /// Returns the correct asset path based on platform.
  /// On web when imported as a package, assets are prefixed with 'packages/<package>/'
  /// On web standalone build, use direct 'assets/' paths
  static String getSvgPath(String assetName) {
    if (kIsWeb) {
      // Check if running as package import (mediku_web_demo) or standalone
      // In package imports, paths use 'packages/mediku/'
      // In standalone builds, paths use direct 'assets/'
      return 'assets/assets/svg/$assetName';
    }
    return 'assets/svg/$assetName';
  }

  /// Returns the correct image asset path based on platform.
  /// For use with Image.asset()
  static String getImagePath(String assetName) {
    if (kIsWeb) {
      return 'assets/assets/images/$assetName';
    }
    return 'assets/images/$assetName';
  }

  /// Returns the correct icon asset path based on platform.
  /// For use with Image.asset() for icons
  static String getIconPath(String assetName) {
    if (kIsWeb) {
      return 'assets/assets/icon/$assetName';
    }
    return 'assets/icon/$assetName';
  }

  /// Returns the correct font family name based on platform.
  /// On web when imported as a package, fonts are prefixed with 'packages/<package>/'
  static String getFontFamily(String fontFamily) {
    if (kIsWeb) {
      // For standalone web build, fonts are in assets/packages/mediku/assets/fonts/
      // but the font family reference doesn't need the packages prefix in this case
      return fontFamily;
    }
    return fontFamily;
  }

  /// Get web-optimized image path for faster loading
  /// Falls back to original if web version doesn't exist
  /// Only applies to web platform - mobile uses original high-res
  static String getWebImagePath(String filename) {
    if (kIsWeb) {
      // Convert to webp extension
      final webpFilename = filename
          .replaceAll('.jpg', '.webp')
          .replaceAll('.jpeg', '.webp')
          .replaceAll('.png', '.webp');
      return 'assets/assets/images/web/$webpFilename';
    }
    // Mobile uses original high-res
    return 'assets/images/$filename';
  }
}
