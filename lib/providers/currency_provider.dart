import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expensify/models/currency.dart';

class CurrencyProvider with ChangeNotifier {
  static const String _key = 'selected_currency_code';
  Currency _currency = Currency.all.first;

  Currency get currency => _currency;

  String format(double amount) => _currency.format(amount);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) {
      _currency = Currency.fromCode(code);
      notifyListeners();
    }
  }

  Future<void> setCurrency(Currency c) async {
    _currency = c;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, c.code);
    notifyListeners();
  }
}
