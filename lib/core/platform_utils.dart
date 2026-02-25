import 'package:flutter/foundation.dart';

/// Platform utilities - safe for Web and Mobile
class PlatformUtils {
  PlatformUtils._();

  static bool get isWeb => kIsWeb;

  static bool get isMobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static bool get isAndroid {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  static bool get isIOS {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Contacts feature - only on mobile
  static bool get contactsSupported => isMobile;

  /// PDF download - only on mobile/desktop, not web
  static bool get pdfDownloadSupported => !isWeb;
}
