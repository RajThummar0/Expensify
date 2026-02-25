import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:expensify/models/expense.dart';
import 'package:expensify/models/budget_goal.dart';
import 'package:expensify/models/category.dart';
import 'package:expensify/services/hive_service.dart';

class ExpenseProvider with ChangeNotifier {
  final List<Expense> _expenses = [];
  final List<BudgetGoal> _budgetGoals = [];
  static const String _expensesKey = 'expenses';
  static const String _goalsKey = 'budget_goals';
  final _uuid = const Uuid();

  List<Expense> get expenses => List.unmodifiable(_expenses);
  List<BudgetGoal> get budgetGoals => List.unmodifiable(_budgetGoals);

  Future<void> loadData() async {
    try {
      final box = HiveService.expensesBox;
      final goalsBox = HiveService.goalsBox;

      final expensesData = box.get(_expensesKey);
      if (expensesData != null) {
        final list = expensesData is List ? expensesData : jsonDecode(expensesData.toString()) as List;
        _expenses.clear();
        for (var e in list) {
          try {
            _expenses.add(Expense.fromJson(Map<String, dynamic>.from(e as Map)));
          } catch (_) {}
        }
      }

      final goalsData = goalsBox.get(_goalsKey);
      if (goalsData != null) {
        final list = goalsData is List ? goalsData : jsonDecode(goalsData.toString()) as List;
        _budgetGoals.clear();
        for (var g in list) {
          try {
            _budgetGoals.add(BudgetGoal.fromJson(Map<String, dynamic>.from(g as Map)));
          } catch (_) {}
        }
      }

      if (_expenses.isEmpty) await _migrateFromSharedPrefs();
      _ensureDefaultGoals();
    } catch (e) {
      debugPrint('ExpenseProvider load error: $e');
      await _migrateFromSharedPrefs();
    }
    notifyListeners();
  }

  Future<void> _migrateFromSharedPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expensesJson = prefs.getString(_expensesKey);
      final goalsJson = prefs.getString(_goalsKey);
      if (expensesJson != null) {
        final decoded = jsonDecode(expensesJson) as List;
        for (var e in decoded) {
          try {
            _expenses.add(Expense.fromJson(e as Map<String, dynamic>));
          } catch (_) {}
        }
        await _saveExpenses();
        await prefs.remove(_expensesKey);
      }
      if (goalsJson != null) {
        final decoded = jsonDecode(goalsJson) as List;
        for (var g in decoded) {
          try {
            _budgetGoals.add(BudgetGoal.fromJson(g as Map<String, dynamic>));
          } catch (_) {}
        }
        await _saveGoals();
        await prefs.remove(_goalsKey);
      }
    } catch (_) {}
  }

  void _ensureDefaultGoals() {
    if (_budgetGoals.isEmpty) {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month);
      for (final cat in ExpenseCategory.values) {
        if (cat != ExpenseCategory.other) {
          _budgetGoals.add(BudgetGoal(
            id: _uuid.v4(),
            category: cat,
            targetAmount: 500,
            month: monthStart,
          ));
        }
      }
      _saveGoals();
    }
  }

  Future<void> _saveExpenses() async {
    await HiveService.expensesBox.put(
      _expensesKey,
      _expenses.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> _saveGoals() async {
    await HiveService.goalsBox.put(
      _goalsKey,
      _budgetGoals.map((g) => g.toJson()).toList(),
    );
  }

  void addExpense(Expense expense) {
    _expenses.add(expense);
    _saveExpenses();
    notifyListeners();
  }

  void updateExpense(Expense expense) {
    final i = _expenses.indexWhere((e) => e.id == expense.id);
    if (i >= 0) {
      _expenses[i] = expense;
      _saveExpenses();
      notifyListeners();
    }
  }

  void removeExpense(String id) {
    _expenses.removeWhere((e) => e.id == id);
    _saveExpenses();
    notifyListeners();
  }

  void addOrUpdateBudgetGoal(BudgetGoal goal) {
    final i = _budgetGoals.indexWhere((g) =>
        g.category == goal.category &&
        g.month.year == goal.month.year &&
        g.month.month == goal.month.month);
    if (i >= 0) {
      _budgetGoals[i] = BudgetGoal(
        id: _budgetGoals[i].id,
        category: goal.category,
        targetAmount: goal.targetAmount,
        month: goal.month,
      );
    } else {
      _budgetGoals.add(BudgetGoal(
        id: _uuid.v4(),
        category: goal.category,
        targetAmount: goal.targetAmount,
        month: goal.month,
      ));
    }
    _saveGoals();
    notifyListeners();
  }

  double getTotalSpentThisMonth() {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0, (sum, e) => sum + e.amount);
  }

  double getSpentByCategoryThisMonth(ExpenseCategory cat) {
    final now = DateTime.now();
    return _expenses
        .where((e) =>
            e.category == cat &&
            e.date.year == now.year &&
            e.date.month == now.month)
        .fold(0, (sum, e) => sum + e.amount);
  }

  Map<ExpenseCategory, double> getCategorySpendingThisMonth() {
    final map = <ExpenseCategory, double>{};
    for (final cat in ExpenseCategory.values) {
      map[cat] = getSpentByCategoryThisMonth(cat);
    }
    return map;
  }

  List<Expense> getExpensesThisMonth() {
    return getExpensesForMonth(DateTime.now().year, DateTime.now().month);
  }

  List<Expense> getExpensesForMonth(int year, int month) {
    return _expenses
        .where((e) => e.date.year == year && e.date.month == month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Expense> getAllExpenses() {
    return _expenses.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  BudgetGoal? getGoalForCategory(ExpenseCategory cat) {
    final now = DateTime.now();
    try {
      return _budgetGoals.firstWhere(
        (g) =>
            g.category == cat &&
            g.month.year == now.year &&
            g.month.month == now.month,
      );
    } catch (_) {
      return null;
    }
  }

  /// Amount others owe you (from expenses you created & split)
  double getYouGet(String? userEmail) {
    return _expenses.where((e) {
      if (e.participants.length <= 1) return false;
      return e.createdById == userEmail || (userEmail == null && e.createdBy == 'You');
    }).fold(0, (sum, e) {
      final perPerson = e.amount / e.participants.length;
      final othersCount = e.participants.length - 1;
      return sum + (perPerson * othersCount);
    });
  }

  /// Amount you owe others (simplified - no multi-user sync)
  double getYouOwe(String? userEmail) => 0;
}
