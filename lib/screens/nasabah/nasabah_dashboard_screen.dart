import 'package:bank_sampah_app/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bank_sampah_app/providers/auth_provider.dart';
import 'package:bank_sampah_app/providers/transaction_provider.dart';
import 'package:bank_sampah_app/screens/nasabah/buku_tabungan_screen.dart';
import 'package:bank_sampah_app/screens/nasabah/setor_sampah_screen.dart';
import 'package:bank_sampah_app/screens/nasabah/nasabah_chart_widget.dart';
import 'package:bank_sampah_app/screens/common/profile_screen.dart';
import 'package:bank_sampah_app/screens/auth/login_screen.dart';
import 'package:bank_sampah_app/widgets/loading_indicator.dart';
import 'package:intl/intl.dart';
import 'package:bank_sampah_app/models/user.dart';
import 'package:bank_sampah_app/providers/products_provider.dart';
import 'package:bank_sampah_app/providers/events_provider.dart';
import 'package:bank_sampah_app/widgets/product_card.dart'; // File baru
import 'package:bank_sampah_app/widgets/event_card.dart'; // File baru
import 'package:bank_sampah_app/screens/nasabah/all_products_screen.dart'; // Halaman baru
import 'package:bank_sampah_app/screens/nasabah/all_events_screen.dart'; // Halaman baru

class NasabahDashboardScreen extends StatefulWidget {
  const NasabahDashboardScreen({super.key});

  @override
  State<NasabahDashboardScreen> createState() => _NasabahDashboardScreenState();
}

