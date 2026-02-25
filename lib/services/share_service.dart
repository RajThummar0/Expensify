import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:expensify/models/expense.dart';
import 'package:expensify/models/category.dart';
import 'package:expensify/models/currency.dart';

class ShareService {
  static String generateExpenseSummary({
    required List<Expense> expenses,
    required Currency currency,
    required String appName,
  }) {
    final sb = StringBuffer();
    sb.writeln('$appName - Expense Summary');
    sb.writeln('Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}');
    sb.writeln('');
    sb.writeln('--- Expenses ---');
    double total = 0;
    for (final e in expenses) {
      sb.writeln('• ${e.title}: ${currency.format(e.amount)} (${e.category.displayName}) - ${DateFormat('dd/MM/yyyy').format(e.date)}');
      total += e.amount;
      if (e.participants.isNotEmpty) {
        for (final p in e.participants) {
          sb.writeln('  └ ${p.name}: ${currency.format(p.amount)}');
        }
      }
    }
    sb.writeln('');
    sb.writeln('Total: ${currency.format(total)}');
    return sb.toString();
  }

  static Future<bool> shareViaNative({required String text, String? subject}) async {
    try {
      await Share.share(text, subject: subject ?? 'Expense Summary');
      return true;
    } catch (e) {
      debugPrint('Share error: $e');
      return false;
    }
  }

  static Future<bool> shareViaEmail({
    String? to,
    required String subject,
    required String body,
  }) async {
    try {
      final query = _encodeQuery({'subject': subject, 'body': body});
      final uri = Uri(
        scheme: 'mailto',
        path: to ?? '',
        query: query.isNotEmpty ? query : null,
      );
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Email launch error: $e');
      return false;
    }
  }

  static Future<bool> shareViaSms({
    required String phone,
    required String body,
  }) async {
    try {
      final uri = Uri(
        scheme: 'sms',
        path: phone.replaceAll(RegExp(r'[^\d+]'), ''),
        queryParameters: {'body': body},
      );
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('SMS launch error: $e');
      return false;
    }
  }

  static String _encodeQuery(Map<String, String> params) =>
      params.entries.where((e) => e.value.isNotEmpty).map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
}
