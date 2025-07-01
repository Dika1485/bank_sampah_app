import 'package:bank_sampah_app/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/providers/auth_provider.dart';
import 'package:bank_sampah_app/providers/transaction_provider.dart';
import 'package:bank_sampah_app/screens/nasabah/buku_tabungan_screen.dart';
import 'package:bank_sampah_app/screens/nasabah/setor_sampah_screen.dart';
import 'package:bank_sampah_app/screens/nasabah/nasabah_chart_widget.dart'; // Widget chart
import 'package:bank_sampah_app/screens/common/profile_screen.dart';
import 'package:bank_sampah_app/screens/auth/login_screen.dart'; // Untuk logout
import 'package:bank_sampah_app/widgets/loading_indicator.dart';
import 'package:intl/intl.dart'; // For currency formatting

class NasabahDashboardScreen extends StatefulWidget {
  const NasabahDashboardScreen({super.key});

  @override
  State<NasabahDashboardScreen> createState() => _NasabahDashboardScreenState();
}

class _NasabahDashboardScreenState extends State<NasabahDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Start listening to transactions for the current user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.appUser != null) {
        Provider.of<TransactionProvider>(
          context,
          listen: false,
        ).listenToNasabahTransactions(authProvider.appUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);

    if (authProvider.appUser == null) {
      // If user data somehow is not loaded, redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
      return const LoadingIndicator(); // Show loading while redirecting
    }

    final String nasabahName = authProvider.appUser?.nama ?? 'Nasabah';
    final String formattedBalance = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(transactionProvider.nasabahBalance);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Nasabah'),
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
                    'Selamat Datang, $nasabahName!',
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
                            'Saldo Buku Tabungan:',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formattedBalance,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
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
                                            const SetorSampahScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Setor Sampah'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
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
                                    // TODO: Implement actual withdrawal request logic
                                    _showWithdrawalDialog(
                                      context,
                                      authProvider.appUser!.id,
                                    );
                                  },
                                  icon: const Icon(Icons.money),
                                  label: const Text('Cairkan Dana'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
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
                    'Analisis Setoran Sampah:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // Display the chart widget
                  if (transactionProvider.nasabahTransactions.isNotEmpty)
                    NasabahChartWidget(
                      transactions: transactionProvider.nasabahTransactions,
                    )
                  else
                    const Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text('Belum ada data setoran untuk grafik.'),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Text(
                    'Riwayat Transaksi Terbaru:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // Display recent transactions
                  transactionProvider.nasabahTransactions.isEmpty
                      ? const Card(
                          elevation: 2,
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text('Belum ada riwayat transaksi.'),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount:
                              transactionProvider.nasabahTransactions.length > 5
                              ? 5
                              : transactionProvider.nasabahTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction =
                                transactionProvider.nasabahTransactions[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: Icon(
                                  transaction.type == TransactionType.setoran
                                      ? Icons.upload_file
                                      : Icons.download,
                                  color:
                                      transaction.type ==
                                          TransactionType.setoran
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                title: Text(
                                  transaction.type == TransactionType.setoran
                                      ? 'Setoran: ${transaction.sampahTypeName}'
                                      : 'Pencairan Dana',
                                ),
                                subtitle: Text(
                                  '${DateFormat('dd MMM yyyy HH:mm').format(transaction.timestamp)} - ${transaction.weightKg > 0 ? '${transaction.weightKg.toStringAsFixed(2)} kg - ' : ''}Status: ${transaction.status.toString().split('.').last.toUpperCase()}',
                                ),
                                trailing: Text(
                                  NumberFormat.currency(
                                    locale: 'id_ID',
                                    symbol: 'Rp ',
                                    decimalDigits: 0,
                                  ).format(transaction.amount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        transaction.type ==
                                            TransactionType.setoran
                                        ? Colors.green
                                        : Colors.red,
                                  ),
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
                            builder: (context) => const BukuTabunganScreen(),
                          ),
                        );
                      },
                      child: const Text('Lihat Semua Riwayat Transaksi'),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_to_photos),
            label: 'Setor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Buku Tabungan',
          ),
        ],
        currentIndex: 0, // Currently on Dashboard
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SetorSampahScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const BukuTabunganScreen(),
              ),
            );
          }
          // Index 0 is current screen, no action needed
        },
      ),
    );
  }

  void _showWithdrawalDialog(BuildContext context, String userId) {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cairkan Dana'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Penarikan (Rp)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Saldo Tersedia: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(Provider.of<TransactionProvider>(context, listen: false).nasabahBalance)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Cairkan'),
              onPressed: () async {
                final double? amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Masukkan jumlah yang valid.'),
                    ),
                  );
                  return;
                }

                // TODO: In a real app, the Pengepul ID for withdrawal would need to be selected or determined.
                // For this example, we'll use a placeholder or assume the current logged-in user is a Pengepul handling it.
                // Or, more realistically, a separate request to a Pengepul would be made.
                // For simplicity, let's assume there's always an 'admin' or 'default' pengepul ID for processing.
                // Or, the Nasabah just requests, and Pengepul's screen will show pending withdrawal requests.
                // Let's modify requestPencairan to not strictly require pengepulId for the initial request.
                // For now, using a dummy ID, but this needs proper flow for multi-user Pengepul.

                final transactionProvider = Provider.of<TransactionProvider>(
                  context,
                  listen: false,
                );
                // Assume there's a dummy pengepulId for now, or fetch from list of active pengepuls
                String dummyPengepulId =
                    'dummy_pengepul_id_001'; // IMPORTANT: This needs proper implementation

                await transactionProvider.requestPencairan(
                  userId: userId,
                  pengepulId: dummyPengepulId,
                  amount: amount,
                );

                if (transactionProvider.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(transactionProvider.errorMessage!)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Permintaan pencairan berhasil diajukan!'),
                    ),
                  );
                  Navigator.of(dialogContext).pop(); // Close dialog
                }
              },
            ),
          ],
        );
      },
    );
  }
}
