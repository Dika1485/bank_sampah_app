import 'package:bank_sampah_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/providers/products_provider.dart';
import 'package:bank_sampah_app/providers/transaction_provider.dart'; // Import TransactionProvider
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
                              // Panggil dialog penjualan
                              onPressed: () =>
                                  _showRecordSaleDialog(context, product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  productsProvider.deleteProduct(product.id),
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

  // Dialog untuk menambah/mengedit produk (tetap sama)
  void _showAddEditProductDialog(BuildContext context, {Product? product}) {
    // ... (kode ini tetap sama dengan sebelumnya)
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product == null ? 'Tambah Produk Baru' : 'Edit Produk'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Produk'),
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
                  decoration: const InputDecoration(labelText: 'Stok Tersedia'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty &&
                    priceController.text.isNotEmpty &&
                    stockController.text.isNotEmpty) {
                  final newProduct = Product(
                    id: product?.id ?? '',
                    name: nameController.text,
                    description: descriptionController.text,
                    price: double.parse(priceController.text),
                    stock: int.parse(stockController.text),
                  );
                  final provider = Provider.of<ProductsProvider>(
                    context,
                    listen: false,
                  );
                  if (product == null) {
                    provider.addProduct(newProduct);
                  } else {
                    provider.editProduct(newProduct);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(product == null ? 'Tambah' : 'Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showRecordSaleDialog(BuildContext context, Product product) {
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Consumer<TransactionProvider>(
          builder: (context, transactionProvider, child) {
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
                  onPressed: () => Navigator.pop(context),
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

                          if (quantitySold > 0 &&
                              quantitySold <= product.stock) {
                            // Tutup dialog secara instan
                            Navigator.pop(context);

                            // Panggil fungsi sellProduct dan tangani hasilnya
                            await transactionProvider.sellProduct(
                              product,
                              quantitySold,
                              currentPengepulId!,
                            );

                            if (transactionProvider.errorMessage != null) {
                              // Tampilkan pesan error jika ada
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Gagal: ${transactionProvider.errorMessage}',
                                  ),
                                ),
                              );
                            } else {
                              // Tampilkan pesan sukses
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Penjualan berhasil dicatat.'),
                                ),
                              );
                            }
                          } else {
                            // Tampilkan pesan error di dalam dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Jumlah terjual tidak valid atau melebihi stok tersedia.',
                                ),
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
