import 'package:flutter/foundation.dart';
import 'package:expensify/core/platform_utils.dart';
import 'package:expensify/services/permission_service.dart';
import 'package:expensify/services/pdf_file_io.dart'
    if (dart.library.html) 'package:expensify/services/pdf_file_stub.dart'
    as pdf_io;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:expensify/models/expense.dart';
import 'package:expensify/models/category.dart';
import 'package:expensify/models/currency.dart';

/// Result of PDF download operation
class PdfDownloadResult {
  final bool success;
  final String? path;
  final String? error;

  PdfDownloadResult({required this.success, this.path, this.error});
}

/// PDF Service - saves to device Downloads folder (Android: /storage/emulated/0/Download)
class PdfService {
  /// Downloads PDF to device Downloads folder.
  /// File name: expense_report_YYYYMMDD.pdf
  /// Requires storage permission on mobile.
  static Future<PdfDownloadResult> downloadToDownloadsFolder({
    required List<Expense> expenses,
    required Currency currency,
    required String appName,
  }) async {
    if (kIsWeb) {
      return PdfDownloadResult(success: false, error: 'PDF download not supported on web');
    }
    if (!PlatformUtils.pdfDownloadSupported) {
      return PdfDownloadResult(success: false, error: 'PDF not supported on this platform');
    }

    try {
      if (PlatformUtils.isMobile) {
        final hasStorage = await PermissionService.requestStorage();
        if (!hasStorage) {
          return PdfDownloadResult(
            success: false,
            error: 'Storage permission denied. Grant access in Settings to save PDF.',
          );
        }
      }

      final bytes = await _generatePdfBytes(expenses: expenses, currency: currency, appName: appName);
      final fileName = 'expense_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      final outputPath = await _getDownloadsPath(fileName);

      if (outputPath == null) {
        return PdfDownloadResult(success: false, error: 'Could not access Downloads folder');
      }

      await pdf_io.writePdfToFile(outputPath, bytes);
      return PdfDownloadResult(success: true, path: outputPath);
    } catch (e) {
      debugPrint('PdfService error: $e');
      return PdfDownloadResult(success: false, error: e.toString());
    }
  }

  static Future<List<int>> _generatePdfBytes({
    required List<Expense> expenses,
    required Currency currency,
    required String appName,
  }) async {
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
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
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
              child: pw.Text('Split Details by Contact',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
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

    return pdf.save();
  }

  /// Gets path to Downloads folder. On Android uses /storage/emulated/0/Download
  /// for public Downloads visibility.
  static Future<String?> _getDownloadsPath(String fileName) async {
    if (kIsWeb) return null;

    try {
      if (PlatformUtils.isAndroid) {
        const androidDownloads = '/storage/emulated/0/Download';
        final dir = androidDownloads;
        return '$dir${_pathSep()}$fileName';
      }
    } catch (e) {
      debugPrint('Android Downloads path error: $e');
    }

    try {
      final dir = await getDownloadsDirectory();
      if (dir != null) return '${dir.path}${_pathSep()}$fileName';
    } catch (e) {
      debugPrint('getDownloadsDirectory error: $e');
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      return '${appDir.path}${_pathSep()}$fileName';
    } catch (e) {
      debugPrint('getApplicationDocumentsDirectory error: $e');
    }
    return null;
  }

  static String _pathSep() => '/';

  static pw.Widget _cell(String text, {bool isHeader = false}) => pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: isHeader ? 10 : 9,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
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
}
