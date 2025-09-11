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
    _fetchInitialData();
  }

  void _fetchInitialData() {
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
    final productProvider = Provider.of<ProductsProvider>(context);
    final eventProvider = Provider.of<EventsProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Sampah'),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text('Login', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian utama untuk ajakan login/daftar
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Selamat Datang di Bank Sampah!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Kelola tabungan sampah Anda, tukarkan poin, dan ikut serta dalam acara komunitas.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Login untuk Mengelola Akun Anda'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionHeader(context, 'Produk dari Bank Sampah', () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AllProductsScreen(),
                ),
              );
            }),
            const SizedBox(height: 10),
            SizedBox(
              height: 200, // Ukuran tetap untuk daftar horizontal
              child: productProvider.isLoading
                  ? const Center(child: LoadingIndicator())
                  : productProvider.products.isEmpty
                  ? const Center(child: Text('Belum ada produk saat ini.'))
                  : ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: productProvider.products.length,
                      itemBuilder: (context, index) {
                        final product = productProvider.products[index];
                        return ProductCard(product: product);
                      },
                    ),
            ),

            const SizedBox(height: 20),
            _buildSectionHeader(context, 'Acara Komunitas', () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AllEventsScreen(),
                ),
              );
            }),
            const SizedBox(height: 10),
            SizedBox(
              height: 200, // Ukuran tetap untuk daftar horizontal
              child: eventProvider.isLoading
                  ? const Center(child: LoadingIndicator())
                  : eventProvider.events.isEmpty
                  ? const Center(child: Text('Belum ada acara mendatang.'))
                  : ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: eventProvider.events.length,
                      itemBuilder: (context, index) {
                        final event = eventProvider.events[index];
                        return EventCard(event: event);
                      },
                    ),
            ),
          ],
        ),
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
