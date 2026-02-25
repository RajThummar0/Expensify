import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:expensify/services/pdf_file_io.dart' if (dart.library.html) 'package:expensify/services/pdf_file_stub.dart' as pdf_io;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:expensify/models/expense.dart';
import 'package:expensify/models/category.dart';
import 'package:expensify/models/currency.dart';
import 'package:expensify/core/platform_utils.dart';
import 'package:expensify/services/permission_service.dart';

class PdfExportService {
  static Future<FileResult?> generateAndSaveReport({
    required List<Expense> expenses,
    required Currency currency,
    required String appName,
  }) async {
    if (kIsWeb) return null;
    if (!PlatformUtils.pdfDownloadSupported) return null;
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
      final now = DateTime.now();
      final total = expenses.fold<double>(0, (s, e) => s + e.amount);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (ctx) => pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Text(
              appName,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          footer: (ctx) => pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
          build: (ctx) => [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Expense Report',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated: ${dateFormat.format(now)}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Divider(),
                ],
              ),
            ),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _cell('Title', isHeader: true),
                    _cell('Category', isHeader: true),
                    _cell('Date', isHeader: true),
                    _cell('Amount', isHeader: true),
                    _cell('Split', isHeader: true),
                  ],
                ),
                ...expenses.map((e) => pw.TableRow(
                      children: [
                        _cell(e.title),
                        _cell(e.category.displayName),
                        _cell(DateFormat('dd/MM/yyyy').format(e.date)),
                        _cell(currency.format(e.amount)),
                        _cell(_formatSplit(e)),
                      ],
                    )),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(currency.format(total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            if (_hasAnySplits(expenses)) ...[
              pw.SizedBox(height: 24),
              pw.Header(
                level: 0,
                child: pw.Text('Split Details by Contact', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 8),
              ..._getSplitSummary(expenses).entries.map((e) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(e.key),
                        pw.Text(currency.format(e.value)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      );

      if (PlatformUtils.isMobile) {
        final hasStorage = await PermissionService.requestStorage();
        if (!hasStorage) {
          return FileResult(success: false, path: null, error: 'Storage permission denied');
        }
      }

      final output = await _getOutputPath();
      if (output == null) {
        return FileResult(success: false, path: null, error: 'Could not get storage path');
      }
      try {
        await pdf_io.writePdfToFile(output, await pdf.save());
        return FileResult(success: true, path: output, error: null);
      } catch (e) {
        debugPrint('PDF write error: $e');
        return FileResult(success: false, path: null, error: e.toString());
      }
    } catch (e) {
      debugPrint('PDF export error: $e');
      return FileResult(success: false, path: null, error: e.toString());
    }
  }

  static pw.Widget _cell(String text, {bool isHeader = false}) => pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(text, style: pw.TextStyle(fontSize: isHeader ? 10 : 9, fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );

  static String _formatSplit(Expense e) {
    if (e.participants.isEmpty) return '-';
    return e.participants.map((s) => '${s.name}: ${s.amount.toStringAsFixed(2)}').join('; ');
  }

  static bool _hasAnySplits(List<Expense> expenses) =>
      expenses.any((e) => e.participants.isNotEmpty);

  static Map<String, double> _getSplitSummary(List<Expense> expenses) {
    final map = <String, double>{};
    for (final e in expenses) {
      for (final p in e.participants) {
        map[p.name] = (map[p.name] ?? 0) + p.amount;
      }
    }
    return map;
  }

  static Future<String?> _getOutputPath() async {
    if (kIsWeb) return null;
    try {
      final dir = await getDownloadsDirectory();
      if (dir != null) {
        return '${dir.path}/Expensify_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      }
    } catch (e) {
      debugPrint('getDownloadsDirectory error: $e');
    }
    try {
      final appDir = await getApplicationDocumentsDirectory();
      return '${appDir.path}/Expensify_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    } catch (e) {
      debugPrint('getApplicationDocumentsDirectory error: $e');
    }
    return null;
  }
}

class FileResult {
  final bool success;
  final String? path;
  final String? error;
  FileResult({required this.success, this.path, this.error});
}
