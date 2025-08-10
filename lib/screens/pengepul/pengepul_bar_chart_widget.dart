import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:bank_sampah_app/models/transaction.dart';

class PengepulBarChartWidget extends StatelessWidget {
  final List<Transaction> transactions;

  const PengepulBarChartWidget({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final completedSetoran = transactions
        .where(
          (t) =>
              t.type == TransactionType.setoran &&
              t.status == TransactionStatus.completed,
        )
        .toList();

    if (completedSetoran.isEmpty) {
      return const SizedBox.shrink(); // Widget kosong jika tidak ada data
    }

    Map<String, double> wasteWeightData = {};
    for (var transaction in completedSetoran) {
      wasteWeightData.update(
        transaction.sampahTypeName,
        (value) => value + transaction.weightKg,
        ifAbsent: () => transaction.weightKg,
      );
    }

    final sortedWasteTypes = wasteWeightData.keys.toList()..sort();
    double maxY = 0;
    for (var weight in wasteWeightData.values) {
      if (weight > maxY) {
        maxY = weight;
      }
    }
    maxY = maxY * 1.1;

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
                'Berat Sampah per Jenis (kg)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barGroups: sortedWasteTypes.asMap().entries.map((entry) {
                      final index = entry.key;
                      final type = entry.value;
                      final weight = wasteWeightData[type] ?? 0.0;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: weight,
                            color: Colors.blueAccent,
                            width: 15,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < sortedWasteTypes.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  sortedWasteTypes[index],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                            return const Text('');
                          },
                          reservedSize: 40,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${value.toInt()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                          interval: (maxY / 4).ceilToDouble(),
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return const FlLine(
                          color: Colors.grey,
                          strokeWidth: 0.5,
                          dashArray: [5, 5],
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
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
