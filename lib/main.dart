import 'package:bank_sampah_app/providers/bank_balance_provider.dart';
import 'package:bank_sampah_app/providers/events_provider.dart';
import 'package:bank_sampah_app/providers/products_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/firebase_options.dart'; // Ini akan di-generate Firebase CLI
import 'package:bank_sampah_app/providers/auth_provider.dart';
import 'package:bank_sampah_app/providers/transaction_provider.dart'; // New
import 'package:bank_sampah_app/providers/sampah_price_provider.dart'; // New
import 'package:bank_sampah_app/utils/routes.dart'; // New

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
            foregroundColor: Colors.white, // For app bar icons and text
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, // Default button color
              foregroundColor: Colors.white, // Default button text color
            ),
          ),
          // Further customization as needed
        ),
        initialRoute: AppRoutes.splash, // Use initialRoute
        routes: AppRoutes.getRoutes(), // Use the generated routes
      ),
    );
  }
}
