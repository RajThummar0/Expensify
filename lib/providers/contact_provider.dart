import 'package:flutter/foundation.dart';
import 'package:expensify/services/contact_service.dart';

class ContactProvider with ChangeNotifier {
  List<DeviceContact> _contacts = [];
  bool _isLoading = false;
  bool _permissionDenied = false;
  String? _error;

  List<DeviceContact> get contacts => List.unmodifiable(_contacts);
  bool get isLoading => _isLoading;
  bool get permissionDenied => _permissionDenied;
  String? get error => _error;

  Future<void> fetchContacts() async {
    _isLoading = true;
    _error = null;
    _permissionDenied = false;
    notifyListeners();

    final result = await ContactService.getContacts();
    _contacts = result.contacts;
    _isLoading = false;
    _permissionDenied = !result.permissionGranted;
    _error = result.error;
    notifyListeners();
  }

  Future<bool> requestPermissionAndFetch() async {
    await fetchContacts();
    return !_permissionDenied;
  }
}
