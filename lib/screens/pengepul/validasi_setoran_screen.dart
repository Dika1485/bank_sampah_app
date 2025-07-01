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
  final String? initialTransactionId; // Optional: to pre-select a transaction

  const ValidasiSetoranScreen({super.key, this.initialTransactionId});

  @override
  State<ValidasiSetoranScreen> createState() => _ValidasiSetoranScreenState();
}

class _ValidasiSetoranScreenState extends State<ValidasiSetoranScreen> {
  final TextEditingController _actualWeightController = TextEditingController();
  Transaction? _selectedTransaction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).listenToPendingPengepulValidations();
      Provider.of<SampahPriceProvider>(
        context,
        listen: false,
      ).sampahTypes; // Ensure prices are loaded

      if (widget.initialTransactionId != null) {
        // Find and pre-select the transaction if ID is provided
        final transactions = Provider.of<TransactionProvider>(
          context,
          listen: false,
        ).pendingPengepulValidations;
        final initialTx = transactions.firstWhereOrNull(
          (tx) => tx.id == widget.initialTransactionId,
        );
        if (initialTx != null) {
          setState(() {
            _selectedTransaction = initialTx;
            _actualWeightController.text = initialTx.weightKg.toStringAsFixed(
              2,
            );
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
    if (_selectedTransaction == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih setoran yang akan divalidasi.')),
      );
      return;
    }

    final double? actualWeight = double.tryParse(_actualWeightController.text);
    if (actualWeight == null || actualWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan berat aktual yang valid.')),
      );
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

    if (authProvider.appUser == null ||
        authProvider.appUser!.userType != UserType.pengepul) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda tidak memiliki izin untuk melakukan validasi.'),
        ),
      );
      return;
    }

    final SampahType? sampahType = sampahPriceProvider.getSampahTypeById(
      _selectedTransaction!.sampahTypeId,
    );
    if (sampahType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jenis sampah tidak ditemukan.')),
      );
      return;
    }

    await transactionProvider.validateSetoran(
      transactionId: _selectedTransaction!.id,
      pengepulId: authProvider.appUser!.id,
      actualWeightKg: actualWeight,
      sampahType: sampahType,
    );

    if (!mounted) return;

    if (transactionProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(transactionProvider.errorMessage!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Setoran berhasil divalidasi dan saldo nasabah diperbarui.',
          ),
        ),
      );
      setState(() {
        _selectedTransaction = null; // Clear selected after validation
        _actualWeightController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Validasi Setoran Sampah')),
      body: Consumer2<TransactionProvider, SampahPriceProvider>(
        builder: (context, transactionProvider, sampahPriceProvider, child) {
          if (transactionProvider.isLoading || sampahPriceProvider.isLoading) {
            return const LoadingIndicator();
          }

          if (transactionProvider.errorMessage != null) {
            return Center(
              child: Text('Error: ${transactionProvider.errorMessage}'),
            );
          }

          final List<Transaction> pending =
              transactionProvider.pendingPengepulValidations;

          return Column(
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
                      ),
                      items: pending.map((tx) {
                        return DropdownMenuItem<Transaction>(
                          value: tx,
                          child: Text(
                            '${DateFormat('dd MMM HH:mm').format(tx.timestamp)} - ${tx.sampahTypeName} (${tx.weightKg.toStringAsFixed(2)} kg) dari User ID: ${tx.userId.substring(0, 8)}...',
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
                        'Harga per kg: Rp ${sampahPriceProvider.getSampahTypeById(_selectedTransaction!.sampahTypeId)?.pricePerKg.toStringAsFixed(0) ?? 'N/A'}',
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
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Masukkan berat aktual',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Berat aktual tidak boleh kosong';
                          }
                          if (double.tryParse(value) == null ||
                              double.parse(value) <= 0) {
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
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Daftar Semua Setoran Pending (${pending.length}):',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: pending.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada setoran yang menunggu validasi.',
                        ),
                      )
                    : ListView.builder(
                        itemCount: pending.length,
                        itemBuilder: (context, index) {
                          final transaction = pending[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.pending,
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
          );
        },
      ),
    );
  }
}

// Extension to add firstWhereOrNull for convenience
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
