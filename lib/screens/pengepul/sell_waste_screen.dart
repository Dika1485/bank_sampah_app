import 'package:bank_sampah_app/providers/auth_provider.dart';
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

  // --- Fungsi Tambahan: Pengecekan Kuantitas Sampah Total ---
  Map<String, double> _getSoldWasteQuantities() {
    final Map<String, double> soldWaste = {};
    _wasteControllers.forEach((type, controller) {
      // Gunakan nilai yang sudah divalidasi oleh TextFormField (hanya perlu parse)
      final value = double.tryParse(controller.text);
      if (value != null && value > 0) {
        soldWaste[type] = value;
      }
    });
    return soldWaste;
  }

  Future<void> _sellWaste() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String? currentPengepulId = authProvider.appUser?.id;

    // Pengecekan ID Pengepul di awal (sebelum validasi form)
    if (currentPengepulId == null || currentPengepulId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID Pengepul tidak ditemukan. Mohon login ulang.'),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final Map<String, double> soldWaste = _getSoldWasteQuantities();

      // **VALIDASI 1 (Tingkat Form Kustom): Minimal Satu Sampah Terjual**
      if (soldWaste.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pilih setidaknya satu jenis sampah dengan jumlah lebih dari 0 kg.',
            ),
            backgroundColor: Colors.orange, // Umpan balik yang jelas
          ),
        );
        return; // Hentikan proses jika tidak ada sampah yang dijual
      }

      // **VALIDASI 2 (Tingkat Form): Total Harga**
      final double totalRevenue =
          double.tryParse(_revenueController.text) ?? 0.0;
      if (totalRevenue <= 0) {
        // Validator di TextFormField sudah menangani ini, tapi ini pengamanan tambahan
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Total harga harus lebih dari Rp 0.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Hapus semua pengecekan validasi yang sudah dipindahkan di atas

        // Panggil fungsi sellWaste dari TransactionProvider
        await Provider.of<TransactionProvider>(
          context,
          listen: false,
        ).sellWaste(soldWaste, totalRevenue, currentPengepulId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Penjualan berhasil dicatat!'),
            backgroundColor: Colors.green, // Indikasi sukses
          ),
        );

        // Clear controllers setelah sukses
        _wasteControllers.forEach((key, controller) => controller.clear());
        _revenueController.clear();

        // Navigator.of(context).pop(); // Opsi: kembali ke layar sebelumnya
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: Penjualan gagal dicatat. Detail: ${e.toString()}',
            ),
            backgroundColor: Colors.red, // Indikasi error
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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
