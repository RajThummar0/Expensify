import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:expensify/providers/auth_provider.dart';
import 'package:expensify/providers/expense_provider.dart';
import 'package:expensify/providers/currency_provider.dart';
import 'package:expensify/models/expense.dart';
import 'package:expensify/models/category.dart';
import 'package:expensify/models/currency.dart';
import 'package:expensify/screens/add_expense_screen.dart';
import 'package:expensify/theme/app_theme.dart';
import 'package:expensify/services/ocr_scan_service.dart';
import 'package:expensify/services/permission_service.dart';
import 'package:expensify/utils/scan_bill_platform_stub.dart'
    if (dart.library.io) 'package:expensify/utils/scan_bill_platform_io.dart'
    as scan_platform;

class ScanBillScreen extends StatefulWidget {
  const ScanBillScreen({super.key});

  @override
  State<ScanBillScreen> createState() => _ScanBillScreenState();
}

class _ScanBillScreenState extends State<ScanBillScreen> {
  XFile? _xFile;
  Uint8List? _imageBytes;
  bool _isProcessing = false;
  String? _extractedAmount;
  DateTime? _extractedDate;
  String _extractedMerchant = '';

  Future<void> _pickImage({required ImageSource source}) async {
    if (source == ImageSource.camera) {
      final hasCamera = await PermissionService.requestCamera();
      if (!hasCamera && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission required to scan receipt'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: PermissionService.openSettings,
            ),
          ),
        );
        return;
      }
    }
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (x != null) {
      final bytes = await x.readAsBytes();
      setState(() {
        _xFile = x;
        _imageBytes = bytes;
        _extractedAmount = null;
        _extractedDate = null;
        _extractedMerchant = '';
        _isProcessing = true;
      });
      await _processImage();
    }
  }

  Future<void> _processImage() async {
    if (_xFile == null) return;
    try {
      final text = await scan_platform.processImageForOcr(_xFile!) ?? '';
      if (text.isEmpty) {
        setState(() {
          _isProcessing = false;
          _extractedAmount = null;
          _extractedDate = null;
          if (kIsWeb) {
            _extractedMerchant = 'Enter amount below (OCR not available on web)';
          }
        });
        if (kIsWeb && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bill scanning works on mobile. Enter amount manually below.'),
            ),
          );
        }
        return;
      }
      final parsed = OcrScanService.parseBillText(text);
      setState(() {
        _isProcessing = false;
        _extractedAmount = parsed.amount?.toString();
        _extractedDate = parsed.date ?? DateTime.now();
        _extractedMerchant = parsed.merchant ?? '';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _extractedAmount = null;
        _extractedDate = null;
        if (kIsWeb) _extractedMerchant = 'Enter amount below';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showImageSourcePicker(BuildContext context) {
    if (kIsWeb) {
      _pickImage(source: ImageSource.gallery);
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              subtitle: const Text('Take a photo of receipt'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              subtitle: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(source: ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showDetails = _extractedAmount != null ||
        _extractedMerchant.isNotEmpty ||
        (_imageBytes != null && _extractedAmount == null);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Bill'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _isProcessing ? null : () => _showImageSourcePicker(context),
              child: Container(
                height: 240,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _imageBytes == null
                    ? _isProcessing
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: AppTheme.primaryColor),
                                const SizedBox(height: 20),
                                Text(
                                  'Scanning bill...',
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.receipt_long_rounded,
                                  size: 56,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tap to upload bill image',
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'We\'ll extract amount & date',
                                style: TextStyle(
                                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                      ),
              ),
            ),
            if (showDetails) ...[
              const SizedBox(height: 28),
              Text(
                'Extracted Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Consumer<CurrencyProvider>(
                builder: (_, cp, __) => _ExtractedField(
                  label: 'Amount',
                  value: _extractedAmount != null
                      ? cp.format(double.tryParse(_extractedAmount!) ?? 0)
                      : '-',
                ),
              ),
              _ExtractedField(
                label: 'Date',
                value: _extractedDate != null
                    ? '${_extractedDate!.year}-${_extractedDate!.month.toString().padLeft(2, '0')}-${_extractedDate!.day.toString().padLeft(2, '0')}'
                    : '-',
              ),
              if (_extractedMerchant.isNotEmpty)
                _ExtractedField(label: 'Merchant', value: _extractedMerchant),
              if (_extractedAmount == null && _imageBytes != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Enter amount manually:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                _ManualAmountField(
                  onAmountEntered: (amt, dt) {
                    setState(() {
                      _extractedAmount = amt?.toString();
                      if (dt != null) _extractedDate = dt;
                    });
                  },
                ),
              ],
              const SizedBox(height: 16),
              Consumer<CurrencyProvider>(
                builder: (_, cp, __) => DropdownButtonFormField<Currency>(
                  value: cp.currency,
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                    border: OutlineInputBorder(),
                  ),
                  items: Currency.all
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('${c.symbol} ${c.code}'),
                          ))
                      .toList(),
                  onChanged: (v) => v != null ? cp.setCurrency(v) : null,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _canAddExpense ? () => _generateExpense(context) : null,
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: const Text('Generate Expense'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _canAddExpense {
    if (_extractedAmount != null) {
      final amt = double.tryParse(_extractedAmount!);
      return amt != null && amt > 0;
    }
    return false;
  }

  void _generateExpense(BuildContext context) {
    final amount = double.tryParse(_extractedAmount ?? '0') ?? 0;
    if (amount <= 0) return;
    final title = _extractedMerchant.isNotEmpty ? _extractedMerchant : 'Scanned Expense';
    final date = _extractedDate ?? DateTime.now();
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          initialTitle: title,
          initialAmount: amount,
          initialDate: date,
        ),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit details and save'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _ManualAmountField extends StatefulWidget {
  final void Function(double? amount, DateTime? date) onAmountEntered;

  const _ManualAmountField({required this.onAmountEntered});

  @override
  State<_ManualAmountField> createState() => _ManualAmountFieldState();
}

class _ManualAmountFieldState extends State<_ManualAmountField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              border: OutlineInputBorder(),
              hintText: '0.00',
            ),
            onChanged: (_) {
              final amt = double.tryParse(_controller.text);
              widget.onAmountEntered(amt, null);
            },
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (d != null) widget.onAmountEntered(null, d);
          },
        ),
      ],
    );
  }
}

class _ExtractedField extends StatelessWidget {
  final String label;
  final String value;

  const _ExtractedField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
