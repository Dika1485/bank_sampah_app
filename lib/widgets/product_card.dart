import 'package:bank_sampah_app/models/product.dart';
import 'package:bank_sampah_app/screens/nasabah/product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  // Widget helper untuk menampilkan bagian gambar
  Widget _buildProductImage() {
    // Cek apakah imageUrl tersedia dan tidak kosong
    final hasImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: hasImage
            ? Colors.transparent
            : Colors.grey[200], // Ubah warna dasar jika ada gambar
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: hasImage
          ? ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              child: Image.network(
                product.imageUrl!,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                // Tambahkan loadingBuilder untuk UX yang lebih baik saat memuat gambar
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
                // Tambahkan errorBuilder jika gambar gagal dimuat
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                  );
                },
              ),
            )
          : const Center(
              // Placeholder jika tidak ada gambar
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 50,
                color: Colors.grey,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(right: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Aksi saat Card ditekan, navigasi ke layar detail produk
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 💡 Gunakan widget helper untuk gambar
              _buildProductImage(),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(product.price),
                      style: const TextStyle(color: Colors.green),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stok: ${product.stock}',
                      style: TextStyle(
                        color: product.stock > 0
                            ? Colors.grey[700]
                            : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Aksi saat tombol detail ditekan, navigasi ke layar detail produk
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        child: Text('Detail'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
