import 'package:bank_sampah_app/models/product.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Cek apakah URL gambar tersedia dan tidak kosong
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;

    // 💡 Definisikan widget gambar secara kondisional
    Widget productImageWidget = Container(
      height: 250, // Tinggikan sedikit agar lebih menonjol di halaman detail
      width: double.infinity,
      color: Colors.grey[200],
      child: hasImage
          ? Image.network(
              product.imageUrl!,
              fit: BoxFit.cover,
              // Loading builder untuk menampilkan indikator saat memuat
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
              // Error builder jika gambar gagal dimuat
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                );
              },
            )
          : const Center(
              // Placeholder jika tidak ada URL gambar
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 100,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Gambar Tidak Tersedia',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 💡 Gunakan widget gambar yang sudah direvisi
            productImageWidget,

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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: product.stock > 0 ? Colors.black : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
