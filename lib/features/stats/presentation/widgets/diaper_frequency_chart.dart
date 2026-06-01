import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/color_schemes.dart';
import '../../domain/entities/daily_summary.dart';

class DiaperFrequencyChart extends StatelessWidget {
  const DiaperFrequencyChart({super.key, required this.summaries});

  final List<DailySummary> summaries;

  static const _wetColor = Color(0xFF42A5F5);
  static const _dirtyColor = Color(0xFF8D6E63);
  static const _bothColor = AppColorSchemes.diaperColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (summaries.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data')),
      );
    }

    final maxY = summaries
        .fold<int>(0, (max, s) => s.diaperCount > max ? s.diaperCount : max)
        .toDouble();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Diapers per Day',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Row(
              children: [
                _legend(_wetColor, 'Wet'),
                const SizedBox(width: 12),
                _legend(_dirtyColor, 'Dirty'),
                const SizedBox(width: 12),
                _legend(_bothColor, 'Both'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: (maxY + 2).ceilToDouble(),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= summaries.length) {
                            return const SizedBox.shrink();
                          }
                          if (summaries.length > 7 && index % 2 != 0) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat.MMMd()
                                  .format(summaries[index].date),
                              style: theme.textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value != value.roundToDouble()) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            value.toInt().toString(),
                            style: theme.textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(summaries.length, (i) {
                    final s = summaries[i];
                    final wet = (s.diapersByType['wet'] ?? 0).toDouble();
                    final dirty = (s.diapersByType['dirty'] ?? 0).toDouble();
                    final both = (s.diapersByType['both'] ?? 0).toDouble();
                    final dry = (s.diapersByType['dry'] ?? 0).toDouble();

                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: wet + dirty + both + dry,
                          width: summaries.length <= 7 ? 16 : 8,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                          rodStackItems: [
                            BarChartRodStackItem(0, wet, _wetColor),
                            BarChartRodStackItem(wet, wet + dirty, _dirtyColor),
                            BarChartRodStackItem(
                                wet + dirty, wet + dirty + both, _bothColor),
                            if (dry > 0)
                              BarChartRodStackItem(wet + dirty + both,
                                  wet + dirty + both + dry, Colors.grey),
                          ],
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
