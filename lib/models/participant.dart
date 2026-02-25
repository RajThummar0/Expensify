/// A participant in an expense (User or Contact)
/// User is always included; contacts are selected from device
class Participant {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final bool isUser;
  final double amount; // Per-person share

  Participant({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.isUser = false,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'isUser': isUser,
        'amount': amount,
      };

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        isUser: json['isUser'] as bool? ?? false,
        amount: (json['amount'] as num).toDouble(),
      );
}
