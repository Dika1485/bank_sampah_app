import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/providers/auth_provider.dart';
import 'package:bank_sampah_app/providers/transaction_provider.dart';
import 'package:bank_sampah_app/screens/pengepul/validasi_setoran_screen.dart';
import 'package:bank_sampah_app/screens/pengepul/harga_sampah_screen.dart';
import 'package:bank_sampah_app/screens/pengepul/pengepul_chart_widget.dart'; // Pengepul specific chart
import 'package:bank_sampah_app/screens/common/profile_screen.dart';
import 'package:bank_sampah_app/screens/auth/login_screen.dart'; // Untuk logout
import 'package:bank_sampah_app/widgets/loading_indicator.dart';
import 'package:intl/intl.dart';
import 'package:bank_sampah_app/screens/pengepul/validasi_pencairan_screen.dart'; // Import for withdrawal validation screen

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
      // Pengepul perlu mendengarkan setoran pending
      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).listenToPendingPengepulValidations();
      // --- TAMBAHAN: Pengepul juga perlu mendengarkan permintaan pencairan pending ---
      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).listenToPendingWithdrawalRequests();
      // ----------------------------------------------------------------------------------
      // TODO: Pengepul dashboard might also need aggregated historical data
      // For a full Pengepul report, all completed transactions might be needed.
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);

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
                  // Card untuk Setoran Menunggu Validasi
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ValidasiSetoranScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.pending_actions,
                              size: 40,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Setoran Menunggu Validasi:',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '$pendingSetoranCount Transaksi',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Card untuk Permintaan Pencairan Pending
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: InkWell(
                      onTap: () {
                        // Navigasi ke layar validasi pencairan
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const ValidasiPencairanScreen(), // Anda perlu membuat layar ini
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet,
                              size: 40,
                              color: Colors.purple,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Permintaan Pencairan Pending:',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '$pendingWithdrawalCount Permintaan',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Card untuk Mengelola Harga Sampah
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const HargaSampahScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.price_change,
                              size: 40,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Kelola Harga Sampah:',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Atur harga beli sampah',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Analisis Operasional:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // Pengepul Chart (requires all transactions, not just pending)
                  // TODO: Pengepul chart data should be based on ALL validated transactions, not just Nasabah's.
                  // Currently using nasabahTransactions as a placeholder. You'll need to add a new stream
                  // to TransactionProvider to fetch all completed transactions relevant to the pengepul.
                  PengepulChartWidget(
                    transactions: transactionProvider.nasabahTransactions,
                  ),
                  const SizedBox(height: 20),
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
            label: 'Validasi Setoran', // Label diubah agar lebih jelas
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.money_off), // Icon untuk validasi pencairan
            label: 'Validasi Cair', // Label untuk validasi pencairan
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Harga',
          ),
        ],
        currentIndex: 0, // Currently on Dashboard
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ValidasiSetoranScreen(),
              ),
            );
          } else if (index == 2) {
            // Navigasi ke Validasi Pencairan
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    const ValidasiPencairanScreen(), // Pastikan layar ini ada
              ),
            );
          } else if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const HargaSampahScreen(),
              ),
            );
          }
          // Index 0 is current screen, no action needed
        },
      ),
    );
  }
}
