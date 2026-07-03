import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformUtil {
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  // Linux has no Firebase SDK; web would need firebase options wired into
  // index.html/firebase_options.dart, which this project doesn't ship.
  static bool get firebaseAvailable => !kIsWeb && !isLinux;
}