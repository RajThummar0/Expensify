import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expensify/providers/expense_provider.dart';
import 'package:expensify/providers/currency_provider.dart';
import 'package:expensify/models/category.dart';
import 'package:expensify/theme/app_theme.dart';

class CategoryChart extends StatelessWidget {
  const CategoryChart({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer2<ExpenseProvider, CurrencyProvider>(
      builder: (_, expenseProvider, currencyProvider, __) {
        final data = expenseProvider.getCategorySpendingThisMonth();
        final total = data.values.fold(0.0, (a, b) => a + b);

        if (total == 0) {
          return _emptyState(context);
        }

        final sorted = data.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final topCategory = sorted.first;

        return Column(
          children: [
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 60,
                      startDegreeOffset: -90,
                      sections: sorted.map((entry) {
                        final percent = (entry.value / total) * 100;
                        return PieChartSectionData(
                          color: entry.key.color,
                          value: entry.value,
                          radius: 60,
                          showTitle: false,
                        );
                      }).toList(),
                    ),
                  ),

                  // 🎯 CENTER VALUE (MAIN FIX)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currencyProvider.format(total),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "This Month",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 CLEAN LEGEND (MODERN)
            ...sorted.map((entry) {
              final percent = (entry.value / total) * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: entry.key.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key.displayName,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      "${percent.toStringAsFixed(0)}%",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 200,
      child: Center(
        child: Text(
          "No category data yet",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}