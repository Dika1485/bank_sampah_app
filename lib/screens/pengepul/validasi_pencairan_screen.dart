import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:bank_sampah_app/providers/transaction_provider.dart';
import 'package:bank_sampah_app/providers/auth_provider.dart';
import 'package:bank_sampah_app/widgets/loading_indicator.dart';
import 'package:bank_sampah_app/models/withdrawal_request.dart';

class ValidasiPencairanScreen extends StatefulWidget {
  const ValidasiPencairanScreen({super.key});

  @override
  State<ValidasiPencairanScreen> createState() =>
      _ValidasiPencairanScreenState();
}

class _ValidasiPencairanScreenState extends State<ValidasiPencairanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).listenToPendingWithdrawalRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentPengepulId = authProvider.appUser?.id;

    if (currentPengepulId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Validasi Pencairan Dana')),
        body: const Center(child: Text('Anda belum login sebagai pengepul.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Validasi Pencairan Dana Nasabah')),
      body: transactionProvider.isLoading
          ? const LoadingIndicator() // Ini yang akan aktif saat isLoading true
          : transactionProvider.pendingWithdrawalRequests.isEmpty
          ? const Center(
              child: Text('Tidak ada permintaan pencairan dana yang menunggu.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: transactionProvider.pendingWithdrawalRequests.length,
              itemBuilder: (context, index) {
                final request =
                    transactionProvider.pendingWithdrawalRequests[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dari: ${request.userName}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Jumlah: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(request.amount)}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tanggal Permintaan: ${DateFormat('dd MMM HH:mm').format(request.timestamp)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Menambahkan kondisi disabled jika sedang loading
                            ElevatedButton(
                              onPressed: transactionProvider.isLoading
                                  ? null
                                  : () => _processWithdrawal(
                                      context,
                                      request,
                                      currentPengepulId,
                                      true,
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Setujui'),
                            ),
                            const SizedBox(width: 8),
                            // Menambahkan kondisi disabled jika sedang loading
                            OutlinedButton(
                              onPressed: transactionProvider.isLoading
                                  ? null
                                  : () => _processWithdrawal(
                                      context,
                                      request,
                                      currentPengepulId,
                                      false,
                                    ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                              ),
                              child: const Text('Tolak'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _processWithdrawal(
    BuildContext context,
    WithdrawalRequest request,
    String pengepulId,
    bool approve,
  ) async {
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );

    // --- HAPUS showDialog() DAN Navigator.of(context).pop() DI SINI ---
    // Logika loading sekarang ditangani oleh Provider di method build

    try {
      await transactionProvider.processWithdrawalRequest(
        request,
        pengepulId,
        approve,
      );
      if (mounted) {
        // Cek errorMessage dari provider setelah operasi selesai
        if (transactionProvider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${transactionProvider.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                approve
                    ? 'Permintaan pencairan disetujui!'
                    : 'Permintaan pencairan ditolak.',
              ),
              backgroundColor: approve ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Catch blok ini mungkin tidak akan terpanggil jika error ditangani di provider
      // Namun, baik untuk berjaga-jaga jika ada error yang tidak tertangkap oleh provider
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan tak terduga: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
