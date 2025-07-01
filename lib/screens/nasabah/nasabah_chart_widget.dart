import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:bank_sampah_app/models/transaction.dart'; // Pastikan ada model Transaksi

class NasabahChartWidget extends StatelessWidget {
  final List<Transaction> transactions;

  const NasabahChartWidget({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Filter hanya transaksi setoran yang sudah completed
    final completedSetoran = transactions
        .where(
          (t) =>
              t.type == TransactionType.setoran &&
              t.status == TransactionStatus.completed,
        )
        .toList();

    if (completedSetoran.isEmpty) {
      return const Center(
        child: Text('Belum ada data setoran untuk ditampilkan.'),
      );
    }

    // Hitung total berat per jenis sampah
    Map<String, double> sampahWeightMap = {};
    for (var t in completedSetoran) {
      sampahWeightMap.update(
        t.sampahTypeName,
        (value) => value + t.weightKg,
        ifAbsent: () => t.weightKg,
      );
    }

    // Ubah ke format PieChartSectionData
    List<PieChartSectionData> sections = [];
    double totalWeight = sampahWeightMap.values.fold(
      0.0,
      (sum, item) => sum + item,
    );
    int i = 0;
    final List<Color> pieColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ]; // Contoh warna

    sampahWeightMap.forEach((key, value) {
      final double percentage = (value / totalWeight) * 100;
      sections.add(
        PieChartSectionData(
          color: pieColors[i % pieColors.length],
          value: value, // Nilai absolut berat
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: _Badge(
            key, // Nama jenis sampah sebagai label
            size: 20,
            borderColor: Colors.black,
          ),
          badgePositionPercentageOffset: 1.4,
        ),
      );
      i++;
    });

    return AspectRatio(
      aspectRatio: 1.3,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        color: const Color(0xff2c4260),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 16),
            const Text(
              'Distribusi Setoran Sampah',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      // Handle touch events if needed
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: sections,
                ),
              ),
            ),
            // Indikator legenda
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: sampahWeightMap.keys.map((key) {
                  final int index = sampahWeightMap.keys.toList().indexOf(key);
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        color: pieColors[index % pieColors.length],
                      ),
                      const SizedBox(width: 4),
                      Text(key, style: const TextStyle(color: Colors.white)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget untuk badge (label jenis sampah)
class _Badge extends StatelessWidget {
  const _Badge(this.text, {required this.size, required this.borderColor});

  final String text;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text.substring(0, 1), // Ambil huruf pertama untuk badge
            style: TextStyle(fontSize: size * .6, color: Colors.black),
          ),
        ),
      ),
    );
  }
}
