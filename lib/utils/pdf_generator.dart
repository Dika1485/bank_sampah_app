import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal
import 'package:bank_sampah_app/models/transaction.dart';
import 'package:bank_sampah_app/models/user.dart';

class PdfGenerator {
  static Future<void> generateNasabahReport({
    required AppUser nasabah,
    required List<Transaction> transactions,
    required double currentBalance,
  }) async {
    final pdf = pw.Document();

    // Filter transaksi yang completed untuk laporan
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
                'Laporan Buku Tabungan Sampah',
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

    // Simpan file PDF
    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/laporan_buku_tabungan_${nasabah.nama.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    // Buka file PDF
    await OpenFilex.open(file.path);
  }

  // Anda bisa membuat fungsi serupa untuk Pengepul
  static Future<void> generatePengepulReport({
    required AppUser pengepul,
    required List<Transaction> allTransactions, // Semua transaksi
  }) async {
    final pdf = pw.Document();

    // Filter transaksi yang relevan untuk pengepul (misal, semua setoran dan pencairan yang dia validasi)
    final relevantTransactions = allTransactions
        .where(
          (t) =>
              t.pengepulId == pengepul.id ||
              (t.type == TransactionType.setoran &&
                  t.status ==
                      TransactionStatus
                          .completed), // Pengepul melihat semua setoran yg completed
        )
        .toList();

    // Hitung ringkasan performa untuk pengepul
    double totalSampahDiterimaKg = relevantTransactions
        .where(
          (t) =>
              t.type == TransactionType.setoran &&
              t.status == TransactionStatus.completed,
        )
        .fold(0.0, (sum, item) => sum + item.weightKg);

    double totalUangDikeluarkanPencairan = relevantTransactions
        .where(
          (t) =>
              t.type == TransactionType.pencairan &&
              t.status == TransactionStatus.completed,
        )
        .fold(0.0, (sum, item) => sum + item.amount);

    double totalNilaiSetoranMasuk = relevantTransactions
        .where(
          (t) =>
              t.type == TransactionType.setoran &&
              t.status == TransactionStatus.completed,
        )
        .fold(0.0, (sum, item) => sum + item.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Text(
                'Laporan Operasional Pengepul Sampah',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Nama Pengepul: ${pengepul.nama}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.Text(
              'NIK: ${pengepul.nik}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.Text(
              'Email: ${pengepul.email}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'Ringkasan Performa:',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              data: [
                [
                  'Total Sampah Diterima (kg)',
                  '${totalSampahDiterimaKg.toStringAsFixed(2)} kg',
                ],
                [
                  'Total Nilai Setoran Masuk (Rp)',
                  NumberFormat('#,##0', 'id_ID').format(totalNilaiSetoranMasuk),
                ],
                [
                  'Total Uang Dikeluarkan (Pencairan) (Rp)',
                  NumberFormat(
                    '#,##0',
                    'id_ID',
                  ).format(totalUangDikeluarkanPencairan),
                ],
              ],
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(5),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Riwayat Transaksi Divalidasi:',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            if (relevantTransactions.isEmpty)
              pw.Text('Belum ada riwayat transaksi yang relevan.')
            else
              pw.Table.fromTextArray(
                headers: [
                  'Tanggal',
                  'Jenis Transaksi',
                  'Nasabah',
                  'Jenis Sampah',
                  'Berat (kg)',
                  'Nominal (Rp)',
                ],
                data: relevantTransactions.map((t) {
                  // Anda perlu mengambil nama nasabah dari Firestore berdasarkan t.userId
                  // Untuk contoh ini, saya akan menampilkan ID user saja.
                  return [
                    DateFormat('dd-MM-yyyy HH:mm').format(t.timestamp),
                    t.type == TransactionType.setoran ? 'Setoran' : 'Pencairan',
                    'User ID: ${t.userId.substring(0, 5)}...', // Contoh singkat
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
      '${output.path}/laporan_pengepul_${pengepul.nama.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }
}
