import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/providers/auth_provider.dart';
import 'package:bank_sampah_app/providers/sampah_price_provider.dart';
import 'package:bank_sampah_app/providers/transaction_provider.dart';
import 'package:bank_sampah_app/models/sampah.dart';
import 'package:bank_sampah_app/widgets/loading_indicator.dart';

class SetorSampahScreen extends StatefulWidget {
  const SetorSampahScreen({super.key});

  @override
  State<SetorSampahScreen> createState() => _SetorSampahScreenState();
}

class _SetorSampahScreenState extends State<SetorSampahScreen> {
  SampahType? _selectedSampahType;
  final TextEditingController _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Ensure sampah prices are loaded when this screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SampahPriceProvider>(
        context,
        listen: false,
      ).sampahTypes; // Accessing it will trigger loading if not already
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _submitSetoran() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSampahType == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pilih jenis sampah.')));
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final transactionProvider = Provider.of<TransactionProvider>(
        context,
        listen: false,
      );

      if (authProvider.appUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda harus login untuk menyetor sampah.'),
          ),
        );
        return;
      }

      final double estimatedWeight = double.parse(_weightController.text);

      await transactionProvider.requestSetoran(
        userId: authProvider.appUser!.id,
        sampahType: _selectedSampahType!,
        estimatedWeightKg: estimatedWeight,
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
              'Permintaan setoran berhasil diajukan! Menunggu validasi Pengepul.',
            ),
          ),
        );
        Navigator.of(context).pop(); // Go back to dashboard
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setor Sampah')),
      body: Consumer2<SampahPriceProvider, TransactionProvider>(
        builder: (context, sampahPriceProvider, transactionProvider, child) {
          if (sampahPriceProvider.isLoading || transactionProvider.isLoading) {
            return const LoadingIndicator();
          }
          if (sampahPriceProvider.errorMessage != null) {
            return Center(
              child: Text('Error: ${sampahPriceProvider.errorMessage}'),
            );
          }
          if (sampahPriceProvider.sampahTypes.isEmpty) {
            return const Center(
              child: Text('Belum ada jenis sampah yang tersedia.'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Jenis Sampah:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<SampahType>(
                    value: _selectedSampahType,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Sampah',
                      border: OutlineInputBorder(),
                    ),
                    items: sampahPriceProvider.sampahTypes.map((type) {
                      return DropdownMenuItem<SampahType>(
                        value: type,
                        child: Text(
                          '${type.name} (Rp ${type.pricePerKg.toStringAsFixed(0)}/kg)',
                        ),
                      );
                    }).toList(),
                    onChanged: (SampahType? newValue) {
                      setState(() {
                        _selectedSampahType = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Mohon pilih jenis sampah';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Perkiraan Berat Sampah (kg):',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Berat (kg)',
                      hintText: 'Cth: 2.5',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Berat tidak boleh kosong';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Masukkan berat yang valid (angka positif)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: transactionProvider.isLoading
                          ? null
                          : _submitSetoran,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
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
                              'Ajukan Setoran',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
