import 'dart:io';

import 'package:bank_sampah_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/providers/products_provider.dart';
import 'package:bank_sampah_app/providers/transaction_provider.dart';
import 'package:bank_sampah_app/models/product.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductsProvider>(context, listen: false).listenToProducts();
    });
  }

  // Menampilkan SnackBar untuk pesan
  void _showSnackbar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    // Pastikan widget masih ada sebelum menampilkan SnackBar
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer2 untuk mendengarkan dua provider
    return Consumer2<ProductsProvider, TransactionProvider>(
      builder: (context, productsProvider, transactionProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Kelola Produk'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddEditProductDialog(context),
              ),
            ],
          ),
          body: productsProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : productsProvider.errorMessage != null
              ? Center(child: Text('Error: ${productsProvider.errorMessage}'))
              : productsProvider.products.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada produk. Tambahkan produk baru!',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: productsProvider.products.length,
                  itemBuilder: (context, index) {
                    final product = productsProvider.products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        leading:
                            product.imageUrl != null &&
                                product.imageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  product.imageUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                      ),
                                ),
                              )
                            : const Icon(
                                Icons.shopping_bag_outlined,
                                size: 50,
                                color: Colors.grey,
                              ),
                        title: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(product.description),
                            const SizedBox(height: 8),
                            Text(
                              'Harga: Rp. ${product.price.toStringAsFixed(0)} | Stok: ${product.stock}',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.sell, color: Colors.blue),
                              onPressed: () =>
                                  _showRecordSaleDialog(context, product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              // 💡 Perbarui: Kirim objek Product agar provider bisa hapus gambar
                              onPressed: () => _confirmDelete(
                                context,
                                productsProvider,
                                product,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _showAddEditProductDialog(
                          context,
                          product: product,
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  // --- DELETE CONFIRMATION ---
  void _confirmDelete(
    BuildContext context,
    ProductsProvider provider,
    Product product,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Anda yakin ingin menghapus produk "${product.name}"?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Batal'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.of(ctx).pop(); // Tutup dialog
              await provider.deleteProduct(
                product,
              ); // Panggil deleteProduct yang diperbarui
              if (!mounted) return; // Tambahkan guard
              if (provider.errorMessage != null) {
                _showSnackbar(context, provider.errorMessage!, isError: true);
              } else {
                _showSnackbar(
                  context,
                  'Produk ${product.name} berhasil dihapus.',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // --- ADD/EDIT PRODUCT DIALOG (DENGAN MANAJEMEN GAMBAR) ---
  void _showAddEditProductDialog(BuildContext context, {Product? product}) {
    final nameController = TextEditingController(text: product?.name);
    final descriptionController = TextEditingController(
      text: product?.description,
    );
    final priceController = TextEditingController(
      text: product?.price.toString(),
    );
    final stockController = TextEditingController(
      text: product?.stock.toString(),
    );

    // Gunakan nilai dari Product yang ada atau null
    String? initialExistingImageUrl = product?.imageUrl;

    showDialog(
      context: context,
      builder: (dialogContext) {
        // State lokal untuk gambar yang dipilih dan URL yang ada
        File? pickedImage;
        String? existingImageUrl = initialExistingImageUrl;

        return StatefulBuilder(
          // 💡 PERBAIKAN PENTING: StatefulBuilder hanya untuk mengelola state lokal (gambar)
          // Hapus Provider.of(listen: true) dari sini
          builder: (BuildContext innerContext, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(
                product == null ? 'Tambah Produk Baru' : 'Edit Produk',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // BAGIAN UPLOAD GAMBAR
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(
                          source: ImageSource.gallery,
                        );

                        if (pickedFile != null) {
                          setDialogState(() {
                            pickedImage = File(pickedFile.path);
                            existingImageUrl =
                                null; // Hapus URL lama jika memilih gambar baru
                          });
                        }
                      },
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade200,
                        ),
                        child: pickedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  pickedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : existingImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  existingImageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Colors.grey,
                                size: 40,
                              ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(
                          source: ImageSource.gallery,
                        );

                        if (pickedFile != null) {
                          setDialogState(() {
                            pickedImage = File(pickedFile.path);
                            existingImageUrl = null;
                          });
                        }
                      },
                      icon: const Icon(Icons.upload),
                      label: Text(
                        pickedImage != null
                            ? 'Ubah Gambar'
                            : existingImageUrl != null
                            ? 'Ubah Gambar'
                            : 'Pilih Gambar (Opsional)',
                      ),
                    ),
                    if (existingImageUrl != null || pickedImage != null)
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            pickedImage = null;
                            existingImageUrl = null;
                          });
                        },
                        child: const Text(
                          'Hapus Gambar',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 10),
                    // BAGIAN INPUT TEKS
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Produk',
                      ),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Deskripsi'),
                      maxLines: 3,
                    ),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Harga'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stok Tersedia',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(innerContext),
                  child: const Text('Batal'),
                ),
                // 💡 PERBAIKAN PENTING: Gunakan Consumer di sini agar hanya tombol yang dibangun ulang
                Consumer<ProductsProvider>(
                  builder: (context, provider, child) {
                    return ElevatedButton(
                      onPressed: provider.isLoading
                          ? null
                          : () async {
                              if (nameController.text.isNotEmpty &&
                                  descriptionController.text.isNotEmpty &&
                                  priceController.text.isNotEmpty &&
                                  stockController.text.isNotEmpty) {
                                // 1. Ambil Provider tanpa listen untuk fungsi async
                                final ProductsProvider nonListeningProvider =
                                    Provider.of<ProductsProvider>(
                                      innerContext,
                                      listen: false,
                                    );

                                // 2. Inisialisasi URL gambar
                                String? finalImageUrl = existingImageUrl;

                                // 3. Upload gambar ke Cloudinary jika ada file baru
                                if (pickedImage != null) {
                                  finalImageUrl = await nonListeningProvider
                                      .uploadImageAndGetUrl(pickedImage!);

                                  // Periksa apakah upload gagal
                                  if (finalImageUrl == null) {
                                    if (!mounted) return;
                                    _showSnackbar(
                                      this.context, // Gunakan context State utama
                                      nonListeningProvider.errorMessage ??
                                          'Gagal mengunggah gambar.',
                                      isError: true,
                                    );
                                    return;
                                  }
                                } else if (existingImageUrl == null &&
                                    product?.imageUrl != null) {
                                  // Kasus Edit: Gambar lama dihapus manual
                                  finalImageUrl = null;
                                }

                                final newProduct = Product(
                                  id: product?.id ?? '',
                                  name: nameController.text,
                                  description: descriptionController.text,
                                  price: double.parse(priceController.text),
                                  stock: int.parse(stockController.text),
                                  imageUrl: finalImageUrl,
                                );

                                // 4. Panggil Add/Edit Product (mengubah state isLoading)
                                if (product == null) {
                                  await nonListeningProvider.addProduct(
                                    newProduct,
                                  );
                                } else {
                                  await nonListeningProvider.editProduct(
                                    newProduct,
                                  );
                                }

                                // 5. Tutup dialog dengan innerContext
                                Navigator.pop(innerContext);

                                // 6. Tampilkan pesan sukses di context utama (pastikan mounted)
                                if (!mounted) return;
                                _showSnackbar(
                                  this.context, // Gunakan context State utama
                                  '${product == null ? 'Penambahan' : 'Pengeditan'} produk berhasil!',
                                );
                              } else {
                                _showSnackbar(
                                  innerContext, // Gunakan innerContext untuk pesan di dialog
                                  'Mohon isi semua field wajib.',
                                  isError: true,
                                );
                              }
                            },
                      child: provider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(product == null ? 'Tambah' : 'Simpan'),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Pastikan controller dihapus setelah dialog ditutup
      nameController.dispose();
      descriptionController.dispose();
      priceController.dispose();
      stockController.dispose();
    });
  }

  // Fungsi _showRecordSaleDialog tidak memerlukan revisi karena tidak berinteraksi langsung dengan Cloudinary.
  void _showRecordSaleDialog(BuildContext context, Product product) {
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer<TransactionProvider>(
          builder: (innerContext, transactionProvider, child) {
            return AlertDialog(
              title: const Text('Catat Penjualan Produk'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Produk: ${product.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Harga per unit: Rp. ${product.price.toStringAsFixed(0)}',
                    ),
                    Text('Stok tersedia: ${product.stock}'),
                    const SizedBox(height: 20),
                    TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Terjual',
                        hintText: 'Masukkan jumlah produk yang terjual',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(innerContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  // Tombol akan nonaktif jika sedang loading
                  onPressed: transactionProvider.isLoading
                      ? null
                      : () async {
                          final quantitySold =
                              int.tryParse(quantityController.text) ?? 0;
                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          final String? currentPengepulId =
                              authProvider.appUser?.id;
                          if (currentPengepulId == null) {
                            // <-- PERIKSA ID PENGGUNA
                            // Tampilkan pesan error jika ID pengguna tidak ditemukan
                            Navigator.pop(
                              innerContext,
                            ); // Tutup dialog dengan innerContext
                            _showSnackbar(
                              context,
                              'Kesalahan: ID pengguna tidak ditemukan. Mohon coba login ulang.',
                              isError: true,
                            );
                            return;
                          }

                          if (quantitySold > 0 &&
                              quantitySold <= product.stock) {
                            // Tutup dialog secara instan
                            Navigator.pop(innerContext); // Gunakan innerContext

                            // Panggil fungsi sellProduct dan tangani hasilnya
                            try {
                              // <-- TANGKAP EXCEPTION DI SINI
                              // Panggil fungsi sellProduct dan tangani hasilnya
                              await transactionProvider.sellProduct(
                                product,
                                quantitySold,
                                currentPengepulId,
                              );
                            } catch (e) {
                              // Tangani exception tak terduga (mis. network, Firestore)
                              if (!mounted) return;
                              _showSnackbar(
                                context,
                                'Kesalahan Transaksi: Terjadi kesalahan tak terduga. ${e.toString()}',
                                isError: true,
                              );
                              return; // Hentikan eksekusi
                            }

                            if (transactionProvider.errorMessage != null) {
                              // Tampilkan pesan error jika ada
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Gagal: ${transactionProvider.errorMessage}',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } else {
                              // Tampilkan pesan sukses
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Penjualan berhasil dicatat.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } else {
                            // Tampilkan pesan error di dalam dialog
                            ScaffoldMessenger.of(innerContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Jumlah terjual tidak valid atau melebihi stok tersedia.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: transactionProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Catat'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
