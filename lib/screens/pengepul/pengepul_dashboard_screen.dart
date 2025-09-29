import 'package:bank_sampah_app/providers/bank_balance_provider.dart';
import 'package:bank_sampah_app/screens/produksi/manage_products_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/providers/auth_provider.dart';
import 'package:bank_sampah_app/providers/transaction_provider.dart';
import 'package:bank_sampah_app/screens/pengepul/validasi_setoran_screen.dart';
import 'package:bank_sampah_app/screens/pengepul/harga_sampah_screen.dart';
import 'package:bank_sampah_app/screens/pengepul/pengepul_chart_widget.dart';
import 'package:bank_sampah_app/screens/common/profile_screen.dart';
import 'package:bank_sampah_app/screens/auth/login_screen.dart';
import 'package:bank_sampah_app/widgets/loading_indicator.dart';
import 'package:intl/intl.dart';
import 'package:bank_sampah_app/screens/pengepul/validasi_pencairan_screen.dart';
import 'package:bank_sampah_app/screens/pengepul/pengepul_bar_chart_widget.dart';
import 'package:bank_sampah_app/screens/pengepul/sell_waste_screen.dart';
// Import halaman baru untuk laporan bendahara
import 'package:bank_sampah_app/screens/pengepul/laporan_bendahara_screen.dart';
import 'package:bank_sampah_app/models/user.dart'; // Pastikan model user diimpor

class PengepulDashboardScreen extends StatefulWidget {
  const PengepulDashboardScreen({super.key});

  @override
  State<PengepulDashboardScreen> createState() =>
      _PengepulDashboardScreenState();
}

class _PengepulDashboardScreenState extends State<PengepulDashboardScreen> {
  // Tambahkan state untuk mengontrol indeks bottom navigation bar
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pastikan fungsi ini yang mengisi transactionProvider.nasabahTransactions
      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).listenToAllTransactions();

      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).listenToPendingPengepulValidations();

      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).listenToPendingWithdrawalRequests();

      // OPTIONAL: Panggil fetch data lain yang mungkin dibutuhkan charts (jika ada)
    });
  }

  // Fungsi untuk menangani navigasi
  void _onItemTapped(int index) {
    // Reset _selectedIndex ke 0 jika navigasi ke halaman lain terjadi,
    // agar tampilan dashboard tidak terlihat seperti terpotong.
    if (index != 0) {
      // Kita tidak perlu mengubah _selectedIndex = index di sini,
      // karena kita melakukan push() ke halaman baru, bukan switch tab.
      // Cukup pastikan dashboard tetap terlihat sebagai 'Home'.
    }

    switch (index) {
      case 0:
        // Navigasi ke halaman Home (Dashboard) - Sudah ada di sini
        break;
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ValidasiSetoranScreen(),
          ),
        );
        break;
      case 2:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ValidasiPencairanScreen(),
          ),
        );
        break;
      case 3:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const HargaSampahScreen()),
        );
        break;
      case 4:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const SellWasteScreen()),
        );
        break;
      case 5:
        // Navigasi ke halaman Laporan Bendahara
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const LaporanBendaharaScreen(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final bankBalanceProvider = Provider.of<BankBalanceProvider>(context);

    if (authProvider.appUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
      return const LoadingIndicator();
    }

    final String pengepulName = authProvider.appUser?.nama ?? 'Bendahara';
    final int pendingSetoranCount =
        transactionProvider.pendingPengepulValidations.length;
    final int pendingWithdrawalCount =
        transactionProvider.pendingWithdrawalRequests.length;
    final double totalRevenue = bankBalanceProvider.totalRevenue;

    // Cek apakah ada data transaksi untuk analisis
    final bool hasTransactionData =
        transactionProvider.nasabahTransactions.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Bendahara'),
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
      body: transactionProvider.isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang, $pengepulName!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Card untuk Saldo Bank Sampah
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: Colors.green,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saldo Bank Sampah (Pendapatan):',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp. ',
                              decimalDigits: 0,
                            ).format(totalRevenue),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      // Card untuk Setoran Menunggu Validasi
                      Expanded(
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ValidasiSetoranScreen(),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.pending_actions,
                                    size: 30,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Setoran Menunggu:',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    '$pendingSetoranCount Transaksi',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Card untuk Permintaan Pencairan Pending
                      Expanded(
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ValidasiPencairanScreen(),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.account_balance_wallet,
                                    size: 30,
                                    color: Colors.purple,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Pencairan Pending:',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    '$pendingWithdrawalCount Permintaan',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SellWasteScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      'Jual Sampah ke Pihak Lain',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Analisis Operasional:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // --- START: Bagian Analisis Operasional yang Diperbarui ---
                  if (!hasTransactionData)
                    const Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.bar_chart_outlined,
                                size: 40,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Data Operasional Belum Tersedia.',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Grafik akan muncul setelah ada data setoran yang tervalidasi.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        // Bar Chart untuk berat sampah per jenis
                        PengepulBarChartWidget(
                          transactions: transactionProvider.nasabahTransactions,
                        ),
                        const SizedBox(height: 20),
                        // Line Chart untuk berat sampah per bulan
                        PengepulChartWidget(
                          transactions: transactionProvider.nasabahTransactions,
                        ),
                      ],
                    ),
                  // --- END: Bagian Analisis Operasional yang Diperbarui ---
                  const SizedBox(height: 20),
                  // Bagian untuk daftar setoran menunggu validasi
                  const Text(
                    'Setoran Menunggu Validasi (Terbaru):',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  transactionProvider.pendingPengepulValidations.isEmpty
                      ? const Card(
                          elevation: 2,
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'Tidak ada setoran menunggu validasi.',
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount:
                              transactionProvider
                                      .pendingPengepulValidations
                                      .length >
                                  5
                              ? 5
                              : transactionProvider
                                    .pendingPengepulValidations
                                    .length,
                          itemBuilder: (context, index) {
                            final transaction = transactionProvider
                                .pendingPengepulValidations[index];

                            // Mencari nama pengguna dari daftar semua pengguna
                            final AppUser? user = authProvider.allUsers
                                .firstWhere(
                                  (user) => user.id == transaction.userId,
                                  orElse: () => AppUser(
                                    id: transaction.userId,
                                    email: '',
                                    nama: 'Unknown User',
                                    nik: '',
                                    userType: UserType.nasabah,
                                    validated: false,
                                  ),
                                );
                            final String userName =
                                user?.nama ??
                                'User ID: ${transaction.userId.substring(0, 8)}...';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.hourglass_empty,
                                  color: Colors.orange,
                                ),
                                // Menggunakan nama pengguna atau user ID sebagai cadangan
                                title: Text('Setoran dari $userName'),
                                subtitle: Text(
                                  '${transaction.sampahTypeName} - ${transaction.weightKg.toStringAsFixed(2)} kg (estimasi)\n'
                                  '${DateFormat('dd MMM HH:mm').format(transaction.timestamp)}',
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ValidasiSetoranScreen(
                                              initialTransactionId:
                                                  transaction.id,
                                            ),
                                      ),
                                    );
                                  },
                                  child: const Text('Validasi'),
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ValidasiSetoranScreen(),
                          ),
                        );
                      },
                      child: const Text('Lihat Semua Setoran Pending'),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Validasi Setoran',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.money_off),
            label: 'Validasi Cair',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Harga',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.sell), label: 'Jual Sampah'),
          // Tambahkan item baru untuk Laporan Bendahara
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Laporan',
          ),
        ],
        currentIndex: 0, // Selalu di 0 karena navigasi menggunakan push
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped, // Gunakan fungsi terpisah
      ),
    );
  }
}
