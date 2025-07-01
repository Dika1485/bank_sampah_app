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
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
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
                          const Text(
                            'Setoran Menunggu Validasi:',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${transactionProvider.pendingPengepulValidations.length} Permintaan',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ValidasiSetoranScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Validasi Setoran'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const HargaSampahScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.attach_money),
                                  label: const Text('Atur Harga'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
                  // For simplicity, let's pass Nasabah's transactions here,
                  // but in a real app, you'd fetch all relevant transactions for the Pengepul.
                  PengepulChartWidget(
                    transactions: transactionProvider.nasabahTransactions,
                  ),
                  // TODO: Pengepul chart data should be based on ALL validated transactions, not just Nasabah's
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
                                  '${DateFormat('dd MMM yyyy HH:mm').format(transaction.timestamp)}',
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
            label: 'Validasi',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.money), label: 'Harga'),
        ],
        currentIndex: 0, // Currently on Dashboard
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
