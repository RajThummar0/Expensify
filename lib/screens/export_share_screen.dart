import 'package:flutter/material.dart';
import 'package:expensify/core/platform_utils.dart';
import 'package:provider/provider.dart';
import 'package:expensify/models/expense.dart';
import 'package:expensify/providers/currency_provider.dart';
import 'package:expensify/services/pdf_service.dart';
import 'package:expensify/services/share_service.dart';
import 'package:expensify/theme/app_theme.dart';
import 'package:expensify/services/permission_service.dart';

class ExportShareScreen extends StatelessWidget {
  final List<Expense> expenses;
  final String filterLabel;

  const ExportShareScreen({
    super.key,
    required this.expenses,
    required this.filterLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export & Share')),
      body: Consumer<CurrencyProvider>(
        builder: (_, cp, __) {
          if (expenses.isEmpty) {
            return const Center(child: Text('No expenses to export'));
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Export as PDF',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Download expense report as PDF to your device (Downloads folder).',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              if (PlatformUtils.pdfDownloadSupported)
                _ExportButton(
                  icon: Icons.picture_as_pdf,
                  label: 'Download PDF',
                  onPressed: () => _exportPdf(context, expenses, cp),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('PDF download available on mobile/desktop. Use Share for web.', style: TextStyle(color: Colors.orange)),
                ),
              const SizedBox(height: 32),
              const Text(
                'Share Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Share expense summary via Email, SMS, or other apps.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _ExportButton(
                icon: Icons.share,
                label: 'Share via...',
                onPressed: () => _share(context, expenses, cp),
              ),
              const SizedBox(height: 16),
              _ExportButton(
                icon: Icons.email,
                label: 'Send via Email',
                onPressed: () => _shareEmail(context, expenses, cp),
              ),
              const SizedBox(height: 16),
              _ExportButton(
                icon: Icons.sms,
                label: 'Send via SMS',
                onPressed: () => _shareSms(context, expenses, cp),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, List<Expense> expenses, CurrencyProvider cp) async {
    try {
      final result = await PdfService.downloadToDownloadsFolder(
        expenses: expenses,
        currency: cp.currency,
        appName: 'Expensify',
      );
      if (context.mounted) {
        if (result.success && result.path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF saved to ${result.path}'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Could not save PDF'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => PermissionService.openSettings(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _share(BuildContext context, List<Expense> expenses, CurrencyProvider cp) async {
    final text = ShareService.generateExpenseSummary(
      expenses: expenses,
      currency: cp.currency,
      appName: 'Expensify',
    );
    await ShareService.shareViaNative(text: text, subject: 'Expensify Expense Summary');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share sheet opened'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _shareEmail(BuildContext context, List<Expense> expenses, CurrencyProvider cp) async {
    final body = ShareService.generateExpenseSummary(expenses: expenses, currency: cp.currency, appName: 'Expensify');
    final ok = await ShareService.shareViaEmail(to: '', subject: 'Expensify Expense Summary - $filterLabel', body: body);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Email app opened' : 'Could not open email'), backgroundColor: ok ? AppTheme.successColor : Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _shareSms(BuildContext context, List<Expense> expenses, CurrencyProvider cp) async {
    final body = ShareService.generateExpenseSummary(expenses: expenses, currency: cp.currency, appName: 'Expensify');
    final ok = await ShareService.shareViaSms(phone: '', body: body);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'SMS app opened' : 'Could not open SMS'), backgroundColor: ok ? AppTheme.successColor : Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }
}

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ExportButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}
