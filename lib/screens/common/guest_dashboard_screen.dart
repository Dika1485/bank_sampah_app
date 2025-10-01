import 'package:bank_sampah_app/providers/auth_provider.dart';
import 'package:bank_sampah_app/providers/events_provider.dart';
import 'package:bank_sampah_app/providers/products_provider.dart';
import 'package:bank_sampah_app/widgets/event_card.dart';
import 'package:bank_sampah_app/widgets/loading_indicator.dart';
import 'package:bank_sampah_app/widgets/product_card.dart';
import 'package:flutter/material.dart';

// Import screens yang dapat diakses oleh pengguna tamu
import 'package:bank_sampah_app/screens/auth/login_screen.dart';
import 'package:bank_sampah_app/screens/nasabah/all_products_screen.dart';
import 'package:bank_sampah_app/screens/nasabah/all_events_screen.dart';
import 'package:provider/provider.dart';

class GuestDashboardScreen extends StatefulWidget {
  const GuestDashboardScreen({super.key});

  @override
  State<GuestDashboardScreen> createState() => _GuestDashboardScreenState();
}

class _GuestDashboardScreenState extends State<GuestDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Menggunakan WidgetsBinding untuk memastikan context tersedia sebelum fetching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  // Mengambil data awal untuk event dan product
  void _fetchInitialData() {
    // Pastikan listen: false karena ini di luar method build
    final productProvider = Provider.of<ProductsProvider>(
      context,
      listen: false,
    );
    final eventProvider = Provider.of<EventsProvider>(context, listen: false);

    productProvider.listenToProducts();
    eventProvider.listenToEvents();
  }

  @override
  Widget build(BuildContext context) {
    // Consumer untuk menghindari rebuild seluruh widget
    final productProvider = Provider.of<ProductsProvider>(context);
    final eventProvider = Provider.of<EventsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        // 💡 Penyesuaian Branding Simaru
        title: const Text('Simaru'),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text(
              'Login',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian utama untuk ajakan login/daftar (Refactored)
            _buildWelcomeCard(context),
            const SizedBox(height: 20),

            // Bagian Produk (Refactored)
            _buildSectionHeader(
              context,
              'Katalog Produk Daur Ulang', // Judul baru
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AllProductsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildProductList(productProvider),

            const SizedBox(height: 20),

            // Bagian Acara (Refactored)
            _buildSectionHeader(
              context,
              'Acara Komunitas', // Judul lebih spesifik
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AllEventsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildEventList(eventProvider),
          ],
        ),
      ),
    );
  }

  // 💡 Metode baru untuk Card Sambutan (Memisahkan logic UI)
  Widget _buildWelcomeCard(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Selamat Datang di Simaru!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              // 💡 Mengubah deskripsi agar lebih umum dan tidak berfokus pada 'tukar saldo'
              'Sistem Informasi Bank Sampah Mawar Biru membantu Anda mengelola tabungan bank sampah, melihat katalog produk daur ulang, dan mengikuti acara komunitas. Login untuk mulai menabung!',
              style: TextStyle(fontSize: 15, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.green, // Mengubah ke warna biru yang tegas
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Masuk / Daftar Akun',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 💡 Metode untuk membangun daftar produk horizontal
  Widget _buildProductList(ProductsProvider productProvider) {
    return SizedBox(
      height: 240,
      child: productProvider.isLoading
          ? const Center(child: LoadingIndicator())
          : productProvider.products.isEmpty
          ? const Center(
              // 💡 Pesan baru
              child: Text(
                'Belum ada produk daur ulang dalam katalog.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: productProvider.products.length,
              itemBuilder: (context, index) {
                final product = productProvider.products[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: ProductCard(product: product),
                );
              },
            ),
    );
  }

  // 💡 Metode untuk membangun daftar acara horizontal
  Widget _buildEventList(EventsProvider eventProvider) {
    return SizedBox(
      height: 215, // Ukuran tetap untuk daftar horizontal
      child: eventProvider.isLoading
          ? const Center(child: LoadingIndicator())
          : eventProvider.events.isEmpty
          ? const Center(
              child: Text(
                'Belum ada acara komunitas mendatang.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: eventProvider.events.length,
              itemBuilder: (context, index) {
                final event = eventProvider.events[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: EventCard(event: event),
                );
              },
            ),
    );
  }

  // Metode untuk membuat header dengan tombol "Lihat Semua"
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    VoidCallback onSeeAll,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        TextButton(onPressed: onSeeAll, child: const Text('Lihat Semua')),
      ],
    );
  }
}
