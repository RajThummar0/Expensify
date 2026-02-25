import 'package:expensify/models/category.dart';

class BudgetGoal {
  final String id;
  final ExpenseCategory category;
  final double targetAmount;
  final DateTime month;

  BudgetGoal({
    required this.id,
    required this.category,
    required this.targetAmount,
    required this.month,
  });

  double getProgress(double spent) {
    if (targetAmount <= 0) return 0;
    return (spent / targetAmount).clamp(0.0, 1.5);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'targetAmount': targetAmount,
        'month': month.toIso8601String(),
      };

  factory BudgetGoal.fromJson(Map<String, dynamic> json) => BudgetGoal(
        id: json['id'] as String,
        category: ExpenseCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => ExpenseCategory.other,
        ),
        targetAmount: (json['targetAmount'] as num).toDouble(),
        month: DateTime.parse(json['month'] as String),
      );
}