class _NasabahDashboardScreenState extends State<NasabahDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  // Tambahkan key untuk form dialog pencairan
  final _withdrawalFormKey = GlobalKey<FormState>();

  void _fetchInitialData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(
      context,
      listen: false,
    );
    final productProvider = Provider.of<ProductsProvider>(
      context,
      listen: false,
    );
    final eventProvider = Provider.of<EventsProvider>(context, listen: false);

    if (authProvider.appUser != null) {
      transactionProvider.listenToNasabahData(authProvider.appUser!.id);
      productProvider.listenToProducts();
      eventProvider.listenToEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final productProvider = Provider.of<ProductsProvider>(context);
    final eventProvider = Provider.of<EventsProvider>(context);

    if (authProvider.appUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
      return const LoadingIndicator();
    }

    final String nasabahName = authProvider.appUser?.nama ?? 'Nasabah';
    final String formattedBalance = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(transactionProvider.nasabahBalance);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Nasabah'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (transactionProvider.isLoading &&
              transactionProvider.errorMessage == null) {
            return const Center(child: LoadingIndicator());
          }
          if (transactionProvider.errorMessage != null) {
            return Center(
              child: Text(
                'Terjadi kesalahan: ${transactionProvider.errorMessage}',
                textAlign: TextAlign.center,
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang, $nasabahName!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saldo Buku Tabungan:',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formattedBalance,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SetorSampahScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Setor Sampah',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (authProvider.appUser != null) {
                                    _showWithdrawalDialog(
                                      context,
                                      authProvider.appUser!.id,
                                      authProvider.appUser!.nama,
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.money,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Cairkan Dana',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                  height: 240, // Ukuran tetap untuk daftar horizontal
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
                  height: 215, // Ukuran tetap untuk daftar horizontal
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

                const SizedBox(height: 20),
                const Text(
                  'Analisis Setoran Sampah:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (transactionProvider.nasabahTransactions.isNotEmpty)
                  NasabahChartWidget(
                    transactions: transactionProvider.nasabahTransactions,
                  )
                else
                  const Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text('Belum ada data setoran untuk grafik.'),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
                _buildSectionHeader(context, 'Riwayat Transaksi Terbaru', () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BukuTabunganScreen(),
                    ),
                  );
                }),
                const SizedBox(height: 10),
                transactionProvider.nasabahTransactions.isEmpty
                    ? const Card(
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text('Belum ada riwayat transaksi.'),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount:
                            transactionProvider.nasabahTransactions.length > 5
                            ? 5
                            : transactionProvider.nasabahTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction =
                              transactionProvider.nasabahTransactions[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Icon(
                                transaction.type == TransactionType.setoran
                                    ? Icons.upload_file
                                    : Icons.download,
                                color:
                                    transaction.type == TransactionType.setoran
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              title: Text(
                                transaction.type == TransactionType.setoran
                                    ? 'Setoran: ${transaction.sampahTypeName}'
                                    : 'Pencairan Dana',
                              ),
                              subtitle: Text(
                                '${DateFormat('dd MMM HH:mm').format(transaction.timestamp)} - ${transaction.weightKg > 0 ? '${transaction.weightKg.toStringAsFixed(2)} kg - ' : ''}Status: ${transaction.status.toString().split('.').last.toUpperCase()}',
                              ),
                              trailing: Text(
                                NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0,
                                ).format(transaction.amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      transaction.type ==
                                          TransactionType.setoran
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_to_photos),
            label: 'Setor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Buku Tabungan',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SetorSampahScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const BukuTabunganScreen(),
              ),
            );
          }
        },
      ),
    );
  }

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

  void _showWithdrawalDialog(
    BuildContext context,
    String userId,
    String userName,
  ) {
    // Reset key setiap kali dialog dibuka jika perlu, atau gunakan key yang sama.
    // Jika Anda ingin form ini di-reset setiap kali, Anda bisa mendefinisikan key di sini
    // final _withdrawalFormKey = GlobalKey<FormState>();
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Consumer<TransactionProvider>(
          builder: (context, transactionProvider, child) {
            // --- Membungkus konten dengan Form ---
            return Form(
              key: _withdrawalFormKey, // Gunakan GlobalKey
              child: AlertDialog(
                title: const Text('Cairkan Dana'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- Mengganti TextField dengan TextFormField ---
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah Penarikan (Rp)',
                          border: OutlineInputBorder(),
                        ),
                        // --- Tambahkan Validator ---
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Jumlah penarikan wajib diisi.';
                          }
                          final double? amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Masukkan jumlah yang valid (> Rp 0).';
                          }
                          if (amount > transactionProvider.nasabahBalance) {
                            return 'Saldo tidak mencukupi. Tersedia: Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(transactionProvider.nasabahBalance)}';
                          }
                          return null; // Valid
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Saldo Tersedia: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(transactionProvider.nasabahBalance)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Batal'),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      amountController
                          .dispose(); // Bersihkan controller saat dibatalkan
                    },
                  ),
                  ElevatedButton(
                    onPressed: transactionProvider.isLoading
                        ? null
                        : () async {
                            // --- Panggil Form Validation di sini ---
                            if (_withdrawalFormKey.currentState!.validate()) {
                              final double amount = double.parse(
                                amountController.text,
                              );

                              // Logika validasi saldo > 0 sudah ditangani oleh validator

                              try {
                                await transactionProvider.requestPencairan(
                                  userId: userId,
                                  userName: userName,
                                  amount: amount,
                                );

                                // Cek error dari provider (jika ada error yang ditangani di level provider, misal kegagalan API)
                                if (transactionProvider.errorMessage != null) {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        transactionProvider.errorMessage!,
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } else {
                                  Navigator.of(dialogContext).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Permintaan pencairan berhasil diajukan!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Terjadi kesalahan tak terduga: $e',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } finally {
                                amountController
                                    .dispose(); // Bersihkan controller setelah selesai
                              }
                            }
                          },
                    child: transactionProvider.isLoading
                        ? const LoadingIndicator(color: Colors.white)
                        : const Text('Cairkan'),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      // Pastikan controller dihapus (meskipun sudah dilakukan di logic)
      amountController.dispose();
    });
  }
}
