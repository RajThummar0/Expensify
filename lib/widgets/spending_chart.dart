import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expensify/providers/expense_provider.dart';
import 'package:expensify/providers/currency_provider.dart';

class SpendingChart extends StatelessWidget {
  const SpendingChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ExpenseProvider, CurrencyProvider>(
      builder: (_, ep, cp, __) {
        final now = DateTime.now();
        final dailySpending = <int, double>{};
        for (var i = 1; i <= now.day; i++) {
          final dt = DateTime(now.year, now.month, i);
          final total = ep.expenses
              .where((e) =>
                  e.date.year == dt.year &&
                  e.date.month == dt.month &&
                  e.date.day == dt.day)
              .fold<double>(0, (s, e) => s + e.amount);
          dailySpending[i] = total;
        }

        final spots = dailySpending.entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList();
        if (spots.isEmpty) {
          spots.add(const FlSpot(0, 0));
          spots.add(const FlSpot(1, 0));
        }

        var maxY = (dailySpending.values.isEmpty
                ? 100.0
                : dailySpending.values.reduce((a, b) => a > b ? a : b) * 1.2)
            .ceilToDouble();
        if (maxY <= 0) maxY = 100;

        final horizontalInterval = (maxY / 4).clamp(1.0, double.infinity);

        return Container(
          padding: const EdgeInsets.all(16),
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
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: horizontalInterval,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (v, _) => Text(
                      cp.format(v),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 5,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toInt()}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: now.day > 0 ? now.day.toDouble() : 31,
              minY: 0,
              maxY: maxY > 0 ? maxY : 100,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFF6366F1),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF6366F1).withOpacity(0.15),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
