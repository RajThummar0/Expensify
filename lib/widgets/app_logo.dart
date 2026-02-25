import 'package:flutter/material.dart';

/// Reusable app logo widget for Splash, AppBar, PDF header
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({super.key, this.size = 48, this.showText = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => buildFallbackLogo(size),
        ),
        if (showText) ...[
          SizedBox(width: size * 0.25),
          Flexible(
            child: Text(
              'Expensify',
              style: TextStyle(
                fontSize: size * 0.6,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  /// Fallback when asset fails to load
  static Widget buildFallbackLogo(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
          ),
          borderRadius: BorderRadius.circular(size * 0.2),
        ),
        child: Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: size * 0.6),
      );
}
