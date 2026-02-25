import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expensify/providers/currency_provider.dart';
import 'package:expensify/models/currency.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: Consumer<CurrencyProvider>(
        builder: (_, cp, __) => ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: Currency.all.length,
          itemBuilder: (_, i) {
            final c = Currency.all[i];
            final selected = cp.currency.code == c.code;
            return ListTile(
              leading: Text(
                c.symbol,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              title: Text('${c.name} (${c.code})'),
              trailing: selected ? const Icon(Icons.check, color: Color(0xFF6366F1)) : null,
              onTap: () => cp.setCurrency(c),
            );
          },
        ),
      ),
    );
  }
}
