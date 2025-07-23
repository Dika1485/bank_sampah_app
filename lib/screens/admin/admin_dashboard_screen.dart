import 'package:bank_sampah_app/screens/common/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/providers/auth_provider.dart';
import 'package:bank_sampah_app/screens/admin/user_validation_screen.dart';
import 'package:bank_sampah_app/screens/admin/manage_users_screen.dart'; // Akan kita buat nanti
import 'package:bank_sampah_app/screens/auth/login_screen.dart'; // Untuk logout

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat Datang, ${authProvider.appUser?.nama ?? 'Admin'}!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColorDark,
              ),
            ),
            const SizedBox(height: 30),
            // Card untuk Navigasi Validasi User
            _buildDashboardCard(
              context: context,
              title: 'Validasi Pengguna',
              subtitle: 'Validasi akun pengguna baru (Nasabah, dll.)',
              icon: Icons.check_circle_outline,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserValidationScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),
            // Card untuk Navigasi Kelola User
            _buildDashboardCard(
              context: context,
              title: 'Kelola Pengguna',
              subtitle: 'Lihat dan kelola semua akun pengguna',
              icon: Icons.people_alt_outlined,
              color: Colors.blueAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageUsersScreen(),
                  ),
                );
              },
            ),
            // Anda bisa menambahkan card lain di sini, misalnya:
            // const SizedBox(height: 15),
            // _buildDashboardCard(
            //   context: context,
            //   title: 'Lihat Laporan Transaksi',
            //   subtitle: 'Akses laporan keseluruhan transaksi sampah',
            //   icon: Icons.insert_chart_outlined,
            //   color: Colors.orange,
            //   onTap: () {
            //     // Navigator.push(context, MaterialPageRoute(builder: (context) => ReportScreen()));
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       const SnackBar(content: Text('Halaman Laporan akan datang!')),
            //     );
            //   },
            // ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Validasi Pengguna',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: 'Kelola Pengguna',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const UserValidationScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ManageUsersScreen(),
              ),
            );
          }
        },
      ),
    );
  }

  // Widget helper untuk membuat kartu dashboard
  Widget _buildDashboardCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 50, color: color),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // Fungsi konfirmasi logout
  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun admin?',
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
                Navigator.of(dialogContext).pop();
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
