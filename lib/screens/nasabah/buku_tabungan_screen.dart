import 'package:bank_sampah_app/utils/pdf_generator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/providers/auth_provider.dart';
import 'package:bank_sampah_app/providers/transaction_provider.dart';
import 'package:bank_sampah_app/widgets/loading_indicator.dart';
import 'package:intl/intl.dart';
import 'package:bank_sampah_app/models/transaction.dart';
// Tidak perlu import 'package:bank_sampah_app/utils/pdf_generator.dart'; di sini jika hanya untuk PDF,
// tapi jika ada penggunaan lain biarkan saja.

class BukuTabunganScreen extends StatefulWidget {
  const BukuTabunganScreen({super.key});

  @override
  State<BukuTabunganScreen> createState() => _BukuTabunganScreenState();
}

class _BukuTabunganScreenState extends State<BukuTabunganScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure transactions and balance are loaded for the current user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.appUser != null) {
        // --- PERUBAHAN DI SINI: listenToNasabahData() ---
        Provider.of<TransactionProvider>(
          context,
          listen: false,
        ).listenToNasabahData(authProvider.appUser!.id);
        // --------------------------------------------------
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

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
            onPressed: () async {
              if (authProvider.appUser != null) {
                await PdfGenerator.generateNasabahReport(
                  nasabah: authProvider.appUser!,
                  transactions: transactionProvider.nasabahTransactions,
                  currentBalance: transactionProvider.nasabahBalance,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Fungsi cetak laporan sedang dikembangkan.',
                      ),
                    ),
                  );
                }
              }
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
