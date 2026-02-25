import 'package:flutter/foundation.dart';

/// Extracted bill data from OCR
class ScannedBillData {
  final double? amount;
  final DateTime? date;
  final String? merchant;

  ScannedBillData({this.amount, this.date, this.merchant});

  bool get hasAmount => amount != null && amount! > 0;
  bool get hasDate => date != null;
  bool get hasMerchant => merchant != null && merchant!.trim().isNotEmpty;
}

/// OCR Scan Service - extracts amount, date, merchant from receipt text
class OcrScanService {
  static ScannedBillData parseBillText(String text) {
    if (text.trim().isEmpty) return ScannedBillData();

    String? amountStr;
    DateTime? date;
    String? merchant;
    final now = DateTime.now();
    final twoDigitYearCutoff = now.year % 100;

    // Amount patterns - prioritize TOTAL, AMOUNT DUE, GRAND TOTAL
    final amountPatterns = [
      RegExp(
        r'(?:grand\s*total|total\s*amount|amount\s*due|balance\s*due|total\s*due)[\s:]*[\$₹Rs\.]*\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:total|amount|balance|due|sum|amt\.?)[\s:]*[\$₹Rs\.]*\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(r'[\$₹Rs\.]\s*([\d,]+\.?\d{2})'),
      RegExp(r'([\d,]+\.\d{2})\s*(?:USD|INR|EUR|GBP)?'),
    ];

    for (final pattern in amountPatterns) {
      final matches = pattern.allMatches(text).toList();
      double? bestAmount;
      for (final m in matches) {
        final val = m.group(1)?.replaceAll(',', '');
        if (val != null) {
          final numVal = double.tryParse(val);
          if (numVal != null && numVal > 0 && numVal < 10000000) {
            if (bestAmount == null || numVal > bestAmount) {
              bestAmount = numVal;
            }
          }
        }
      }
      if (bestAmount != null) {
        amountStr = bestAmount.toString();
        break;
      }
    }

    // Date patterns
    final isoDate = RegExp(r'(\d{4})[/\-\.](\d{1,2})[/\-\.](\d{1,2})');
    final dmyDate = RegExp(r'(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{2,4})');
    final wordDate = RegExp(
      r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{2,4})',
      caseSensitive: false,
    );
    const monthNames = [
      'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
    ];

    DateTime? tryParseDate(int d, int mo, int y) {
      if (y < 100) y += y <= twoDigitYearCutoff ? 2000 : 1900;
      if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
      try {
        final dt = DateTime(y, mo, d);
        if (dt.isBefore(now.add(const Duration(days: 1))) &&
            dt.isAfter(DateTime(2015, 1, 1))) {
          return dt;
        }
      } catch (_) {}
      return null;
    }

    for (final m in isoDate.allMatches(text)) {
      final y = int.tryParse(m.group(1) ?? '');
      final mo = int.tryParse(m.group(2) ?? '');
      final d = int.tryParse(m.group(3) ?? '');
      if (y != null && mo != null && d != null) {
        date = tryParseDate(d, mo, y);
        if (date != null) break;
      }
    }
    if (date == null) {
      for (final m in dmyDate.allMatches(text)) {
        final d = int.tryParse(m.group(1) ?? '');
        final mo = int.tryParse(m.group(2) ?? '');
        final y = int.tryParse(m.group(3) ?? '');
        if (d != null && mo != null && y != null) {
          date = tryParseDate(d, mo, y);
          if (date != null) break;
        }
      }
    }
    if (date == null) {
      for (final m in wordDate.allMatches(text)) {
        final d = int.tryParse(m.group(1) ?? '');
        final monthStr = (m.group(2) ?? '').toLowerCase();
        final mi = monthNames.indexWhere((mn) => monthStr.startsWith(mn));
        final y = int.tryParse(m.group(3) ?? '');
        if (d != null && mi >= 0 && y != null) {
          date = tryParseDate(d, mi + 1, y);
          if (date != null) break;
        }
      }
    }

    // Merchant - first non-numeric, non-keyword line
    final lines = text
        .split(RegExp(r'[\n\r]+'))
        .map((e) => e.trim())
        .where((e) => e.length > 3)
        .toList();
    if (lines.isNotEmpty) {
      final filtered = lines
          .where((l) =>
              !RegExp(r'^[\d\s\$\.,₹]+$').hasMatch(l) &&
              !RegExp(r'^(total|amount|date|subtotal|tax)',
                  caseSensitive: false).hasMatch(l))
          .toList();
      merchant = filtered.isNotEmpty ? filtered.first : lines.first;
    }

    return ScannedBillData(
      amount: amountStr != null ? double.tryParse(amountStr) : null,
      date: date ?? now,
      merchant: merchant,
    );
  }

}
