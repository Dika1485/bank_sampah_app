import 'package:bank_sampah_app/screens/common/guest_dashboard_screen.dart';
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

    // 💡 Durasi diubah menjadi 3 detik untuk memberi waktu loading data dan menikmati splash
    await Future.delayed(const Duration(seconds: 3));

    // Pastikan widget masih mounted sebelum melakukan navigasi
    if (!mounted) return;

    if (authProvider.firebaseUser != null) {
      // User sudah login, cek tipe user dan arahkan
      // Gunakan listen: false saat memanggil getter Future appUser
      await authProvider.appUser;

      if (!mounted) return;

      if (authProvider.appUser?.userType == UserType.nasabah) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const NasabahDashboardScreen()),
        );
      } else if (authProvider.appUser?.userType == UserType.bendahara) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PengepulDashboardScreen()),
        );
      } else {
        // Jika appUser null atau tipe tidak dikenal setelah login Firebase
        // Arahkan ke GuestDashboard jika data user bermasalah, bukan langsung ke Login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GuestDashboardScreen()),
        );
      }
    } else {
      // User belum login, arahkan ke Guest Dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GuestDashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Latar belakang putih agar logo menonjol
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 💡 Ganti dengan widget Image.asset menggunakan path logo Anda
            Image.asset(
              'lib/assets/Gemini_Generated_Image_a5cufza5cufza5cu 1 (Traced) (3).png',
              height: 150, // Sesuaikan ukuran logo
              width: 150,
            ),
            const SizedBox(height: 30),
            Text(
              'SIMARU',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
            ),
            const Text(
              'Sistem Informasi Bank Sampah Mawar Biru',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 50),
            // Menggunakan widget indikator loading bawaan
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.green,
              ), // Hijau bank sampah
            ),
          ],
        ),
      ),
    );
  }
}
