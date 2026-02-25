import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Central permission handling for Android/iOS.
/// On Web, all permissions return false/denied.
class PermissionService {
  static Future<bool> requestCamera() async {
    if (kIsWeb) return false;
    try {
      final status = await ph.Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Permission camera error: $e');
      return false;
    }
  }

  static Future<bool> requestContacts() async {
    if (kIsWeb) return false;
    try {
      final status = await ph.Permission.contacts.request();
      return status.isGranted || status.isLimited;
    } catch (e) {
      debugPrint('Permission contacts error: $e');
      return false;
    }
  }

  static Future<bool> hasContacts() async {
    if (kIsWeb) return false;
    try {
      final status = await ph.Permission.contacts.status;
      return status.isGranted || status.isLimited;
    } catch (_) {
      return false;
    }
  }

  /// Request storage for PDF/save. On Android 10+ uses scoped storage.
  static Future<bool> requestStorage() async {
    if (kIsWeb) return false;
    try {
      final status = await ph.Permission.storage.request();
      if (status.isGranted) return true;
      final manageStatus = await ph.Permission.manageExternalStorage.request();
      return manageStatus.isGranted;
    } catch (e) {
      debugPrint('Permission storage error: $e');
      return false;
    }
  }

  static Future<bool> openSettings() async {
    if (kIsWeb) return false;
    try {
      return await ph.openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
