// bank_sampah_app/screens/harga_sampah_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/providers/sampah_price_provider.dart';
import 'package:bank_sampah_app/models/sampah.dart';
import 'package:bank_sampah_app/widgets/loading_indicator.dart';
import 'package:intl/intl.dart';

// Extension to add firstWhereOrNull for convenience (jika belum ada di file terpisah)
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

  // State loading lokal untuk tombol di dialog
  bool _isDialogButtonLoading = false;

  @override
  void initState() {
    super.initState();
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
    _isDialogButtonLoading =
        false; // Reset loading state setiap kali dialog dibuka

    showDialog(
      context: context,
      barrierDismissible:
          false, // Tidak bisa ditutup dengan tap di luar saat loading
      builder: (BuildContext dialogContext) {
        // Gunakan StatefulBuilder untuk mengelola state di dalam dialog
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                        // Nama tidak bisa diubah saat mengedit atau saat loading
                        enabled: sampah == null && !_isDialogButtonLoading,
                      ),
                    if (sampah == null) const SizedBox(height: 16),
                    if (sampah ==
                        null) // Only allow adding category for new sampah
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
                        onChanged: _isDialogButtonLoading
                            ? null
                            : (SampahCategory? newValue) {
                                setDialogState(() {
                                  // Gunakan setDialogState untuk update UI dialog
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Harga per kg (Rp)',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isDialogButtonLoading, // Disable saat loading
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
                  onPressed: _isDialogButtonLoading
                      ? null
                      : () {
                          // Disable saat loading
                          Navigator.of(dialogContext).pop();
                          _clearForm();
                        },
                ),
                ElevatedButton(
                  child: _isDialogButtonLoading
                      ? const LoadingIndicator(
                          color: Colors.white,
                        ) // Tampilkan loading di tombol
                      : Text(sampah == null ? 'Tambah' : 'Simpan'),
                  onPressed: _isDialogButtonLoading
                      ? null
                      : () async {
                          // Disable saat loading
                          final sampahPriceProvider =
                              Provider.of<SampahPriceProvider>(
                                context,
                                listen: false,
                              );
                          final double? price = double.tryParse(
                            _priceController.text,
                          );

                          // Validasi input
                          if (price == null || price <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Masukkan harga yang valid.'),
                              ),
                            );
                            return;
                          }
                          if (sampah == null) {
                            // Jika menambah baru, cek nama dan kategori
                            if (_nameController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Nama jenis sampah tidak boleh kosong.',
                                  ),
                                ),
                              );
                              return;
                            }
                            if (_selectedCategory == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pilih kategori jenis sampah.'),
                                ),
                              );
                              return;
                            }
                          }

                          // Set loading state di dalam dialog
                          setDialogState(() {
                            _isDialogButtonLoading = true;
                          });

                          try {
                            if (sampah == null) {
                              await sampahPriceProvider.addSampahType(
                                name: _nameController.text,
                                category: _selectedCategory!,
                                pricePerKg: price,
                              );
                            } else {
                              await sampahPriceProvider.updateSampahPrice(
                                sampah.id,
                                price,
                              );
                            }

                            if (!mounted)
                              return; // Check if widget is still mounted

                            if (sampahPriceProvider.errorMessage != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    sampahPriceProvider.errorMessage!,
                                  ),
                                  backgroundColor:
                                      Colors.red, // Warna merah untuk error
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    sampah == null
                                        ? 'Jenis sampah berhasil ditambahkan!'
                                        : 'Harga sampah berhasil diperbarui!',
                                  ),
                                  backgroundColor:
                                      Colors.green, // Warna hijau untuk sukses
                                ),
                              );
                              Navigator.of(dialogContext).pop(); // Tutup dialog
                              _clearForm(); // Bersihkan form
                            }
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Terjadi kesalahan: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            // Pastikan loading state diset false di akhir
                            setDialogState(() {
                              _isDialogButtonLoading = false;
                            });
                          }
                        },
                ),
              ],
            );
          },
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

  void _confirmDeleteSampah(BuildContext context, SampahType sampah) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text(
            'Apakah Anda yakin ingin menghapus jenis sampah "${sampah.name}"?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // Batal
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(true); // Konfirmasi hapus
                final sampahPriceProvider = Provider.of<SampahPriceProvider>(
                  context,
                  listen: false,
                );
                await sampahPriceProvider.deleteSampahType(sampah.id);

                if (!mounted) return;
                if (sampahPriceProvider.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(sampahPriceProvider.errorMessage!),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${sampah.name} berhasil dihapus.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddEditDialog(sampah: sampah),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteSampah(
                          context,
                          sampah,
                        ), // Panggil konfirmasi hapus
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
