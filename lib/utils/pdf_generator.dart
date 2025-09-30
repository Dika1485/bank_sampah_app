import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import 'package:bank_sampah_app/models/transaction.dart';
import 'package:bank_sampah_app/models/user.dart';

class PdfGenerator {
  // Fungsi pembantu untuk mendapatkan nama pengguna (lookup)
  String _getUserName(String userId, List<AppUser> allUsers) {
    try {
      final user = allUsers.firstWhere((user) => user.id == userId);
      return user.nama;
    } catch (e) {
      return 'Nama tidak ditemukan';
    }
  }

  // Fungsi pembantu untuk mendapatkan label jenis transaksi
  static String _getTransactionTypeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.setoran:
        return 'Setoran Sampah';
      case TransactionType.pencairan:
        return 'Pencairan Dana';
      case TransactionType.jualsampah:
        return 'Jual Sampah';
      case TransactionType.produk:
        return 'Produk';
      default:
        return 'Tidak Dikenal';
    }
  }

  // --- Fungsi generateNasabahReport (Tidak Berubah) ---
  static Future<void> generateNasabahReport({
    required AppUser nasabah,
    required List<Transaction> transactions,
    required double currentBalance,
    String? period,
  }) async {
    final pdf = pw.Document();
    final completedTransactions = transactions
        .where((t) => t.status == TransactionStatus.completed)
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Text(
                'Laporan Buku Tabungan Sampah${period != null ? ' ($period)' : ''}',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Nama Nasabah: ${nasabah.nama}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.Text(
              'NIK: ${nasabah.nik}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.Text(
              'Email: ${nasabah.email}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'Saldo Saat Ini: Rp ${NumberFormat('#,##0', 'id_ID').format(currentBalance)}',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Riwayat Transaksi:',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            if (completedTransactions.isEmpty)
              pw.Text('Belum ada riwayat transaksi yang selesai.')
            else
              pw.Table.fromTextArray(
                headers: [
                  'Tanggal',
                  'Jenis Transaksi',
                  'Jenis Sampah',
                  'Berat (kg)',
                  'Nominal (Rp)',
                ],
                data: completedTransactions.map((t) {
                  return [
                    DateFormat('dd-MM-yyyy HH:mm').format(t.timestamp),
                    t.type == TransactionType.setoran ? 'Setoran' : 'Pencairan',
                    t.sampahTypeName.isNotEmpty ? t.sampahTypeName : '-',
                    t.weightKg > 0
                        ? '${t.weightKg.toStringAsFixed(2)} kg'
                        : '-',
                    NumberFormat('#,##0', 'id_ID').format(t.amount),
                  ];
                }).toList(),
                border: pw.TableBorder.all(color: PdfColors.black),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(5),
              ),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Text(
                'Dicetak pada: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}',
              ),
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/laporan_buku_tabungan_${nasabah.nama.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }

  // --- Fungsi generateBendaharaReport (Direvisi) ---
  // --- Fungsi generateBendaharaReport (Direvisi Total) ---
  static Future<void> generateBendaharaReport({
    required AppUser bendahara,
    required List<Transaction> allTransactions,
    // Parameter baru yang diperlukan untuk lookup nama
    required List<AppUser> allUsers,
    required double totalRevenue,
    String? period,
  }) async {
    final pdf = pw.Document();
    final generator = PdfGenerator();

    // REVISI 1: Hapus filter jenis transaksi. Hanya filter status completed.
    final completedTransactions = allTransactions
        .where((t) => t.status == TransactionStatus.completed)
        .toList();

    // 2. Hitung ringkasan transaksi
    final Map<String, double> summary = {
      'totalSetoranNasabah': 0.0,
      'totalPencairanNasabah': 0.0,
      'totalPenjualanSampah': 0.0, // Tambah variabel ringkasan
      'totalPenjualanProduk': 0.0, // Tambah variabel ringkasan
    };

    completedTransactions.forEach((t) {
      if (t.type == TransactionType.setoran) {
        summary['totalSetoranNasabah'] =
            (summary['totalSetoranNasabah']! + t.amount);
      } else if (t.type == TransactionType.pencairan) {
        summary['totalPencairanNasabah'] =
            (summary['totalPencairanNasabah']! + t.amount);
      } else if (t.type == TransactionType.jualsampah) {
        summary['totalPenjualanSampah'] =
            (summary['totalPenjualanSampah']! + t.amount);
      } else if (t.type == TransactionType.produk) {
        summary['totalPenjualanProduk'] =
            (summary['totalPenjualanProduk']! + t.amount);
      }
    });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // ... (Bagian Header Sama) ...
            pw.Center(
              child: pw.Text(
                'Laporan Keuangan Bank Sampah Lengkap${period != null ? ' ($period)' : ''}',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Nama Bendahara: ${bendahara.nama}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.SizedBox(height: 10),

            // --- PENAMBAHAN SALDO KAS BANK SAMPAH (totalRevenue) ---
            pw.Text(
              'Saldo Kas Bank Sampah Saat Ini: Rp ${NumberFormat('#,##0', 'id_ID').format(totalRevenue)}',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 20),

            // --- Ringkasan Transaksi Periodik (Dibuat 2 Kolom untuk fix error) ---
            pw.Text(
              'Ringkasan Transaksi Periodik:',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              // Header opsional untuk 2 kolom:
              headers: ['Deskripsi', 'Nominal'],
              data: [
                // Pendapatan Kas Bank Sampah
                [
                  'Total Penjualan Sampah',
                  'Rp ${NumberFormat('#,##0', 'id_ID').format(summary['totalPenjualanSampah'])}',
                ],
                [
                  'Total Penjualan Produk',
                  'Rp ${NumberFormat('#,##0', 'id_ID').format(summary['totalPenjualanProduk'])}',
                ],
                // Transaksi Nasabah
                [
                  'Total Nilai Setoran Nasabah',
                  'Rp ${NumberFormat('#,##0', 'id_ID').format(summary['totalSetoranNasabah'])}',
                ],
                [
                  'Total Pencairan Dana Nasabah',
                  'Rp ${NumberFormat('#,##0', 'id_ID').format(summary['totalPencairanNasabah'])}',
                ],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(5),
              cellStyle: const pw.TextStyle(fontSize: 12),
              border: pw.TableBorder.all(color: PdfColors.grey),
            ),
            pw.SizedBox(height: 20),

            // --- Riwayat Transaksi Rinci ---
            pw.Text(
              'Riwayat Transaksi Rinci:',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            if (completedTransactions.isEmpty)
              pw.Text('Belum ada riwayat transaksi yang selesai.')
            else
              pw.Table.fromTextArray(
                headers: [
                  'Tanggal',
                  'Jenis Transaksi',
                  'Keterangan', // Diganti Keterangan
                  'Pihak Terkait', // Diganti Pihak Terkait
                  'Nominal (Rp)',
                ],
                data: completedTransactions.map((t) {
                  String pihakTerkait = '';
                  String keterangan =
                      t.sampahTypeName; // Default dari Sampah/Produk Name

                  if (t.type == TransactionType.setoran ||
                      t.type == TransactionType.pencairan) {
                    // Jika transaksi nasabah, gunakan nama nasabah sebagai Pihak Terkait
                    pihakTerkait = generator._getUserName(t.userId, allUsers);
                  } else if (t.type == TransactionType.jualsampah) {
                    // Jika penjualan sampah ke pabrik
                    pihakTerkait =
                        'Penjual (${generator._getUserName(t.pengepulId!, allUsers)})';
                    keterangan =
                        'Jual ${t.weightKg.toStringAsFixed(2)} kg Sampah';
                  } else if (t.type == TransactionType.produk) {
                    // Jika penjualan produk
                    pihakTerkait =
                        'Penjual (${generator._getUserName(t.pengepulId!, allUsers)})';
                    keterangan =
                        'Penjualan Produk: ${t.sampahTypeName}'; // SampahTypeName berisi nama produk
                  }

                  return [
                    DateFormat('dd-MM-yyyy HH:mm').format(t.timestamp),
                    _getTransactionTypeLabel(t.type),
                    keterangan,
                    pihakTerkait,
                    // Tampilkan nominal dengan warna berdasarkan jenis transaksi (opsional, tapi bagus)
                    pw.Text(
                      'Rp ${NumberFormat('#,##0', 'id_ID').format(t.amount)}',
                      style: pw.TextStyle(
                        color: t.type == TransactionType.pencairan
                            ? PdfColors.red
                            : PdfColors.black,
                      ),
                    ),
                  ];
                }).toList(),
                border: pw.TableBorder.all(color: PdfColors.black),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(5),
              ),
            // ... (Bagian Footer Sama) ...
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Text(
                'Dicetak pada: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}',
              ),
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/laporan_bendahara_lengkap_${bendahara.nama.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }
}
