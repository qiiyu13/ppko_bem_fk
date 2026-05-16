import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformUtil {
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  static bool get firebaseAvailable => !isLinux;
}