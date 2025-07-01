import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/providers/sampah_price_provider.dart';
import 'package:bank_sampah_app/models/sampah.dart';
import 'package:bank_sampah_app/widgets/loading_indicator.dart';
import 'package:intl/intl.dart';

class HargaSampahScreen extends StatefulWidget {
  const HargaSampahScreen({super.key});

  @override
  State<HargaSampahScreen> createState() => _HargaSampahScreenState();
}

class _HargaSampahScreenState extends State<HargaSampahScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  SampahCategory? _selectedCategory;
  SampahType? _editingSampah; // To hold the sampah being edited

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
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _showAddEditDialog({SampahType? sampah}) {
    _editingSampah = sampah;
    _nameController.text = sampah?.name ?? '';
    _priceController.text = sampah?.pricePerKg.toStringAsFixed(0) ?? '';
    _selectedCategory = sampah?.category;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            sampah == null ? 'Tambah Jenis Sampah' : 'Edit Harga Sampah',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sampah == null) // Only allow adding name for new sampah
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Jenis Sampah',
                      border: OutlineInputBorder(),
                    ),
                    enabled: sampah == null, // Disable if editing existing
                  ),
                if (sampah == null) const SizedBox(height: 16),
                if (sampah == null) // Only allow adding category for new sampah
                  DropdownButtonFormField<SampahCategory>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: SampahCategory.organik,
                        child: Text('Organik'),
                      ),
                      DropdownMenuItem(
                        value: SampahCategory.anorganik,
                        child: Text('Anorganik'),
                      ),
                    ],
                    onChanged: (SampahCategory? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null && sampah == null) {
                        return 'Pilih kategori';
                      }
                      return null;
                    },
                  ),
                if (sampah == null) const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga per kg (Rp)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harga tidak boleh kosong';
                    }
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Masukkan harga yang valid';
                    }
                    return null;
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
                _clearForm();
              },
            ),
            ElevatedButton(
              child: Text(sampah == null ? 'Tambah' : 'Simpan'),
              onPressed: () async {
                final sampahPriceProvider = Provider.of<SampahPriceProvider>(
                  context,
                  listen: false,
                );
                final double? price = double.tryParse(_priceController.text);

                if (price == null || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Masukkan harga yang valid.')),
                  );
                  return;
                }

                if (sampah == null) {
                  // Add new sampah type
                  if (_nameController.text.isEmpty ||
                      _selectedCategory == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Isi nama dan pilih kategori.'),
                      ),
                    );
                    return;
                  }
                  await sampahPriceProvider.addSampahType(
                    name: _nameController.text,
                    category: _selectedCategory!,
                    pricePerKg: price,
                  );
                } else {
                  // Update existing sampah type
                  await sampahPriceProvider.updateSampahPrice(sampah.id, price);
                }

                if (!mounted) return;

                if (sampahPriceProvider.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(sampahPriceProvider.errorMessage!)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        sampah == null
                            ? 'Jenis sampah berhasil ditambahkan!'
                            : 'Harga sampah berhasil diperbarui!',
                      ),
                    ),
                  );
                  Navigator.of(dialogContext).pop();
                  _clearForm();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _clearForm() {
    _nameController.clear();
    _priceController.clear();
    _selectedCategory = null;
    _editingSampah = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harga Sampah'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      body: Consumer<SampahPriceProvider>(
        builder: (context, sampahPriceProvider, child) {
          if (sampahPriceProvider.isLoading) {
            return const LoadingIndicator();
          }
          if (sampahPriceProvider.errorMessage != null) {
            return Center(
              child: Text('Error: ${sampahPriceProvider.errorMessage}'),
            );
          }
          if (sampahPriceProvider.sampahTypes.isEmpty) {
            return const Center(
              child: Text('Belum ada jenis sampah yang terdaftar.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: sampahPriceProvider.sampahTypes.length,
            itemBuilder: (context, index) {
              final sampah = sampahPriceProvider.sampahTypes[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Text(
                    sampah.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Kategori: ${sampah.category.toString().split('.').last.toUpperCase()}\nHarga: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(sampah.pricePerKg)}/kg',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showAddEditDialog(sampah: sampah),
                  ),
                  // TODO: Add delete functionality with confirmation dialog
                ),
              );
            },
          );
        },
      ),
    );
  }
}
