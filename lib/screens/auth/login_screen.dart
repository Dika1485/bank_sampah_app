import 'package:bank_sampah_app/models/user.dart';
import 'package:bank_sampah_app/screens/admin/admin_dashboard_screen.dart';
import 'package:bank_sampah_app/screens/admin/user_validation_screen.dart';
import 'package:bank_sampah_app/screens/auth/register_screen.dart';
import 'package:bank_sampah_app/screens/common/profile_screen.dart';
import 'package:bank_sampah_app/screens/edukasi/edukasi_dashboard_screen.dart';
import 'package:bank_sampah_app/screens/produksi/produksi_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/providers/auth_provider.dart';
import 'package:bank_sampah_app/screens/nasabah/nasabah_dashboard_screen.dart'; // Contoh
import 'package:bank_sampah_app/screens/pengepul/pengepul_dashboard_screen.dart'; // Contoh

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signIn(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      if (authProvider.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(authProvider.errorMessage!)));
      } else if (authProvider.appUser != null) {
        // Navigasi berdasarkan tipe user
        if (authProvider.appUser!.userType == UserType.nasabah) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const NasabahDashboardScreen(),
            ),
            (Route<dynamic> route) => false, // Remove all previous routes
          );
          // Navigator.of(context).pushReplacement(
          //   MaterialPageRoute(builder: (_) => const NasabahDashboardScreen()),
          // );
        } else if (authProvider.appUser!.validated == false) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
            (Route<dynamic> route) => false, // Remove all previous routes
          );
          // Navigator.of(context).pushReplacement(
          //   MaterialPageRoute(builder: (_) => const ProfileScreen()),
          // );
        } else if (authProvider.appUser!.userType == UserType.direktur) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const AdminDashboardScreen(),
            ),
            (Route<dynamic> route) => false, // Remove all previous routes
          );
          // Navigator.of(context).pushReplacement(
          //   MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          // );
        } else if (authProvider.appUser!.userType == UserType.sekretaris) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const AdminDashboardScreen(),
            ),
            (Route<dynamic> route) => false, // Remove all previous routes
          );
          // Navigator.of(context).pushReplacement(
          //   MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          // );
        } else if (authProvider.appUser!.userType == UserType.bendahara) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const PengepulDashboardScreen(),
            ),
            (Route<dynamic> route) => false, // Remove all previous routes
          );
          // Navigator.of(context).pushReplacement(
          //   MaterialPageRoute(builder: (_) => const PengepulDashboardScreen()),
          // );
        } else if (authProvider.appUser!.userType == UserType.edukasi) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const EdukasiDashboardScreen(),
            ),
            (Route<dynamic> route) => false, // Remove all previous routes
          );
          // Navigator.of(context).pushReplacement(
          //   MaterialPageRoute(builder: (_) => const EdukasiDashboardScreen()),
          // );
        } else if (authProvider.appUser!.userType == UserType.produksi) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const ProduksiDashboardScreen(),
            ),
            (Route<dynamic> route) => false, // Remove all previous routes
          );
          // Navigator.of(context).pushReplacement(
          //   MaterialPageRoute(builder: (_) => const ProduksiDashboardScreen()),
          // );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Bank Sampah')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!value.contains('@')) {
                      return 'Masukkan email yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return authProvider.isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 15,
                              ),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(fontSize: 18),
                            ),
                          );
                  },
                ),
                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: () {
                    // TODO: Navigasi ke halaman registrasi
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                    print('Go to Register Page');
                  },
                  child: const Text('Belum punya akun? Daftar di sini'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
