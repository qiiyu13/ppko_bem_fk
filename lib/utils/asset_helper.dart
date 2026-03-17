import 'package:flutter/foundation.dart';

/// Helper class to handle asset paths that work correctly on both
/// mobile (direct assets) and web when imported as a package.
class AssetHelper {
  AssetHelper._();

  /// Returns the correct asset path based on platform.
  /// On web, assets from a package are prefixed with 'packages/<package>/'
  static String getSvgPath(String assetName) {
    if (kIsWeb) {
      return 'packages/mediku/assets/svg/$assetName';
    }
    return 'assets/svg/$assetName';
  }

  /// Returns the correct image asset path based on platform.
  /// For use with Image.asset()
  static String getImagePath(String assetName) {
    if (kIsWeb) {
      return 'packages/mediku/assets/images/$assetName';
    }
    return 'assets/images/$assetName';
  }

  /// Returns the correct icon asset path based on platform.
  /// For use with Image.asset() for icons
  static String getIconPath(String assetName) {
    if (kIsWeb) {
      return 'packages/mediku/assets/icon/$assetName';
    }
    return 'assets/icon/$assetName';
  }

  /// Returns the correct font family name based on platform.
  /// On web when imported as a package, fonts are prefixed with 'packages/<package>/'
  static String getFontFamily(String fontFamily) {
    if (kIsWeb) {
      return 'packages/mediku/$fontFamily';
    }
    return fontFamily;
  }
}
