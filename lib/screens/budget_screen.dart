import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:expensify/providers/expense_provider.dart';
import 'package:expensify/providers/currency_provider.dart';
import 'package:expensify/models/category.dart';
import 'package:expensify/models/budget_goal.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  Future<void> _showApplyToAllDialog(
    BuildContext context,
    ExpenseProvider ep,
    CurrencyProvider cp,
  ) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apply Budget to All Categories'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Set the same budget limit for all categories?',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount (${cp.currency.symbol})',
                border: const OutlineInputBorder(),
                hintText: '500',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (result == true && context.mounted) {
      final amount = double.tryParse(controller.text) ?? 0;
      if (amount > 0) {
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month);
        for (final cat in ExpenseCategory.values) {
          if (cat != ExpenseCategory.other) {
            final existing = ep.budgetGoals
                .where((g) =>
                    g.category == cat &&
                    g.month.year == now.year &&
                    g.month.month == now.month)
                .toList();
            final goalId = existing.isNotEmpty ? existing.first.id : const Uuid().v4();
            ep.addOrUpdateBudgetGoal(BudgetGoal(
              id: goalId,
              category: cat,
              targetAmount: amount,
              month: monthStart,
            ));
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Budget of ${cp.format(amount)} applied to all categories'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Budget Goals'),
        elevation: 0,
        actions: [
          Consumer2<ExpenseProvider, CurrencyProvider>(
            builder: (_, ep, cp, __) => IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Apply to all categories',
              onPressed: () => _showApplyToAllDialog(context, ep, cp),
            ),
          ),
        ],
      ),
      body: Consumer2<ExpenseProvider, CurrencyProvider>(
        builder: (_, ep, cp, __) {
          final goals = ep.budgetGoals;
          final now = DateTime.now();
          final monthGoals = goals
              .where((g) =>
                  g.month.year == now.year && g.month.month == now.month)
              .toList();

          if (monthGoals.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.savings, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No budget goals set',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: monthGoals.length,
            itemBuilder: (_, i) {
              final goal = monthGoals[i];
              final spent = ep.getSpentByCategoryThisMonth(goal.category);
              final progress = goal.getProgress(spent);
              return _BudgetGoalCard(
                goal: goal,
                spent: spent,
                progress: progress,
                formattedSpent: cp.format(spent),
                formattedTarget: cp.format(goal.targetAmount),
              );
            },
          );
        },
      ),
    );
  }
}

class _BudgetGoalCard extends StatelessWidget {
  final BudgetGoal goal;
  final double spent;
  final double progress;
  final String formattedSpent;
  final String formattedTarget;

  const _BudgetGoalCard({
    required this.goal,
    required this.spent,
    required this.progress,
    required this.formattedSpent,
    required this.formattedTarget,
  });

  Future<void> _showEditDialog(BuildContext context, ExpenseProvider ep, CurrencyProvider cp) async {
    final controller = TextEditingController(text: goal.targetAmount.toStringAsFixed(0));
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${goal.category.displayName} Budget'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Target amount (${cp.currency.symbol})',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == true && context.mounted) {
      final amount = double.tryParse(controller.text) ?? goal.targetAmount;
      if (amount > 0) {
        ep.addOrUpdateBudgetGoal(BudgetGoal(
          id: goal.id,
          category: goal.category,
          targetAmount: amount,
          month: goal.month,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOver = progress >= 1;
    final category = goal.category;
    return InkWell(
      onTap: () {
        final ep = context.read<ExpenseProvider>();
        final cp = context.read<CurrencyProvider>();
        _showEditDialog(context, ep, cp);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, color: category.color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '$formattedSpent / $formattedTarget',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOver
                      ? Colors.red.withOpacity(0.15)
                      : Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOver ? 'Over' : 'On track',
                  style: TextStyle(
                    color: isOver ? Colors.red : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver ? Colors.red : category.color,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
