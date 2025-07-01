import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/providers/auth_provider.dart';
import 'package:bank_sampah_app/models/user.dart'; // Pastikan AppUser dan UserType ada
import 'package:bank_sampah_app/widgets/loading_indicator.dart'; // Pastikan ini diimpor
import 'package:bank_sampah_app/utils/validators.dart'; // Import validator

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();

  UserType? _selectedUserType;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _namaController.dispose();
    _nikController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedUserType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih jenis pengguna (Nasabah/Pengepul).'),
          ),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Tidak ada lagi logika unggah KTP di sini
      // Langsung panggil fungsi register di AuthProvider

      await authProvider.register(
        email: _emailController.text,
        password: _passwordController.text,
        nama: _namaController.text,
        nik: _nikController.text,
        userType: _selectedUserType!,
      );

      if (!mounted) return;

      if (authProvider.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(authProvider.errorMessage!)));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Registrasi Berhasil!')));
        // Navigasi ke halaman login atau dashboard yang sesuai
        Navigator.of(
          context,
        ).pushReplacementNamed('/login'); // Kembali ke login
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrasi Akun')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      AppValidators.validateRequired(value, 'Nama Lengkap'),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _nikController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor NIK',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => AppValidators.validateNIK(value),
                ),
                const SizedBox(height: 16.0),
                // Bagian Unggah KTP telah dihapus
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => AppValidators.validateEmail(value),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) => AppValidators.validatePassword(value),
                ),
                const SizedBox(height: 16.0),
                // Pilihan Jenis Pengguna
                DropdownButtonFormField<UserType>(
                  value: _selectedUserType,
                  decoration: const InputDecoration(
                    labelText: 'Daftar sebagai',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: UserType.nasabah,
                      child: Text('Nasabah'),
                    ),
                    DropdownMenuItem(
                      value: UserType.pengepul,
                      child: Text('Pengepul'),
                    ),
                  ],
                  onChanged: (UserType? newValue) {
                    setState(() {
                      _selectedUserType = newValue;
                    });
                  },
                  validator: (value) => AppValidators.validateRequired(
                    value?.toString(),
                    'Jenis Pengguna',
                  ),
                ),
                const SizedBox(height: 24.0),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return authProvider.isLoading
                        ? const LoadingIndicator()
                        : ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 15,
                              ),
                            ),
                            child: const Text(
                              'Daftar',
                              style: TextStyle(fontSize: 18),
                            ),
                          );
                  },
                ),
                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Kembali ke halaman login
                  },
                  child: const Text('Sudah punya akun? Login di sini'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
