import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:expensify/firebase_options.dart';
import 'package:expensify/providers/auth_provider.dart';
import 'package:expensify/providers/expense_provider.dart';
import 'package:expensify/providers/currency_provider.dart';
import 'package:expensify/providers/contact_provider.dart';
import 'package:expensify/services/hive_service.dart';
import 'package:expensify/providers/theme_provider.dart';
import 'package:expensify/screens/splash_screen.dart';
import 'package:expensify/theme/app_theme.dart';
import 'package:expensify/theme/dark_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error (non-fatal): $e');
  }

  try {
    await HiveService.init();
  } catch (e) {
    debugPrint('Hive init error (non-fatal): $e');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFAFAFA),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ExpensifyApp());
}

class ExpensifyApp extends StatelessWidget {
  const ExpensifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadAuthState()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()..loadData()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()..load()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, __) => MaterialApp(
          title: 'Expensify',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: DarkTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
