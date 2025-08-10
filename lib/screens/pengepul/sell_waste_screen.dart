import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/providers/transaction_provider.dart';
import 'package:bank_sampah_app/models/sampah.dart';
import 'package:bank_sampah_app/providers/sampah_price_provider.dart';

class SellWasteScreen extends StatefulWidget {
  const SellWasteScreen({super.key});

  @override
  State<SellWasteScreen> createState() => _SellWasteScreenState();
}

class _SellWasteScreenState extends State<SellWasteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _revenueController = TextEditingController();
  final Map<String, TextEditingController> _wasteControllers = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller untuk setiap jenis sampah
    // Akses SampahPriceProvider untuk mendapatkan daftar jenis sampah
    final sampahProvider = Provider.of<SampahPriceProvider>(
      context,
      listen: false,
    );
    for (var sampahType in sampahProvider.sampahTypes) {
      _wasteControllers[sampahType.name] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _revenueController.dispose();
    _wasteControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _sellWaste() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final Map<String, double> soldWaste = {};
        _wasteControllers.forEach((type, controller) {
          final value = double.tryParse(controller.text);
          if (value != null && value > 0) {
            soldWaste[type] = value;
          }
        });

        // Pastikan ada setidaknya satu sampah yang dijual
        if (soldWaste.isEmpty) {
          throw Exception('Pilih setidaknya satu jenis sampah yang dijual.');
        }

        final double totalRevenue =
            double.tryParse(_revenueController.text) ?? 0.0;

        // Pastikan totalRevenue valid
        if (totalRevenue <= 0) {
          throw Exception('Total harga harus lebih dari Rp 0.');
        }

        // Panggil fungsi sellWaste dari TransactionProvider
        await Provider.of<TransactionProvider>(
          context,
          listen: false,
        ).sellWaste(soldWaste, totalRevenue);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Penjualan berhasil dicatat!')),
        );

        Navigator.of(context).pop();
      } on Exception catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer untuk mendengarkan perubahan dari kedua provider
    return Consumer2<SampahPriceProvider, TransactionProvider>(
      builder: (context, sampahProvider, transactionProvider, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Jual Sampah')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const Text('Masukkan jumlah sampah (kg) yang dijual:'),
                  const SizedBox(height: 16),
                  // Loop melalui jenis sampah dari SampahPriceProvider
                  ...sampahProvider.sampahTypes.map((sampahType) {
                    // Dapatkan stok saat ini dari TransactionProvider
                    final currentStock =
                        transactionProvider.wasteStock[sampahType.name] ?? 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: TextFormField(
                        controller: _wasteControllers[sampahType.name],
                        decoration: InputDecoration(
                          labelText: '${sampahType.name} (kg)',
                          border: const OutlineInputBorder(),
                          suffixText:
                              'Stok: ${currentStock.toStringAsFixed(2)} kg', // Tampilkan stok
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final soldAmount = double.tryParse(value);
                            if (soldAmount == null || soldAmount < 0) {
                              return 'Masukkan angka yang valid';
                            }
                            if (soldAmount > currentStock) {
                              return 'Stok tidak mencukupi. Tersedia: ${currentStock.toStringAsFixed(2)} kg';
                            }
                          }
                          return null;
                        },
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                  const Text('Masukkan total harga yang diterima:'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _revenueController,
                    decoration: const InputDecoration(
                      labelText: 'Total Harga (Rp)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Total harga harus diisi';
                      }
                      if (double.tryParse(value) == null ||
                          double.tryParse(value)! <= 0) {
                        return 'Masukkan total harga yang valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _sellWaste,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                          ),
                          child: const Text('Simpan Transaksi Penjualan'),
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
