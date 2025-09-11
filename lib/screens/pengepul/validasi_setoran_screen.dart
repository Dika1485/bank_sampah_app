import 'package:bank_sampah_app/models/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/providers/transaction_provider.dart';
import 'package:bank_sampah_app/providers/sampah_price_provider.dart';
import 'package:bank_sampah_app/providers/auth_provider.dart';
import 'package:bank_sampah_app/models/transaction.dart';
import 'package:bank_sampah_app/models/sampah.dart';
import 'package:bank_sampah_app/widgets/loading_indicator.dart';
import 'package:intl/intl.dart';

class ValidasiSetoranScreen extends StatefulWidget {
  final String? initialTransactionId;

  const ValidasiSetoranScreen({super.key, this.initialTransactionId});

  @override
  State<ValidasiSetoranScreen> createState() => _ValidasiSetoranScreenState();
}

class _ValidasiSetoranScreenState extends State<ValidasiSetoranScreen> {
  final TextEditingController _actualWeightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Transaction? _selectedTransaction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );

      transactionProvider.listenToPendingPengepulValidations();

      if (widget.initialTransactionId != null) {
        final transactions = transactionProvider.pendingPengepulValidations;

        Transaction? foundTx;
        for (var tx in transactions) {
          if (tx.id == widget.initialTransactionId) {
            foundTx = tx;
            break;
          }
        }

        if (foundTx != null) {
          setState(() {
            _selectedTransaction = foundTx;
            _actualWeightController.text = foundTx!.weightKg.toStringAsFixed(2);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _actualWeightController.dispose();
    super.dispose();
  }

  void _validateSetoran() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTransaction == null) {
      _showSnackBar('Pilih setoran yang akan divalidasi.');
      return;
    }

    final double actualWeight = double.parse(_actualWeightController.text);
    if (actualWeight <= 0) {
      _showSnackBar('Masukkan berat aktual yang valid (lebih dari 0).');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    final sampahPriceProvider = Provider.of<SampahPriceProvider>(
      context,
      listen: false,
    );

    final String? currentPengepulId = authProvider.appUser?.id;
    if (currentPengepulId == null ||
        authProvider.appUser?.userType != UserType.bendahara) {
      _showSnackBar('Anda tidak memiliki izin untuk melakukan validasi.');
      return;
    }

    final SampahType? sampahType = sampahPriceProvider.getSampahTypeById(
      _selectedTransaction!.sampahTypeId,
    );
    if (sampahType == null) {
      _showSnackBar(
        'Jenis sampah tidak ditemukan atau harga belum dimuat. Harap periksa koneksi atau data harga sampah.',
      );
      return;
    }

    try {
      await transactionProvider.validateSetoran(
        transactionId: _selectedTransaction!.id,
        pengepulId: currentPengepulId,
        actualWeightKg: actualWeight,
        sampahType: sampahType,
        userId: _selectedTransaction!.userId,
      );

      if (!mounted) return;

      if (transactionProvider.errorMessage != null) {
        _showSnackBar(transactionProvider.errorMessage!, isError: true);
      } else {
        _showSnackBar(
          'Setoran berhasil divalidasi dan saldo nasabah diperbarui.',
        );
        setState(() {
          _selectedTransaction = null;
          _actualWeightController.clear();
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Terjadi kesalahan: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mengubah Consumer2 menjadi Consumer3 untuk mengakses AuthProvider
    return Scaffold(
      appBar: AppBar(title: const Text('Validasi Setoran Sampah')),
      body: Consumer3<TransactionProvider, SampahPriceProvider, AuthProvider>(
        builder: (context, transactionProvider, sampahPriceProvider, authProvider, child) {
          // Fungsi helper untuk mendapatkan nama pengguna dari AuthProvider
          String getUserName(String userId) {
            try {
              final user = authProvider.allUsers.firstWhere(
                (user) => user.id == userId,
              );
              return user.nama;
            } catch (e) {
              return 'Nama tidak ditemukan';
            }
          }

          if (transactionProvider.isLoading ||
              sampahPriceProvider.isLoading ||
              authProvider.isLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (transactionProvider.errorMessage != null) {
            return Center(
              child: Text(
                'Error Transaksi: ${transactionProvider.errorMessage}\nHarap coba lagi.',
              ),
            );
          }
          if (sampahPriceProvider.errorMessage != null) {
            return Center(
              child: Text(
                'Error Harga Sampah: ${sampahPriceProvider.errorMessage}\nHarap coba lagi.',
              ),
            );
          }
          if (authProvider.errorMessage != null) {
            return Center(
              child: Text(
                'Error User: ${authProvider.errorMessage}\nHarap coba lagi.',
              ),
            );
          }

          final List<Transaction> pendingTransactions =
              transactionProvider.pendingPengepulValidations;

          return Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Setoran untuk Divalidasi:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<Transaction>(
                        value: _selectedTransaction,
                        decoration: const InputDecoration(
                          labelText: 'Setoran Pending',
                          border: OutlineInputBorder(),
                          helperText: 'Pilih setoran dari daftar di bawah',
                        ),
                        items: pendingTransactions.map((tx) {
                          // Menggunakan nama pengguna di DropdownMenuItem
                          final userName = getUserName(tx.userId);
                          return DropdownMenuItem<Transaction>(
                            value: tx,
                            child: Text(
                              '${DateFormat('dd MMM yyyy, HH:mm').format(tx.timestamp)} - ${tx.sampahTypeName} (${tx.weightKg.toStringAsFixed(2)} kg) dari: $userName',
                            ),
                          );
                        }).toList(),
                        onChanged: (Transaction? newValue) {
                          setState(() {
                            _selectedTransaction = newValue;
                            if (newValue != null) {
                              _actualWeightController.text = newValue.weightKg
                                  .toStringAsFixed(2);
                            } else {
                              _actualWeightController.clear();
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Pilih setoran yang akan divalidasi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      if (_selectedTransaction != null) ...[
                        Text(
                          'Jenis Sampah: ${_selectedTransaction!.sampahTypeName}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Estimasi Berat: ${_selectedTransaction!.weightKg.toStringAsFixed(2)} kg',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Harga per kg: Rp ${sampahPriceProvider.getSampahTypeById(_selectedTransaction!.sampahTypeId)?.pricePerKg.toStringAsFixed(0) ?? '0'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Berat Aktual (kg):',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _actualWeightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Masukkan berat aktual',
                            hintText: 'Contoh: 2.50',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Berat aktual tidak boleh kosong';
                            }
                            final double? weight = double.tryParse(value);
                            if (weight == null || weight <= 0) {
                              return 'Masukkan berat yang valid (angka positif)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: transactionProvider.isLoading
                                ? null
                                : _validateSetoran,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 15,
                              ),
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: transactionProvider.isLoading
                                ? const LoadingIndicator(color: Colors.white)
                                : const Text(
                                    'Validasi Setoran',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                      if (pendingTransactions.isEmpty &&
                          _selectedTransaction == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(
                            child: Text(
                              'Tidak ada setoran pending yang tersedia untuk divalidasi.',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Daftar Semua Setoran Pending (${pendingTransactions.length}):',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: pendingTransactions.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada setoran yang menunggu validasi.',
                          ),
                        )
                      : ListView.builder(
                          itemCount: pendingTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = pendingTransactions[index];
                            // Menggunakan nama pengguna di ListTile
                            final userName = getUserName(transaction.userId);
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              elevation: 2,
                              child: ListTile(
                                leading: const Icon(
                                  Icons.pending,
                                  color: Colors.orange,
                                ),
                                title: Text(
                                  'Setoran dari: $userName',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Jenis Sampah: ${transaction.sampahTypeName}\n'
                                  'Estimasi Berat: ${transaction.weightKg.toStringAsFixed(2)} kg\n'
                                  'Tanggal: ${DateFormat('dd MMM yyyy, HH:mm').format(transaction.timestamp)}',
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedTransaction = transaction;
                                      _actualWeightController.text = transaction
                                          .weightKg
                                          .toStringAsFixed(2);
                                    });
                                  },
                                  child: const Text('Pilih'),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
