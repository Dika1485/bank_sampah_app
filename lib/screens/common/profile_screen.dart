import 'package:bank_sampah_app/models/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/providers/auth_provider.dart';
import 'package:bank_sampah_app/widgets/loading_indicator.dart';
import 'package:bank_sampah_app/screens/common/update_password_screen.dart';
import 'package:bank_sampah_app/utils/pdf_generator.dart'; // For PDF
import 'package:bank_sampah_app/providers/transaction_provider.dart'; // For PDF data
import 'package:bank_sampah_app/screens/auth/login_screen.dart'; // For logout

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final appUser = authProvider.appUser;

    if (appUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: const Center(child: Text('Data pengguna tidak tersedia.')),
      );
    }

    // Determine validation status text and color
    String validationStatusText = appUser.validated ? 'Valid' : 'Belum Valid';
    Color validationStatusColor = appUser.validated ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: authProvider.isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        appUser.nama.isNotEmpty
                            ? appUser.nama[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileInfoRow('Nama Lengkap', appUser.nama),
                          _buildProfileInfoRow('Email', appUser.email),
                          _buildProfileInfoRow('NIK', appUser.nik),
                          _buildProfileInfoRow(
                            'Tipe Pengguna',
                            appUser.userType
                                .toString()
                                .split('.')
                                .last
                                .toUpperCase(),
                          ),
                          // Tampilkan kolom validasi hanya jika userType bukan nasabah
                          if (appUser.userType != UserType.nasabah)
                            _buildProfileInfoRow(
                              'Status Validasi',
                              validationStatusText,
                              valueColor: validationStatusColor,
                            ),
                          // Tampilkan peringatan jika belum valid dan bukan nasabah
                          if (appUser.userType != UserType.nasabah &&
                              !appUser.validated)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Text(
                                'Peringatan: Akun Anda belum divalidasi. Mohon hubungi Sekretaris atau Direktur untuk validasi.',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const UpdatePasswordScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.lock_reset),
                              label: const Text('Ubah Password'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Center(
                          //   child: ElevatedButton.icon(
                          //     onPressed: () async {
                          //       final transactionProvider =
                          //           Provider.of<TransactionProvider>(
                          //             context,
                          //             listen: false,
                          //           );
                          //       if (appUser.userType == UserType.nasabah) {
                          //         await PdfGenerator.generateNasabahReport(
                          //           nasabah: appUser,
                          //           transactions:
                          //               transactionProvider.nasabahTransactions,
                          //           currentBalance:
                          //               transactionProvider.nasabahBalance,
                          //         );
                          //       } else {
                          //         // In a real app, you would fetch all relevant transactions for the Pengepul,
                          //         // not just nasabahTransactions. This is a placeholder.
                          //         await PdfGenerator.generatePengepulReport(
                          //           pengepul: appUser,
                          //           allTransactions: transactionProvider
                          //               .nasabahTransactions, // Placeholder: replace with actual Pengepul transactions
                          //         );
                          //       }
                          //       if (context.mounted) {
                          //         ScaffoldMessenger.of(context).showSnackBar(
                          //           const SnackBar(
                          //             content: Text(
                          //               'Laporan PDF berhasil dibuat.',
                          //             ),
                          //           ),
                          //         );
                          //       }
                          //     },
                          //     icon: const Icon(Icons.picture_as_pdf),
                          //     label: const Text('Cetak Laporan'),
                          //     style: ElevatedButton.styleFrom(
                          //       backgroundColor: Colors.redAccent,
                          //       shape: RoundedRectangleBorder(
                          //         borderRadius: BorderRadius.circular(8),
                          //       ),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => _confirmLogout(
                        context,
                        authProvider,
                      ), // Use a confirmation dialog
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Helper method for profile info rows
  Widget _buildProfileInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: valueColor, // Tambahkan opsi warna
            ),
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  // New method to handle logout with confirmation
  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Dismiss dialog first
                await authProvider.signOut();
                if (context.mounted) {
                  // Navigate to LoginScreen after successful logout
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (Route<dynamic> route) =>
                        false, // Remove all previous routes
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red, // Use a distinct color for confirmation
              ),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
