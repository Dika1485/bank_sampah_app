import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
import 'package:bank_sampah_app/providers/auth_provider.dart';
import 'package:bank_sampah_app/models/user.dart'; // Pastikan AppUser dan UserType ada

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
  File? _ktpImageFile; // Untuk menyimpan gambar KTP yang dipilih

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _namaController.dispose();
    _nikController.dispose();
    super.dispose();
  }

  // Fungsi untuk memilih gambar dari galeri
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _ktpImageFile = File(pickedFile.path);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada gambar yang dipilih.')),
        );
      }
    });
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
      if (_ktpImageFile == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mohon unggah foto KTP.')));
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // --- Upload Gambar KTP ke Firebase Storage ---
      String ktpImageUrl = '';
      try {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mengunggah KTP...')));
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('ktp_images')
            .child(
              '${_nikController.text}_${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
        await storageRef.putFile(_ktpImageFile!);
        ktpImageUrl = await storageRef.getDownloadURL();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengunggah KTP: $e')));
        return; // Hentikan proses jika upload gagal
      }
      // --- Selesai Upload Gambar KTP ---

      await authProvider.register(
        email: _emailController.text,
        password: _passwordController.text,
        nama: _namaController.text,
        nik: _nikController.text,
        noKtp: ktpImageUrl, // Kirim URL gambar KTP
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _nikController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor NIK',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length != 16) {
                      return 'NIK harus 16 digit';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                // Bagian Upload KTP
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Unggah Foto KTP'),
                ),
                if (_ktpImageFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Image.file(_ktpImageFile!, height: 100),
                  ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains('@')) {
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
                    if (value == null || value.isEmpty || value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
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
                  validator: (value) {
                    if (value == null) {
                      return 'Pilih jenis pengguna';
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
