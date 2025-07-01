import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/providers/auth_provider.dart';
import 'package:bank_sampah_app/screens/auth/login_screen.dart';
import 'package:bank_sampah_app/screens/nasabah/nasabah_dashboard_screen.dart';
import 'package:bank_sampah_app/screens/pengepul/pengepul_dashboard_screen.dart';
import 'package:bank_sampah_app/models/user.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Tunggu sebentar untuk animasi splash screen (opsional)
    await Future.delayed(const Duration(seconds: 2));

    if (authProvider.firebaseUser != null) {
      // User sudah login, cek tipe user dan arahkan
      await authProvider.appUser; // Pastikan appUser sudah dimuat
      if (!mounted) return;

      if (authProvider.appUser?.userType == UserType.nasabah) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const NasabahDashboardScreen()),
        );
      } else if (authProvider.appUser?.userType == UserType.pengepul) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PengepulDashboardScreen()),
        );
      } else {
        // Jika appUser null atau tipe tidak dikenal setelah login Firebase
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      // User belum login, arahkan ke halaman login
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ganti dengan logo aplikasi Anda
            Icon(Icons.recycling, size: 100, color: Colors.green),
            SizedBox(height: 20),
            Text(
              'Bank Sampah App',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
