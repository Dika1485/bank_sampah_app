import 'package:bank_sampah_app/utils/pdf_generator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/providers/auth_provider.dart';
import 'package:bank_sampah_app/providers/transaction_provider.dart';
import 'package:bank_sampah_app/widgets/loading_indicator.dart';
import 'package:intl/intl.dart';
import 'package:bank_sampah_app/models/transaction.dart';
import 'package:bank_sampah_app/utils/date_filter_util.dart';

class LaporanBendaharaScreen extends StatefulWidget {
  const LaporanBendaharaScreen({super.key});

  @override
  State<LaporanBendaharaScreen> createState() => _LaporanBendaharaScreenState();
}

class _LaporanBendaharaScreenState extends State<LaporanBendaharaScreen> {
  @override
  void initState() {
    super.initState();
    // Memuat semua transaksi saat layar diinisialisasi
    // Asumsi: TransactionProvider memiliki method untuk ini
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).listenToAllTransactions();
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

    final allTransactions = transactionProvider.allTransactions;

    final filteredTransactions = DateFilterUtil.filterTransactionsByPeriod(
      allTransactions,
      period,
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Membuat laporan $period...')));

    // Memanggil fungsi baru di PdfGenerator untuk bendahara
    await PdfGenerator.generateBendaharaReport(
      bendahara: authProvider.appUser!,
      allTransactions: filteredTransactions,
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

    // Data ringkasan untuk tampilan dashboard
    final Map<String, dynamic> summary = DateFilterUtil.calculateSummary(
      transactionProvider.allTransactions,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Bendahara'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              _showPrintOptions();
            },
          ),
        ],
      ),
      body: transactionProvider.isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ringkasan Transaksi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tampilan kartu ringkasan
                    _buildSummaryCard(
                      title: 'Total Setoran Sampah',
                      value: NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(summary['totalSetoran']),
                      color: Colors.green,
                    ),
                    _buildSummaryCard(
                      title: 'Total Pencairan Dana',
                      value: NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(summary['totalPencairan']),
                      color: Colors.red,
                    ),
                    _buildSummaryCard(
                      title: 'Total Penjualan Sampah',
                      value: NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(summary['totalJualSampah']),
                      color: Colors.blue,
                    ),
                    _buildSummaryCard(
                      title: 'Total Penjualan Produk',
                      value: NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(summary['totalProduk']),
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Riwayat Transaksi Terakhir:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Daftar riwayat transaksi
                    if (transactionProvider.allTransactions.isEmpty)
                      const Center(child: Text('Belum ada riwayat transaksi.'))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: transactionProvider.allTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction =
                              transactionProvider.allTransactions[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Icon(
                                transaction.type == TransactionType.setoran
                                    ? Icons.upload_file
                                    : transaction.type ==
                                          TransactionType.pencairan
                                    ? Icons.download
                                    : Icons
                                          .shopping_bag, // Asumsi ikon untuk jenis lain
                                color: _getIconColor(transaction.type),
                              ),
                              title: Text(_getTransactionTitle(transaction)),
                              subtitle: Text(
                                '${DateFormat('dd MMM HH:mm').format(transaction.timestamp)} - ${transaction.status.toString().split('.').last.toUpperCase()}',
                              ),
                              trailing: Text(
                                NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0,
                                ).format(transaction.amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getIconColor(transaction.type),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getIconColor(TransactionType type) {
    switch (type) {
      case TransactionType.setoran:
        return Colors.green;
      case TransactionType.pencairan:
        return Colors.red;
      case TransactionType.jualsampah:
        return Colors.blue;
      case TransactionType.produk:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getTransactionTitle(Transaction transaction) {
    switch (transaction.type) {
      case TransactionType.setoran:
        return 'Setoran: ${transaction.sampahTypeName}';
      case TransactionType.pencairan:
        return 'Pencairan Dana';
      case TransactionType.jualsampah:
        return 'Jual Sampah ke Pabrik';
      case TransactionType.produk:
        return 'Penjualan Produk';
      default:
        return 'Transaksi Tidak Dikenal';
    }
  }
}
