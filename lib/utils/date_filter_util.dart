import 'package:bank_sampah_app/models/transaction.dart';

class DateFilterUtil {
  /// Memfilter daftar transaksi berdasarkan periode waktu yang diberikan.
  static List<Transaction> filterTransactionsByPeriod(
    List<Transaction> transactions,
    String period,
  ) {
    // Mendapatkan tanggal dan waktu saat ini
    final now = DateTime.now();

    // Inisialisasi tanggal awal periode
    DateTime startDate;

    switch (period.toLowerCase()) {
      case 'mingguan':
        // Menghitung tanggal 7 hari yang lalu
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'bulanan':
        // Menghitung awal bulan saat ini
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'tahunan':
        // Menghitung awal tahun saat ini
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        // Jika tidak ada periode yang cocok, kembalikan semua transaksi
        return transactions;
    }

    // Memfilter transaksi yang timestamp-nya setelah tanggal awal
    return transactions
        .where((transaction) => transaction.timestamp.isAfter(startDate))
        .toList();
  }

  // Fungsi baru untuk menghitung ringkasan transaksi
  static Map<String, double> calculateSummary(List<Transaction> transactions) {
    final Map<String, double> summary = {
      'totalSetoran': 0.0,
      'totalPencairan': 0.0,
      'totalJualSampah': 0.0,
      'totalProduk': 0.0,
    };

    for (var t in transactions) {
      // Hanya hitung transaksi yang sudah selesai
      if (t.status == TransactionStatus.completed) {
        if (t.type == TransactionType.setoran) {
          summary['totalSetoran'] = (summary['totalSetoran']! + t.amount);
        } else if (t.type == TransactionType.pencairan) {
          summary['totalPencairan'] = (summary['totalPencairan']! + t.amount);
        } else if (t.type == TransactionType.jualsampah) {
          summary['totalJualSampah'] = (summary['totalJualSampah']! + t.amount);
        } else if (t.type == TransactionType.produk) {
          summary['totalProduk'] = (summary['totalProduk']! + t.amount);
        }
      }
    }
    return summary;
  }
}
