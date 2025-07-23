import 'package:bank_sampah_app/screens/admin/admin_dashboard_screen.dart';
import 'package:bank_sampah_app/screens/admin/manage_users_screen.dart';
import 'package:bank_sampah_app/screens/common/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/models/user.dart';
import 'package:bank_sampah_app/providers/auth_provider.dart';
import 'package:bank_sampah_app/widgets/loading_indicator.dart';

class UserValidationScreen extends StatefulWidget {
  const UserValidationScreen({super.key});

  @override
  State<UserValidationScreen> createState() => _UserValidationScreenState();
}

class _UserValidationScreenState extends State<UserValidationScreen> {
  @override
  void initState() {
    super.initState();
    // Tidak perlu memanggil fetchUsers() di sini lagi
    // karena AuthProvider sudah mendengarkan stream _listenToAllUsers()
    // yang akan mengisi `allUsers` secara otomatis.
  }

  // Fungsi untuk mengonfirmasi dan memperbarui status validasi
  void _confirmValidation(BuildContext context, AppUser userToValidate) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Validasi'),
          content: Text(
            'Apakah Anda yakin ingin memvalidasi akun ${userToValidate.nama}?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Tutup dialog
                try {
                  await Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  ).updateUserValidationStatus(userToValidate.id, true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Akun ${userToValidate.nama} berhasil divalidasi!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal memvalidasi akun: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  debugPrint('Error validating user: $e');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                'Validasi',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Validasi Pengguna')),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading && authProvider.allUsers.isEmpty) {
            // Tampilkan loading jika sedang memuat dan belum ada data
            return const LoadingIndicator();
          }

          if (authProvider.errorMessage != null) {
            return Center(child: Text('Error: ${authProvider.errorMessage}'));
          }

          // Filter pengguna yang belum divalidasi dan bukan nasabah
          final unvalidatedUsers = authProvider.allUsers.where((user) {
            return !user.validated && user.userType != UserType.nasabah;
          }).toList();

          if (unvalidatedUsers.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada pengguna yang perlu divalidasi.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: unvalidatedUsers.length,
            itemBuilder: (context, index) {
              final user = unvalidatedUsers[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.nama,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Email: ${user.email}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'NIK: ${user.nik}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Tipe: ${user.userType.toString().split('.').last.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmValidation(context, user),
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Validasi Akun',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
