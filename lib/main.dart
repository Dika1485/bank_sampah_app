import 'package:bank_sampah_app/providers/bank_balance_provider.dart';
import 'package:bank_sampah_app/providers/events_provider.dart';
import 'package:bank_sampah_app/providers/products_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/firebase_options.dart';
import 'package:bank_sampah_app/providers/auth_provider.dart';
import 'package:bank_sampah_app/providers/transaction_provider.dart';
import 'package:bank_sampah_app/providers/sampah_price_provider.dart';
import 'package:bank_sampah_app/utils/routes.dart';

// Tambahkan import untuk localization
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => SampahPriceProvider()),
        ChangeNotifierProvider(create: (_) => EventsProvider()),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
        ChangeNotifierProvider(create: (_) => BankBalanceProvider()),
      ],
      child: MaterialApp(
        title: 'Bank Sampah App',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        // --- Bagian yang direvisi/ditambahkan di sini ---
        // Menambahkan localization delegates untuk mendukung berbagai bahasa
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // Menambahkan locale yang didukung, dalam hal ini Indonesia
        supportedLocales: const [
          Locale('id', 'ID'), // Locale Indonesia
          Locale('en', 'US'), // Locale Inggris (opsional)
        ],

        // --- Akhir dari revisi ---
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.getRoutes(),
      ),
    );
  }
}
