import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:expensify/core/theme/app_colors.dart';
import 'package:expensify/models/expense.dart';
import 'package:expensify/models/participant.dart';
import 'package:expensify/models/category.dart';
import 'package:expensify/models/currency.dart';
import 'package:expensify/providers/auth_provider.dart';
import 'package:expensify/providers/expense_provider.dart';
import 'package:expensify/providers/currency_provider.dart';
import 'package:expensify/providers/contact_provider.dart';
import 'package:expensify/services/contact_service.dart';
import 'package:expensify/services/permission_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? existingExpense;
  final String? initialTitle;
  final double? initialAmount;
  final DateTime? initialDate;

  const AddExpenseScreen({
    super.key,
    this.existingExpense,
    this.initialTitle,
    this.initialAmount,
    this.initialDate,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  ExpenseCategory _selectedCategory = ExpenseCategory.food;
  List<DeviceContact> _selectedContacts = [];
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    if (widget.existingExpense != null) {
      final e = widget.existingExpense!;
      _titleController.text = e.title;
      _amountController.text = e.amount.toString();
      _noteController.text = e.note ?? '';
      _selectedDate = e.date;
      _selectedCategory = e.category;
      for (final p in e.participants) {
        if (!p.isUser) {
          _selectedContacts.add(DeviceContact(
            id: p.id,
            name: p.name,
            phone: p.phone,
            email: p.email,
          ));
        }
      }
    } else {
      if (widget.initialTitle != null) _titleController.text = widget.initialTitle!;
      if (widget.initialAmount != null) _amountController.text = widget.initialAmount!.toString();
      if (widget.initialDate != null) _selectedDate = widget.initialDate!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text) ?? 0;
  int get _totalParticipants => 1 + _selectedContacts.length;
  double get _perPersonAmount => _totalParticipants > 0 ? _amount / _totalParticipants : _amount;

  List<Participant> _buildParticipants(String userName) {
    final perPerson = _perPersonAmount;
    final list = <Participant>[
      Participant(id: 'user', name: userName, isUser: true, amount: perPerson),
    ];
    for (final c in _selectedContacts) {
      list.add(Participant(
        id: c.id,
        name: c.name,
        phone: c.phone,
        email: c.email,
        isUser: false,
        amount: perPerson,
      ));
    }
    return list;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = _amount;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final provider = context.read<ExpenseProvider>();
    final auth = context.read<AuthProvider>();
    final userName = auth.userName ?? 'You';
    final participants = _buildParticipants(userName);

    if (widget.existingExpense != null) {
      provider.updateExpense(Expense(
        id: widget.existingExpense!.id,
        title: _titleController.text.trim(),
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        imagePath: widget.existingExpense!.imagePath,
        createdBy: userName,
        createdById: auth.userEmail,
        participants: participants,
      ));
    } else {
      provider.addExpense(Expense(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        createdBy: userName,
        createdById: auth.userEmail,
        participants: participants,
      ));
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.existingExpense != null ? 'Expense updated' : 'Expense added'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingExpense != null ? 'Edit Expense' : 'Add Expense'),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 4) {
              if (_validateStep()) setState(() => _currentStep++);
            } else {
              _submit();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep--);
          },
          controlsBuilder: (_, details) => Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                FilledButton(
                  onPressed: details.onStepContinue,
                  child: Text(_currentStep == 4 ? 'Save' : 'Continue'),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ],
              ],
            ),
          ),
          steps: [
            _buildStepTitle(),
            _buildStepAmount(),
            _buildStepDate(),
            _buildStepContacts(),
            _buildStepPreview(),
          ],
        ),
      ),
    );
  }

  bool _validateStep() {
    switch (_currentStep) {
      case 0:
        return _titleController.text.trim().isNotEmpty;
      case 1:
        return _amount > 0;
      default:
        return true;
    }
  }

  Step _buildStepTitle() {
    return Step(
      title: const Text('Title'),
      content: TextFormField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'Expense Title',
          hintText: 'e.g. Dinner at restaurant',
        ),
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      ),
    );
  }

  Step _buildStepAmount() {
    return Step(
      title: const Text('Amount'),
      content: Consumer<CurrencyProvider>(
        builder: (_, cp, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      hintText: '0.00',
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Enter valid amount';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<Currency>(
                    value: cp.currency,
                    decoration: const InputDecoration(labelText: 'Currency'),
                    items: Currency.all
                        .map((c) => DropdownMenuItem(value: c, child: Text('${c.symbol} ${c.code}')))
                        .toList(),
                    onChanged: (v) => v != null ? cp.setCurrency(v) : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ExpenseCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ExpenseCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Icon(c.icon, color: c.color, size: 20),
                            const SizedBox(width: 8),
                            Text(c.displayName),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
          ],
        ),
      ),
    );
  }

  Step _buildStepDate() {
    return Step(
      title: const Text('Date'),
      content: ListTile(
        title: const Text('Date'),
        subtitle: Text(
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
        ),
        trailing: const Icon(Icons.calendar_today),
        onTap: () async {
          final p = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (p != null) setState(() => _selectedDate = p);
        },
      ),
    );
  }

  Step _buildStepContacts() {
    return Step(
      title: Text('Split with (${_selectedContacts.length} selected)'),
      content: kIsWeb
          ? const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Contact picking is available on mobile. On web, expense will be saved for you only.'),
              ),
            )
          : _ContactPickerWrapper(
              selectedContacts: _selectedContacts,
              onChanged: (list) => setState(() => _selectedContacts = list),
            ),
    );
  }

  Step _buildStepPreview() {
    return Step(
      title: const Text('Review'),
      content: Consumer<CurrencyProvider>(
        builder: (_, cp, __) => Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_titleController.text, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(cp.format(_amount), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Divider(),
                Text('Per person: ${cp.format(_perPersonAmount)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _ParticipantChip(label: 'You', isUser: true),
                ..._selectedContacts.map((c) => _ParticipantChip(label: c.name, isUser: false)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: 'Note (optional)', hintText: 'Add a note'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ParticipantChip extends StatelessWidget {
  final String label;
  final bool isUser;

  const _ParticipantChip({required this.label, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Chip(
        avatar: CircleAvatar(
          backgroundColor: isUser ? AppColors.primary : Colors.grey,
          child: Text(label[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        label: Text(isUser ? '$label (You)' : label),
      ),
    );
  }
}

class _ContactPickerWrapper extends StatefulWidget {
  final List<DeviceContact> selectedContacts;
  final ValueChanged<List<DeviceContact>> onChanged;

  const _ContactPickerWrapper({required this.selectedContacts, required this.onChanged});

  @override
  State<_ContactPickerWrapper> createState() => _ContactPickerWrapperState();
}

class _ContactPickerWrapperState extends State<_ContactPickerWrapper> {
  bool _fetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fetched) {
      _fetched = true;
      context.read<ContactProvider>().fetchContacts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ContactPickerSection(
      selectedContacts: widget.selectedContacts,
      onChanged: widget.onChanged,
    );
  }
}

class _ContactPickerSection extends StatefulWidget {
  final List<DeviceContact> selectedContacts;
  final ValueChanged<List<DeviceContact>> onChanged;

  const _ContactPickerSection({required this.selectedContacts, required this.onChanged});

  @override
  State<_ContactPickerSection> createState() => _ContactPickerSectionState();
}

class _ContactPickerSectionState extends State<_ContactPickerSection> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactProvider>(
      builder: (_, cp, __) {
        if (cp.isLoading) {
          return const _ShimmerContactList();
        }
        if (cp.permissionDenied) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.contacts_outlined, size: 48),
                  const SizedBox(height: 12),
                  Text(cp.error ?? 'Contact permission denied'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => cp.requestPermissionAndFetch(),
                    child: const Text('Grant Permission'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: PermissionService.openSettings,
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('Open Settings'),
                  ),
                ],
              ),
            ),
          );
        }
        if (cp.contacts.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No contacts found. Grant permission to access your contacts.'),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.selectedContacts.map((c) => Chip(
                avatar: c.avatarBytes != null
                    ? CircleAvatar(backgroundImage: MemoryImage(c.avatarBytes!))
                    : CircleAvatar(child: Text(c.name[0].toUpperCase())),
                label: Text(c.name),
                onDeleted: () => widget.onChanged(widget.selectedContacts.where((x) => x.id != c.id).toList()),
              )).toList(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: _filteredContacts(cp.contacts).length,
                itemBuilder: (_, i) {
                  final c = _filteredContacts(cp.contacts)[i];
                  final selected = widget.selectedContacts.any((x) => x.id == c.id);
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (v) {
                      if (v == true) {
                        widget.onChanged([...widget.selectedContacts, c]);
                      } else {
                        widget.onChanged(widget.selectedContacts.where((x) => x.id != c.id).toList());
                      }
                    },
                    secondary: c.avatarBytes != null
                        ? CircleAvatar(backgroundImage: MemoryImage(c.avatarBytes!))
                        : CircleAvatar(child: Text(c.name[0].toUpperCase())),
                    title: Text(c.name),
                    subtitle: c.phone != null ? Text(c.phone!) : null,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<DeviceContact> _filteredContacts(List<DeviceContact> contacts) {
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) return contacts;
    return contacts.where((c) =>
        c.name.toLowerCase().contains(q) ||
        (c.phone?.contains(q) ?? false) ||
        (c.email?.toLowerCase().contains(q) ?? false)).toList();
  }
}

class _ShimmerContactList extends StatelessWidget {
  const _ShimmerContactList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: 8,
      itemBuilder: (_, __) => ListTile(
        leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(20))),
        title: Container(height: 16, color: Colors.grey[300]),
        subtitle: Container(height: 12, color: Colors.grey[200], margin: const EdgeInsets.only(top: 4)),
      ),
    );
  }
}
