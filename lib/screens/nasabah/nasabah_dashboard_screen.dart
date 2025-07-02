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
import 'package:bank_sampah_app/models/user.dart'; // Import AppUser

class NasabahDashboardScreen extends StatefulWidget {
  const NasabahDashboardScreen({super.key});

  @override
  State<NasabahDashboardScreen> createState() => _NasabahDashboardScreenState();
}

class _NasabahDashboardScreenState extends State<NasabahDashboardScreen> {
  // HAPUS _isWithdrawalLoading: State loading akan dikelola oleh TransactionProvider
  // bool _isWithdrawalLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.appUser != null) {
        Provider.of<TransactionProvider>(
          context,
          listen: false,
        ).listenToNasabahData(authProvider.appUser!.id);
      }
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
      return const LoadingIndicator(); // Tampilkan loading saat redirect
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
        ],
      ),
      body:
          transactionProvider.isLoading &&
              transactionProvider.errorMessage == null
          ? const LoadingIndicator() // Tampilkan loading jika ada operasi global di provider dan tidak ada error
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
                                    // Pastikan appUser tidak null sebelum memanggil dialog
                                    if (authProvider.appUser != null) {
                                      _showWithdrawalDialog(
                                        context,
                                        authProvider.appUser!.id,
                                        authProvider.appUser!.nama,
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Anda harus login untuk mencairkan dana.',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
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
                                  '${DateFormat('dd MMM HH:mm').format(transaction.timestamp)} - ${transaction.weightKg > 0 ? '${transaction.weightKg.toStringAsFixed(2)} kg - ' : ''}Status: ${transaction.status.toString().split('.').last.toUpperCase()}',
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
        currentIndex: 0,
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
        },
      ),
    );
  }

  // --- Fungsi _showWithdrawalDialog yang direvisi ---
  void _showWithdrawalDialog(
    BuildContext context,
    String userId,
    String userName,
  ) {
    final TextEditingController amountController = TextEditingController();
    // selectedPengepul dideklarasikan di sini agar state-nya dikelola oleh StatefulBuilder
    AppUser? selectedPengepul;

    showDialog(
      context: context,
      barrierDismissible:
          false, // Tidak bisa ditutup dengan tap di luar saat proses
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Kita mendapatkan provider di dalam StatefulBuilder/Consumer
            // Agar dialog bisa bereaksi terhadap perubahan isLoading dari provider
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            final transactionProvider = Provider.of<TransactionProvider>(
              context,
            ); // listen: true agar rebuild

            return AlertDialog(
              title: const Text('Cairkan Dana'),
              content: SingleChildScrollView(
                child: Column(
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
                      'Saldo Tersedia: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(transactionProvider.nasabahBalance)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<AppUser>>(
                      future: authProvider.fetchPengepulUsers(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Text(
                            'Error memuat pengepul: ${snapshot.error}',
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text('Tidak ada pengepul tersedia.');
                        }

                        List<AppUser> pengepulList = snapshot.data!;
                        // Inisialisasi selectedPengepul jika belum ada
                        if (selectedPengepul == null &&
                            pengepulList.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setDialogState(() {
                              selectedPengepul = pengepulList.first;
                            });
                          });
                        }

                        return DropdownButtonFormField<AppUser>(
                          value: selectedPengepul,
                          decoration: const InputDecoration(
                            labelText: 'Pilih Pengepul',
                            border: OutlineInputBorder(),
                          ),
                          items: pengepulList.map((pengepul) {
                            return DropdownMenuItem(
                              value: pengepul,
                              child: Text(pengepul.nama),
                            );
                          }).toList(),
                          onChanged: (AppUser? newValue) {
                            setDialogState(() {
                              // Gunakan setDialogState untuk memperbarui UI dialog
                              selectedPengepul = newValue;
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                ElevatedButton(
                  // Tombol dinonaktifkan jika transactionProvider.isLoading atau belum ada pengepul terpilih
                  onPressed:
                      transactionProvider.isLoading || selectedPengepul == null
                      ? null
                      : () async {
                          final double? amount = double.tryParse(
                            amountController.text,
                          );

                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text('Masukkan jumlah yang valid.'),
                              ),
                            );
                            return;
                          }

                          if (amount > transactionProvider.nasabahBalance) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Saldo tidak mencukupi. Saldo Anda: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(transactionProvider.nasabahBalance)}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          try {
                            // Panggil requestPencairan. Provider akan mengelola status loading dan error-nya.
                            await transactionProvider.requestPencairan(
                              userId: userId,
                              userName: userName,
                              amount: amount,
                            );

                            // Periksa errorMessage dari provider setelah operasi selesai
                            if (transactionProvider.errorMessage != null) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    transactionProvider.errorMessage!,
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } else {
                              // Jika berhasil, tutup dialog dan tampilkan snackbar sukses di parent context
                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                // Gunakan context dari widget utama
                                const SnackBar(
                                  content: Text(
                                    'Permintaan pencairan berhasil diajukan!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            // Catch-all untuk error tak terduga yang mungkin tidak ditangani provider
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Terjadi kesalahan tak terduga: $e',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          // Block finally tidak diperlukan di sini karena transactionProvider sudah mengelola isLoading
                        },
                  // Tampilkan LoadingIndicator di dalam tombol jika provider sedang loading
                  child: transactionProvider.isLoading
                      ? const LoadingIndicator(color: Colors.white)
                      : const Text('Cairkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
