import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:expensify/core/platform_utils.dart';
import 'package:expensify/services/permission_service.dart';

/// Wrapper around device contact for expense splitting.
class DeviceContact {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final Uint8List? avatarBytes;

  DeviceContact({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.avatarBytes,
  });
}

class ContactFetchResult {
  final List<DeviceContact> contacts;
  final bool permissionGranted;
  final String? error;

  ContactFetchResult({
    required this.contacts,
    required this.permissionGranted,
    this.error,
  });
}

class ContactService {
  static bool _lastPermissionGranted = false;
  static bool get lastPermissionGranted => _lastPermissionGranted;

  static Future<ContactFetchResult> getContacts() async {
    if (kIsWeb || !PlatformUtils.isMobile) {
      return ContactFetchResult(contacts: [], permissionGranted: false);
    }
    try {
      _lastPermissionGranted = await PermissionService.requestContacts();
      if (!_lastPermissionGranted) {
        return ContactFetchResult(
          contacts: [],
          permissionGranted: false,
          error: 'Contact permission denied. Please grant in Settings.',
        );
      }
      final contacts = await _fetchFromDevice();
      return ContactFetchResult(
        contacts: contacts,
        permissionGranted: true,
      );
    } catch (e) {
      debugPrint('ContactService error: $e');
      return ContactFetchResult(
        contacts: [],
        permissionGranted: _lastPermissionGranted,
        error: e.toString(),
      );
    }
  }

  static Future<List<DeviceContact>> _fetchFromDevice() async {
    if (kIsWeb) return [];
    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );
      return contacts.map(_toDeviceContact).toList();
    } catch (e) {
      debugPrint('_fetchFromDevice error: $e');
      return [];
    }
  }

  static DeviceContact _toDeviceContact(dynamic c) {
    final phone = c.phones.isNotEmpty ? c.phones.first.number : null;
    final email = c.emails.isNotEmpty ? c.emails.first.address : null;
    return DeviceContact(
      id: c.id,
      name: c.displayName,
      phone: phone,
      email: email,
      avatarBytes: c.photo,
    );
  }
}
