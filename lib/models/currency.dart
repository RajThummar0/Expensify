class Currency {
  final String code;
  final String symbol;
  final String name;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
  });

  String format(double amount) => '$symbol${amount.toStringAsFixed(2)}';

  static const List<Currency> all = [
    Currency(code: 'USD', symbol: '\$', name: 'US Dollar'),
    Currency(code: 'EUR', symbol: '€', name: 'Euro'),
    Currency(code: 'GBP', symbol: '£', name: 'British Pound'),
    Currency(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
    Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
    Currency(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar'),
    Currency(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
    Currency(code: 'CHF', symbol: 'Fr', name: 'Swiss Franc'),
    Currency(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
    Currency(code: 'KRW', symbol: '₩', name: 'South Korean Won'),
    Currency(code: 'MXN', symbol: '\$', name: 'Mexican Peso'),
    Currency(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real'),
    Currency(code: 'RUB', symbol: '₽', name: 'Russian Ruble'),
    Currency(code: 'ZAR', symbol: 'R', name: 'South African Rand'),
  ];

  static Currency fromCode(String code) {
    return all.firstWhere(
      (c) => c.code == code,
      orElse: () => all.first,
    );
  }
}
