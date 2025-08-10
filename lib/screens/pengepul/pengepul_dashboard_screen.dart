import 'package:bank_sampah_app/providers/bank_balance_provider.dart';
import 'package:bank_sampah_app/screens/pengepul/manage_products_screen.dart';
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
import 'package:bank_sampah_app/screens/pengepul/sell_waste_screen.dart'; // Import halaman baru

class PengepulDashboardScreen extends StatefulWidget {
  const PengepulDashboardScreen({super.key});

  @override
  State<PengepulDashboardScreen> createState() =>
      _PengepulDashboardScreenState();
}

class _PengepulDashboardScreenState extends State<PengepulDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).listenToPendingPengepulValidations();
      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).listenToPendingWithdrawalRequests();
    });
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

    final String pengepulName = authProvider.appUser?.nama ?? 'Pengepul';
    final int pendingSetoranCount =
        transactionProvider.pendingPengepulValidations.length;
    final int pendingWithdrawalCount =
        transactionProvider.pendingWithdrawalRequests.length;
    final double totalRevenue = bankBalanceProvider.totalRevenue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Pengepul'),
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
                    color: Colors.lightGreen,
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
                      backgroundColor: Colors.green[700],
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
                  // Bar Chart untuk berat sampah per jenis
                  PengepulBarChartWidget(
                    transactions: transactionProvider
                        .nasabahTransactions, // Asumsikan ini berisi semua transaksi setoran
                  ),
                  const SizedBox(height: 20),
                  // Line Chart untuk berat sampah per bulan
                  PengepulChartWidget(
                    transactions: transactionProvider
                        .nasabahTransactions, // Asumsikan ini berisi semua transaksi setoran
                  ),
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
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.hourglass_empty,
                                  color: Colors.orange,
                                ),
                                title: Text(
                                  'Setoran dari User ID: ${transaction.userId.substring(0, 8)}...',
                                ),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Produk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sell), // Ikon baru untuk Jual Sampah
            label: 'Jual Sampah', // Label baru
          ),
        ],
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ValidasiSetoranScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ValidasiPencairanScreen(),
              ),
            );
          } else if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const HargaSampahScreen(),
              ),
            );
          } else if (index == 4) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ManageProductsScreen(),
              ),
            );
          } else if (index == 5) {
            // Index baru untuk Jual Sampah
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SellWasteScreen()),
            );
          }
        },
      ),
    );
  }
}
