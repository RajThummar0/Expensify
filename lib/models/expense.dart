import 'package:expensify/models/category.dart';
import 'package:expensify/models/participant.dart';

/// Expense model with correct split logic:
/// Participants = User (createdBy) + selected contacts
/// perPersonAmount = totalAmount / participants.length
class Expense {
  final String id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? note;
  final String? imagePath;
  final String createdBy; // User name who created
  final String? createdById; // User id (email) if available
  final List<Participant> participants; // User + contacts

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.imagePath,
    required this.createdBy,
    this.createdById,
    required this.participants,
  });

  double get perPersonAmount =>
      participants.isEmpty ? amount : amount / participants.length;

  bool get isSplit => participants.length > 1;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category.name,
        'date': date.toIso8601String(),
        'note': note,
        'imagePath': imagePath,
        'createdBy': createdBy,
        'createdById': createdById,
        'participants': participants.map((p) => p.toJson()).toList(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) {
    List<Participant> parts = [];
    final partsJson = json['participants'] as List<dynamic>?;
    if (partsJson != null && partsJson.isNotEmpty) {
      parts = partsJson
          .map((e) => Participant.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    // Backward compat: migrate from splitDetails if present
    final splitsJson = json['splitDetails'] as List<dynamic>?;
    if (parts.isEmpty && splitsJson != null && splitsJson.isNotEmpty) {
      parts = splitsJson.map((e) {
        final m = e as Map<String, dynamic>;
        return Participant(
          id: m['contactId'] as String,
          name: m['contactName'] as String,
          phone: m['contactPhone'] as String?,
          email: m['contactEmail'] as String?,
          isUser: false,
          amount: (m['amount'] as num).toDouble(),
        );
      }).toList();
    }
    return Expense(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      imagePath: json['imagePath'] as String?,
      createdBy: json['createdBy'] as String? ?? 'You',
      createdById: json['createdById'] as String?,
      participants: parts,
    );
  }
}
