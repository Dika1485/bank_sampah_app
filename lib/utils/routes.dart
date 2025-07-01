// routes.dart
import 'package:flutter/material.dart';
import 'package:bank_sampah_app/screens/splash_screen.dart';
import 'package:bank_sampah_app/screens/auth/login_screen.dart';
import 'package:bank_sampah_app/screens/auth/register_screen.dart';
import 'package:bank_sampah_app/screens/nasabah/nasabah_dashboard_screen.dart';
import 'package:bank_sampah_app/screens/nasabah/setor_sampah_screen.dart';
import 'package:bank_sampah_app/screens/nasabah/buku_tabungan_screen.dart';
import 'package:bank_sampah_app/screens/pengepul/pengepul_dashboard_screen.dart';
import 'package:bank_sampah_app/screens/pengepul/validasi_setoran_screen.dart';
import 'package:bank_sampah_app/screens/pengepul/harga_sampah_screen.dart';
import 'package:bank_sampah_app/screens/common/profile_screen.dart';
import 'package:bank_sampah_app/screens/common/update_password_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String nasabahDashboard = '/nasabah_dashboard';
  static const String setorSampah = '/setor_sampah';
  static const String bukuTabungan = '/buku_tabungan';
  static const String pengepulDashboard = '/pengepul_dashboard';
  static const String validasiSetoran = '/validasi_setoran';
  static const String hargaSampah = '/harga_sampah';
  static const String profile = '/profile';
  static const String updatePassword = '/update_password';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      nasabahDashboard: (context) => const NasabahDashboardScreen(),
      setorSampah: (context) => const SetorSampahScreen(),
      bukuTabungan: (context) => const BukuTabunganScreen(),
      pengepulDashboard: (context) => const PengepulDashboardScreen(),
      validasiSetoran: (context) => const ValidasiSetoranScreen(),
      hargaSampah: (context) => const HargaSampahScreen(),
      profile: (context) => const ProfileScreen(),
      updatePassword: (context) => const UpdatePasswordScreen(),
    };
  }
}
