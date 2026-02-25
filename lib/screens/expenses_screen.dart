import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expensify/providers/expense_provider.dart';
import 'package:expensify/providers/currency_provider.dart';
import 'package:expensify/models/expense.dart';
import 'package:expensify/models/category.dart';
import 'package:expensify/screens/add_expense_screen.dart';
import 'package:expensify/screens/export_share_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  int? _selectedYear;
  int? _selectedMonth;

  List<Expense> _getFilteredExpenses(ExpenseProvider ep) {
    if (_selectedYear != null && _selectedMonth != null) {
      return ep.getExpensesForMonth(_selectedYear!, _selectedMonth!);
    }
    return ep.getAllExpenses();
  }

  String _getFilterLabel() {
    if (_selectedYear != null && _selectedMonth != null) {
      return DateFormat('MMMM yyyy').format(DateTime(_selectedYear!, _selectedMonth!));
    }
    return 'All time';
  }

  Future<void> _pickMonth(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear ?? now.year, _selectedMonth ?? now.month),
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, 12, 31),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _selectedYear = picked.year;
        _selectedMonth = picked.month;
      });
    }
  }

  void _showMonthFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'View expenses for',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text('All time'),
                onTap: () {
                  setState(() {
                    _selectedYear = null;
                    _selectedMonth = null;
                  });
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Select month...'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickMonth(context);
                },
              ),
              if (_selectedYear != null && _selectedMonth != null)
                ListTile(
                  leading: const Icon(Icons.today),
                  title: Text('This month (${DateFormat('MMMM yyyy').format(DateTime.now())})'),
                  onTap: () {
                    final now = DateTime.now();
                    setState(() {
                      _selectedYear = now.year;
                      _selectedMonth = now.month;
                    });
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Expenses'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Export & Share',
            onPressed: () {
              final ep = Provider.of<ExpenseProvider>(context, listen: false);
              final list = _getFilteredExpenses(ep);
              if (list.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No expenses to export')));
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExportShareScreen(
                    expenses: list,
                    filterLabel: _getFilterLabel(),
                  ),
                ),
              );
            },
          ),
          TextButton.icon(
            onPressed: () => _showMonthFilter(context),
            icon: const Icon(Icons.filter_list, size: 20),
            label: Text(_getFilterLabel()),
          ),
        ],
      ),
      body: Consumer2<ExpenseProvider, CurrencyProvider>(
        builder: (_, ep, cp, __) {
          final expenses = _getFilteredExpenses(ep);
          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _selectedYear != null && _selectedMonth != null
                        ? 'No expenses in ${_getFilterLabel()}'
                        : 'No expenses yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _showMonthFilter(context),
                    child: const Text('Change filter'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: expenses.length,
            itemBuilder: (_, i) {
              final e = expenses[i];
              return _ExpenseTile(
                expense: e,
                formattedAmount: cp.format(e.amount),
                onDelete: () => _confirmDelete(context, ep, e),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddExpenseScreen(existingExpense: e),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, ExpenseProvider provider, Expense e) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Delete "${e.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.removeExpense(e.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final String formattedAmount;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _ExpenseTile({
    required this.expense,
    required this.formattedAmount,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete'),
            content: Text('Delete "${expense.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: expense.category.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                expense.category.icon,
                color: expense.category.color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${expense.category.displayName} • ${DateFormat.MMMd().format(expense.date)}${expense.isSplit ? ' • Split' : ''}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Text(
                formattedAmount,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
