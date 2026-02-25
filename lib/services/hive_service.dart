import 'package:hive_flutter/hive_flutter.dart';
import 'package:expensify/core/constants.dart';

class HiveService {
  static late Box _expensesBox;
  static late Box _goalsBox;
  static late Box _settingsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _expensesBox = await Hive.openBox(AppConstants.hiveExpensesBox);
    _goalsBox = await Hive.openBox(AppConstants.hiveGoalsBox);
    _settingsBox = await Hive.openBox(AppConstants.hiveSettingsBox);
  }

  static Box get expensesBox => _expensesBox;
  static Box get goalsBox => _goalsBox;
  static Box get settingsBox => _settingsBox;
}
