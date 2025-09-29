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
  static Future<void> generateBendaharaReport({
    required AppUser bendahara,
    required List<Transaction> allTransactions,
    // Parameter baru yang diperlukan untuk lookup nama
    required List<AppUser> allUsers,
    String? period,
  }) async {
    final pdf = pw.Document();
    final generator =
        PdfGenerator(); // Inisialisasi untuk memanggil fungsi _getUserName

    // 1. Filter: Hanya ambil transaksi Setoran Sampah dan Pencairan Dana yang sudah completed
    final nasabahTransactions = allTransactions
        .where(
          (t) =>
              (t.type == TransactionType.setoran ||
                  t.type == TransactionType.pencairan) &&
              t.status == TransactionStatus.completed,
        )
        .toList();

    // 2. Hitung ringkasan transaksi nasabah
    final Map<String, double> summary = {
      'totalSetoran': 0.0,
      'totalPencairan': 0.0,
    };

    nasabahTransactions.forEach((t) {
      if (t.type == TransactionType.setoran) {
        summary['totalSetoran'] = (summary['totalSetoran']! + t.amount);
      } else if (t.type == TransactionType.pencairan) {
        summary['totalPencairan'] = (summary['totalPencairan']! + t.amount);
      }
    });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Text(
                'Laporan Transaksi Nasabah Bank Sampah${period != null ? ' ($period)' : ''}',
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
            pw.Text(
              'Ringkasan Transaksi Nasabah:',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            // Tampilkan Setoran dan Pencairan
            pw.Table.fromTextArray(
              data: [
                [
                  'Total Setoran Sampah',
                  'Rp ${NumberFormat('#,##0', 'id_ID').format(summary['totalSetoran'])}',
                ],
                [
                  'Total Pencairan Dana',
                  'Rp ${NumberFormat('#,##0', 'id_ID').format(summary['totalPencairan'])}',
                ],
              ],
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(5),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Riwayat Transaksi Rinci Nasabah:',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            if (nasabahTransactions.isEmpty)
              pw.Text('Belum ada riwayat transaksi nasabah yang relevan.')
            else
              pw.Table.fromTextArray(
                headers: [
                  'Tanggal',
                  'Jenis Transaksi',
                  'Nama Nasabah', // Header diubah ke Nama Nasabah
                  'Nominal (Rp)',
                  'Status',
                ],
                data: nasabahTransactions.map((t) {
                  return [
                    DateFormat('dd-MM-yyyy HH:mm').format(t.timestamp),
                    _getTransactionTypeLabel(t.type),
                    // Menggunakan lookup function
                    generator._getUserName(t.userId, allUsers),
                    NumberFormat('#,##0', 'id_ID').format(t.amount),
                    t.status.toString().split('.').last.toUpperCase(),
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
      '${output.path}/laporan_bendahara_${bendahara.nama.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }
}
