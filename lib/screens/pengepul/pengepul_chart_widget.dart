import 'package:fl_chart/fl_chart.dart'; // Ini yang sangat penting
import 'package:flutter/material.dart';
import 'package:bank_sampah_app/models/transaction.dart';
import 'package:intl/intl.dart';

class PengepulChartWidget extends StatelessWidget {
  final List<Transaction>
  transactions; // All relevant transactions for pengepul analysis

  const PengepulChartWidget({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Filter only completed setoran transactions
    final completedSetoran = transactions
        .where(
          (t) =>
              t.type == TransactionType.setoran &&
              t.status == TransactionStatus.completed,
        )
        .toList();

    if (completedSetoran.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada data setoran yang selesai untuk grafik Pengepul.',
        ),
      );
    }

    // Aggregate data by month for a line chart (total weight received)
    Map<String, double> monthlyWeightData =
        {}; // Format: 'YYYY-MM' : total_weight

    for (var transaction in completedSetoran) {
      final monthKey = DateFormat('yyyy-MM').format(transaction.timestamp);
      monthlyWeightData.update(
        monthKey,
        (value) => value + transaction.weightKg,
        ifAbsent: () => transaction.weightKg,
      );
    }

    // Sort months chronologically
    final sortedMonthKeys = monthlyWeightData.keys.toList()..sort();

    // Prepare data for LineChart
    List<FlSpot> spots = [];
    double maxY = 0;
    for (int i = 0; i < sortedMonthKeys.length; i++) {
      final month = sortedMonthKeys[i];
      final weight = monthlyWeightData[month] ?? 0.0;
      spots.add(FlSpot(i.toDouble(), weight));
      if (weight > maxY) {
        maxY = weight;
      }
    }

    // Add some padding to maxY for better visualization
    maxY = maxY * 1.1;
    if (maxY == 0) maxY = 1; // Avoid division by zero if all weights are 0

    return AspectRatio(
      aspectRatio: 1.5,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        color: const Color(0xff2c4260),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Total Berat Sampah Diterima (kg) per Bulan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < sortedMonthKeys.length) {
                              final month = sortedMonthKeys[value.toInt()];
                              // Solusi Alternatif: Gunakan Padding saja, hindari SideTitleWidget
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: 8.0,
                                ), // Sesuaikan padding
                                child: Text(
                                  month.substring(
                                    5,
                                  ), // Hanya tampilkan bulan (contoh: '06' untuk Juni)
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            // Solusi Alternatif: Gunakan Align saja, hindari SideTitleWidget
                            return Align(
                              alignment: Alignment
                                  .centerRight, // Agar teks sejajar kanan untuk sumbu kiri
                              child: Text(
                                '${value.toInt()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                          interval: (maxY / 4)
                              .ceilToDouble(), // Dynamic interval
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: const Color(0xff37434d),
                        width: 1,
                      ),
                    ),
                    minX: 0,
                    maxX: (sortedMonthKeys.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        gradient: const LinearGradient(
                          colors: [Colors.blueAccent, Colors.purpleAccent],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient:
                              const LinearGradient(
                                colors: [
                                  Colors.blueAccent,
                                  Colors.purpleAccent,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).withOpacity(
                                0.3,
                              ), // Menggunakan .withOpacity() langsung pada Gradient
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
