import 'package:flutter/material.dart';

enum ExpenseCategory {
  food,
  transport,
  shopping,
  entertainment,
  bills,
  health,
  education,
  travel,
  other,
}

extension ExpenseCategoryExt on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.bills:
        return 'Bills';
      case ExpenseCategory.health:
        return 'Health';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.transport:
        return Icons.directions_car;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.entertainment:
        return Icons.movie;
      case ExpenseCategory.bills:
        return Icons.receipt_long;
      case ExpenseCategory.health:
        return Icons.favorite;
      case ExpenseCategory.education:
        return Icons.school;
      case ExpenseCategory.travel:
        return Icons.flight;
      case ExpenseCategory.other:
        return Icons.category;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFFF59E0B);
      case ExpenseCategory.transport:
        return const Color(0xFF3B82F6);
      case ExpenseCategory.shopping:
        return const Color(0xFFEC4899);
      case ExpenseCategory.entertainment:
        return const Color(0xFF8B5CF6);
      case ExpenseCategory.bills:
        return const Color(0xFF6366F1);
      case ExpenseCategory.health:
        return const Color(0xFF10B981);
      case ExpenseCategory.education:
        return const Color(0xFF06B6D4);
      case ExpenseCategory.travel:
        return const Color(0xFF14B8A6);
      case ExpenseCategory.other:
        return const Color(0xFF6B7280);
    }
  }
}
