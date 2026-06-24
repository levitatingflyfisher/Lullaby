import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/daily_summary.dart';

class SleepPatternChart extends StatelessWidget {
  const SleepPatternChart({super.key, required this.summaries});

  final List<DailySummary> summaries;

  static const _nightColor = Color(0xFF3949AB); // darker indigo

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
        .fold<double>(0, (max, s) => s.sleepHours > max ? s.sleepHours : max);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sleep Hours per Day',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _nightColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text('Sleep', style: theme.textTheme.bodySmall),
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
                            '${value.toInt()}h',
                            style: theme.textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(summaries.length, (i) {
                    final s = summaries[i];
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: s.sleepHours,
                          color: _nightColor,
                          width: summaries.length <= 7 ? 16 : 8,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
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
}
