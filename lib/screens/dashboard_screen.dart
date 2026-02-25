import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expensify/providers/auth_provider.dart';
import 'package:expensify/providers/expense_provider.dart';
import 'package:expensify/providers/currency_provider.dart';
import 'package:expensify/widgets/spending_chart.dart';
import 'package:expensify/widgets/category_chart.dart';
import 'package:expensify/theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔥 HEADER (CLEAN + SPACIOUS)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dashboard',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// 💳 SUMMARY CARDS
              Consumer3<AuthProvider, ExpenseProvider, CurrencyProvider>(
                builder: (_, auth, ep, cp, __) {
                  final total = ep.getTotalSpentThisMonth();
                  final youGet = ep.getYouGet(auth.userEmail);
                  final youOwe = ep.getYouOwe(auth.userEmail);
                  final month = DateFormat('MMMM yyyy').format(DateTime.now());

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _ModernSummaryCard(
                              title: 'Total Spent',
                              value: cp.format(total),
                              subtitle: month,
                              icon: Icons.trending_up_rounded,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ModernSummaryCard(
                              title: 'Transactions',
                              value: ep.expenses.length.toString(),
                              subtitle: 'All Time',
                              icon: Icons.receipt_long_rounded,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _ModernSummaryCard(
                              title: 'You Get',
                              value: cp.format(youGet),
                              subtitle: 'From split expenses',
                              icon: Icons.arrow_downward_rounded,
                              color: AppTheme.successColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ModernSummaryCard(
                              title: 'You Owe',
                              value: cp.format(youOwe),
                              subtitle: 'To others',
                              icon: Icons.arrow_upward_rounded,
                              color: AppTheme.warningColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              /// 📊 SPENDING OVERVIEW SECTION
              Text(
                'Spending Overview',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              _ModernCard(
                child: const SpendingChart(),
              ),

              const SizedBox(height: 28),

              /// 🥧 CATEGORY SECTION
              Text(
                'By Category',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              _ModernCard(
                child: const CategoryChart(),
              ),

              const SizedBox(height: 32),

              /// 🎯 PRIMARY CTA (FOCUSED + MODERN)

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// 💎 MODERN CARD (USED EVERYWHERE)
class _ModernCard extends StatelessWidget {
  final Widget child;

  const _ModernCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E2A) // Premium dark surface
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: child,
    );
  }
}

/// 📈 SUMMARY CARD (TOP ANALYTICS CARDS)
class _ModernSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ModernSummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E2A)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.35)
                : Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ICON + TITLE ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 26),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  size: 14,
                  color: color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),

          const SizedBox(height: 4),

          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}