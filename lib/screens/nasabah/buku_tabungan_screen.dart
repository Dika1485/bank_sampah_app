import 'package:bank_sampah_app/utils/pdf_generator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/providers/auth_provider.dart';
import 'package:bank_sampah_app/providers/transaction_provider.dart';
import 'package:bank_sampah_app/widgets/loading_indicator.dart';
import 'package:intl/intl.dart';
import 'package:bank_sampah_app/models/transaction.dart';

// Import ini diperlukan untuk mengelola tanggal.
import 'package:bank_sampah_app/utils/date_filter_util.dart';

class BukuTabunganScreen extends StatefulWidget {
  const BukuTabunganScreen({super.key});

  @override
  State<BukuTabunganScreen> createState() => _BukuTabunganScreenState();
}

class _BukuTabunganScreenState extends State<BukuTabunganScreen> {
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

  // Fungsi untuk menampilkan dialog pilihan cetak
  void _showPrintOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text(
            'Cetak Laporan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                _generateReport('Mingguan');
              },
              child: const Text('Mingguan', style: TextStyle(fontSize: 16)),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                _generateReport('Bulanan');
              },
              child: const Text('Bulanan', style: TextStyle(fontSize: 16)),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                _generateReport('Tahunan');
              },
              child: const Text('Tahunan', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk memfilter transaksi dan memanggil generator PDF
  Future<void> _generateReport(String period) async {
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.appUser == null) return;

    final allTransactions = transactionProvider.nasabahTransactions;
    List<Transaction> filteredTransactions = [];

    // Logika untuk memfilter berdasarkan periode
    switch (period) {
      case 'Mingguan':
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        filteredTransactions = allTransactions
            .where((t) => t.timestamp.isAfter(sevenDaysAgo))
            .toList();
        break;
      case 'Bulanan':
        final startOfMonth = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          1,
        );
        filteredTransactions = allTransactions
            .where((t) => t.timestamp.isAfter(startOfMonth))
            .toList();
        break;
      case 'Tahunan':
        final startOfYear = DateTime(DateTime.now().year, 1, 1);
        filteredTransactions = allTransactions
            .where((t) => t.timestamp.isAfter(startOfYear))
            .toList();
        break;
      default:
        // Jika tidak ada pilihan, gunakan semua transaksi
        filteredTransactions = allTransactions;
        break;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Membuat laporan $period...')));

    await PdfGenerator.generateNasabahReport(
      nasabah: authProvider.appUser!,
      transactions: filteredTransactions,
      currentBalance: transactionProvider.nasabahBalance,
      period: period,
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Laporan berhasil dibuat!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final String formattedBalance = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(transactionProvider.nasabahBalance);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buku Tabungan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // Panggil fungsi untuk menampilkan pilihan
              _showPrintOptions();
            },
          ),
        ],
      ),
      body: transactionProvider.isLoading
          ? const LoadingIndicator()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
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
                            'Saldo Saat Ini:',
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
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Riwayat Lengkap Transaksi:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: transactionProvider.nasabahTransactions.isEmpty
                      ? const Center(
                          child: Text('Belum ada riwayat transaksi.'),
                        )
                      : ListView.builder(
                          itemCount:
                              transactionProvider.nasabahTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction =
                                transactionProvider.nasabahTransactions[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
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
                ),
              ],
            ),
    );
  }
}
