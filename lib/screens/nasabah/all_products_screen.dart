import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/providers/products_provider.dart';
import 'package:bank_sampah_app/widgets/loading_indicator.dart';
import 'package:bank_sampah_app/widgets/product_card.dart'; // Menggunakan ProductCard yang sudah dibuat sebelumnya

class AllProductsScreen extends StatelessWidget {
  const AllProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Semua Produk')),
      body: Consumer<ProductsProvider>(
        builder: (context, productsProvider, child) {
          if (productsProvider.isLoading) {
            return const Center(child: LoadingIndicator());
          }

          if (productsProvider.products.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada produk saat ini.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Menggunakan GridView.builder untuk tampilan grid yang lebih menarik
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Menampilkan 2 item per baris
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.7, // Mengatur rasio agar card terlihat baik
            ),
            itemCount: productsProvider.products.length,
            itemBuilder: (context, index) {
              final product = productsProvider.products[index];
              return ProductCard(product: product);
            },
          );
        },
      ),
    );
  }
}
