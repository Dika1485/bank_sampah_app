import 'package:bank_sampah_app/models/product.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder untuk gambar produk
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 100,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              product.name,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(product.price),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.green),
            ),
            const SizedBox(height: 20),
            const Text(
              'Deskripsi Produk:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(product.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Text(
              'Stok Tersedia: ${product.stock}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
